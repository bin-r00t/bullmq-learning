#!/usr/bin/env bash
# BullMQ 学习域：主题全集（完整知识地图 T01–T34）登记脚本
#
# 幂等：同一主题 ID 重复执行 = 覆盖更新该主题的元数据（不会动 mastery / 复习档位之外的进度）。
# 用法：
#   bash scripts/register-full-topics.sh              # 默认登记到脚本所在学习域
#   bash scripts/register-full-topics.sh <domain-root>
#
# 注意：完整地图不是当前执行计划。当前 20h 冲刺计划用 scripts/register-sprint-topics.sh。
# 主题清单的权威说明见 ../topics.md，改主题时两处一起改。
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

PHASE1="阶段1·地基"
PHASE2="阶段2·核心机制"
PHASE3="阶段3·工程实践"
PHASE4="阶段4·生产与演进"
PHASE5="阶段5·综合与巩固"

t T01 "BullMQ 定位与选型：四个核心类、与 Bull/Kafka/SQS/Celery 的差异" "$PHASE1" L1 核心必学 概念 "" 1.0 慢 "口述 BullMQ 与消息中间件的差异，并说明什么场景不该用它"
t T02 "核心类与术语：Queue / Worker / QueueEvents / FlowProducer / Job / JobScheduler" "$PHASE1" L1 核心必学 概念 "T01" 1.0 慢 "画出四类对象的职责与调用关系"
t T03 "Job 生命周期与状态机（wait/prioritized/delayed/active/completed/failed/waiting-children）" "$PHASE1" L2 核心必学 原理机制 "T02" 1.5 中 "写出任意一条 add→处理→完成 的完整状态迁移序列"
t T04 "最小可运行闭环：Queue.add + Worker 处理 + 结果返回" "$PHASE1" L1 核心必学 "API 用法" "T02" 1.5 中 "本地跑通生产者+消费者，job 被正确处理并拿到返回值"
t T05 "连接与配置：ioredis 选项、worker 阻塞连接约束、连接复用" "$PHASE1" L2 核心必学 工程实践 "T04" 2.0 快 "解释为何 worker/QueueEvents 需要 maxRetriesPerRequest=null 并写出配置"

t T06 "存储布局与原子性：Redis key 结构 + Lua 脚本" "$PHASE2" L3 核心必学 原理机制 "T03,T05" 2.0 中 "用 redis-cli 观察一个 job 从 wait→active→completed 的 key 变化"
t T07 "Job 数据模型与 options 全解（jobId、data、opts、返回值与进度）" "$PHASE2" L2 核心必学 "API 用法" "T04" 2.0 快 "列出常用 opts 并说出各自影响的行为"
t T08 "Worker 拉取循环与并发模型（阻塞读取、active 集合、token）" "$PHASE2" L3 核心必学 原理机制 "T06" 2.0 中 "解释 worker 如何避免空转与重复消费"
t T09 "并发与横向扩展：本地 concurrency、global concurrency、多进程与多机" "$PHASE2" L3 核心必学 工程实践 "T08" 2.0 中 "为给定吞吐目标算出 worker 数与并发配置并说明假设"
t T10 "延迟任务：delayed 集合与到期提升机制" "$PHASE2" L3 核心必学 原理机制 "T03,T08" 1.5 中 "说明 delay 的实现方式与精度限制"
t T11 "优先级与 FIFO/LIFO 语义" "$PHASE2" L3 推荐 原理机制 "T08" 1.5 中 "构造优先级与 FIFO/LIFO 组合并预测处理顺序"
t T12 "失败与重试：attempts、backoff（fixed/exponential/custom）、UnrecoverableError" "$PHASE2" L2 核心必学 原理机制 "T03" 2.0 中 "写出三档指数退避策略并解释每次重试的调度"
t T13 "限流：queue limiter、worker limiter、global rate limit" "$PHASE2" L3 推荐 工程实践 "T09,T12" 2.0 快 "为下游 10 rps 的 API 设计限流方案并说明放在哪一层"
t T14 "Stalled job：锁续约、lockDuration、maxStalledCount 与排查路径" "$PHASE2" L4 核心必学 原理机制 "T08" 2.5 中 "给出 stalled 的成因清单与定位命令"
t T15 "事件系统：Worker 本地事件 vs QueueEvents（streams）与自定义事件" "$PHASE2" L2 核心必学 "API 用法" "T03" 2.0 快 "用 QueueEvents 监听完成/失败并说明与 worker 本地事件的区别"
t T16 "Job Scheduler：cron/间隔、时区、模板 job、limit 与起止时间" "$PHASE2" L3 核心必学 "API 用法" "T07" 2.5 中 "配置带时区的 cron 调度器并验证下一次执行时间"
t T17 "Flows：父子依赖、waiting-children、fail/continue parent、移除依赖" "$PHASE2" L3 推荐 "API 用法" "T03,T16" 2.5 中 "构建三层 flow 并验证父任务在子任务完成后才执行"
t T18 "去重（deduplication id/ttl/replace/extend）与 v6 移除 debounce" "$PHASE2" L3 推荐 "API 用法" "T07" 1.5 快 "用 dedup id 实现同一订单只入队一次"
t T19 "队列运维操作：pause/resume、drain、obliterate、clean、自动清理" "$PHASE2" L2 推荐 运维排错 "T15" 1.5 快 "在不停服前提下暂停并清空一个测试队列"
t T20 "优雅关闭、任务取消与沙箱处理器" "$PHASE2" L3 核心必学 工程实践 "T08,T09" 2.5 中 "实现 SIGTERM 下不丢任务、不硬中断执行中任务的关闭流程"

