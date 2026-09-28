# S02 最小闭环与 Job 数据模型（讲义）

日期：2026-09-28 ｜ 计划：v1 ｜ 学时：1.5 h（含复习 2.2 h）｜ 覆盖完整地图：T04、T07
代码：`practice/s02-minimal.js`（用本地 Redis 6390 + bullmq 6.3.9 真实运行过，输出见下）

## 1. 三行代码就是全部骨架

```js
const queue = new Queue('device-commands', { connection });   // 生产者侧
await queue.add('ac-control', { deviceId, action }, { attempts: 3 });

const worker = new Worker('device-commands', async (job) => {  // 消费者侧
  return { ok: true };                                        // 返回值写回 Redis，成为 returnvalue
}, { connection, concurrency: 1 });
```

角色对应：`sendAcCommand()` = 你的业务服务器；`Worker` = 与设备通信的网关；`QueueEvents` = 独立部署的监听方。

## 2. 真实运行输出（2026-09-28，`node s02-minimal.js`）

```
[生产者] 入队 → id=1 name=ac-control data={"deviceId":"bedroom-ac-01","action":"turn-on"}
[Worker] 取到 job 1（此刻状态 active），开始联系设备…
[生产者] 入队 → id=2 name=ac-control data={"deviceId":"bedroom-ac-01","action":"turn-off"}
[QueueEvents] 跨进程事件：job 1 完成，returnvalue=[object Object]
[Worker事件] completed job=1 returnvalue={"ok":true,"deviceId":"bedroom-ac-01","action":"turn-on","at":"..."}
[Worker] 取到 job 2（此刻状态 active），开始联系设备…
[主流程] 队列计数器： { wait: 0, active: 1, completed: 1, failed: 0, delayed: 0 }
[主流程] 第一条 job 现在的状态： completed
[主流程] 已优雅关闭 worker / events / queue
```

这份输出里有四个值得注意的事实：

1. **`id=1`、`id=2`**：普通 `add()` 的 jobId 默认是**递增整数**（由 Redis 里 `bull:<queue>:id` 计数器生成）。只有 flow 中未显式给 `jobId` 的节点才是 UUID（官方 v5→v6 迁移页），两者不要记混。
2. **队列计数器是「某一瞬间」的快照**：读到 `active: 1, completed: 1` 时，第二条指令正在处理中。线上做监控时不能用一次读数下结论，要看趋势（S09 展开）。
3. **返回值必须先落到 returnvalue，才能被别人拿到**：worker 的 `return` 会被写进 job 的 `returnvalue`；生产者进程里的 Job 实例**不会自动更新**（我们那次 `job.toJSON()` 读到的 `returnvalue` 是 `null`，因为它是入队时的快照）。要拿结果得靠 `QueueEvents` 或 `await job.reload()` / `await queue.getJob(id)` 重新读。
4. **跨进程监听确实可用**：`QueueEvents` 收到了 `completed`（第 ③ 组日志），而 `worker.on(...)` 只在本进程打印（第 ② 组）。这正是 S01 里纠正过的那个区分。

## 3. Job 数据模型（`job.toJSON()` 实测字段）

| 字段 | 含义 | 谁写入 |
| --- | --- | --- |
| `id` | 任务标识（默认递增整数，可自定义） | 生产者 / BullMQ |
| `name` | 任务类型（同队列里区分不同任务） | 生产者 |
| `data` | 业务载荷（`{ deviceId, action }`） | 生产者 |
| `opts` | 本次任务的行为参数（attempts、backoff、removeOnComplete…） | 生产者 |
| `progress` | 进度（0–100 或任意值，`job.updateProgress()` 更新） | worker |
| `returnvalue` | 返回值（就是 processor 的 `return`） | worker |
| `timestamp` | 入队时间戳 | BullMQ |
| `attemptsMade` / `attemptsStarted` | 已用完的尝试次数 / 已开始的次数 | BullMQ |
| `stalledCounter` | 被判 stalled 的次数（S04 关键线索） | BullMQ |
| `stacktrace` | 失败堆栈（会截断保留） | BullMQ |
| `priority` | 优先级，默认 0（S06 展开） | 生产者 |
| `queueQualifiedName` | `bull:device-commands`，队列在 Redis 里的前缀 | BullMQ |

**记忆锚点**：`data` 是你要它做的，`returnvalue` 是它做完告诉你的，`progress` 是它做到哪了，`attemptsMade` 是它摔了几次。

## 4. 常用 opts 速查（本节只讲「是什么」，行为细节分到后续单元）

| opt | 作用 | 展开在哪 |
| --- | --- | --- |
| `jobId` | 指定任务 ID；重复 ID 会被拒绝/去重，是做幂等的抓手之一 | S05 |
| `attempts` + `backoff` | 失败后的重试次数与退避策略 | S05 |
| `delay` | 延迟执行 | S06 |
| `priority` | 优先级（0 最高，1–2^21 为显式优先级区间） | S06 |
| `removeOnComplete` / `removeOnFail` | 完成后保留/清理策略（**默认保留**，实测见下） | S08 |
| `lifo` / FIFO | 取出顺序 | S06 |

## 5. 顺手实测掉的两个「未核实」项（2026-09-28）

用 `practice/probe-remove-defaults.js` 跑的实验（原文见该文件）：

```
默认（只传 name/data）处理完后：
  getJobCounts = { wait: 0, active: 0, completed: 3, failed: 0 }
  重新读取第一条 job = 仍存在
  第一条 job 状态 = completed
```

Redis 里的 key：

```
bull:probe-remove-defaults:1        ← job hash（每个任务一条）
bull:probe-remove-defaults:2
bull:probe-remove-defaults:3
bull:probe-remove-defaults:completed ← 完成集合（zset）
bull:probe-remove-defaults:events    ← 事件流（QueueEvents 订阅的就是它）
bull:probe-remove-defaults:id        ← jobId 计数器（所以默认 id 是递增整数）
bull:probe-remove-defaults:meta
bull:probe-remove-defaults:stalled-check
```

两个结论：

1. **不传 `removeOnComplete` 时，完成的 job 会一直保留**（默认保留，不会自动删）。生产上必须显式设置，否则 Redis 内存会被历史任务撑爆——这是「常见坑」之一。
2. 队列的 key 结构已经隐约可见（`wait` 是 list，空了就消失，所以这次没看到 `:wait`）。这套结构是 S04 的主题。

## 6. 面试问答种子（S02）

1. job 的 `data` 和 `returnvalue` 分别由谁写入、什么时候可见？生产者怎么拿到处理结果？
2. `job.id` 默认是怎么生成的？为什么生产上有时要自己指定 `jobId`？
3. 不设置 `removeOnComplete` 会怎样？为什么这是个坑？
4. `Queue.add()` 返回之后，任务一定被执行了吗？为什么说生产者「不维护处理状态」？

## 7. 费曼复述要求（不看笔记）

1. **闭环三段**：从 客户端请求进来，到拿到返回值，中间到底发生了几次跨进程的写入？（生产者写 → worker 写 → 监听方读）
2. **data vs returnvalue**：为什么生产者进程里的 Job 实例拿不到返回值？正确做法是什么？
3. **jobId**：默认是什么形态？生产上你会不会自己指定？为什么？
4. **保留策略**：默认会保留还是删除？不设置会有什么后果？
5. **边界**：`getJobCounts()` 读到 `completed: 0` 能不能说明「一条都没成功」？
