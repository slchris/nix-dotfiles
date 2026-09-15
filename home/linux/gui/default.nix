# Linux 桌面层：X11 + i3。系统层（显卡驱动、输入法框架、登录界面）在 homelab 仓库。
{
  imports = [
    ../../base
    ./apps.nix
    ./dunst.nix
    ./fcitx5.nix
    ./fonts.nix
    ./gtk.nix
    ./i3.nix
    ./lock.nix
    ./picom.nix
    ./polybar.nix
    ./power.nix
    ./rofi.nix
    ./screenshot.nix
    ./terminal.nix
  ];
}
