# 本目录约定（learning-coach）

这是 **BullMQ** 知识域的学习工作区，按 `learning-coach` skill 的约定维护。

- **工作区路径**：`~/learning/bullmq`（默认学习根 `~/learning` 在沙箱可写范围外，故落在当前工作区；`state.json.root` 与本文件保持一致）。
- **先读再动**：开始工作前按顺序读 `state.json`、`PLAN.md`、`topics.md`，再看 `logs/` 里最近一篇，避免重复劳动。
- **复习优先**：有 `next_review_at` 已到期的主题时，先复习再讲新内容；跳过的复习必须写进当轮日志的「偏差记录」。
- **计划可追溯**：`PLAN.md` 只能追加修订记录，任何结构性改动都要在 `archive/` 里留新快照，禁止覆盖历史版本。
- **日志强制**：每轮学习（含用户中途结束）都要在 `logs/` 下新增日志，文件名格式 `YYYY-MM-DD-HHmm-NNN-rrrr.md`，用 `python3 ${CODEX_HOME:-$HOME/.codex}/skills/learning-coach/scripts/learn.py new-log --root .` 生成，不要手写。
- **状态机读字段**：`state.json` 里的 `interval_index`、`next_review_at`、`round`、`mastery` 由 `scripts/learn.py` 维护，不要手改。
- **当前计划口径**：执行的是 **20 h 冲刺版**（目标：两周内「生产落地 + 面试能答」），`state.json` 里只有 10 个单元 `S01–S10`；完整知识地图 34 主题（T01–T34）保留在 `topics.md` 第二节，用于以后扩展成系统计划（约 112 h）。
- **主题登记**：冲刺单元用 `scripts/register-sprint-topics.sh`；完整地图用 `scripts/register-full-topics.sh`（两者幂等、同 ID 覆盖更新，但**不要混在同一个 state 里**，切换口径前先 `new-workspace --force` 重建）。主题清单的权威说明是同目录 `topics.md`，改主题时两处同步改。
- **时间预算**：冲刺版总投入约 20.1 h，任何新增内容都要同时说明「从哪里砍」；不允许悄悄超出 20 h 预算。
- **掌握度门槛**：`mastery < 0.6` 的主题不算完成，必须回到讲解并在下一轮重新出现。
- **不许编造**：未核实的 API、版本行为、来源要显式标注「未核实」。本领域版本基线是 **BullMQ v6**（2026-09 最新 6.3.9），v5 及更早的行为差异很大，讲旧行为必须显式声明版本。
- **授课前核实**：`topics.md` 第四节列出的不确定项，在讲到对应主题前必须抓取官方文档确认（网络需申请授权，抓取结果记入当轮日志）。
