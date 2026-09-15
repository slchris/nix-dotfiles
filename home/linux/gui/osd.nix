{
  config,
  lib,
  pkgs,
  ...
}:
let
  cfg = config.dotfiles.desktop;
  c = import ./palette.nix;
  rofi = "${config.programs.rofi.finalPackage}/bin/rofi";

  # 调节音量、麦克风、亮度、性能模式等之后弹出的提示（OSD）。每类提示带自己的 stack tag，
  # dunst 原地替换同类提示而不是堆叠；value 提示显示进度条，hlcolor 设置进度条颜色。
  osd = pkgs.writeShellApplication {
    name = "osd";
    runtimeInputs = with pkgs; [
      brightnessctl
      coreutils
      gawk
      libnotify
      systemd
      util-linux
      wireplumber
      xrandr
    ];
    text = ''
      # notify <类别> <标题> <正文> [进度 0-100] [进度条颜色]
      notify() {
        local args=(--app-name=OSD --urgency=low --expire-time=1500 --transient
          --hint="string:x-dunst-stack-tag:osd-$1")
        if [[ $# -ge 4 ]]; then
          args+=(--hint="int:value:$4" --hint="string:hlcolor:''${5:-${c.lavender}}")
        fi
        notify-send "''${args[@]}" "$2" "$3"
      }

      # wpctl get-volume 的输出形如 "Volume: 0.45"，静音时末尾多一个 [MUTED]。
      percent() {
        awk '{ printf "%d", $2 * 100 + 0.5 }' <<<"$1"
      }

      volume() {
        case "$1" in
          up)
            wpctl set-mute @DEFAULT_AUDIO_SINK@ 0
            wpctl set-volume --limit 1.0 @DEFAULT_AUDIO_SINK@ 5%+
            ;;
          down) wpctl set-volume @DEFAULT_AUDIO_SINK@ 5%- ;;
          mute) wpctl set-mute @DEFAULT_AUDIO_SINK@ toggle ;;
        esac
        local out pct
        out=$(wpctl get-volume @DEFAULT_AUDIO_SINK@)
        pct=$(percent "$out")
        if [[ $out == *MUTED* ]]; then
          notify volume "󰝟  Muted" "$pct%" "$pct" "${c.overlay0}"
        elif ((pct < 34)); then
          notify volume "󰕿  Volume" "$pct%" "$pct"
        elif ((pct < 67)); then
          notify volume "󰖀  Volume" "$pct%" "$pct"
        else
          notify volume "󰕾  Volume" "$pct%" "$pct"
        fi
      }

      mic() {
        wpctl set-mute @DEFAULT_AUDIO_SOURCE@ toggle
        if [[ $(wpctl get-volume @DEFAULT_AUDIO_SOURCE@) == *MUTED* ]]; then
          notify mic "󰍭  Microphone" "Muted"
        else
          notify mic "󰍬  Microphone" "On"
        fi
      }

      brightness() {
        local device=$1 pct
        case "$2" in
          up) brightnessctl --quiet --device="$device" set 5%+ ;;
          # 最低留原始亮度值 1：OLED 屏调到 0 会完全黑屏，看起来像死机。
          down) brightnessctl --quiet --device="$device" --min-value=1 set 5%- ;;
        esac
        # --machine-readable 的输出形如 intel_backlight,backlight,132,33%,400。
        pct=$(brightnessctl --device="$device" --machine-readable | cut -d, -f4)
        pct=''${pct%\%}
        notify brightness "󰃠  Brightness" "$pct%" "$pct" "${c.yellow}"
      }

      keyboard() {
        # 键盘背光由固件直接调节，按键事件到达时亮度可能还没更新，稍等再读。
        sleep 0.2
        local led=/sys/class/leds/$1 level max
        level=$(<"$led/brightness")
        max=$(<"$led/max_brightness")
        notify keyboard "󰌌  Keyboard backlight" "$level / $max" "$((level * 100 / max))" "${c.yellow}"
      }

      airplane() {
        # 内核的 rfkill-input 已经切换了无线开关，这里只读取切换后的状态。
        sleep 0.3
        local state
        state=$(rfkill --noheadings --output SOFT)
        if [[ $state == *unblocked* ]]; then
          notify airplane "󰀞  Airplane mode" "Off"
        else
          notify airplane "󰀝  Airplane mode" "On"
        fi
      }

      profile() {
        local property=(net.hadess.PowerProfiles /net/hadess/PowerProfiles net.hadess.PowerProfiles ActiveProfile)
        case "$1" in
          cycle)
            local current next
            # busctl 的输出形如 s "balanced"。提示由 power-profile-osd 服务在属性变化时弹出。
            current=$(busctl --system get-property "''${property[@]}" | cut -d'"' -f2)
            case "$current" in
              power-saver) next=balanced ;;
              balanced) next=performance ;;
              *) next=power-saver ;;
            esac
            busctl --system set-property "''${property[@]}" s "$next"
            ;;
          show)
            case "$2" in
              power-saver) notify profile "󰌪  Power saver" "Longer battery life" 33 "${c.green}" ;;
              balanced) notify profile "󰾅  Balanced" "Default performance" 66 "${c.lavender}" ;;
              performance) notify profile "󰓅  Performance" "Faster, more heat and fan noise" 100 "${c.peach}" ;;
            esac
            ;;
        esac
      }

      display() {
        local internal=$1 external choice
        external=$(xrandr --query | awk -v internal="$internal" '$2 == "connected" && $1 != internal { print $1; exit }')
        if [[ -z $external ]]; then
          xrandr --output "$internal" --auto --primary
          notify display "󰍹  Display" "No external display connected"
          return
        fi
        choice=$(printf '%s\n' "󰍹  Laptop only" "󰍺  External only" "󰍺  Extend" "󰍺  Mirror" |
          ${rofi} -dmenu -i -no-custom -p Display \
            -theme-str 'window { width: 16em; } listview { lines: 4; scrollbar: false; }') || return 0
        case "$choice" in
          *"Laptop only") xrandr --output "$internal" --auto --primary --output "$external" --off ;;
          *"External only") xrandr --output "$external" --auto --primary --output "$internal" --off ;;
          *Extend) xrandr --output "$internal" --auto --primary --output "$external" --auto --right-of "$internal" ;;
          *Mirror) xrandr --output "$internal" --auto --primary --output "$external" --auto --same-as "$internal" ;;
          *) return 0 ;;
        esac
        ${lib.optionalString (
          cfg.wallpaper != null
        ) "${pkgs.feh}/bin/feh --no-fehbg --bg-fill ${cfg.wallpaper}"}
      }

      case "''${1:-}" in
        volume) volume "$2" ;;
        mic) mic ;;
        brightness) brightness "$2" "$3" ;;
        keyboard) keyboard "$2" ;;
        airplane) airplane ;;
        profile) profile "$2" "''${3:-}" ;;
        display) display "$2" ;;
        *)
          echo "usage: osd volume|mic|brightness|keyboard|airplane|profile|display ..." >&2
          exit 2
          ;;
      esac
    '';
  };

  # 性能模式可能由快捷键、Fn+L/M/H（固件直接切换）或其他程序修改，统一监听 power-profiles-daemon 的属性变化再提示。
  powerProfileOsd = pkgs.writeShellApplication {
    name = "power-profile-osd";
    runtimeInputs = with pkgs; [
      coreutils
      glib
    ];
    text = ''
      re="'ActiveProfile': <'([a-z-]+)'>"
      # gdbus 的输出接到管道时会整块缓冲，用 stdbuf 改为按行输出，否则提示要攒够一块才出来。
      stdbuf --output=L gdbus monitor --system --dest net.hadess.PowerProfiles --object-path /net/hadess/PowerProfiles |
        while read -r line; do
          if [[ $line =~ $re ]]; then
            ${osd}/bin/osd profile show "''${BASH_REMATCH[1]}"
          fi
        done
    '';
  };

  run = args: "exec --no-startup-id ${osd}/bin/osd ${args}";
