{ pkgs, ... }:
{
  # 塙麟（hanrin）：ThinkPad X1 Carbon Gen 12，14 英寸 2880x1800 OLED（约 243 PPI）。
  imports = [ ../home/linux/gui ];

  dotfiles.desktop = {
    # 按 2 倍缩放，逻辑分辨率相当于 1440x900。
    dpi = 192;
    fontSize = 11;
    # 像素密度高，不需要微调；OLED 子像素不是 RGB 条纹，用灰度抗锯齿。
    hinting = "none";
    subpixel = "none";
    monitor = "eDP-1";
    networkInterface = "wlp0s20f3";
    battery = "BAT0";
    backlight = "intel_backlight";
    wallpaper = "${pkgs.nixos-artwork.wallpapers.catppuccin-mocha.gnomeFilePath}";
  };

  dotfiles.packages = {
    cli.enable = true;
    dev.enable = true;
    cloud.enable = true;
    kubernetes.enable = true;
    gui.enable = true;
  };
}
