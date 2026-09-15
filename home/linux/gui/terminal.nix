{ config, ... }:
let
  cfg = config.dotfiles.desktop;
  c = import ./palette.nix;
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

  programs.starship = {
    enable = true;
    settings = {
      palette = "catppuccin_mocha";
      palettes.catppuccin_mocha = removeAttrs c [ ];
      directory.style = "bold lavender";
      git_branch.style = "bold mauve";
      character = {
        success_symbol = "[❯](bold green)";
        error_symbol = "[❯](bold red)";
      };
    };
  };

  # 取自 Catppuccin 官方的 fzf 配色。
  programs.fzf.colors = {
    "bg+" = c.surface0;
    bg = c.base;
    spinner = c.rosewater;
    hl = c.red;
    fg = c.text;
    header = c.red;
    info = c.mauve;
    pointer = c.rosewater;
    marker = c.lavender;
    "fg+" = c.text;
    prompt = c.mauve;
    "hl+" = c.red;
    selected-bg = c.surface1;
    border = c.overlay0;
    label = c.text;
  };
}
