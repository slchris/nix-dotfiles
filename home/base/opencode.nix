# opencode 的配置。默认每个动作都要确认，一天下来全在按 y，所以这里把常规操作放开，
# 只在会改坏东西的命令上停一下。
#
# 匹配规则是从上往下、后命中的覆盖先命中的，所以 "*" 写在最前面，具体的写在后面。
#
# 注意：这份是人坐在终端前用的配置，"ask" 会弹在 TUI 里。openclaw 通过 ACP 调 opencode 时
# 没有 TTY，acpx 只有 approve-all / approve-reads / deny-all 三挡，"ask" 到不了人；
# 那条链路用另一份更严的配置（见 homelab 仓库 nix/workstations/nixos/agent-gateway.nix）。
{
  config,
  lib,
  pkgs,
  ...
}:
let
  cfg = config.dotfiles.packages;

  settings = {
    "$schema" = "https://opencode.ai/config.json";

    permission = {
      # 读与检索没有副作用，一律放行。
      read = "allow";
      glob = "allow";
      grep = "allow";
      lsp = "allow";
      webfetch = "allow";
      websearch = "allow";
      # 改文件也放行：改错了有 git 兜底。
      edit = "allow";
      task = "allow";
      skill = "allow";
      # 跳出当前项目去读别处的目录，问一下。
      external_directory = "ask";

      bash = {
        "*" = "allow";

        # 删除与覆盖。
        "rm -rf *" = "ask";
        "rm -fr *" = "ask";
        "sudo *" = "ask";
        "chmod -R *" = "ask";
        "chown -R *" = "ask";

        # git 里会丢工作成果或改写别人历史的那几条。
        "git push *" = "ask";
        "git reset --hard*" = "ask";
        "git clean *" = "ask";
        "git rebase *" = "ask";
        "git filter-branch *" = "ask";

        # 会动到真实环境的。
        "kubectl apply *" = "ask";
        "kubectl delete *" = "ask";
        "kubectl patch *" = "ask";
        "helm upgrade *" = "ask";
        "helm uninstall *" = "ask";
        "terraform apply*" = "ask";
        "terraform destroy*" = "ask";
        "deploy *" = "ask";
        "nixos-rebuild switch*" = "ask";
        "darwin-rebuild switch*" = "ask";
        "docker system prune*" = "ask";
        "nix store delete*" = "ask";

        # 凭据。读出来就等于泄露，不给。
        "security find-generic-password*" = "deny";
        "pass show *" = "deny";
        "sops -d *" = "ask";

        # 下载即执行，任何情况下都不要。
        "curl * | sh*" = "deny";
        "curl * | bash*" = "deny";
        "wget * | sh*" = "deny";
        "wget * | bash*" = "deny";
      };
    };

    mcp.browser = {
      type = "local";
      enabled = true;
      # 原来是 ~/.local/bin 下手工装的 npm 包，换成 nixpkgs 里的。
      command = [
        (lib.getExe pkgs.playwright-mcp)
        "--browser"
        "chrome"
        "--user-data-dir"
        "${config.home.homeDirectory}/.local/share/opencode-browser-profile"
        "--viewport-size"
        "1440x900"
        "--output-dir"
        "${config.home.homeDirectory}/.local/share/opencode-browser-output"
        "--console-level"
        "warning"
      ];
    };

    # Codex 桌面版的 computer use（cua_repl MCP 服务），让 opencode 也能操作桌面应用。
    # command/args/env 来自 ~/.codex/plugins/cache/openai-bundled/unified-computer-use/<版本>/.mcp.json；
    # Codex 升级后版本号会变，BROWSER_USE_CODEX_APP_VERSION 要跟着更新。
    # opencode 1.18.21 的 MCP 客户端不支持 elicitation（issue #23066），而 Codex 的授权
    # 弹窗（"Allow Computer Use to use ...?"）走 elicitation/create，直接注册会被卡死。
    # 因此先经过同目录的 codex-cu-proxy.py：它代 opencode 声明 elicitation，收到授权请求时
    # 弹 macOS 对话框（拒绝 / 允许一次 / 始终允许）；"始终允许"按 App 记在
    # ~/.local/state/codex-cu-proxy/approvals.json，所有决定写入同目录 approvals.log。
    # 想完全静默放行（不再确认），把 CODEX_CU_PROXY_AUTO_APPROVE 改成 "1"。
    # 等 opencode v2 支持 elicitation 后可以直接去掉代理，command 换回 node + cua-repl.mjs。
    mcp.codex-cu = {
      type = "local";
      enabled = true;
      # 授权对话框最长等 300s，把 MCP 调用超时放宽到 10 分钟。
      timeout = 600000;
      command = [
        "${pkgs.python3}/bin/python3"
        "${./codex-cu-proxy.py}"
        "/Applications/Codex.app/Contents/Resources/cua_node/bin/node"
        "/Applications/Codex.app/Contents/Resources/cua_node/lib/node_modules/@oai/cua-repl/bin/cua-repl.mjs"
      ];
      environment = {
        CODEX_CU_PROXY_AUTO_APPROVE = "0";
        NODE_REPL_NATIVE_PIPE_CONNECT_TIMEOUT_MS = "1000";
        NODE_REPL_NODE_MODULE_DIRS = "/Applications/Codex.app/Contents/Resources/cua_node/lib/node_modules";
        NODE_REPL_NODE_PATH = "/Applications/Codex.app/Contents/Resources/cua_node/bin/node";
        NODE_REPL_TRUSTED_CODE_PATHS = "${config.home.homeDirectory}/.codex:/Applications/Codex.app/Contents/Resources/cua_node/lib/node_modules";
        CODEX_HOME = "${config.home.homeDirectory}/.codex";
        BROWSER_USE_AVAILABLE_BACKENDS = "chrome,iab,mcpapps";
        BROWSER_USE_TINYSKY_ENABLED = "1";
        NODE_REPL_INSTRUCTIONS_USE_CASE_BROWSER = "Control the in-app browser in conjunction with the Browser Plugin.";
        NODE_REPL_INSTRUCTIONS_USE_CASE_CHROME = "Control the Chrome browser in conjunction with the Chrome Plugin. Prefer this method of controlling Chrome over alternatives (such as Computer Use) unless the user explicitly mentions an alternative.";
        NODE_REPL_INSTRUCTIONS_USE_CASE_COMPUTER_USE = "Control desktop apps on macOS through Computer Use.";
        BROWSER_USE_CODEX_APP_BUILD_FLAVOR = "prod";
        BROWSER_USE_CODEX_APP_VERSION = "26.930.31730";
        NODE_REPL_TRUSTED_SERVICES = "{\"browser\":\"@oai/browser-desktop/service\",\"sky\":\"@oai/sky/service\"}";
        SKY_CUA_SERVICE_PATH = "${config.home.homeDirectory}/.codex/computer-use/Codex Computer Use.app";
        CODEX_CLI_PATH = "/Applications/Codex.app/Contents/Resources/codex-cli/CodexCLI.app/Contents/MacOS/codex";
        CUA_REPL_NODE_REPL_PATH = "/Applications/Codex.app/Contents/Resources/cua_node/bin/node_repl";
        CUA_REPL_ENABLED_SURFACES = "browser,computer";
      };
    };
  };
