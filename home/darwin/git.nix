# Mac 上 git 的机器相关设置，取自机器上原来的 ~/.gitconfig。
#
# GitHub 与 gist 的凭据助手不在这里写：home-manager 的 gh 模块已经配好，指向 Nix 里 gh 的绝对路径。
{
  programs.git.settings = {
    core.editor = "vim";

    # 本机的 socks5 代理。
    http.proxy = "socks5://127.0.0.1:6153";
    https.proxy = "socks5://127.0.0.1:6153";

    # 其余远端（例如自建的 Gitea）用 ~/.git-credentials，明文存放。
    credential.helper = "store";
  };
}
