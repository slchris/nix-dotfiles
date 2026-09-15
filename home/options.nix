{ config, lib, ... }:
{
  # 每台机器不同的部分，在 hosts/<主机>.nix 里设置。
  options.dotfiles.desktop = {
    dpi = lib.mkOption {
      type = lib.types.int;
      default = 96;
      description = "Xft.dpi。按显示器的实际像素密度设置，4K 屏常用 144 到 192。";
    };
    scale = lib.mkOption {
      type = lib.types.ints.positive;
      default = config.dotfiles.desktop.dpi / 96;
      defaultText = "dpi / 96";
      description = "以像素为单位的尺寸（边框、间距、圆角、光标、锁屏）放大的倍数。";
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
    subpixel = lib.mkOption {
      type = lib.types.enum [
        "none"
        "rgb"
        "bgr"
      ];
      default = "rgb";
      description = "次像素渲染。OLED 屏的子像素不是 RGB 条纹排列，要设为 none。";
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
    battery = lib.mkOption {
      type = lib.types.nullOr lib.types.str;
      default = null;
      example = "BAT0";
      description = "/sys/class/power_supply 下的电池名；留空时 polybar 不显示电量。";
    };
    backlight = lib.mkOption {
      type = lib.types.nullOr lib.types.str;
      default = null;
      example = "intel_backlight";
      description = "/sys/class/backlight 下的设备名；设置后 polybar 显示亮度，亮度键可用。";
    };
    keyboardBacklight = lib.mkOption {
      type = lib.types.nullOr lib.types.str;
      default = null;
      example = "tpacpi::kbd_backlight";
      description = "/sys/class/leds 下的键盘背光；设置后用 Fn 键调节键盘背光时弹出提示。";
    };
    powerProfiles = lib.mkEnableOption "性能模式的快捷键与切换提示，系统层要启用 power-profiles-daemon";
  };
}
