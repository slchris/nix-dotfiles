# Mac 上的图形程序改回 Homebrew cask 管理：cask 列表由各主机在 hosts/<host> 里
# 通过 workstation.homebrew.casks 声明（见 homelab 的 darwin/homebrew.nix）。
#
# 为什么不在 Nix 里：这些 app 在 nixpkgs 里是把官方 dmg 重新打包，装到
# ~/Applications/Home Manager Apps，应用自带的自动更新失效、版本跟着 nixpkgs 走；而且
# home-manager 每次激活都要 App Management 权限去 rsync 那些 app bundle，否则激活直接中止。
# 交给 cask 后 app 能自更新，激活也不再要那个权限。
#
# 这里只留没有 .app 的命令行工具。
{ pkgs, ... }:
{
  home.packages = with pkgs; [
    android-tools
  ];
}
