{ pkgs, ... }:
{
  # 泰麒（taiki）：家里的工作站，24 英寸 1080p 显示器（约 92 DPI），GTX 1080。
  # 这里只放与机器有关的设置，个人身份在 users/ 下，使用方把两者一起引用。
  imports = [ ../home/linux/gui ];

  dotfiles.desktop = {
    dpi = 96;
    fontSize = 11;
    # 1080p 像素密度低，轻度微调让字形边缘更清晰。
    hinting = "slight";
    monitor = "DP-0";
    networkInterface = "enp5s0f1";
    wallpaper = "${pkgs.nixos-artwork.wallpapers.catppuccin-mocha.gnomeFilePath}";
  };

  dotfiles.packages = {
    cli.enable = true;
    dev.enable = true;
    cloud.enable = true;
    kubernetes.enable = true;
    gui.enable = true;
  };

  # 与 Mac 同步文件，界面在 http://127.0.0.1:8384，首次使用要在两端互相添加设备。
  services.syncthing.enable = true;
}
