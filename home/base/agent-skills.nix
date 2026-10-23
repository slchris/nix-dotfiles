# 各家 coding agent 共用的 skill 集合，全部来自 flake 输入（见 flake.nix 的 agents-skills-*）。
#
# 四个 agent 的 skill 搜索路径只有部分重叠（在本机逐个实测过）：
#   ~/.agents/skills  → Codex、opencode、Grok Build 读；Claude Code 不读
#   ~/.claude/skills  → Claude Code、opencode、Grok Build 读；Codex 不读
#   ~/.codex/skills   → 只有 Codex 读（Codex 另外也读 ~/.agents/skills）
#   ~/.grok/skills    → 只有 Grok Build 读
# 所以往上面两个 root 各链一份，四个 agent 就都覆盖到了。
# opencode 与 Grok 会从两个 root 看到同名 skill，两者都按名字去重，不会重复注入（实测）。
#
# skill 目录本身指进 /nix/store，这是 home-manager 生成软链的常规做法；
# 四家都跟随软链读取，已实测。不用 npx skills add 或各家的 /plugin install：
# 那些写真实目录和各自的状态文件，会跟声明式管理互相覆盖。
{
  config,
  lib,
  agentSkillSources,
  ...
}:
let
  cfg = config.dotfiles.packages;

  # 递归找出 root 下所有含 SKILL.md 的目录，返回 { name, path } 列表。
  #
  # 名字取自 readDir 的键拼出的相对路径，不能用 baseNameOf dir：后者作用在 path 上会带上
  # store context，flake 求值时直接报 "the string 'x' is not allowed to refer to a store path"。
  discover =
    root:
    let
      go =
        dir: rel:
        let
          entries = builtins.readDir dir;
          subdirs = lib.filterAttrs (_: type: type == "directory") entries;
          here = lib.optional (entries ? "SKILL.md") {
            name = lib.last (lib.splitString "/" rel);
            path = dir;
          };
        in
        here
        ++ lib.concatMap (n: go (dir + "/${n}") (if rel == "" then n else "${rel}/${n}")) (
          builtins.attrNames subdirs
        );
    in
    go root "";

  # mattpocock/skills 有 38 个，全装会把每个会话的 skill 清单撑大（description 合计约 5.4KB，
  # 每轮都要进 context 的 <available_skills>），所以只挑日常真的会用的。
  # 刻意跳过两类：
  #   in-progress/  上游自己标注 WIP、改动频繁；
  #   misc/         多为 Claude Code 专用 hooks 脚手架，对另外三个 agent 无意义。
  # 它上游另有 23 个 skill 带 disable-model-invocation: true（Claude 里等于只能手动 /调用），
  # 这个 key 另外三家不认，会被当成可自动触发，挑的时候已避开。
  mattpocockPicks = [
    "engineering/research"
    "engineering/tdd"
    "engineering/diagnosing-bugs"
    "engineering/code-review"
    "engineering/domain-modeling"
    "engineering/codebase-design"
    "engineering/prototype"
    "engineering/implement"
    "engineering/to-spec"
    "engineering/pr"
    "productivity/grilling"
    "productivity/handoff"
    "productivity/writing-for-agents"
  ];

  picked =
    discover (agentSkillSources.cloudflare + "/skills")
    ++ discover (agentSkillSources.ponytail + "/skills")
    ++ map (p: {
      name = lib.last (lib.splitString "/" p);
      path = agentSkillSources.mattpocock + "/skills/${p}";
    }) mattpocockPicks;

  names = map (s: s.name) picked;
  dupes = lib.subtractLists (lib.unique names) names;

  roots = [
    ".agents/skills"
    ".claude/skills"
  ];
in
{
  config = lib.mkIf cfg.ai.enable {
    # 上游改目录名时在这里炸出来，而不是让某个 skill 静默消失。
    assertions = [
      {
        assertion = dupes == [ ];
        message = "agent skill 名字重复：${lib.concatStringsSep "、" dupes}";
      }
      {
        assertion = lib.all (
          p: builtins.pathExists (agentSkillSources.mattpocock + "/skills/${p}/SKILL.md")
        ) mattpocockPicks;
        message = "mattpocock 的 SKILL 清单里有不存在的路径，上游可能改名了";
      }
    ];

    # 平铺成 <root>/<skill 名>/SKILL.md。不用嵌套目录：
    # Codex 与 opencode 能递归找到，Grok 只认一层（实测）。
    #
    # 注意 home.file 遇到已存在的真实目录会报错而不是覆盖。加新 skill 前先看一眼
    # ~/.claude/skills 和 ~/.agents/skills，别和手工装的同名。
    home.file = lib.listToAttrs (
      lib.concatMap (s: map (r: lib.nameValuePair "${r}/${s.name}" { source = s.path; }) roots) picked
    );
  };
}
