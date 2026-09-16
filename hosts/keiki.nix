{ lib, ... }:
{
  # 景麒（keiki）：MacBook Pro，aarch64-darwin。没有 Linux 桌面那一层。
  imports = [ ../home/darwin ];

  # bash、atuin、git、tmux 都已交给 home-manager，机器上原来的内容搬进了 home/darwin/。
  # gpg 仍用机器上现有的 ~/.gnupg：插卡签名一直正常，暂不接管配置文件。
  programs.gpg.enable = lib.mkForce false;

  dotfiles.packages = {
    cli.enable = true;
    dev.enable = true;
    cloud.enable = true;
    kubernetes.enable = true;
    ai.enable = true;
    # 这两个由 Homebrew 的 cask 提供，不再从 Nix 装一份。两者都不在二进制缓存里：
    # codeql 要从 GitHub 下约 1GB（实测卡住），consul 是非自由软件要本机编译。
    exclude = [
      "codeql"
      "consul"
    ];
  };
}
