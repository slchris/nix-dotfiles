{ config, pkgs, ... }:
let
  cfg = config.dotfiles.desktop;
in
{
  programs.rofi = {
    enable = true;
    font = "Inter ${toString (cfg.fontSize + 1)}";
    terminal = "alacritty";
    plugins = [ pkgs.rofi-calc ];
    extraConfig = {
      modi = "drun,run,window,calc";
      show-icons = true;
      icon-theme = "Papirus-Dark";
      drun-display-format = "{name}";
      display-drun = "Apps";
      display-run = "Run";
      display-window = "Windows";
      display-calc = "Calc";
    };
  };
}
