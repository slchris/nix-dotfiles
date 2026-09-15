{
  config,
  lib,
  pkgs,
  unstablePkgs,
  ...
}:
let
  cfg = config.dotfiles.packages;
in
{
  # 软件按用途分组，每台机器在 hosts/<主机>.nix 里按需开启。清单对照 Mac 上 Homebrew 安装的软件整理。
  options.dotfiles.packages = {
    cli.enable = lib.mkEnableOption "常用命令行工具";
    dev.enable = lib.mkEnableOption "开发工具";
    cloud.enable = lib.mkEnableOption "云平台与基础设施工具";
    kubernetes.enable = lib.mkEnableOption "Kubernetes 与容器工具";
    ai.enable = lib.mkEnableOption "AI 编程工具（Claude Code、Codex、opencode）";
  };

  config = lib.mkMerge [
    (lib.mkIf cfg.cli.enable {
      home.packages = with pkgs; [
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
      ];
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
      home.packages = with pkgs; [
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
        pkgconf
        postgresql_14
        pre-commit
        prometheus # promtool
        protobuf
        qemu
        semgrep
        shellcheck
        sqlc
        stripe-cli
        uv
        wrk
        xorriso
      ];
      programs.gh = {
        enable = true;
        # 与 Mac 一致走 HTTPS，由 gh 的 token 认证，不依赖插卡。
        settings.git_protocol = "https";
      };
    })

    (lib.mkIf cfg.cloud.enable {
      home.packages = with pkgs; [
        aliyun-cli
        ansible
        awscli2
        cloudflared
        consul
        google-cloud-sdk
        s3cmd
        terragrunt
        tfsec
      ];
    })

    (lib.mkIf cfg.kubernetes.enable {
      home.packages = with pkgs; [
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
        kubelogin
        kubernetes-helm
        kubeseal
        kustomize
        skaffold
        skopeo
        stern
        tektoncd-cli
        trivy
        velero
      ];
      programs.k9s.enable = true;
    })

    # 这些工具几乎每周发版，稳定版 nixpkgs 落后太多，从 unstable 取。
    (lib.mkIf cfg.ai.enable {
      home.packages = with unstablePkgs; [
        claude-code
        codex
        opencode
      ];
    })
  ];
}