t T21 "至少一次投递与幂等设计" "$PHASE3" L3 核心必学 工程实践 "T12,T14" 2.0 慢 "为扣款类任务写出幂等方案并说明重放后果"
t T22 "失败处理策略：停止重试、死信、人工重放与告警" "$PHASE3" L3 核心必学 工程实践 "T12,T15" 2.0 中 "设计一套失败任务处置流程（含人工介入）"
t T23 "可观测性：metrics、Prometheus 指标、日志与队列看板" "$PHASE3" L3 推荐 运维排错 "T15" 2.0 中 "说清任务积压该看哪些指标"
t T24 "官方 Telemetry：OpenTelemetry traces/metrics 接入" "$PHASE3" L3 推荐 生态集成 "T23" 2.0 中 "接入 telemetry 并在 Jaeger 看到 job 的 trace"
t T25 "测试策略：隔离前缀、obliterate、时间相关逻辑与集成测试" "$PHASE3" L3 推荐 工程实践 "T19" 2.0 中 "写出一组互不干扰的队列集成测试"
t T26 "性能与容量：批量添加、序列化、Redis 负载与保留策略" "$PHASE3" L4 推荐 性能调优 "T06,T13" 2.5 中 "估算目标吞吐对应的 Redis 资源与保留配置"

t T27 "Redis 部署形态：单机/哨兵/集群（hash tag）、托管服务与兼容性" "$PHASE4" L4 推荐 运维排错 "T05,T26" 2.0 慢 "说明集群模式下必须遵守的前缀/hash tag 约束"
t T28 "后端选择：v6 的 PostgreSQL 后端 vs Redis 后端" "$PHASE4" L3 推荐 概念 "T05,T27" 1.5 慢 "说出两套后端的取舍与迁移代价"
t T29 "版本演进与迁移：repeatable→Job Scheduler、v5→v6 破坏性变更" "$PHASE4" L3 核心必学 概念 "T16,T18" 2.0 中 "产出一份 v5→v6 升级检查清单"
t T30 "生态与多语言：NestJS 集成、多语言绑定互操作、看板工具" "$PHASE4" L2 选修 生态集成 "T04" 1.5 慢 "用 NestJS 跑通一个最小队列"
t T31 "常见坑与反模式清单" "$PHASE4" L3 核心必学 运维排错 "T21,T22,T26" 1.5 中 "对给定反例代码指出问题并给出改法"

t T32 "综合项目：带重试/限流/幂等/可观测性的队列服务" "$PHASE5" L4 核心必学 工程实践 "T21,T22,T23,T26" 4.0 慢 "交付可运行项目 + 设计说明并接受评审提问"
t T33 "故障演练：kill worker、Redis 重启与切换、网络抖动" "$PHASE5" L4 推荐 运维排错 "T26,T27,T32" 3.0 中 "记录每类故障的现象、恢复行为与数据影响"
t T34 "BullMQ Pro 概览：groups / batches / observables" "$PHASE5" L2 按需查阅 生态集成 "T30" 1.0 慢 "说明 Pro 特性在什么条件下值得付费"

echo "[完成] 主题登记结束，共 34 个主题（T01–T34）"
python3 "$LEARN_PY" status --root "$DOMAIN_ROOT"
