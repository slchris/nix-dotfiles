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

  # 所有窗口共用中英文状态，切换窗口后不用重新切换。fcitx5 退出时会重写这个文件，每次部署都覆盖回来。
  xdg.configFile."fcitx5/config" = {
    force = true;
    text = ''
      [Behavior]
      ShareInputState=All
    '';
  };

  # nixpkgs 的 rime-ice 把上游的 default.yaml 改名为 rime_ice_suggestion.yaml，原位置只留一个空文件，
  # 不引入它就没有任何输入方案。方案只保留雾凇拼音全拼，左 Shift 切换中英文，候选词每页 7 个。
  # 词库用 rime-ice 自带的字表、基础、扩展与腾讯词库。
  xdg.dataFile."fcitx5/rime/default.custom.yaml" = {
    text = ''
      patch:
        __include: rime_ice_suggestion:/
        schema_list:
          - schema: rime_ice
        "menu/page_size": 7
    '';
    # Nix store 里文件的修改时间都是 1970 年，Rime 判断不出配置变了，要删掉编译结果才会重新部署（下次启动 fcitx5 时）。
    # Rime 备份时把只读的配置复制进 sync 目录，再次备份会因无法覆盖而报错，这里一并加上写权限。
    onChange = ''
      rm -f "${config.xdg.dataHome}/fcitx5/rime/build/default.yaml"
      chmod -R u+w "${config.xdg.dataHome}/fcitx5/rime/sync" 2>/dev/null || true
    '';
  };
}
