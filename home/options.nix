{ lib, ... }:
{
  # 每台机器不同的部分，在 hosts/<主机>.nix 里设置。
  options.dotfiles.desktop = {
    dpi = lib.mkOption {
      type = lib.types.int;
      default = 96;
      description = "Xft.dpi。按显示器的实际像素密度设置，4K 屏常用 144 到 192。";
    };
    fontSize = lib.mkOption {
      type = lib.types.int;
      default = 11;
      description = "界面、终端、状态栏的基础字号（pt）。";
    };
    hinting = lib.mkOption {
      type = lib.types.enum [
        "none"
        "slight"
        "medium"
        "full"
      ];
      default = "slight";
      description = "字体微调。1080p 这类低像素密度的屏幕用 slight 更清晰，4K 屏用 none 更接近原始字形。";
    };
    wallpaper = lib.mkOption {
      type = lib.types.nullOr lib.types.path;
      default = null;
      description = "桌面壁纸。";
    };
    monitor = lib.mkOption {
      type = lib.types.nullOr lib.types.str;
      default = null;
      example = "DP-0";
      description = "polybar 所在的显示器，填 xrandr 输出里的名字；留空时由 polybar 自己选择。";
    };
    networkInterface = lib.mkOption {
      type = lib.types.nullOr lib.types.str;
      default = null;
      example = "enp5s0f1";
      description = "polybar 显示网速的网卡；留空时不显示网络模块。";
    };
  };
}
