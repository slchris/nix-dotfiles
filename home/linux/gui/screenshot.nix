{ config, lib, ... }:
let
  c = import ./palette.nix;
  flameshot = "${config.services.flameshot.package}/bin/flameshot";
  dir = "${config.home.homeDirectory}/Pictures/Screenshots";
in
{
  # 只写 flameshot 认识的设置：遇到不认识的键（例如 nixpkgs 版本已去掉的 checkForUpdates）会尝试改写只读的配置文件，然后崩溃。
  # 修改后用 flameshot config --check 检查。
  # flameshot 随桌面启动并常驻，框选后可以标注，按 Ctrl+C 复制、Ctrl+S 保存。
  services.flameshot = {
    enable = true;
    settings.General = {
      savePath = dir;
      savePathFixed = true;
      filenamePattern = "%Y%m%d-%H%M%S";
      # 复制到剪贴板时同时存一份文件。
      saveAfterCopy = true;
      uiColor = c.lavender;
      contrastUiColor = c.mauve;
      drawColor = c.red;
      disabledTrayIcon = true;
      showStartupLaunchMessage = false;
      showHelp = false;
    };
  };

  home.file."Pictures/Screenshots/.keep".text = "";

  # i3.nix 以 mkOptionDefault 追加快捷键，这里保持同一优先级，否则会覆盖掉全部默认快捷键。
  xsession.windowManager.i3.config.keybindings = lib.mkOptionDefault {
    "Print" = "exec --no-startup-id ${flameshot} gui";
    "Mod4+Shift+s" = "exec --no-startup-id ${flameshot} gui";
    "Shift+Print" = "exec --no-startup-id ${flameshot} full --clipboard --path ${dir}";
  };
}
