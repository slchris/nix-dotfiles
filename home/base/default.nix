# 通用层：所有机器都需要的配置，不依赖图形界面，Linux 桌面与 macOS 共用。
{
  imports = [
    ../options.nix
    ./dsh.nix
    ./git.nix
    ./opencode.nix
    ./packages.nix
    ./pass.nix
    ./prompt.nix
    ./secrets.nix
    ./shell.nix
    ./theme.nix
    ./tmux.nix
  ];
}
