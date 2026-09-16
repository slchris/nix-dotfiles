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
  };
in
{
  config = lib.mkIf cfg.ai.enable {
    # opencode 认 opencode.json 与 opencode.jsonc，两个都在会有歧义，只留一个。
    home.file.".config/opencode/opencode.jsonc".text = builtins.toJSON settings;
  };
}
