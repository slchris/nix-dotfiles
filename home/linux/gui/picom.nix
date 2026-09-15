{ config, lib, ... }:
let
  inherit (config.dotfiles.desktop) scale;
in
{
  # picom 包自带 XDG 自启动项，会在 systemd 服务之外再启动一份并报错退出，这里隐藏它。
  xdg.configFile."autostart/picom.desktop".text = ''
    [Desktop Entry]
    Hidden=true
  '';

  # 窗口圆角、阴影、淡入淡出，以及通知弹出时的动画。
  services.picom = {
    enable = true;

    # 按窗口设置动画要用 picom 12 起的 window rules（写在 extraConfig 里，home-manager 的 settings
    # 只能生成 [ ] 数组，写不出 rules 需要的 ( { … } ) 列表）。启用 rules 后 fade-exclude、shadow-exclude、
    # opacity-rule、wintypes 这些旧选项全部失效并报警告，而 home-manager 模块总会写出它们，
    # 所以整体覆盖 settings，只保留仍然有效的全局选项；原来的排除规则搬到下面的 rules 里。
    settings = lib.mkForce {
      backend = "glx";
      # 系统层已为 NVIDIA 开启 ForceFullCompositionPipeline 防止撕裂，这里再开垂直同步会叠加一帧延迟。
      vsync = false;
      fading = true;
      fade-delta = 4;
      fade-in-step = 0.028;
      fade-out-step = 0.03;
      shadow = true;
      shadow-opacity = 0.35;
      shadow-radius = 18 * scale;
      shadow-offset-x = -14 * scale;
      shadow-offset-y = -14 * scale;
      corner-radius = 10 * scale;
      blur-method = "dual_kawase";
      blur-strength = 4;
      # 全屏程序（游戏、视频）绕过合成器，减少延迟。
      unredir-if-possible = true;
      use-damage = true;
      detect-rounded-corners = true;
      detect-client-opacity = true;
    };

    extraConfig = ''
      rules = (
        # 截图工具要拍到原样的屏幕，不加任何效果。
        { match = "class_g = 'flameshot'"; shadow = false; fade = false; corner-radius = 0; blur-background = false; },
        { match = "window_type = 'dock' || window_type = 'desktop'"; shadow = false; corner-radius = 0; blur-background = false; },
        # GTK 客户端装饰的窗口自己画阴影。
        { match = "_GTK_FRAME_EXTENTS@"; shadow = false; blur-background = false; },
        # 旧选项下全屏窗口默认不做圆角，rules 下要显式写出。
        { match = "fullscreen"; corner-radius = 0; },
        # 通知与音量、亮度等提示：弹出时从略小放大并淡入，消失时反向。
        { match = "window_type = 'notification' || class_g = 'Dunst'";
          animations = (
            { triggers = [ "open", "show" ]; preset = "appear"; scale = 0.9; duration = 0.18; },
            { triggers = [ "close", "hide" ]; preset = "disappear"; scale = 0.9; duration = 0.15; }
          );
        }
      );
    '';
  };
}
