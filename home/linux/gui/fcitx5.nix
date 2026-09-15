{ config, ... }:
let
  cfg = config.dotfiles.desktop;
  cat = config.catppuccin;
  theme = "catppuccin-${cat.flavor}-${cat.accent}";
  themes = cat.sources.fcitx5.override { enableRounded = true; };
in
{
  # 输入法框架与雾凇拼音在系统层（homelab）启用。catppuccin 自带的 fcitx5 模块要求在
  # home-manager 里启用输入法，这里改为直接放皮肤文件并写入 classicui 配置。
  xdg.dataFile."fcitx5/themes/${theme}".source = "${themes}/share/fcitx5/themes/${theme}";

  xdg.configFile."fcitx5/conf/classicui.conf" = {
    # 在 fcitx5 设置界面改动后，它会重写这个文件；每次部署都覆盖回来。
    force = true;
    text = ''
      Vertical Candidate List=False
      PerScreenDPI=True
      Font="Source Han Sans SC ${toString (cfg.fontSize + 1)}"
      MenuFont="Inter ${toString cfg.fontSize}"
      TrayFont="Inter Bold ${toString cfg.fontSize}"
      Theme=${theme}
      DarkTheme=${theme}
      UseDarkTheme=False
    '';
  };

  # 雾凇拼音：候选词每页 7 个。
  xdg.dataFile."fcitx5/rime/default.custom.yaml".text = ''
    patch:
      "menu/page_size": 7
  '';
}
