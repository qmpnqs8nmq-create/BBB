import fs from 'node:fs/promises';
import path from 'node:path';

function safeStamp(ts) {
  const d = new Date(ts);
  const pad = (n) => String(n).padStart(2, '0');
  return `${d.getFullYear()}-${pad(d.getMonth()+1)}-${pad(d.getDate())} ${pad(d.getHours())}:${pad(d.getMinutes())}`;
}

function stripResetSuffix(name) {
  const idx = name.indexOf('.reset.');
  return idx === -1 ? name : name.slice(0, idx);
}

async function readJson(p, fallback) {
  try {
    return JSON.parse(await fs.readFile(p, 'utf8'));
  } catch {
    return fallback;
  }
}

const handler = async (event) => {
  const isResetCommand = event?.type === 'command' && (event.action === 'new' || event.action === 'reset');
  if (!isResetCommand) return;

  try {
    const ctx = event.context || {};
    const prev = ctx.previousSessionEntry || ctx.sessionEntry || {};
    const sessionFile = typeof prev.sessionFile === 'string' ? prev.sessionFile : '';
    if (!sessionFile) return;

    const sessionsDir = path.dirname(sessionFile);
    const sessionsJson = path.join(sessionsDir, 'sessions.json');
    const files = await fs.readdir(sessionsDir);
    const baseName = stripResetSuffix(path.basename(sessionFile));
    const resetCandidates = files
      .filter((n) => n.startsWith(baseName + '.reset.'))
      .sort();
    if (resetCandidates.length === 0) return;

    const latestReset = resetCandidates[resetCandidates.length - 1];
    const latestResetPath = path.join(sessionsDir, latestReset);
    const sessionId = baseName.replace(/\.jsonl$/, '');
    const stamp = latestReset.split('.reset.')[1] || String(Date.now());
    const archiveId = `archive-${sessionId.slice(0,8)}-${stamp.replace(/[^0-9A-Za-z]+/g, '-').replace(/^-+|-+$/g, '')}`;
    const sessionKey = `agent:main:${archiveId}`;
    const agentId = (event.sessionKey || '').split(':')[1] || 'main';
    const source = ctx.commandSource || prev?.origin?.provider || prev?.lastChannel || 'webchat';
    const label = formatLabel(event.timestamp || Date.now(), agentId, source);
    const transcriptCopy = path.join(sessionsDir, `${archiveId}.jsonl`);

    try {
      await fs.access(transcriptCopy);
    } catch {
      await fs.copyFile(latestResetPath, transcriptCopy);
    }

    const index = await readJson(sessionsJson, {});
    if (!index[sessionKey]) {
      const st = await fs.stat(transcriptCopy);
      index[sessionKey] = {
        sessionId: archiveId,
        updatedAt: Math.round(st.mtimeMs),
        systemSent: true,
        abortedLastRun: false,
        chatType: 'direct',
        deliveryContext: { channel: 'webchat' },
        lastChannel: 'webchat',
        origin: { provider: 'webchat', surface: 'webchat', chatType: 'direct' },
        sessionFile: transcriptCopy,
        compactionCount: 0,
        label: `历史会话 ${displayTime}`
      };
      await fs.writeFile(sessionsJson, JSON.stringify(index, null, 2) + '\n', 'utf8');
      console.log(`[preserve-reset-sessions] added ${sessionKey}`);
    }
  } catch (err) {
    console.error('[preserve-reset-sessions] failed:', err?.message || String(err));
  }
};

export default handler;
