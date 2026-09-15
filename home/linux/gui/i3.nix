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

  # 窗口配色取自 Catppuccin 官方的 i3 配色方案。
  colorSet = border: text: {
    inherit border text;
    background = c.base;
    indicator = c.rosewater;
    childBorder = border;
  };
in
{
  # 由 home-manager 生成 ~/.xsession 启动 i3。部署时重启 display-manager 会直接杀掉会话，
  # graphical-session.target 与旧的 DISPLAY 留在 systemd 用户实例里；~/.xprofile 在下次登录时先清理它们。
  xsession.enable = true;
  # ~/.xsession 取代了 NixOS 的会话脚本，fcitx5、nm-applet 这些 XDG 自启动项要由它拉起。
  xdg.autostart.enable = true;

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
