{ config, pkgs, ... }:
let
  inherit (config.dotfiles.desktop) scale;
  c = import ../../palette.nix;
  hex = color: builtins.substring 1 6 color;
  dunstctl = "${config.services.dunst.package}/bin/dunstctl";

  # 显示器在无操作 10 分钟后关闭，锁屏期间缩短为 1 分钟。
  dpms =
    seconds: "${pkgs.xset}/bin/xset dpms ${toString seconds} ${toString seconds} ${toString seconds}";

  # i3lock-color：截取当前屏幕模糊后作为背景，中间显示时钟与输入状态环。
  # 锁屏期间暂停通知弹窗和正在播放的媒体，解锁后恢复通知。
  # 可执行文件名是 i3lock，沿用系统上 programs.i3lock 提供的 PAM 配置。
  lock = pkgs.writeShellScript "lock" ''
    ${dunstctl} set-paused true
    ${pkgs.playerctl}/bin/playerctl --all-players pause 2>/dev/null
    ${dpms 60}

    ${pkgs.i3lock-color}/bin/i3lock-color \
      --nofork --ignore-empty-password --show-failed-attempts \
      --blur 8 --clock --indicator --radius ${toString (120 * scale)} --ring-width ${toString (8 * scale)} \
      --inside-color=${hex c.base}cc --ring-color=${hex c.lavender}ff \
      --insidever-color=${hex c.base}cc --ringver-color=${hex c.blue}ff \
      --insidewrong-color=${hex c.base}cc --ringwrong-color=${hex c.red}ff \
      --keyhl-color=${hex c.green}ff --bshl-color=${hex c.peach}ff \
      --line-color=00000000 --separator-color=00000000 \
      --time-color=${hex c.text}ff --date-color=${hex c.subtext0}ff \
      --verif-color=${hex c.text}ff --wrong-color=${hex c.red}ff --layout-color=${hex c.subtext0}ff \
      --time-font="Inter" --date-font="Inter" --verif-font="Inter" --wrong-font="Inter" \
      --time-size=${toString (56 * scale)} --date-size=${toString (18 * scale)} \
      --verif-size=${toString (18 * scale)} --wrong-size=${toString (18 * scale)} \
      --time-str="%H:%M" --date-str="%A, %B %d" \
      --verif-text="Verifying" --wrong-text="Wrong password" --noinput-text="No input" --lock-text="Locking"

    ${dpms 600}
    ${dunstctl} set-paused false
  '';
in
{
  # xss-lock 在两种情况下锁屏：无操作超时，以及 systemd 准备休眠或执行 loginctl lock-session 时。
  # --transfer-sleep-lock 让休眠等到锁屏画面出现后再进行，唤醒时不会闪现桌面内容。
  services.screen-locker = {
    enable = true;
    lockCmd = "${lock}";
    inactiveInterval = 10;
    xss-lock.extraOptions = [ "--transfer-sleep-lock" ];
    xautolock.enable = false;
  };

  xsession.initExtra = dpms 600;
}