in
{
  config = lib.mkIf cfg.ai.enable {
    # opencode 认 opencode.json 与 opencode.jsonc，两个都在会有歧义，只留一个。
    #
    # 不能直接用 home.file 软链到 /nix/store：magpie 要改写这个文件来切模型
    # （`magpie opencode myclaw/claude-opus-5.5`），软链是只读的，会报
    # "permission denied"。所以改成激活时合并：声明式设置（权限、MCP）以这里为准，
    # magpie 写入的 model/provider 原样保留。
    home.activation.opencodeConfig = lib.hm.dag.entryAfter [ "writeBoundary" ] ''
      cfg="$HOME/.config/opencode/opencode.jsonc"
      base=${pkgs.writeText "opencode-base.jsonc" (builtins.toJSON settings)}

      run mkdir -p "$HOME/.config/opencode"
      if [ -L "$cfg" ] || [ ! -e "$cfg" ]; then
        run rm -f "$cfg"
        run install -m644 "$base" "$cfg"
      else
        tmp="$cfg.tmp.$$"
        if ${pkgs.jq}/bin/jq -s '.[0] * .[1]' "$base" "$cfg" > "$tmp"; then
          run mv "$tmp" "$cfg"
        else
          run rm -f "$tmp"
          echo "opencode.jsonc: merge failed, left unchanged" >&2
        fi
      fi
    '';
  };
}
