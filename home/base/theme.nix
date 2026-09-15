{
  catppuccin = {
    # 所有支持 Catppuccin 的程序默认启用配色。
    enable = true;
    flavor = "mocha";
    accent = "lavender";

    # 以下模块在求值时读取主题源文件（import from derivation）。在 Mac 上求值时，这些读取会被派给
    # Linux 构建机，所以关闭，改为按 home/linux/gui/palette.nix 的色板手写配色。
    polybar.enable = false; # home/linux/gui/polybar.nix
    starship.enable = false; # home/linux/gui/terminal.nix
    fzf.enable = false; # home/linux/gui/terminal.nix

    # nixpkgs 已把 gemini-cli 改名为 antigravity-cli，catppuccin 的 v26.05 版本仍引用旧选项名，求值会报改名警告。
    gemini-cli.enable = false;
  };
}
