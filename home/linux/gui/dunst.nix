{ config, ... }:
let
  cfg = config.dotfiles.desktop;
in
{
  services.dunst = {
    enable = true;
    settings.global = {
      font = "Inter ${toString cfg.fontSize}";
      origin = "top-right";
      offset = "(16, 48)";
      width = 380;
      gap_size = 8;
      padding = 12;
      horizontal_padding = 14;
      frame_width = 2;
      corner_radius = 10;
      icon_theme = "Papirus-Dark";
      enable_recursive_icon_lookup = true;
      max_icon_size = 48;
    };
  };
}
