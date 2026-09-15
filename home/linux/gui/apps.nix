{
  config,
  lib,
  pkgs,
  ...
}:
{
  options.dotfiles.packages.gui.enable = lib.mkEnableOption "图形界面的应用程序（办公、数据库、API 调试、本地大模型等）";

  config = lib.mkMerge [
    (lib.mkIf config.dotfiles.packages.gui.enable {
      home.packages = with pkgs; [
        android-tools
        calibre
        dbeaver-bin
        freerdp
        lmstudio
        obsidian
        postman
      ];
    })
    {
      home.packages = with pkgs; [
        feh
        libnotify
        maim
        mpv
        p7zip
        pavucontrol
        playerctl
        xclip
      ];

      programs.bat.enable = true;
      programs.btop.enable = true;
      # btop 退出时会把界面设置写回配置文件，Chrome 设为默认浏览器时会改写 mimeapps.list。
      # 这些文件由 home-manager 管理，每次部署都覆盖回配置里的版本。
      xdg.configFile."btop/btop.conf".force = true;
      xdg.configFile."mimeapps.list".force = true;
      xdg.dataFile."applications/mimeapps.list".force = true;
      programs.fzf.enable = true;
      programs.zathura.enable = true;

      # 身份验证弹窗（挂载磁盘、NetworkManager 修改连接等）。
      services.polkit-gnome.enable = true;
      # U 盘插入后自动挂载，并在托盘显示。
      services.udiskie = {
        enable = true;
        tray = "auto";
      };

      xdg.userDirs = {
        enable = true;
        createDirectories = true;
      };
      xdg.mimeApps = {
        enable = true;
        defaultApplications = {
          "text/html" = "google-chrome.desktop";
          "x-scheme-handler/http" = "google-chrome.desktop";
          "x-scheme-handler/https" = "google-chrome.desktop";
          "application/pdf" = "org.pwmt.zathura.desktop";
          "image/png" = "feh.desktop";
          "image/jpeg" = "feh.desktop";
          "video/mp4" = "mpv.desktop";
          "inode/directory" = "thunar.desktop";
        };
      };
    }
  ];
}