in
{
  # 与 i3.nix 保持同样的 mkOptionDefault 优先级，否则会覆盖掉全部默认快捷键。
  # 整个属性集要包在 mkOptionDefault 里面：写成 mkOptionDefault { … } // { … } 时，后面的键落在
  # mkOptionDefault 返回的包装对象上，模块系统只读取其中的 content，这些键会被静默丢弃。
  xsession.windowManager.i3.config.keybindings = lib.mkOptionDefault (
    {
      "XF86AudioRaiseVolume" = run "volume up";
      "XF86AudioLowerVolume" = run "volume down";
      "XF86AudioMute" = run "volume mute";
      "XF86AudioMicMute" = run "mic";
      # 飞行模式键：ThinkPad 上 Fn+F8 由 intel-hid 发出 RFKill，老机型的 Fn+F5 由 thinkpad_acpi 发出 WLAN。
      "XF86RFKill" = run "airplane";
      "XF86WLAN" = run "airplane";
    }
    // lib.optionalAttrs (cfg.backlight != null) {
      "XF86MonBrightnessUp" = run "brightness ${cfg.backlight} up";
      "XF86MonBrightnessDown" = run "brightness ${cfg.backlight} down";
    }
    // lib.optionalAttrs (cfg.keyboardBacklight != null) {
      "XF86KbdLightOnOff" = run "keyboard ${cfg.keyboardBacklight}";
    }
    # 显示切换菜单里有“只用笔记本屏幕”，只给有内置屏的笔记本（设置了 backlight）绑定。
    // lib.optionalAttrs (cfg.backlight != null && cfg.monitor != null) {
      "XF86Display" = run "display ${cfg.monitor}";
    }
    // lib.optionalAttrs cfg.powerProfiles {
      "Mod4+Shift+p" = run "profile cycle";
    }
  );

  systemd.user.services.power-profile-osd = lib.mkIf cfg.powerProfiles {
    Unit = {
      Description = "Notify when the power profile changes";
      PartOf = [ "graphical-session.target" ];
      # 不写 After 时 graphical-session.target 会排在它后面，拖慢桌面自启动项。
      After = [ "graphical-session.target" ];
    };
    Service = {
      ExecStart = "${powerProfileOsd}/bin/power-profile-osd";
      Restart = "on-failure";
      RestartSec = 5;
    };
    Install.WantedBy = [ "graphical-session.target" ];
  };
}
