# atuin 的官方预编译二进制。
#
# 为什么不直接用 nixpkgs 的 atuin：稳定版 18.15.2 太旧，撞上本机已被迁移的数据库
# （"migration … previously applied but is missing"），所以只能跟 nixos-unstable。
# 但 unstable 的 atuin 在 aarch64-darwin 上没有 cache.nixos.org 产物，每次版本变动
# 都要本地从源码编这个 Rust 大工程（还会编 test 目标），能把 Mac 拖到 load 255。
# 这里直接取官方 GitHub release 的预编译包，按平台选资产，只装 bin/atuin，完全不编译。
#
# 升级：改下面的 version，再把两个 hash 换成对应 release 的 .sha256（去掉文件名即十六进制，
# 或转成 SRI）。只有 hash 变了才会重新下载，日常不会再触发任何构建。
{
  lib,
  stdenvNoCC,
  fetchurl,
}:
let
  version = "18.23.0";
  # 官方资产名形如 <id>/atuin。Linux 用 musl 静态包，省得再 patchelf。
  sources = {
    aarch64-darwin = {
      id = "aarch64-apple-darwin";
      hash = "sha256-yYi+HN4ZzXKVzmS8i5VdQvsYVeUifLZAyH/AnIQIw/w=";
    };
    x86_64-linux = {
      id = "x86_64-unknown-linux-musl";
      hash = "sha256-0bQN1ufNPYI4Z//iKzmgJbxCD3h1kmrpypdBVTeNoU0=";
    };
  };
  source =
    sources.${stdenvNoCC.hostPlatform.system}
      or (throw "atuin-bin: 没有 ${stdenvNoCC.hostPlatform.system} 的预编译包");
in
stdenvNoCC.mkDerivation {
  pname = "atuin";
  inherit version;

  src = fetchurl {
    url = "https://github.com/atuinsh/atuin/releases/download/v${version}/atuin-${source.id}.tar.gz";
    inherit (source) hash;
  };

  sourceRoot = "atuin-${source.id}";

  dontConfigure = true;
  dontBuild = true;
  dontStrip = true;

  installPhase = ''
    runHook preInstall
    install -Dm755 atuin $out/bin/atuin
    runHook postInstall
  '';

  meta = {
    description = "Magical shell history, as the official prebuilt binary";
    homepage = "https://github.com/atuinsh/atuin";
    license = lib.licenses.mit;
    mainProgram = "atuin";
    platforms = builtins.attrNames sources;
  };
}
