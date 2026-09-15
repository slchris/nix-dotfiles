{ config, ... }:
let
  cfg = config.dotfiles.desktop;
  c = import ./palette.nix;
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
      # 音量、亮度等提示里的进度条，颜色由 osd 脚本按类别用 hlcolor 指定。
      progress_bar_height = 8;
      progress_bar_frame_width = 0;
      progress_bar_corner_radius = 4;
      progress_bar_max_width = 380;
    };

    # osd 脚本（osd.nix）发出的提示：不进通知历史，边框用强调色。
    settings.osd = {
      appname = "OSD";
      history_ignore = true;
      frame_color = c.lavender;
    };
  };
}
