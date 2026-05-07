import fs from 'node:fs';
import path from 'node:path';
import crypto from 'node:crypto';
import { execFileSync } from 'node:child_process';

const STATE = process.env.OPENCLAW_STATE_DIR || '/root/.openclaw';
const CONFIG = process.env.OPENCLAW_CONFIG || path.join(STATE, 'openclaw.json');
const BASE = 'https://ilinkai.weixin.qq.com';
const BOT_TYPE = '3';
const TARGET_AGENT = 'mangba-guest';
const CHANNEL = 'openclaw-weixin';
const VERSION = '2.3.1';
const APP_ID = 'bot';
const CLIENT_VERSION = ((2 & 0xff) << 16) | ((3 & 0xff) << 8) | (1 & 0xff);
const LOG = '/root/.openclaw/workspace/tmp/weixin-mangba-guest-bind.log';

function log(s){ fs.appendFileSync(LOG, `[${new Date().toISOString()}] ${s}\n`); console.log(s); }
function ensureDir(p){ fs.mkdirSync(p, {recursive:true}); }
function randomUin(){ return Buffer.from(String(crypto.randomBytes(4).readUInt32BE(0)), 'utf8').toString('base64'); }
function headers(body=''){
  return {
    'Content-Type':'application/json',
    'AuthorizationType':'ilink_bot_token',
    'Content-Length': String(Buffer.byteLength(body, 'utf8')),
    'X-WECHAT-UIN': randomUin(),
    'iLink-App-Id': APP_ID,
    'iLink-App-ClientVersion': String(CLIENT_VERSION),
  };
}
function commonHeaders(){ return {'iLink-App-Id': APP_ID, 'iLink-App-ClientVersion': String(CLIENT_VERSION)}; }
async function post(endpoint, bodyObj){
  const body = JSON.stringify(bodyObj);
  const res = await fetch(new URL(endpoint, BASE).toString(), {method:'POST', headers:headers(body), body});
  const text = await res.text();
  if(!res.ok) throw new Error(`POST ${endpoint} ${res.status}: ${text}`);
  return JSON.parse(text);
}
async function get(base, endpoint, timeoutMs=35000){
  const ac = new AbortController();
  const t = setTimeout(()=>ac.abort(), timeoutMs);
  try {
    const res = await fetch(new URL(endpoint, base.endsWith('/')?base:base+'/').toString(), {headers:commonHeaders(), signal:ac.signal});
    const text = await res.text();
    if(!res.ok) throw new Error(`GET ${endpoint} ${res.status}: ${text}`);
    return JSON.parse(text);
  } finally { clearTimeout(t); }
}
function accountsDir(){ return path.join(STATE, 'openclaw-weixin', 'accounts'); }
function accountIndex(){ return path.join(STATE, 'openclaw-weixin', 'accounts.json'); }
function listAccounts(){ try { const a=JSON.parse(fs.readFileSync(accountIndex(),'utf8')); return Array.isArray(a)?a.filter(x=>typeof x==='string'):[]; } catch { return []; } }
function loadAccount(id){ try { return JSON.parse(fs.readFileSync(path.join(accountsDir(), `${id}.json`),'utf8')); } catch { return null; } }
function normalizeAccountId(raw){ return String(raw).trim().replace('@','-').replaceAll('.','-').replace(/[\\/:*?"<>|]/g,'_'); }
function saveAccount(id, data){ ensureDir(accountsDir()); fs.writeFileSync(path.join(accountsDir(), `${id}.json`), JSON.stringify(data,null,2), {mode:0o600}); try{fs.chmodSync(path.join(accountsDir(), `${id}.json`),0o600)}catch{} }
function registerAccount(id){ ensureDir(path.dirname(accountIndex())); const arr=listAccounts(); if(!arr.includes(id)){ arr.push(id); fs.writeFileSync(accountIndex(), JSON.stringify(arr,null,2)); } }
function allowPath(accountId){ return path.join(STATE, 'credentials', `openclaw-weixin-${accountId.toLowerCase()}-allowFrom.json`); }
function allowUser(accountId,userId){ ensureDir(path.dirname(allowPath(accountId))); const p=allowPath(accountId); let obj={version:1,allowFrom:[]}; try{ obj=JSON.parse(fs.readFileSync(p,'utf8')); if(!Array.isArray(obj.allowFrom)) obj.allowFrom=[]; }catch{} if(!obj.allowFrom.includes(userId)){ obj.allowFrom.push(userId); fs.writeFileSync(p, JSON.stringify(obj,null,2)); } }
function updateConfig(accountId,userId){
  const cfg = JSON.parse(fs.readFileSync(CONFIG,'utf8'));
  cfg.bindings = Array.isArray(cfg.bindings) ? cfg.bindings : [];
  // Remove any stale exact route for this newly connected weixin account/peer so it cannot point elsewhere.
  cfg.bindings = cfg.bindings.filter(b => !(b?.match?.channel===CHANNEL && b?.match?.accountId===accountId && b?.match?.peer?.kind==='direct' && b?.match?.peer?.id===userId));
  cfg.bindings.unshift({agentId: TARGET_AGENT, match:{channel: CHANNEL, accountId, peer:{kind:'direct', id:userId}}});
  cfg.channels = cfg.channels || {};
  cfg.channels[CHANNEL] = {...(cfg.channels[CHANNEL]||{}), channelConfigUpdatedAt:new Date().toISOString()};
  fs.writeFileSync(CONFIG, JSON.stringify(cfg,null,2)+'\n');
}

const local_token_list = listAccounts().map(id=>loadAccount(id)?.token).filter(Boolean).slice(-10).reverse();
const qrResp = await post(`ilink/bot/get_bot_qrcode?bot_type=${encodeURIComponent(BOT_TYPE)}`, {local_token_list});
const qrcode = qrResp.qrcode;
const link = qrResp.qrcode_img_content;
if(!qrcode || !link) throw new Error(`bad QR response: ${JSON.stringify(qrResp)}`);
log(`LINK ${link}`);
log('Waiting for scan/confirm; target agent=mangba-guest');

let base = BASE;
const deadline = Date.now() + 8*60_000;
while(Date.now() < deadline){
  let st;
  try { st = await get(base, `ilink/bot/get_qrcode_status?qrcode=${encodeURIComponent(qrcode)}`); }
  catch(e){ if(e?.name === 'AbortError') { st={status:'wait'}; } else { log(`poll retry after error: ${String(e)}`); st={status:'wait'}; } }
  log(`STATUS ${st.status}`);
  if(st.status === 'scaned_but_redirect' && st.redirect_host){ base = `https://${st.redirect_host}`; }
  if(st.status === 'need_verifycode') { log('BLOCKED need_verifycode: friend must provide the phone verification number; this script cannot continue automatically.'); process.exit(2); }
  if(st.status === 'binded_redirect') { log('Already connected before; no new binding made.'); process.exit(3); }
  if(st.status === 'confirmed'){
    if(!st.ilink_bot_id || !st.bot_token || !st.ilink_user_id) throw new Error(`confirmed but missing fields: ${JSON.stringify(st)}`);
    const accountId = normalizeAccountId(st.ilink_bot_id);
    const userId = st.ilink_user_id;
    saveAccount(accountId, {token:st.bot_token, savedAt:new Date().toISOString(), ...(st.baseurl?{baseUrl:st.baseurl}:{}), userId});
    registerAccount(accountId);
    allowUser(accountId,userId);
    updateConfig(accountId,userId);
    log(`BOUND accountId=${accountId} peer=${userId} agent=${TARGET_AGENT}`);
    try { execFileSync('openclaw', ['gateway','restart'], {stdio:'pipe', timeout:60000}); log('Gateway restarted'); }
    catch(e){ log(`Gateway restart failed: ${e.message}`); }
    process.exit(0);
  }
  if(st.status === 'expired') { log('QR expired before confirm.'); process.exit(4); }
  await new Promise(r=>setTimeout(r,1000));
}
log('Timeout waiting for confirmation.');
process.exit(5);
