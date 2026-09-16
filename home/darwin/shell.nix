# Mac 上 bash 的环境。内容取自机器上原来手写的 ~/.bashrc 与 ~/.bash_profile，
# 交给 home-manager 之后原文件会被备份为 *.hm-backup。
#
# Homebrew 仍排在 PATH 前面：命令行工具正从 Homebrew 迁到 Nix，迁完之前两边都装着，
# 日常用的应当还是原来那份，避免版本忽然变化。
{
  home.sessionPath = [
    "$HOME/.cargo/bin"
    # uv 与 pipx 装的命令
    "$HOME/.local/bin"
    "$HOME/go/bin"
    "$HOME/.bun/bin"
    "$HOME/.lmstudio/bin"
    "$HOME/.antigravity/antigravity/bin"
    # 应用自带的命令行工具：latex、tshark、imgcat。
    "/Library/TeX/texbin"
    "/Applications/Wireshark.app/Contents/MacOS"
    "/Applications/iTerm.app/Contents/Resources/utilities"
  ];

  home.sessionVariables.AWS_DEFAULT_REGION = "us-east-1";

  programs.bash = {
    # 只有登录 shell 读 ~/.bash_profile。
    profileExtra = ''
      # Homebrew 的 bash 补全。
      [[ -r /opt/homebrew/etc/profile.d/bash_completion.sh ]] && . /opt/homebrew/etc/profile.d/bash_completion.sh
      # OrbStack 的命令行工具与 docker 集成。
      [[ -r "$HOME/.orbstack/shell/init.bash" ]] && . "$HOME/.orbstack/shell/init.bash" 2>/dev/null
    '';

    initExtra = ''
      # gpg-agent 兼作 SSH agent，插着 YubiKey 就能 SSH 登录。gnupg 仍是 Homebrew 那份。
      GPG_TTY=$(tty)
      export GPG_TTY
      SSH_AUTH_SOCK=$(gpgconf --list-dirs agent-ssh-socket)
      export SSH_AUTH_SOCK
      gpgconf --launch gpg-agent
      gpg-connect-agent updatestartuptty /bye >/dev/null

      # GNU 工具排在 BSD 之前：macOS 自带的 bash 3.2 没有 mapfile，BSD grep 没有 -P，BSD realpath 没有 -m。
      case ":$PATH:" in
        *":/opt/homebrew/opt/coreutils/libexec/gnubin:"*) ;;
        *) PATH="/opt/homebrew/opt/coreutils/libexec/gnubin:/opt/homebrew/opt/grep/libexec/gnubin:/opt/homebrew/bin:$PATH" ;;
      esac
      export PATH

      # 各语言运行时由 mise 管理。
      command -v mise >/dev/null && eval "$(mise activate bash)"

      # 编辑器与命令行工具自带的 shell 集成。
      [[ $TERM_PROGRAM == kiro ]] && . "$(kiro --locate-shell-integration-path bash)"
      [[ -f "$HOME/.openclaw/completions/openclaw.bash" ]] && . "$HOME/.openclaw/completions/openclaw.bash"
    '';
  };
}
