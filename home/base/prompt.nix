# 终端提示符与 fzf 配色。放在通用层，Linux 桌面与 macOS 共用。
let
  c = import ../palette.nix;
in
{
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

  # 取自 Catppuccin 官方的 fzf 配色。fzf 未启用时这些设置不生效。
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
