{
  config,
  lib,
  pkgs,
  ...
}:
let
  cfg = config.dotfiles.desktop;
  c = import ./palette.nix;
  mod = "Mod4";

  screenshot = pkgs.writeShellScript "screenshot" ''
    # 框选区域截图：复制到剪贴板，同时保存到 ~/Pictures/Screenshots。
    dir="$HOME/Pictures/Screenshots"
    mkdir -p "$dir"
    file="$dir/$(date +%Y%m%d-%H%M%S).png"
    ${pkgs.maim}/bin/maim --select --hidecursor "$file" || exit 0
    ${pkgs.xclip}/bin/xclip -selection clipboard -t image/png < "$file"
    ${pkgs.libnotify}/bin/notify-send -i "$file" "截图已复制" "$file"
  '';

  # 窗口配色取自 Catppuccin 官方的 i3 配色方案。
  colorSet = border: text: {
    inherit border text;
    background = c.base;
    indicator = c.rosewater;
    childBorder = border;
  };
in
{
  # 由 home-manager 生成 ~/.xsession 启动 i3，LightDM 选 i3 会话时会执行它。
  # NixOS 自带的会话脚本只启动 graphical-session.target，退出 i3 后不会停止；只要 systemd 用户实例还在（例如开着 SSH），
  # xss-lock、polybar 等服务就一直绑定已失效的 DISPLAY，下次登录也不会重新启动。这个脚本在 i3 退出后停止这些服务。
  xsession.enable = true;

  xsession.windowManager.i3 = {
    enable = true;
    config = {
      modifier = mod;
      terminal = "alacritty";
      menu = "rofi -show drun";
      fonts = {
        names = [
          "Inter"
          "Source Han Sans SC"
          "Symbols Nerd Font"
        ];
        size = cfg.fontSize + 0.0;
      };

      window = {
        border = 2;
        titlebar = false;
        hideEdgeBorders = "none";
      };
      floating = {
        border = 2;
        titlebar = false;
        criteria = [
          { class = "Pavucontrol"; }
          { class = "Nm-connection-editor"; }
          { class = "fcitx5-config-qt"; }
          { class = ".blueman-manager-wrapped"; }
          { window_role = "pop-up"; }
          { window_role = "dialog"; }
          { window_type = "dialog"; }
        ];
      };
      gaps = {
        inner = 8;
        outer = 4;
      };
      focus.followMouse = false;

      colors = {
        focused = colorSet c.lavender c.text;
        focusedInactive = colorSet c.overlay0 c.text;
        unfocused = colorSet c.surface1 c.subtext0;
        urgent = colorSet c.peach c.peach;
        placeholder = colorSet c.overlay0 c.text;
        background = c.base;
      };

      # 状态栏用 polybar，不用 i3 自带的 i3bar。
      bars = [ ];

      startup = [
        # tray.target 在 i3 启动前就拉起 polybar，此时它的 i3 模块连不上 i3，所以由 i3 在启动和重载时重启 polybar。
        {
          command = "systemctl --user restart polybar";
          always = true;
          notification = false;
        }
        # 10 分钟无操作关闭显示器（锁屏见 lock.nix）。
        {
          command = "${pkgs.xset}/bin/xset dpms 600 600 600";
          notification = false;
        }
      ]
      ++ lib.optional (cfg.wallpaper != null) {
        command = "${pkgs.feh}/bin/feh --no-fehbg --bg-fill ${cfg.wallpaper}";
        always = true;
        notification = false;
      };

      # 在默认快捷键基础上追加或覆盖。
      keybindings = lib.mkOptionDefault {
        "${mod}+d" = "exec --no-startup-id rofi -show drun";
        "${mod}+Tab" = "exec --no-startup-id rofi -show window";
        "${mod}+b" = "exec google-chrome-stable";
        "${mod}+e" = "exec thunar";
        "${mod}+Shift+x" = "exec --no-startup-id loginctl lock-session";
        "${mod}+Shift+s" = "exec --no-startup-id ${screenshot}";
        "Print" = "exec --no-startup-id ${screenshot}";
        "XF86AudioRaiseVolume" =
          "exec --no-startup-id ${pkgs.pulseaudio}/bin/pactl set-sink-volume @DEFAULT_SINK@ +5%";
        "XF86AudioLowerVolume" =
          "exec --no-startup-id ${pkgs.pulseaudio}/bin/pactl set-sink-volume @DEFAULT_SINK@ -5%";
        "XF86AudioMute" =
          "exec --no-startup-id ${pkgs.pulseaudio}/bin/pactl set-sink-mute @DEFAULT_SINK@ toggle";
        "XF86AudioPlay" = "exec --no-startup-id ${pkgs.playerctl}/bin/playerctl play-pause";
        "XF86AudioNext" = "exec --no-startup-id ${pkgs.playerctl}/bin/playerctl next";
        "XF86AudioPrev" = "exec --no-startup-id ${pkgs.playerctl}/bin/playerctl previous";
      };
    };
  };
}
