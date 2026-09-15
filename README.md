# nix-dotfiles

个人的 home-manager 配置，目前用在 taiki（NixOS + i3）上。

系统层的配置（显卡驱动、输入法框架、LightDM、备份）不在这里。私密配置放在私有仓库 nix-secrets。

## 目录

- `home/base`：bash、git、tmux、配色、命令行工具
- `home/linux/gui`：i3、polybar、picom、rofi、dunst、alacritty、字体、fcitx5 皮肤、锁屏
- `hosts/<主机>.nix`：每台机器的显示器、字号、壁纸和软件分组

配色是 Catppuccin Mocha。字体用 Inter、思源黑体和 Maple Mono NF CN。

## 使用

在 NixOS 的 flake 里加入：

```nix
inputs.nix-dotfiles = {
  url = "github:slchris/nix-dotfiles";
  inputs.nixpkgs.follows = "nixpkgs";
  inputs.home-manager.follows = "home-manager";
};
```

然后引用对应主机的模块：

```nix
home-manager.users.chris.imports = [ nix-dotfiles.homeModules.taiki ];
nixpkgs.config.allowUnfreePredicate =
  pkg: builtins.elem (lib.getName pkg) nix-dotfiles.lib.unfreePackages;
```

系统层还需要启用 i3、fcitx5、`programs.i3lock` 和 `programs.dconf`。

私密配置通过 `dotfiles.secrets.sopsFile` 传入，不设置就不启用。

## 新增主机

复制 `hosts/taiki.nix` 并修改，再把主机名加进 `flake.nix` 的 `hosts`。

atuin 要在新机器上登录一次。先在已有机器上执行 `atuin key` 得到助记词，再在新机器上执行下面的命令，按提示输入口令和助记词：

```sh
atuin login -u chris
atuin sync
```

## 备注

- catppuccin/nix 的 polybar、starship、fzf 模块在求值时要读取主题文件（IFD），没有 Linux 构建机的 Mac 上会求值失败。这三个模块已关闭，颜色按 `home/linux/gui/palette.nix` 手写。
- 新增 unfree 软件时，同时修改 `unfree.nix`。
