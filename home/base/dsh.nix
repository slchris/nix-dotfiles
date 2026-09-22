# DeepSeek Harness（dsh）与 kixparadigm 预设。
#
# dsh 本体在 NUR（nixpkgs 还没有，见 nur 的 pkgs/deepseek-harness）；kixparadigm 是它的
# agent-preset：常驻认知层 + kixpower 多智能体编排，见 nur 的 pkgs/kixparadigm。
# 上游的安装器（npm i -g kixparadigm）只是把 preset 目录拷进 ~/.dsh/.agent-presets/，
# 这里由 activation 做同样的事——必须是真目录：dsh 的 preset 发现用
# readdir(withFileTypes).isDirectory()，软链会被跳过。
#
# 升级：nix flake update nur-slchris（版本钉在 nur 的 pkgs/kixparadigm）。
#
# 目前只在 Darwin 上启用：nur 的 deepseek-harness 的 npmDepsHash 是按 darwin 算的，
# 要上 Linux 得先在 Linux 上取 hash 再按平台分列。
{
  config,
  lib,
  nurPkgs,
  pkgs,
  ...
}:
let
  cfg = config.dotfiles.packages;
in
{
  config = lib.mkIf (cfg.ai.enable && pkgs.stdenv.hostPlatform.isDarwin) {
    home.packages = [ nurPkgs.deepseek-harness ];

    # 只接管这两个 id，~/.dsh/.agent-presets 下别的东西不动。
    home.activation.kixparadigmPresets = lib.hm.dag.entryAfter [ "writeBoundary" ] ''
      presets="$HOME/.dsh/.agent-presets"
      ${pkgs.coreutils}/bin/mkdir -p "$presets"
      for id in kixparadigm kixparadigm-classic; do
        ${pkgs.coreutils}/bin/rm -rf "$presets/$id"
        ${pkgs.coreutils}/bin/cp -RL ${nurPkgs.kixparadigm}/presets/$id "$presets/$id"
        # store 里的文件是只读的，拷出来要恢复属主可写，下次 activation 才删得掉。
        ${pkgs.coreutils}/bin/chmod -R u+rwX "$presets/$id"
      done
    '';
  };
}
