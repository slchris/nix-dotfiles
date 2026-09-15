# 通用层：所有机器都需要的配置，不依赖图形界面，以后 macOS 也可以复用。
{
  imports = [
    ../options.nix
    ./git.nix
    ./packages.nix
    ./secrets.nix
    ./shell.nix
    ./theme.nix
    ./tmux.nix
  ];
}
