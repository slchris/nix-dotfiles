# Mac 上的图形程序。原来由 Homebrew 的 cask 安装，改由 Nix 管理。
#
# nixpkgs 里这些基本是把官方 dmg 重新打包，装出来在 ~/Applications/Home Manager Apps。
# 代价是应用自带的自动更新不再生效，版本跟着 nixpkgs 走，更新要靠 nix flake update nixpkgs。
{ pkgs, ... }:
{
  home.packages = with pkgs; [
    android-tools
    dbeaver-bin
    lmstudio
    notion-app
    obsidian
    postman
    wireshark # Qt 界面，同时提供 tshark
    zoom-us
  ];
}
