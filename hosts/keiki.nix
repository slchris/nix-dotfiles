{ lib, ... }:
{
  # 景麒（keiki）：MacBook Pro，aarch64-darwin。没有 Linux 桌面那一层。
  imports = [ ../home/darwin ];

  # bash 与 atuin 已交给 home-manager，机器上原来的内容搬进了 home/darwin/shell.nix。
  # 下面三项仍用机器上现有的那套，逐项对过再接管：
  # git 的 ~/.gitconfig 是手写的，gpg 与读卡器用 Homebrew 那份，tmux 配置还链着旧的 dotfiles 仓库。
  programs.git.enable = lib.mkForce false;
  programs.gpg.enable = lib.mkForce false;
  programs.tmux.enable = lib.mkForce false;

  dotfiles.packages = {
    cli.enable = true;
    dev.enable = true;
    cloud.enable = true;
    kubernetes.enable = true;
    ai.enable = true;
    # Mac 上这三个由 Homebrew 的 cask 提供，不再从 Nix 装一份。
    # codeql 与 consul 都不在二进制缓存里：codeql 要从 GitHub 下约 1GB（实测卡住），consul 要本机编译。
    exclude = [
      "codeql"
      "consul"
      "google-cloud-sdk"
    ];
  };
}
