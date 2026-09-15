# chris 的身份：git 提交者、签名密钥（在 YubiKey 上）与私密配置。
{
  dotfiles.git = {
    name = "Chris Su";
    email = "chris@lesscrowds.org";
    signingKey = "0x45D10727855239D3";
    publicKeys = [ ../keys/chris.asc ];
  };

  dotfiles.secrets = {
    githubUser = "slchris";
    sshConfig = true;
  };
}
