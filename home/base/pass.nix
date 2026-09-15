{
  config,
  lib,
  pkgs,
  ...
}:
let
  cfg = config.dotfiles.pass;
  dir = "${config.home.homeDirectory}/.password-store";
  git = "${config.programs.git.package}/bin/git";
  others = lib.filterAttrs (name: _: name != cfg.cloneFrom) cfg.remotes;
in
{
  options.dotfiles.pass = {
    enable = lib.mkEnableOption "pass 密码库";
    remotes = lib.mkOption {
      type = lib.types.attrsOf lib.types.str;
      default = { };
      example = {
        github = "https://github.com/example/pass.git";
      };
      description = "密码库的 git 远端，键是远端名。";
    };
    cloneFrom = lib.mkOption {
      type = lib.types.nullOr lib.types.str;
      default = null;
      example = "github";
      description = "本机还没有密码库时，从这个远端克隆，并加上 remotes 里的其他远端。";
    };
  };

  config = lib.mkIf cfg.enable {
    assertions = [
      {
        assertion = cfg.cloneFrom == null || cfg.remotes ? ${cfg.cloneFrom};
        message = "dotfiles.pass.cloneFrom 必须是 dotfiles.pass.remotes 里的一个远端";
      }
    ];

    programs.password-store = {
      enable = true;
      # 与 Mac 上的位置一致。
      settings.PASSWORD_STORE_DIR = dir;
    };

    # 克隆只需要 git 凭据，解密条目时才需要插入 OpenPGP 卡。网络还没就绪时失败，30 秒后重试。
    systemd.user.services.pass-store-clone = lib.mkIf (pkgs.stdenv.isLinux && cfg.cloneFrom != null) {
      Unit = {
        Description = "Clone the password store";
        ConditionPathExists = "!${dir}/.git";
      };
      Service = {
        Type = "oneshot";
        Restart = "on-failure";
        RestartSec = 30;
        ExecStart = toString (
          pkgs.writeShellScript "pass-store-clone" ''
            set -eu
            ${git} clone --origin ${cfg.cloneFrom} ${lib.escapeShellArg cfg.remotes.${cfg.cloneFrom}} ${dir}
            ${lib.concatStrings (
              lib.mapAttrsToList (name: url: ''
                ${git} -C ${dir} remote add ${name} ${lib.escapeShellArg url}
              '') others
            )}
          ''
        );
      };
      Install.WantedBy = [ "default.target" ];
    };
  };
}
