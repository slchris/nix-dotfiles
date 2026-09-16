{ lib, ... }:
{
  # 景麒（keiki）：MacBook Pro，aarch64-darwin。只引用通用层，没有 Linux 桌面那一层。
  imports = [ ../home/base ];
  #
  # Mac 上先只用 Nix 装命令行工具。bash、git、tmux、atuin、gpg 的配置文件仍用机器上现有的那套：
  # ~/.bashrc 与 ~/.bash_profile 里有 cargo、uv、mise、OrbStack、bash-preexec、GNU coreutils 前置
  # 以及 gpg-agent 的 SSH_AUTH_SOCK 等手工维护的内容，要逐条对过才能交给 home-manager，
  # 否则切换后终端环境会变样。对完之后把下面这些 mkForce 去掉即可。
  programs.bash.enable = lib.mkForce false;
  programs.git.enable = lib.mkForce false;
  programs.gpg.enable = lib.mkForce false;
  programs.tmux.enable = lib.mkForce false;
  programs.atuin.enable = lib.mkForce false;

  dotfiles.packages = {
    cli.enable = true;
    dev.enable = true;
    cloud.enable = true;
    kubernetes.enable = true;
    ai.enable = true;
  };
}
