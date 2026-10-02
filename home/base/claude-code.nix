# Claude Code 的 DeepSeek 车道。官方 Claude 那条线（claude 命令）保持原样，
# 这里只加一个 claude-ds 包装命令，环境变量全部指向 DeepSeek 的 Anthropic 兼容接口。
#
# 模型只用 flash：DeepSeek 侧会把 claude-opus* 映射到按 Pro 计费的 deepseek-v4-pro，
# 所以 opus/sonnet 两个默认位也显式指到 flash，子代理和 /model 都落不到 Pro 上。
# shell 里的 ANTHROPIC_MODEL 优先于 ~/.claude/settings.json 的 model（官方文档的
# per-pair 优先级），那份文件由 Orca 管着 hooks，不用动。
#
# key：声明了 sops 的 deepseek-api-key 的主机（keiki）读解出来的文件；NixOS 上如果
# 走系统层 sops，秘密在 /run/secrets/deepseek-api-key。两者都没有时留
# ANTHROPIC_AUTH_TOKEN 环境变量兜底，再没有就明确报错。
#
# auto 模式的分类器：DeepSeek 网关做不了官方的服务端检查，显式关掉这项协商，
# 免得每个新会话都弹「会话不合格」的提示。计费行为不变，分类器仍按 token 计。
{
  config,
  lib,
  pkgs,
  unstablePkgs,
  ...
}:
let
  cfg = config.dotfiles.packages;
  # 与 home/base/dsh.nix、homelab 的 agent-gateway.nix 是同一把 key。
  apiKeySecret = config.sops.secrets."deepseek-api-key" or null;
  keyFiles = lib.optional (apiKeySecret != null) apiKeySecret.path ++ [
    "/run/secrets/deepseek-api-key"
  ];
  claudeDs = pkgs.writeShellScriptBin "claude-ds" ''
    if [ -z "''${ANTHROPIC_AUTH_TOKEN:-}" ]; then
      for f in ${lib.concatStringsSep " " (map lib.escapeShellArg keyFiles)}; do
        if [ -r "$f" ]; then
          ANTHROPIC_AUTH_TOKEN="$(cat "$f")"
          export ANTHROPIC_AUTH_TOKEN
          break
        fi
      done
    fi
    if [ -z "''${ANTHROPIC_AUTH_TOKEN:-}" ]; then
      echo "claude-ds: 未找到 DeepSeek API key（sops 的 deepseek-api-key 未部署，也没有 ANTHROPIC_AUTH_TOKEN）" >&2
      exit 1
    fi

    export ANTHROPIC_BASE_URL="https://api.deepseek.com/anthropic"
    export ANTHROPIC_MODEL="deepseek-flash[1m]"
    export ANTHROPIC_DEFAULT_OPUS_MODEL="deepseek-flash[1m]"
    export ANTHROPIC_DEFAULT_SONNET_MODEL="deepseek-flash[1m]"
    export ANTHROPIC_DEFAULT_HAIKU_MODEL="deepseek-flash"
    export CLAUDE_CODE_SUBAGENT_MODEL="deepseek-flash"
    export CLAUDE_CODE_EFFORT_LEVEL="max"
    export CLAUDE_CODE_AUTO_COMPACT_WINDOW="786432"
    export CLAUDE_CODE_AUTO_MODE_SERVER="0"

    exec ${unstablePkgs.claude-code}/bin/claude "$@"
  '';
in
{
  config = lib.mkIf cfg.ai.enable {
    home.packages = [ claudeDs ];
  };
}
