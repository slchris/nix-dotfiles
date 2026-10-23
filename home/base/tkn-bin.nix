# tkn（Tekton CLI）的官方预编译二进制，另外以 kubectl-tkn 的名字再装一份，当 kubectl 插件用。
#
# 为什么不直接用 nixpkgs 的 tektoncd-cli：稳定版停在 0.45.0，缺 0.45.3 / 0.46.2 里的安全修复
# （gRPC-Go 的 CVE-2026-84304、Go 工具链的 CVE-2026-111943、bundle 解包时的无界内存分配）。
# unstable 也只到 0.46.1，而且它的 aarch64-darwin 产物在本机从 cache.nixos.org 反复拉不下来。
# 这里直接取官方 GitHub release 的预编译包，按平台选资产，完全不编译。
#
# 0.46 起 Hub CLI 并进了 tkn 本体，独立的 tkn hub 用法被废弃；查过自己的仓库没有用到。
#
# kubectl-tkn：官方文档的做法是 ln -s tkn kubectl-tkn，kubectl 在 PATH 里找到它就能
# kubectl tkn ...。注意 opencode 的 bash 权限只拦了 kubectl apply/delete/patch，
# 走 kubectl tkn 的写操作（例如 kubectl tkn pipeline start）不会被问。
#
# 升级：改下面的 version，再把 hash 换成该 release 的 checksums.txt 里对应资产的值
# （nix hash convert --hash-algo sha256 --to sri <十六进制>）。
{
  lib,
  stdenvNoCC,
  fetchurl,
  installShellFiles,
}:
let
  version = "0.46.2";
  # 官方资产名形如 tkn_<version>_<id>.tar.gz。Darwin 只发一个 universal 包。
  sources = {
    aarch64-darwin = {
      id = "Darwin_all";
      hash = "sha256-K+z+5KVrcgTuF4TpPtSwBGGhvEJO5kR/5YCOlEV9bQ4=";
    };
    x86_64-linux = {
      id = "Linux_x86_64";
      hash = "sha256-9thrx5YNha+U60b49ICsjRE6p454sV1vjS9T2A2qss4=";
    };
  };
  source =
    sources.${stdenvNoCC.hostPlatform.system}
      or (throw "tkn-bin: 没有 ${stdenvNoCC.hostPlatform.system} 的预编译包");
in
stdenvNoCC.mkDerivation {
  # 与 nixpkgs 同名，dotfiles.packages.exclude 里写 "tektoncd-cli" 照样生效。
  pname = "tektoncd-cli";
  inherit version;

  src = fetchurl {
    url = "https://github.com/tektoncd/cli/releases/download/v${version}/tkn_${version}_${source.id}.tar.gz";
    inherit (source) hash;
  };

  # 资产里文件直接在顶层，没有包一层目录。
  sourceRoot = ".";

  nativeBuildInputs = [ installShellFiles ];

  dontConfigure = true;
  dontBuild = true;
  dontStrip = true;

  installPhase = ''
    runHook preInstall
    install -Dm755 tkn $out/bin/tkn
    ln -s tkn $out/bin/kubectl-tkn
    runHook postInstall
  '';

  # nixpkgs 的包带补全，换成二进制后由 tkn 自己生成，免得 tab 补全变少。
  postInstall = ''
    installShellCompletion --cmd tkn \
      --bash <($out/bin/tkn completion bash) \
      --zsh <($out/bin/tkn completion zsh) \
      --fish <($out/bin/tkn completion fish)
  '';

  meta = {
    description = "Tekton CLI (tkn), as the official prebuilt binary";
    homepage = "https://tekton.dev/docs/cli/";
    changelog = "https://github.com/tektoncd/cli/releases/tag/v${version}";
    license = lib.licenses.asl20;
    mainProgram = "tkn";
    platforms = builtins.attrNames sources;
  };
}
