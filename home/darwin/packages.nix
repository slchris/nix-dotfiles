# Mac 上要由 Nix 提供的软件。Linux 机器上这些来自系统层（homelab 的 NixOS 配置），
# macOS 没有系统层可依赖，只能装在用户这一层。
#
# 目标是把 Homebrew 的 formula 全部换成 Nix，Homebrew 只留 cask。
{ pkgs, ... }:
{
  home.packages = with pkgs; [
    # GNU 工具。macOS 自带的是 BSD 版：bash 3.2 没有 mapfile，BSD grep 没有 -P，BSD realpath 没有 -m。
    bashInteractive
    coreutils
    gnugrep

    # 日常命令行
    bat
    btop
    fastfetch
    fd
    fzf
    htop
    jq
    mtr
    ncdu
    p7zip
    ripgrep
    rsync
    tmux
    tree
    wget

    # OpenPGP 卡。gpg-agent 兼作 SSH agent，pinentry-mac 弹图形界面输入 PIN。
    gnupg
    pinentry_mac

    # HashiCorp 的工具。BUSL 许可，缓存里没有，第一次装要在本机编译几分钟。
    # 只装在 Mac 上：taiki 与 hanrin 用不到，不必陪着编译。
    nomad
    packer
    terraform
    vault

    # 其他
    freerdp
    mpv
    syncthing
    terminal-notifier
  ];
}
