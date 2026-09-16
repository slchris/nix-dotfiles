{
  description = "slchris 的 dotfiles：home-manager 用户配置，分通用层、Linux 桌面层与主机特化";

  inputs = {
    nixpkgs.url = "github:NixOS/nixpkgs/nixos-26.05";
    # 更新很快的 AI 编程工具从 unstable 取。
    nixpkgs-unstable.url = "github:NixOS/nixpkgs/nixos-unstable";
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
    # nixpkgs 里没有的软件，例如 Claude Desktop。
    nur-slchris = {
      url = "github:slchris/nur";
      inputs.nixpkgs.follows = "nixpkgs";
    };
  };

  outputs =
    {
      self,
      nixpkgs,
      nixpkgs-unstable,
      home-manager,
      catppuccin,
      sops-nix,
      nur-slchris,
      ...
    }:
    let
      inherit (nixpkgs) lib;
      # 有特化配置的主机，值是系统平台。
      hosts = {
        taiki = "x86_64-linux";
        hanrin = "x86_64-linux";
        keiki = "aarch64-darwin";
      };
      # 个人身份（git、签名密钥、私密配置），与主机配置分开，同一台机器的多个用户各引用自己的一份。
      users = [ "chris" ];
      # 用到的非自由软件。在 NixOS 里使用时，需要在系统的 nixpkgs.config.allowUnfreePredicate 里放行同样的名单。
      unfreePackages = import ./unfree.nix;
    in
    {
      lib.unfreePackages = unfreePackages;

      # nix fmt 用 nixfmt 格式化全部 .nix 文件，CI 里用 nix fmt -- --ci 检查。
      formatter = lib.genAttrs [
        "x86_64-linux"
        "aarch64-darwin"
      ] (system: nixpkgs.legacyPackages.${system}.nixfmt-tree);

      # 给 NixOS 或 nix-darwin 里的 home-manager 使用，引用一台主机和一个用户：
      #   home-manager.users.chris.imports = [ nix-dotfiles.homeModules.taiki nix-dotfiles.homeModules.chris ];
      homeModules =
        lib.genAttrs (lib.attrNames hosts) (name: {
          imports = [
            catppuccin.homeModules.catppuccin
            sops-nix.homeManagerModules.sops
            {
              sops.package = sops-nix.packages.${hosts.${name}}.sops-install-secrets;
              _module.args.nurPkgs = nur-slchris.legacyPackages.${hosts.${name}};
              _module.args.unstablePkgs = import nixpkgs-unstable {
                system = hosts.${name};
                config.allowUnfreePredicate = pkg: builtins.elem (lib.getName pkg) unfreePackages;
              };
            }
            ./hosts/${name}.nix
          ];
        })
        // lib.genAttrs users (name: ./users/${name}.nix);

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
              self.homeModules.chris
              {
                home = {
                  username = "chris";
                  homeDirectory = if lib.hasSuffix "darwin" system then "/Users/chris" else "/home/chris";
                  stateVersion = "26.05";
                };
              }
            ];
          }
        )
      ) hosts;
    };
}
