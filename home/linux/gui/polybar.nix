{
  config,
  lib,
  pkgs,
  ...
}:
let
  cfg = config.dotfiles.desktop;
  c = import ./palette.nix;
  size = toString cfg.fontSize;
in
{
  services.polybar = {
    enable = true;
    package = pkgs.polybar.override {
      i3Support = true;
      pulseSupport = true;
    };
    # 实际由 i3 在启动时执行 systemctl --user restart polybar，见 i3.nix。
    script = "polybar main &";
    settings = {
      "bar/main" = {
        width = "100%";
        height = 32;
        radius = 10;
        # 悬浮样式：四周留出与 i3 间距一致的透明边框，由 picom 合成透明。
        border-top-size = 6;
        border-left-size = 12;
        border-right-size = 12;
        border-color = "#00000000";
        background = c.base;
        foreground = c.text;
        line-size = 3;
        padding-left = 1;
        padding-right = 2;
        module-margin = 1;
        separator = "·";
        separator-foreground = c.surface2;
        font-0 = "Inter:size=${size};3";
        font-1 = "Source Han Sans SC:size=${size};3";
        font-2 = "Symbols Nerd Font Mono:size=${toString (cfg.fontSize + 2)};3";
        modules-left = "i3";
        modules-center = "xwindow";
        modules-right = lib.concatStringsSep " " (
          [
            "cpu"
            "memory"
            "pulseaudio"
          ]
          ++ lib.optional (cfg.networkInterface != null) "network"
          ++ [
            "date"
            "tray"
            "power"
          ]
        );
        cursor-click = "pointer";
        enable-ipc = true;
        wm-restack = "i3";
      }
      // lib.optionalAttrs (cfg.monitor != null) { inherit (cfg) monitor; };

      "module/i3" = {
        type = "internal/i3";
        pin-workspaces = true;
        index-sort = true;
        enable-scroll = false;
        label-focused = "%index%";
        label-focused-foreground = c.lavender;
        label-focused-background = c.surface0;
        label-focused-underline = c.lavender;
        label-focused-padding = 2;
        label-unfocused = "%index%";
        label-unfocused-foreground = c.overlay1;
        label-unfocused-padding = 2;
        label-visible = "%index%";
        label-visible-foreground = c.subtext0;
        label-visible-padding = 2;
        label-urgent = "%index%";
        label-urgent-foreground = c.base;
        label-urgent-background = c.red;
        label-urgent-padding = 2;
        label-mode = "%mode%";
        label-mode-foreground = c.base;
        label-mode-background = c.peach;
        label-mode-padding = 2;
      };

      "module/xwindow" = {
        type = "internal/xwindow";
        label = "%title:0:60:…%";
        label-foreground = c.subtext0;
      };

      "module/cpu" = {
        type = "internal/cpu";
        interval = 2;
        format-prefix = "󰘚 ";
        format-prefix-foreground = c.sapphire;
        label = "%percentage:2%%";
      };

      "module/memory" = {
        type = "internal/memory";
        interval = 3;
        format-prefix = "󰍛 ";
        format-prefix-foreground = c.green;
        label = "%percentage_used:2%%";
      };

      "module/pulseaudio" = {
        type = "internal/pulseaudio";
        format-volume = "<ramp-volume> <label-volume>";
        ramp-volume-0 = "󰕿";
        ramp-volume-1 = "󰖀";
        ramp-volume-2 = "󰕾";
        ramp-volume-foreground = c.peach;
        label-muted = "󰝟 Muted";
        label-muted-foreground = c.overlay0;
        click-right = "pavucontrol";
      };

      "module/network" = lib.mkIf (cfg.networkInterface != null) {
        type = "internal/network";
        interface = cfg.networkInterface;
        interval = 3;
        label-connected = "󰈀 %downspeed:8%";
        label-connected-foreground = c.teal;
        label-disconnected = "󰈂 Offline";
        label-disconnected-foreground = c.red;
      };

      "module/date" = {
        type = "internal/date";
        interval = 1;
        date = "%a %b %d";
        time = "%H:%M";
        format-prefix = "󰃭 ";
        format-prefix-foreground = c.lavender;
        label = "%date%  %time%";
      };

      "module/tray" = {
        type = "internal/tray";
        tray-spacing = 8;
        tray-size = "70%";
      };
    };
  };
}
