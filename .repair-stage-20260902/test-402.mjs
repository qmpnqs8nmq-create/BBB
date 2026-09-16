import { t as classifyFailoverReason } from "/usr/lib/node_modules/openclaw/dist/classify-DnWIoIyL.mjs";

const quoted = classifyFailoverReason('{"code":"402","message":"Payment Required"}');
const bare = classifyFailoverReason('{"code":402,"message":"Payment Required"}');
const quota = classifyFailoverReason(
  '{"error":{"code":"402","type":"quote_exceeded","message":"subscription quota limit; automatic quota refresh uses a rolling time window"}}',
);
if (quoted !== "billing" || bare !== "billing" || quota !== "rate_limit") {
  throw new Error(`402 classification mismatch: quoted=${quoted} bare=${bare} quota=${quota}`);
}
console.log(`quoted=${quoted} bare=${bare} quota=${quota}`);
