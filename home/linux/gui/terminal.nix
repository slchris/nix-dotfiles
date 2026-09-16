{ config, ... }:
let
  cfg = config.dotfiles.desktop;
in
{
  programs.alacritty = {
    enable = true;
    settings = {
      font = {
        normal.family = "Maple Mono NF CN";
        size = cfg.fontSize + 0.0;
      };
      window = {
        padding = {
          x = 12;
          y = 10;
        };
        dynamic_padding = true;
        # 由 picom 合成透明与背景模糊。
        opacity = 0.94;
      };
      cursor.style = {
        shape = "Beam";
        blinking = "On";
      };
      scrolling.history = 100000;
    };
  };
}
