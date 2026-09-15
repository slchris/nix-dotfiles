{
  description = "slchris 的 dotfiles：home-manager 用户配置，分通用层、Linux 桌面层与主机特化";

  inputs = {
    nixpkgs.url = "github:NixOS/nixpkgs/nixos-26.05";
    home-manager = {
      url = "github:nix-community/home-manager/release-26.05";
      inputs.nixpkgs.follows = "nixpkgs";
    };
    # 配色统一用 Catppuccin，版本与 nixpkgs 对齐。
    catppuccin = {
      url = "github:catppuccin/nix/v26.05";
      inputs.nixpkgs.follows = "nixpkgs";
    };
    # 解密私有仓库 nix-secrets 里的配置。不跟随 nixpkgs，sops-install-secrets 才能从 cache.thalheim.io 下载。
    sops-nix.url = "github:Mic92/sops-nix";
  };

  outputs =
    {
      self,
      nixpkgs,
      home-manager,
      catppuccin,
      sops-nix,
      ...
    }:
    let
      inherit (nixpkgs) lib;
      # 有特化配置的主机，值是系统平台。
      hosts = {
        taiki = "x86_64-linux";
      };
      # 用到的非自由软件。在 NixOS 里使用时，需要在系统的 nixpkgs.config.allowUnfreePredicate 里放行同样的名单。
      unfreePackages = import ./unfree.nix;
    in
    {
      lib.unfreePackages = unfreePackages;

      # 给 NixOS 或 nix-darwin 里的 home-manager 使用，每台机器只引用自己那一个：
      #   home-manager.users.chris.imports = [ nix-dotfiles.homeModules.taiki ];
      homeModules = lib.genAttrs (lib.attrNames hosts) (name: {
        imports = [
          catppuccin.homeModules.catppuccin
          sops-nix.homeManagerModules.sops
          { sops.package = sops-nix.packages.${hosts.${name}}.sops-install-secrets; }
          ./hosts/${name}.nix
        ];
      });

      # 不经 NixOS 单独求值，用于检查配置，也可以在非 NixOS 的 Linux 上直接使用。
      homeConfigurations = lib.mapAttrs' (
        name: system:
        lib.nameValuePair "chris@${name}" (
          home-manager.lib.homeManagerConfiguration {
            pkgs = import nixpkgs {
              inherit system;
              config.allowUnfreePredicate = pkg: builtins.elem (lib.getName pkg) unfreePackages;
            };
            modules = [
              self.homeModules.${name}
              {
                home = {
                  username = "chris";
                  homeDirectory = "/home/chris";
                  stateVersion = "26.05";
                };
              }
            ];
          }
        )
      ) hosts;
    };
}
