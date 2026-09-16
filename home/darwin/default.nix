# macOS 层：通用层加上 Mac 专有的设置。系统层（nix-darwin）在 homelab 仓库。
{
  imports = [
    ../base
    ./packages.nix
    ./shell.nix
  ];
}
