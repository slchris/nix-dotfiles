{
  config,
  lib,
  pkgs,
  ...
}:
let
  cfg = config.dotfiles.git;
  gpg = "${config.programs.gpg.package}/bin/gpg";

  identity = {
    name = lib.mkOption {
      type = lib.types.str;
      description = "提交者姓名。";
    };
    email = lib.mkOption {
      type = lib.types.str;
      description = "提交者邮箱。";
    };
    signingKey = lib.mkOption {
      type = lib.types.nullOr lib.types.str;
      default = null;
      example = "0x45D10727855239D3";
      description = "签名用的 OpenPGP 密钥 ID 或指纹，私钥可以在智能卡上。为 null 时不签名。";
    };
  };

  signingKeys = lib.filter (k: k != null) ([ cfg.signingKey ] ++ map (i: i.signingKey) cfg.includes);
in
{
  options.dotfiles.git = identity // {
    publicKeys = lib.mkOption {
      type = lib.types.listOf lib.types.path;
      default = [ ];
      description = "导入 gpg 并设为绝对信任的公钥文件，通常是本人的所有密钥。";
    };
    includes = lib.mkOption {
      type = lib.types.listOf (
        lib.types.submodule {
          options = identity // {
            condition = lib.mkOption {
              type = lib.types.str;
              example = "gitdir:~/work/";
              description = "git includeIf 的条件。";
            };
          };
        }
      );
      default = [ ];
      description = "按条件切换身份，例如工作目录下的仓库使用另一个邮箱和密钥。";
    };
  };

  config = {
    programs.git = {
      enable = true;
      settings.user = { inherit (cfg) name email; };
      signing = lib.mkIf (cfg.signingKey != null) {
        key = cfg.signingKey;
        signByDefault = true;
        format = "openpgp";
      };
      includes = map (i: {
        inherit (i) condition;
        contents = {
          user = {
            inherit (i) name email;
          }
          // lib.optionalAttrs (i.signingKey != null) { signingKey = i.signingKey; };
          commit.gpgSign = i.signingKey != null;
        };
      }) cfg.includes;
    };

    programs.gpg = {
      enable = true;
      publicKeys = map (source: {
        inherit source;
        trust = 5;
      }) cfg.publicKeys;
      # Linux 上读卡交给系统的 pcscd，scdaemon 自带的 CCID 驱动会与它争用设备。
      scdaemonSettings = lib.mkIf pkgs.stdenv.isLinux { disable-ccid = true; };
    };

    # 私钥在 OpenPGP 卡上时，gpg 要先执行一次 --card-status 才会在 ~/.gnupg 里记下私钥位置，否则签名报找不到私钥。
    # 登录时执行一次；插卡时由系统层的 udev 规则再次触发。已经记下所有签名密钥时不碰卡，
    # 记录完成后结束本用户的 scdaemon 释放读卡器，避免多个用户同时登录时抢占别人的卡。
    systemd.user.services.gpg-card-learn = lib.mkIf (pkgs.stdenv.isLinux && signingKeys != [ ]) {
      # 目标会等它想要的 oneshot 服务结束才算到达；排在桌面会话之后，避免没插卡时等满 10 秒才启动输入法等自启动项。
      Unit = {
        Description = "Record private keys stored on OpenPGP cards";
        After = [ "graphical-session.target" ];
      };
      Service = {
        Type = "oneshot";
        ExecStart = toString (
          pkgs.writeShellScript "gpg-card-learn" ''
            missing=0
            for key in ${lib.escapeShellArgs signingKeys}; do
              ${gpg} --list-secret-keys "$key" >/dev/null 2>&1 || missing=1
            done
            [ "$missing" = 1 ] || exit 0

            # pcscd 识别刚插入的卡需要一两秒。
            for _ in 1 2 3 4 5; do
              ${gpg} --card-status >/dev/null 2>&1 && break
              sleep 2
            done
            ${config.programs.gpg.package}/bin/gpgconf --kill scdaemon
          ''
        );
      };
      Install.WantedBy = [ "graphical-session.target" ];
    };
  };
}
