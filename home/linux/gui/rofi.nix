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
  # Mod+p 搜索 pass 条目，选中后复制口令或自动输入。
  programs.rofi.pass = lib.mkIf config.dotfiles.pass.enable {
    enable = true;
    stores = [ config.programs.password-store.settings.PASSWORD_STORE_DIR ];
  };
  xsession.windowManager.i3.config.keybindings = lib.mkIf config.dotfiles.pass.enable (
    lib.mkOptionDefault { "Mod4+p" = "exec --no-startup-id rofi-pass"; }
  );

  programs.rofi = {
    enable = true;
    font = "Inter ${toString (cfg.fontSize + 1)}";
    terminal = "alacritty";
    plugins = [ pkgs.rofi-calc ];
    extraConfig = {
      modi = "drun,run,window,calc";
      dpi = cfg.dpi;
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
