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
  home.packages = with pkgs; [
    inter # 西文界面
    source-serif # 西文衬线，字族名 Source Serif 4
    source-han-sans # 思源黑体，中文界面
    source-han-serif # 思源宋体
    maple-mono.NF-CN # 等宽，中英文宽度 2:1，内置 Nerd Font 图标；带微调版本，适合 1080p
    nerd-fonts.symbols-only # 其他字体缺少的图标
    noto-fonts-color-emoji
  ];

  fonts.fontconfig = {
    enable = true;
    # 同一类字体按顺序回退：西文字形优先，缺字时用中文字体，最后是表情符号。
    # 中文字体写明 SC，避免汉字按日文字形显示。
    defaultFonts = {
      sansSerif = [
        "Inter"
        "Source Han Sans SC"
        "Noto Color Emoji"
      ];
      serif = [
        "Source Serif 4"
        "Source Han Serif SC"
        "Noto Color Emoji"
      ];
      monospace = [
        "Maple Mono NF CN"
        "Symbols Nerd Font Mono"
        "Noto Color Emoji"
      ];
      emoji = [ "Noto Color Emoji" ];
    };
    antialiasing = true;
    inherit (cfg) hinting;
    subpixelRendering = "rgb";
  };

  xresources.properties = {
    "Xft.dpi" = cfg.dpi;
    "Xft.antialias" = 1;
    "Xft.hinting" = if cfg.hinting == "none" then 0 else 1;
    "Xft.hintstyle" = "hint${cfg.hinting}";
    "Xft.rgba" = "rgb";
    "Xft.lcdfilter" = "lcddefault";
  };

  # home-manager 默认在部署时把 .Xresources 合并进当前 X 会话，只要环境里有 DISPLAY 就执行。
  # 用户退出后，systemd 用户实例里仍残留旧的 DISPLAY，此时 :0 上是登录界面，合并失败会让整个部署回滚。
  # 登录时 NixOS 的会话脚本会加载 .Xresources，所以连不上当前会话时直接跳过。
  home.file."${config.home.homeDirectory}/.Xresources".onChange = lib.mkForce ''
    if [[ -v DISPLAY ]]; then
      ${lib.getExe pkgs.xrdb} -merge ${config.home.homeDirectory}/.Xresources 2>/dev/null || true
    fi
  '';
}
