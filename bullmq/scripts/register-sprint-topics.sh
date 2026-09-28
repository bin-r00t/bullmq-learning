#!/usr/bin/env bash
# BullMQ 学习域：20 小时冲刺计划（S01–S10）登记脚本
#
# 口径：目标 = 生产落地 + 面试；总投入 ≈ 20 h（含 35% 复习，技能规定的复习下限）。
# 学时 = 冲刺深度下的学习块时长；`--verify` 前缀 `覆盖 Txx` 记录它吸收了完整地图里的哪些主题。
#
# 幂等：同一 ID 重复执行 = 覆盖更新元数据。用法：
#   bash scripts/register-sprint-topics.sh [domain-root]
#
# 冲刺单元表的权威说明见 ../topics.md 第二节，改单元时两处一起改。
set -euo pipefail

DOMAIN_ROOT="${1:-$(cd "$(dirname "$0")/.." && pwd)}"
LEARN_PY="${LEARN_PY:-${CODEX_HOME:-$HOME/.codex}/skills/learning-coach/scripts/learn.py}"

if [ ! -f "$LEARN_PY" ]; then
  echo "[错误] 找不到 learn.py: $LEARN_PY（可用 LEARN_PY 环境变量指定）" >&2
  exit 1
fi

# t <id> <title> <phase> <difficulty> <importance> <type> <depends_on> <effort_hours> <forgetting> <verify>
t() {
  python3 "$LEARN_PY" topic --root "$DOMAIN_ROOT" \
    --id "$1" --title "$2" --phase "$3" --difficulty "$4" --importance "$5" \
    --type "$6" --depends-on "$7" --effort-hours "$8" --forgetting "$9" --verify "${10}"
}

P1="阶段1·主干"
P2="阶段2·扩展"
P3="阶段3·收口"

t S01 "概念模型与选型：四个核心类、Job 生命周期全景、与其它中间件的差异" "$P1" L1 核心必学 概念 "" 0.5 慢 \
  "覆盖 T01+T02｜口述 Queue/Worker/QueueEvents/FlowProducer 的职责，并说明 BullMQ 与 Kafka/SQS 的选型差异"
t S02 "最小闭环与 Job 数据模型：Queue.add、processor、jobId/data/opts、返回值" "$P1" L2 核心必学 "API 用法" "S01" 1.5 快 \
  "覆盖 T04+T07｜本地跑通生产+消费，并说出常用 opts 各自影响的行为"
t S03 "Job 状态机与迁移路径（wait/delayed/prioritized/active/completed/failed/waiting-children）" "$P1" L2 核心必学 原理机制 "S02" 1.0 中 \
  "覆盖 T03｜写出 add→active→completed 与失败重试两条完整迁移序列"
t S04 "Worker 机制与存储布局：拉取循环、并发模型、锁续约、stalled job、Redis key 结构" "$P1" L3 核心必学 原理机制 "S03" 2.0 中 \
  "覆盖 T06+T08+T09+T14｜用 redis-cli 指认 job 在 wait/active 时的 key，解释如何避免重复消费，给出 stalled 成因清单，并为给定吞吐算出并发配置"
t S05 "失败语义、重试与幂等：attempts/backoff、UnrecoverableError、至少一次投递" "$P1" L3 核心必学 工程实践 "S04" 2.0 慢 \
  "覆盖 T12+T21｜写出三档指数退避，并说明扣款类任务的幂等方案与重放后果"

t S06 "延迟、调度与优先级：delayed、Job Scheduler（cron/时区）、priority 与 FIFO/LIFO" "$P2" L3 核心必学 "API 用法" "S03" 1.5 中 \
  "覆盖 T10+T16+T11｜配置带时区的 cron 调度器并预测优先级与 FIFO/LIFO 下的处理顺序"
t S07 "限流与背压：queue limiter、worker limiter、global rate limit" "$P2" L3 推荐 工程实践 "S05" 0.5 快 \
  "覆盖 T13｜为下游 10 rps 的 API 设计限流方案并说明放在哪一层（时间紧时可砍）"
t S08 "连接、优雅关闭与运维操作：ioredis 约束、SIGTERM 关停、pause/drain/obliterate" "$P2" L2 核心必学 工程实践 "S02" 1.5 快 \
  "覆盖 T05+T20+T19｜写出 worker/QueueEvents 的正确连接配置，并实现不丢任务的关停流程"

t S09 "事件、可观测性与排错：worker 事件 vs QueueEvents、指标、常见坑" "$P3" L3 核心必学 运维排错 "S05" 1.0 中 \
  "覆盖 T15+T23（精简）+T31｜说出任务积压该看哪些指标，并指出给定反例代码的问题"
t S10 "版本演进与综合演练：v5→v6 破坏性变更、面试问答清单、小项目串讲" "$P3" L3 核心必学 概念 "S06,S08" 1.0 慢 \
  "覆盖 T29+T32（精简）｜产出 v5→v6 升级检查清单，并独立讲清一个带重试/幂等的队列服务设计"

echo "[完成] 冲刺计划登记结束，共 10 个单元（S01–S10）"
python3 "$LEARN_PY" status --root "$DOMAIN_ROOT"
