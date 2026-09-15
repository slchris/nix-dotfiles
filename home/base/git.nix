{ lib, pkgs, ... }:
{
  programs.git = {
    enable = true;
    settings.user = {
      name = "Chris Su";
      email = "chris@lesscrowds.org";
    };
    # 与 Mac 上的设置一致：提交默认用 OpenPGP 卡上的密钥签名。
    signing = {
      key = "0x45D10727855239D3";
      signByDefault = true;
      format = "openpgp";
    };
  };

  programs.gpg = {
    enable = true;
    # 导入公钥后，插卡即可认出卡上的私钥，用于签名、解密 sops 与 SSH 登录。
    publicKeys = [
      {
        source = ../../keys/pgp-chris.asc;
        trust = 5;
      }
    ];
    # Linux 上读卡交给系统的 pcscd，scdaemon 自带的 CCID 驱动会与它争用设备。
    scdaemonSettings = lib.mkIf pkgs.stdenv.isLinux { disable-ccid = true; };
  };
}
