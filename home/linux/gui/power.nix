{
  config,
  lib,
  pkgs,
  ...
}:
let
  rofi = "${config.programs.rofi.finalPackage}/bin/rofi";
  i3msg = "${config.xsession.windowManager.i3.package}/bin/i3-msg";
  systemd = "${pkgs.systemd}/bin";

  # 注销、重启、关机会结束所有程序，要再确认一次。
  powermenu = pkgs.writeShellScriptBin "powermenu" ''
    menu() {
      ${rofi} -dmenu -i -no-custom \
        -theme-str 'window { width: 16em; } listview { lines: 5; scrollbar: false; }' "$@"
    }
    confirm() {
      [ "$(printf 'Cancel\n%s\n' "$1" | menu -p "$1?")" = "$1" ]
    }

    choice=$(printf '%s\n' "󰌾  Lock" "󰍃  Log out" "󰤄  Suspend" "󰜉  Reboot" "󰐥  Shut down" | menu -p Power)
    case "$choice" in
      *Lock) ${systemd}/loginctl lock-session ;;
      *"Log out") confirm "Log out" && ${i3msg} exit ;;
      *Suspend) ${systemd}/systemctl suspend ;;
      *Reboot) confirm Reboot && ${systemd}/systemctl reboot ;;
      *"Shut down") confirm "Shut down" && ${systemd}/systemctl poweroff ;;
    esac
  '';
in
{
  home.packages = [ powermenu ];

  # 替换 i3 默认的退出确认栏。与 i3.nix 保持同样的 mkOptionDefault 优先级，否则会覆盖掉全部默认快捷键。
  xsession.windowManager.i3.config.keybindings = lib.mkOptionDefault {
    "Mod4+Shift+e" = "exec --no-startup-id ${powermenu}/bin/powermenu";
  };

  # 状态栏最右侧的电源按钮，polybar.nix 的 modules-right 引用它。
  services.polybar.settings."module/power" = {
    type = "custom/text";
    format = "󰐥";
    format-foreground = (import ./palette.nix).red;
    format-padding = 1;
    click-left = "${powermenu}/bin/powermenu";
  };
}
