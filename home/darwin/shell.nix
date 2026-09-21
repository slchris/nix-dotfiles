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

  # 进入项目目录时自动加载 flake 的 devShell（.envrc 里写 use flake）。
  # Linux 上 direnv 由系统层（homelab 的 NixOS 配置）提供，这里只管 Mac。
  programs.direnv = {
    enable = true;
    nix-direnv.enable = true;
  };

  programs.bash = {
    # 只有登录 shell 读 ~/.bash_profile。
    profileExtra = ''
      # 补全全部由 home-manager 的 bash-completion 2.x 提供，不加载 Homebrew 的任何补全。
      # Homebrew 装的是 1.3，它会把补全目录指到自己那 246 个 v1 写法的脚本，v2 再读一遍就会
      # 因为没有 have 这个函数而逐个报错。Nix 装的包自带 v2 补全，由 XDG_DATA_DIRS 自动发现。
      # OrbStack 的命令行工具与 docker 集成。
      [[ -r "$HOME/.orbstack/shell/init.bash" ]] && . "$HOME/.orbstack/shell/init.bash" 2>/dev/null
    '';

    initExtra = ''
      # PATH 要排在最前面：下面几行用到的 gpgconf、mise 现在还来自 Homebrew。
      # 迁移期间 Homebrew 仍排在前面，且 GNU 工具要排在 BSD 之前。Nix 的 coreutils 与 gnugrep
      # 已经装在用户这一层，等 Homebrew 的 formula 卸干净、下面这段不再命中，GNU 工具就由 Nix 提供。
      if [[ -d /opt/homebrew/opt/coreutils/libexec/gnubin ]]; then
        case ":$PATH:" in
          *":/opt/homebrew/opt/coreutils/libexec/gnubin:"*) ;;
          *) PATH="/opt/homebrew/opt/coreutils/libexec/gnubin:/opt/homebrew/opt/grep/libexec/gnubin:/opt/homebrew/bin:$PATH" ;;
        esac
      else
        # formula 卸完后 Homebrew 只剩 cask 与 brew 本身，放在 PATH 末尾即可。
        case ":$PATH:" in
          *":/opt/homebrew/bin:"*) ;;
          *) PATH="$PATH:/opt/homebrew/bin:/opt/homebrew/sbin" ;;
        esac
      fi
      export PATH

      # gpg-agent 兼作 SSH agent，插着 YubiKey 就能 SSH 登录。gnupg 仍是 Homebrew 那份。
      if command -v gpgconf >/dev/null; then
        GPG_TTY=$(tty)
        export GPG_TTY
        SSH_AUTH_SOCK=$(gpgconf --list-dirs agent-ssh-socket)
        export SSH_AUTH_SOCK
        gpgconf --launch gpg-agent
        gpg-connect-agent updatestartuptty /bye >/dev/null
      fi

      # 各语言运行时由 mise 管理。
      command -v mise >/dev/null && eval "$(mise activate bash)"

      # 编辑器与命令行工具自带的 shell 集成。
      [[ $TERM_PROGRAM == kiro ]] && . "$(kiro --locate-shell-integration-path bash)"
      [[ -f "$HOME/.openclaw/completions/openclaw.bash" ]] && . "$HOME/.openclaw/completions/openclaw.bash"
    '';
  };
}
