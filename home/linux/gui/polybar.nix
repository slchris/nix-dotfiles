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
  px = n: n * cfg.scale;
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
        height = px 32;
        radius = px 10;
        inherit (cfg) dpi;
        # 悬浮样式：四周留出与 i3 间距一致的透明边框，由 picom 合成透明。
        border-top-size = px 6;
        border-left-size = px 12;
        border-right-size = px 12;
        border-color = "#00000000";
        background = c.base;
        foreground = c.text;
        line-size = px 3;
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
          ++ lib.optional (cfg.backlight != null) "backlight"
          ++ lib.optional (cfg.networkInterface != null) "network"
          ++ lib.optional (cfg.battery != null) "battery"
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

      "module/backlight" = lib.mkIf (cfg.backlight != null) {
        type = "internal/backlight";
        card = cfg.backlight;
        enable-scroll = true;
        format = "<ramp> <label>";
        ramp-0 = "󰃞";
        ramp-1 = "󰃟";
        ramp-2 = "󰃠";
        ramp-foreground = c.yellow;
        label = "%percentage%%";
      };

      "module/battery" = lib.mkIf (cfg.battery != null) {
        type = "internal/battery";
        battery = cfg.battery;
        adapter = "AC";
        full-at = 99;
        low-at = 15;
        poll-interval = 5;
        format-charging = "<label-charging>";
        label-charging = "󰂄 %percentage%%";
        label-charging-foreground = c.green;
        format-discharging = "<ramp-capacity> <label-discharging>";
        label-discharging = "%percentage%%";
        ramp-capacity-0 = "󰁺";
        ramp-capacity-0-foreground = c.red;
        ramp-capacity-1 = "󰁼";
        ramp-capacity-1-foreground = c.peach;
        ramp-capacity-2 = "󰁾";
        ramp-capacity-3 = "󰂀";
        ramp-capacity-4 = "󰁹";
        ramp-capacity-foreground = c.green;
        format-full = "<label-full>";
        label-full = "󰁹 %percentage%%";
        label-full-foreground = c.green;
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
