{
  # 迁移自原 dotfiles 仓库的 .tmux.conf，状态栏配色由 Catppuccin 插件提供。
  programs.tmux = {
    enable = true;
    terminal = "screen-256color";
    historyLimit = 65535;
    mouse = true;
    keyMode = "vi";
    extraConfig = ''
      set -g display-time 3000
      set -g status-interval 1
      set -g status-justify left
      setw -g monitor-activity on
    '';
  };
}
