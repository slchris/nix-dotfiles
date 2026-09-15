{ config, pkgs, ... }:
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
    size = 24;
    gtk.enable = true;
    x11.enable = true;
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
