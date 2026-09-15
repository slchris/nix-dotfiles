{
  config,
  lib,
  pkgs,
  ...
}:
let
  cfg = config.dotfiles.desktop;
in
{
  # catppuccin/nix 已移除 GTK 主题（上游已归档），GTK 程序用 adw-gtk3 暗色主题。
  gtk = {
    enable = true;
    theme = {
      name = "adw-gtk3-dark";
      package = pkgs.adw-gtk3;
    };
    font = {
      name = "Inter";
      size = cfg.fontSize;
    };
    gtk3.extraConfig.gtk-application-prefer-dark-theme = 1;
    gtk4.extraConfig.gtk-application-prefer-dark-theme = 1;
  };

  # 图标（Papirus，文件夹颜色跟随强调色）与光标由 catppuccin 模块提供。
  catppuccin.gtk.icon.enable = true;
  catppuccin.cursors.enable = true;
  home.pointerCursor = {
    size = 24 * cfg.scale;
    gtk.enable = true;
    x11.enable = true;
  };

  # 高分屏上 GTK 3 按整数倍放大界面，字号已由 Xft.dpi 放大，这里抵消掉一次。Qt 6 按 Xft.dpi 计算缩放。
  home.sessionVariables = lib.mkIf (cfg.scale > 1) {
    GDK_SCALE = cfg.scale;
    GDK_DPI_SCALE = "0.5";
    QT_AUTO_SCREEN_SCALE_FACTOR = 1;
  };

  # Qt 程序用 Kvantum 引擎，配色由 catppuccin 模块提供。
  qt = {
    enable = true;
    platformTheme.name = "kvantum";
    style.name = "kvantum";
  };

  # Chrome 等程序按这个值决定是否使用暗色界面。
  dconf.settings."org/gnome/desktop/interface" = {
    color-scheme = "prefer-dark";
    gtk-theme = "adw-gtk3-dark";
  };
}
