{ config, lib, ... }:
let
  cfg = config.dotfiles.secrets;
  inherit (config.sops) placeholder;
in
{
  options.dotfiles.secrets = {
    sopsFile = lib.mkOption {
      type = lib.types.nullOr lib.types.path;
      default = null;
      description = ''
        私有仓库 nix-secrets 里该用户的 sops 加密文件，由使用方（私有的 homelab 仓库）传入。
        本仓库公开，不含任何密钥；留空时不部署私密配置。
      '';
    };
    githubUser = lib.mkOption {
      type = lib.types.nullOr lib.types.str;
      default = null;
      description = "GitHub 用户名。设置后从加密文件的 github-token 生成 gh 的登录信息。";
    };
    sshConfig = lib.mkEnableOption "从加密文件的 ssh-config 引入 SSH 主机列表";
  };

  config = lib.mkIf (cfg.sopsFile != null) (
    lib.mkMerge [
      {
        sops = {
          defaultSopsFile = cfg.sopsFile;
          # 每台机器上用户自己的 age 密钥，生成方法见 nix-secrets 的 README。
          age.keyFile = "${config.xdg.configHome}/sops/age/keys.txt";
          # 验证用的非敏感条目，解密后位于 ~/.config/sops-nix/secrets/nix-secrets-canary。
          secrets.nix-secrets-canary = { };
        };
      }

      (lib.mkIf (cfg.githubUser != null) {
        sops.secrets.github-token = { };
        # 桌面上没有密钥环，gh 本来就把 token 明文写在 hosts.yml，这里改为由 sops 生成。
        # 文件只读，gh auth login 与 logout 会失败；更换 token 要修改 nix-secrets 后重新部署。
        sops.templates."gh-hosts.yml" = {
          path = "${config.xdg.configHome}/gh/hosts.yml";
          content = ''
            github.com:
              users:
                ${cfg.githubUser}:
                  oauth_token: ${placeholder.github-token}
              git_protocol: https
              oauth_token: ${placeholder.github-token}
              user: ${cfg.githubUser}
          '';
        };
      })

      (lib.mkIf cfg.sshConfig {
        sops.secrets.ssh-config = { };
        # 服务器与内网主机的地址不公开，Host 条目在 nix-secrets 里，这里只引用解密后的文件。
        programs.ssh = {
          enable = true;
          enableDefaultConfig = false;
          includes = [ config.sops.secrets.ssh-config.path ];
        };
      })
    ]
  );
}
