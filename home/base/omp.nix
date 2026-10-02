# oh-my-pi（omp）的配置。包与 home-manager 模块来自上游 flake（见 flake.nix 的 omp 输入，
# 模块会装 programs.omp.package 并把 programs.omp.settings 写成 ~/.omp/agent/config.yml）。
#
# DeepSeek 的 key 与 claude-ds、dsh 共用 sops 里的 deepseek-api-key：声明了该 secret 的主机
# 把 omp 换成一层 wrapper，启动时读文件、以 DEEPSEEK_API_KEY 注入（omp 的 provider 凭据链认
# 这个变量，见上游 docs/environment-variables.md），key 不落盘也不进 store。没声明 secret
# 的主机装原始包，自己在 omp 里 /login 或 /connect。
{
  config,
  lib,
  ompPkg,
  pkgs,
  ...
}:
let
  cfg = config.dotfiles.packages;
  # 与 claude-code.nix、dsh.nix 是同一把 key。
  apiKeySecret = config.sops.secrets."deepseek-api-key" or null;
  keyFiles = lib.optional (apiKeySecret != null) apiKeySecret.path ++ [
    "/run/secrets/deepseek-api-key"
  ];
  ompCli = pkgs.writeShellScriptBin "omp" ''
    if [ -z "''${DEEPSEEK_API_KEY:-}" ]; then
      for f in ${lib.concatStringsSep " " (map lib.escapeShellArg keyFiles)}; do
        if [ -r "$f" ]; then
          DEEPSEEK_API_KEY="$(cat "$f")"
          export DEEPSEEK_API_KEY
          break
        fi
      done
    fi
    exec ${ompPkg}/bin/omp "$@"
  '';
in
{
  config = lib.mkIf cfg.ai.enable {
    programs.omp = {
      enable = true;
      package = ompCli;
    };
    # 有 key 的主机默认就落到 DeepSeek flash；没有 key 的主机不写死模型，留给 /model。
    programs.omp.settings = lib.mkIf (apiKeySecret != null) {
      modelRoles.default = "deepseek/deepseek-flash";
    };
  };
}
