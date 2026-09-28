<!-- mirror-notice:start -->
> **这是脱敏镜像。** 本仓库由本地学习工作区的 `scripts/publish.sh` 自动导出，公开前做了两层处理：
>
> 1. **标识替换**：本机绝对路径（`/home/...`）、GitHub 账号、邮箱等替换为 `~/...` 或占位符；
> 2. **场景泛化**：业务场景里的可识别细节（具体终端形态、设备位置）替换为通用描述。
>
> 因此**本仓库中的路径不能照抄执行**，请按「本地练习环境」一节改成你自己的路径。
> 脱敏规则本身保存在本地、不随仓库分发；导出脚本会做「残留检查」，只要敏感原文仍能命中就整体失败、不产出镜像。
<!-- mirror-notice:end -->
# 学习工作区：BullMQ（20 小时冲刺）

这是我的 BullMQ 学习工作区，按 `learning-coach` 的约定维护：**计划、日志、错点、复习队列全部落盘**，任何一次新会话都能凭文件接着上次继续，不用重新交代背景。

## 目标与期限

| 项目 | 内容 |
| --- | --- |
| 目标 | 两周内达到「能上手写（生产落地）+ 面试能答」 |
| 约定截止日 | 2026-10-12（用户指定；我的推荐日是 2026-10-19，按 7 h/周 换算） |
| 总预算 | 约 20.1 h（含 35% 复习），10 个学习单元 S01–S10 |
| 版本基线 | BullMQ v6（最新 6.3.9） |
| 贯穿场景 | 客户端 App → 业务服务器 → 现场设备（开/关空调） |

完整计划见 [bullmq/PLAN.md](bullmq/PLAN.md)（v1 已冻结，改动只追加修订记录 + `bullmq/archive/` 快照）。

## 目录结构

```text
learning/
├── INDEX.md                     # 学习域索引（由脚本生成）
└── bullmq/
    ├── AGENTS.md                # 本目录约定（给未来的自己/agent 看）
    ├── PLAN.md                  # 学习计划：目标、截止日、阶段、检查点、修订记录
    ├── topics.md                # 冲刺单元表（S01–S10）+ 完整知识地图（T01–T34）
    ├── state.json               # 机器可读状态：进度、掌握度、复习队列
    ├── notes/                   # 每个单元的讲义与复述稿
    ├── logs/                    # 每轮学习日志（YYYY-MM-DD-HHmm-NNN-rrrr.md）
    ├── archive/                 # 计划快照 PLAN-v1.md …
    ├── scripts/                 # 主题登记脚本（幂等）
    └── practice/                # 动手练习代码（package.json + 示例）
```

## 怎么续做（给未来的自己）

1. 读 `bullmq/state.json`、`bullmq/PLAN.md`、`bullmq/topics.md`，再看 `bullmq/logs/` 里最近一篇；
2. 跑 `python3 ~/.codex/skills/learning-coach/scripts/learn.py due --root bullmq --horizon 3` 看待复习项，**先复习再上新内容**；
3. 学完一个单元按「讲解 → 费曼复述 → 考官五维打分 → 写日志」走，掌握度 < 0.6 的单元下一轮必须重讲。

## 本地练习环境

仓库里不含运行环境（`.gitignore` 已排除），需要时按下面重建：

```bash
# 1) Redis（本机用户态编译，端口 6390；沙箱内需以非沙箱方式启动）
mkdir -p .tools && cd .tools
curl -sSL -o redis.tar.gz https://download.redis.io/releases/redis-8.10.2.tar.gz
tar xzf redis.tar.gz && cd redis-8.10.2 && make -j8 MALLOC=libc BUILD_TLS=no
./src/redis-server --port 6390 --daemonize yes --dir ../data --save '' --appendonly no

# 2) 依赖
cd bullmq/practice && npm install bullmq
```

## 说明

- 本仓库是个人学习记录：计划、讲义、日志、面试问答都会持续追加。
- 讲义里的 API 行为尽量标注了来源与核实状态（`已核实` / `未核实`），未核实项会写明确认方式。

## 两个仓库的分工

| 仓库 | 内容 | 用途 |
| --- | --- | --- |
| **本仓库（private）** | 原始工作区：真实绝对路径、真实业务场景、脱敏规则文件，全部保留 | 跨机器接手、完整可追溯 |
| 公开镜像（`bullmq-learning`） | 由 `scripts/publish.sh` 生成的**脱敏**副本 | 对外分享 |

同步命令：

```bash
bash scripts/sync-private.sh   # 原始版 → private 仓库
bash scripts/sync-public.sh    # 脱敏版 → 公开仓库
```

在**另一台电脑**上接手的步骤：克隆本仓库 → 重建练习环境（见上「本地练习环境」）→ 让 agent 读 `bullmq/AGENTS.md` 与 `bullmq/state.json`，按 `bullmq/PLAN.md` 的阶段继续。注意 `PLAN.md` 与 `state.json` 里记的是**原来那台机器的绝对路径**，必要时先按新机器路径更新这两处。
