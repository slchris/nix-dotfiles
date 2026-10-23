{
  description = "slchris 的 dotfiles：home-manager 用户配置，分通用层、Linux 桌面层与主机特化";

  inputs = {
    nixpkgs.url = "github:NixOS/nixpkgs/nixos-26.05";
    # 更新很快的 AI 编程工具从 unstable 取。
    # opencode 1.18.30 每次发消息都崩在 SystemPrompt.environment（undefined is not an object
    # evaluating 'a.name'），上游多人报告、尚未修复，1.18.31 的更新说明里也没有这条。
    # 先钉在打 1.18.21 的这个 nixpkgs 提交，实测正常。上游修好后删掉这个输入。
    nixpkgs-opencode.url = "github:NixOS/nixpkgs/c03747f0c729d362b050bb3dae36d349e5c68184";
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
    # oh-my-pi（omp）：另一个 coding agent，上游自带 home-manager 模块（programs.omp）。
    # 它锁自己的 nixpkgs（unstable）和各种构建输入，不 follows，免得被 26.05 拖住构建。
    omp.url = "github:can1357/oh-my-pi";
    # Grok Build：xAI 的终端 coding agent。官方只发 curl | bash 的自更新二进制，
    # 这个 flake 把官方二进制按版本与哈希钉住，并关掉自更新（Nix store 只读，
    # 自更新本来也无处可写）。跟着 nixpkgs，更新上游版本走 nix flake update 这个输入。
    grok-build-nix = {
      url = "github:gesop0n/grok-build-nix";
      inputs.nixpkgs.follows = "nixpkgs";
    };
    # 各家 coding agent 共用的 skill 仓库。三个都没有 flake.nix，当源码树取来即可。
    # 它们只提供 SKILL.md 目录，由 home/base/agent-skills.nix 软链进 agent 的 skill 路径，
    # 升级走 nix flake update agents-skills-<名字>。
    agents-skills-cloudflare = {
      url = "github:cloudflare/security-audit-skill";
      flake = false;
    };
    agents-skills-ponytail = {
      url = "github:DietrichGebert/ponytail";
      flake = false;
    };
    agents-skills-mattpocock = {
      url = "github:mattpocock/skills";
      flake = false;
    };
  };

  outputs =
    {
      self,
      nixpkgs,
      nixpkgs-unstable,
      nixpkgs-opencode,
      home-manager,
      catppuccin,
      sops-nix,
      nur-slchris,
      omp,
      grok-build-nix,
      agents-skills-cloudflare,
      agents-skills-ponytail,
      agents-skills-mattpocock,
      ...
    }:
    let
      inherit (nixpkgs) lib;
      # 有特化配置的主机，值是系统平台。
      hosts = {
        taiki = "x86_64-linux";
        hanrin = "x86_64-linux";
        sairin = "x86_64-linux";
        keiki = "aarch64-darwin";
        enki = "aarch64-darwin";
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
            omp.homeManagerModules.default
            {
              sops.package = sops-nix.packages.${hosts.${name}}.sops-install-secrets;
              _module.args.nurPkgs = nur-slchris.legacyPackages.${hosts.${name}};
              # 见上面 nixpkgs-opencode 输入的说明：1.18.30 有回归，先钉住能用的版本。
              _module.args.opencodePkg = (import nixpkgs-opencode { system = hosts.${name}; }).opencode;
              # omp 的包由 home/base/omp.nix 包一层 sops key 注入的 wrapper，这里只取上游包。
              _module.args.ompPkg = omp.packages.${hosts.${name}}.default;
              # Grok Build，只有 Mac 的 home/darwin/packages.nix 会引用。
              _module.args.grokBuildPkg = grok-build-nix.packages.${hosts.${name}}.default;
              # agent skill 的源码树，由 home/base/agent-skills.nix 使用。与平台无关，各主机同一份。
              _module.args.agentSkillSources = {
                cloudflare = agents-skills-cloudflare;
                ponytail = agents-skills-ponytail;
                mattpocock = agents-skills-mattpocock;
              };
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
