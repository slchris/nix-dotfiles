# chris 的身份：git 提交者、签名密钥（在 YubiKey 上）与私密配置。
{
  dotfiles.git = {
    name = "Chris Su";
    email = "chris@lesscrowds.org";
    signingKey = "0x45D10727855239D3";
    publicKeys = [ ../keys/chris.asc ];
  };

  # 密码库在 GitHub 私有仓库（经 gh 的 token 克隆）与 homelab 的 Gitea 各有一份。
  dotfiles.pass = {
    enable = true;
    cloneFrom = "github";
    remotes = {
      github = "https://github.com/slchris/pass.git";
      origin = "https://git.infra.plz.ac/slchris/.password-store.git";
    };
  };

  dotfiles.secrets = {
    githubUser = "slchris";
    sshConfig = true;
  };
}
