{ config, ... }:
{
  programs.bash = {
    enable = true;
    # 沿用 Gentoo 上的历史记录习惯：文件名 ~/.history，保留一百万条。
    historyFile = "${config.home.homeDirectory}/.history";
    historySize = 1000000;
    historyFileSize = 1000000;
    historyControl = [
      "ignoredups"
      "ignorespace"
    ];
    sessionVariables.HISTTIMEFORMAT = "%Y-%m-%d %H:%M:%S ";
    initExtra = ''
      # 每条命令执行完立即写入历史，多个终端同时打开时不会互相覆盖。
      PROMPT_COMMAND="history -a''${PROMPT_COMMAND:+; $PROMPT_COMMAND}"
      [ -f "$HOME/.config/aliasrc" ] && . "$HOME/.config/aliasrc"
    '';
  };
}
