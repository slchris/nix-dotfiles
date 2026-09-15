{ config, ... }:
let
  inherit (config.dotfiles.desktop) scale;
in
{
  # picom 包自带 XDG 自启动项，会在 systemd 服务之外再启动一份并报错退出，这里隐藏它。
  xdg.configFile."autostart/picom.desktop".text = ''
    [Desktop Entry]
    Hidden=true
  '';

  # 窗口圆角、阴影与淡入淡出。
  services.picom = {
    enable = true;
    backend = "glx";
    # 系统层已为 NVIDIA 开启 ForceFullCompositionPipeline 防止撕裂，这里再开垂直同步会叠加一帧延迟。
    vSync = false;
    fade = true;
    fadeDelta = 4;
    fadeExclude = [ "class_g = 'flameshot'" ];
    shadow = true;
    shadowOpacity = 0.35;
    shadowExclude = [
      "class_g = 'flameshot'"
      "window_type = 'dock'"
      "window_type = 'desktop'"
      "_GTK_FRAME_EXTENTS@"
    ];
    settings = {
      corner-radius = 10 * scale;
      rounded-corners-exclude = [
        "class_g = 'flameshot'"
        "window_type = 'dock'"
        "window_type = 'desktop'"
      ];
      shadow-radius = 18 * scale;
      shadow-offset-x = -14 * scale;
      shadow-offset-y = -14 * scale;
      blur-method = "dual_kawase";
      blur-strength = 4;
      blur-background-exclude = [
        "class_g = 'flameshot'"
        "window_type = 'dock'"
        "window_type = 'desktop'"
        "_GTK_FRAME_EXTENTS@"
      ];
      # 全屏程序（游戏、视频）绕过合成器，减少延迟。
      unredir-if-possible = true;
      use-damage = true;
      detect-rounded-corners = true;
      detect-client-opacity = true;
    };
  };
}
