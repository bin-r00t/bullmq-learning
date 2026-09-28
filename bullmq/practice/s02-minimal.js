// S02 最小闭环：一条「开/关空调」指令从入队到完成的完整生命周期
//
// 运行前先确保本地 Redis 在 6390 端口：
//   learning/.tools/redis-8.10.2/src/redis-server --port 6390 --daemonize yes \
//     --dir learning/.tools/data --save '' --appendonly no
// 运行：
//   cd learning/bullmq/practice && node s02-minimal.js
//
// 角色映射：
//   生产者 sendAcCommand() = 你的业务服务器（客户端请求进来后只做这一件事：入队）
//   Worker                = 与现场设备通信的网关进程（真正的执行者）
//   QueueEvents           = 独立部署的监听方（这里演示跨进程事件）

import { Queue, Worker, QueueEvents } from 'bullmq';

const connection = { host: '127.0.0.1', port: 6390, maxRetriesPerRequest: null };
const QUEUE_NAME = 'device-commands';

const queue = new Queue(QUEUE_NAME, { connection });

// ── ① 生产者：业务服务器收到请求后要做的全部事情 ──────────────────────────
async function sendAcCommand(deviceId, action, opts = {}) {
  const job = await queue.add(
    'ac-control', // name：同一队列里可以有多种任务类型，用 name 区分
    { deviceId, action }, // data：任务数据（你的业务载荷）
    {
      jobId: opts.jobId, // 不传就由 BullMQ 生成（S05 讲幂等时会用得上）
      attempts: 3, // 最多尝试 3 次（重试细节在 S05）
      backoff: { type: 'exponential', delay: 1000 },
      removeOnComplete: 100, // 完成记录保留最近 100 条（默认策略 S08 核实）
      removeOnFail: 500,
    }
  );
  console.log(
    `[生产者] 入队 → id=${job.id} name=${job.name} data=${JSON.stringify(job.data)}`
  );
  return job;
}

// ── ② 消费者：设备网关进程 ────────────────────────────────────────────────
const worker = new Worker(
  QUEUE_NAME,
  async (job) => {
    console.log(`[Worker] 取到 job ${job.id}（此刻状态 active），开始联系设备…`);
    await new Promise((r) => setTimeout(r, 150)); // 假装与设备通信耗时
    return {
      ok: true,
      deviceId: job.data.deviceId,
      action: job.data.action,
      at: new Date().toISOString(),
    };
  },
  { connection, concurrency: 1 }
);

worker.on('completed', (job, result) =>
  console.log(`[Worker事件] completed job=${job.id} returnvalue=${JSON.stringify(result)}`)
);
worker.on('failed', (job, err) =>
  console.log(`[Worker事件] failed job=${job.id} err=${err.message} attemptsMade=${job.attemptsMade}`)
);

// ── ③ 跨进程事件监听：独立部署的服务用这个（对比上面的 worker 本地事件）──
const events = new QueueEvents(QUEUE_NAME, { connection });
events.on('completed', ({ jobId, returnvalue }) =>
  console.log(`[QueueEvents] 跨进程事件：job ${jobId} 完成，returnvalue=${returnvalue}`)
);

// ── 主流程：模拟 用户点了两下 ─────────────────────────────────────────
await worker.waitUntilReady();
const job = await sendAcCommand('bedroom-ac-01', 'turn-on');
await sendAcCommand('bedroom-ac-01', 'turn-off');

const finished = new Promise((resolve, reject) => {
  const timer = setTimeout(() => reject(new Error('10 秒内没有等到完成事件')), 10000);
  events.on('completed', ({ jobId, returnvalue }) => {
    if (String(jobId) === String(job.id)) {
      clearTimeout(timer);
      resolve(returnvalue);
    }
  });
});
console.log('[主流程] 最终返回值：', await finished);

console.log(
  '[主流程] 队列计数器：',
  await queue.getJobCounts('wait', 'active', 'completed', 'failed', 'delayed')
);
console.log('[主流程] 第一条 job 现在的状态：', await job.getState());
console.log('[主流程] 任务数据（重新从 Redis 读回来）：', JSON.stringify(await job.toJSON()));

await worker.close();
await events.close();
await queue.close();
console.log('[主流程] 已优雅关闭 worker / events / queue（S08 会细讲关停顺序）');
