{
  # 窗口圆角、阴影与淡入淡出。
  services.picom = {
    enable = true;
    backend = "glx";
    # 系统层已为 NVIDIA 开启 ForceFullCompositionPipeline 防止撕裂，这里再开垂直同步会叠加一帧延迟。
    vSync = false;
    fade = true;
    fadeDelta = 4;
    shadow = true;
    shadowOpacity = 0.35;
    shadowExclude = [
      "window_type = 'dock'"
      "window_type = 'desktop'"
      "_GTK_FRAME_EXTENTS@"
    ];
    settings = {
      corner-radius = 10;
      rounded-corners-exclude = [
        "window_type = 'dock'"
        "window_type = 'desktop'"
      ];
      shadow-radius = 18;
      shadow-offset-x = -14;
      shadow-offset-y = -14;
      blur-method = "dual_kawase";
      blur-strength = 4;
      blur-background-exclude = [
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
