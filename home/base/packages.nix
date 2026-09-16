{
  config,
  lib,
  pkgs,
  unstablePkgs,
  ...
}:
let
  cfg = config.dotfiles.packages;
  # 分组里按名字剔除个别包，用于某台机器上该软件已由别处提供的情况。
  keep = lib.filter (p: !(lib.elem (lib.getName p) cfg.exclude));
in
{
  # 软件按用途分组，每台机器在 hosts/<主机>.nix 里按需开启。清单对照 Mac 上 Homebrew 安装的软件整理。
  options.dotfiles.packages = {
    cli.enable = lib.mkEnableOption "常用命令行工具";
    dev.enable = lib.mkEnableOption "开发工具";
    cloud.enable = lib.mkEnableOption "云平台与基础设施工具";
    kubernetes.enable = lib.mkEnableOption "Kubernetes 与容器工具";
    ai.enable = lib.mkEnableOption "AI 编程工具（Claude Code、Codex、opencode）";
    exclude = lib.mkOption {
      type = lib.types.listOf lib.types.str;
      default = [ ];
      example = [ "codeql" ];
      description = ''
        从上面各分组里剔除的包名（lib.getName 的结果）。
        用于这台机器上该软件已由别处提供，例如 Mac 上由 Homebrew 的 cask 安装。
      '';
    };
  };

  config = lib.mkMerge [
    (lib.mkIf cfg.cli.enable {
      home.packages = keep (
        with pkgs;
        [
          age
          aria2
          cloc
          cowsay
          exiftool
          imagemagick
          inetutils # telnet
          nmap
          ntfy-sh
          rclone
          restic
          smartmontools
          trzsz-ssh
          usage
          viddy
          watchman
          whois
          yq-go
          yubikey-manager
          yubikey-personalization
        ]
      );
      # 同步到 homelab 的 atuin 服务端，与 Mac 上的设置一致。新机器要登录一次，见 README。
      programs.atuin = {
        enable = true;
        settings = {
          sync_address = "https://atuin.infra.plz.ac";
          auto_sync = true;
          sync_frequency = "5m";
          enter_accept = true;
          sync.records = true;
        };
      };
    })

    (lib.mkIf cfg.dev.enable {
      home.packages = keep (
        with pkgs;
        [
          act
          cmake
          codeql
          dnsperf
          git-filter-repo
          git-lfs
          gitleaks
          golangci-lint
          gradle
          grpcurl
          hugo
          k6
          mise
          nasm
          ninja
          osv-scanner
          pkg-config
          pkgconf
          pre-commit
          # promtool 在 prometheus 的 cli 输出里，主包只有服务端。
          prometheus.cli
          protobuf
          qemu
          semgrep
          shellcheck
          sqlc
          stripe-cli
          uv
          wrk
          xorriso
        ]
      );
      programs.gh = {
        enable = true;
        settings = {
          # 与 Mac 一致走 HTTPS，由 gh 的 token 认证，不依赖插卡。
          git_protocol = "https";
          # Mac 上原来手写的别名，接管配置文件时补回来。
          aliases.co = "pr checkout";
        };
      };
    })

    (lib.mkIf cfg.cloud.enable {
      home.packages = keep (
        with pkgs;
        [
          aliyun-cli
          ansible
          awscli2
          cloudflared
          consul
          google-cloud-sdk
          s3cmd
          terragrunt
          tfsec
        ]
      );
    })

    (lib.mkIf cfg.kubernetes.enable {
      home.packages = keep (
        with pkgs;
        [
          argo-workflows
          argocd
          cosign
          dive
          egctl
          helmfile
          istioctl
          kompose
          kubecm
          kubectl
          # kubelogin 是 Azure 的，kubelogin-oidc 提供 kubectl-oidc_login，两个都装。
          kubelogin
          kubelogin-oidc
          kubernetes-helm
          kubeseal
          kustomize
          skaffold
          skopeo
          stern
          tektoncd-cli
          trivy
          velero
        ]
      );
      programs.k9s.enable = true;
    })

    # 这些工具几乎每周发版，稳定版 nixpkgs 落后太多，从 unstable 取。
    (lib.mkIf cfg.ai.enable {
      home.packages = keep (
        with unstablePkgs;
        [
          claude-code
          codex
          opencode
        ]
      );
    })
  ];
}
