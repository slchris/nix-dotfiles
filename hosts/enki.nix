{ lib, ... }:
{
  # 延麒（enki）：MacBook，aarch64-darwin。没有 Linux 桌面那一层。
  imports = [ ../home/darwin ];

  # 与 keiki 相同：bash、atuin、git、tmux 都已交给 home-manager。
  # gpg 仍用机器上现有的 ~/.gnupg：插卡签名一直正常，暂不接管配置文件。
  programs.gpg.enable = lib.mkForce false;

  dotfiles.packages = {
    cli.enable = true;
    dev.enable = true;
    cloud.enable = true;
    kubernetes.enable = true;
    ai.enable = true;
    # codeql、consul 这台轻量机不装：前者要从 GitHub 下约 1GB（实测卡住），后者是非自由软件要本机编译。
    # keiki 上这两个由 Homebrew 的 cask 提供，enki 的 cask 列表里没有，也不从 Nix 装。
    exclude = [
      "codeql"
      "consul"
    ];
  };
}
