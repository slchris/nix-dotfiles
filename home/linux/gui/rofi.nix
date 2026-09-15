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
      display-drun = "应用";
      display-run = "命令";
      display-window = "窗口";
      display-calc = "计算";
    };
  };
}
