{ pkgs, ... }:
{
  # 采麟（sairin）：12 英寸 MacBook（2015，MacBook8,1），2304x1440 IPS（约 226 PPI）。
  imports = [ ../home/linux/gui ];

  dotfiles.desktop = {
    # 2304x1440 按 2 倍缩放，逻辑分辨率 1152x720；偏小的话可以改成 144（1.5 倍，1536x960）。
    dpi = 192;
    fontSize = 11;
    # 像素密度高，不做微调；IPS 是 RGB 条纹，开次像素渲染。
    hinting = "none";
    subpixel = "rgb";
    monitor = "eDP-1";
    networkInterface = "wlp1s0";
    battery = "BAT0";
    backlight = "intel_backlight";
    # Apple SMC 的键盘背光；如果 polybar 不显示，用 /sys/class/leds 下的实际名字核实。
    keyboardBacklight = "smc::kbd_backlight";
    # 系统层（homelab 的 nixos/macbook.nix）启用了 power-profiles-daemon。
    powerProfiles = true;
    wallpaper = "${pkgs.nixos-artwork.wallpapers.catppuccin-mocha.gnomeFilePath}";
  };

  dotfiles.packages = {
    cli.enable = true;
    dev.enable = true;
    cloud.enable = true;
    kubernetes.enable = true;
    ai.enable = true;
    gui.enable = true;
  };
}
