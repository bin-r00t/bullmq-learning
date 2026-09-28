// 实验：不显式设置 removeOnComplete / removeOnFail 时，BullMQ 的默认保留行为
// 用途：核实 topics.md「不确定项」里的一条（默认保留策略），供 S08/S09 使用
import { Queue, Worker } from 'bullmq';

const connection = { host: '127.0.0.1', port: 6390, maxRetriesPerRequest: null };
const NAME = 'probe-remove-defaults';

const queue = new Queue(NAME, { connection });
await queue.obliterate({ force: true }); // 每次从干净状态开始

const worker = new Worker(NAME, async (job) => ({ echoed: job.data.n }), {
  connection,
  concurrency: 1,
});
await worker.waitUntilReady();

const jobs = [];
for (let i = 1; i <= 3; i++) jobs.push(await queue.add('probe', { n: i })); // 刻意不传 removeOnComplete

const done = new Promise((resolve, reject) => {
  const timer = setTimeout(() => reject(new Error('超时')), 10000);
  let completed = 0;
  worker.on('completed', () => {
    if (++completed === jobs.length) {
      clearTimeout(timer);
      resolve();
    }
  });
});
await done;

console.log('默认（只传 name/data）处理完后：');
console.log('  getJobCounts =', await queue.getJobCounts('wait', 'active', 'completed', 'failed'));
console.log('  重新读取第一条 job =', await queue.getJob(jobs[0].id) === undefined ? 'undefined（已被删除）' : '仍存在');
console.log('  第一条 job 状态 =', await jobs[0].getState());
console.log('  Redis 里所有相关 key：');

await worker.close();
await queue.close();
