import { t as classifyFailoverReason } from "/usr/lib/node_modules/openclaw/dist/classify-D2TmWS2C.js";

const quoted = classifyFailoverReason('{"code":"402","message":"Payment Required"}');
const bare = classifyFailoverReason('{"code":402,"message":"Payment Required"}');
if (quoted === null || bare === null || quoted !== bare) {
  throw new Error(`402 classification mismatch: quoted=${quoted} bare=${bare}`);
}
console.log(`quoted=${quoted} bare=${bare}`);
