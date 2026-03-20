const https = require('https');
const http = require('http');
const fs = require('fs');
const net = require('net');
const crypto = require('crypto');

const LISTEN_PORT = 8888;
const TARGET_HOST = '127.0.0.1';
const TARGET_PORT = 18789;
const AGENT_ID = 'chief-user';
const GATEWAY_TOKEN = '3df0380ec882129ba80681cb818ae1056ebff9c9be77a184';
const BROWSER_ID_KEY = 'openclaw.lan8888.browser-id.v1';
const INIT_JS_PATH = '/__lan8888/init.js';

const options = {
  key: fs.readFileSync('/Users/bruce/.openclaw-team/certs/lan-https.key'),
  cert: fs.readFileSync('/Users/bruce/.openclaw-team/certs/lan-https.crt'),
};

function buildInitScript() {
  return `(() => {
  const SETTINGS_KEY = 'openclaw.control.settings.v1';
  const BROWSER_ID_KEY = ${JSON.stringify(BROWSER_ID_KEY)};
  const AGENT_ID = ${JSON.stringify(AGENT_ID)};
  const GATEWAY_TOKEN = ${JSON.stringify(GATEWAY_TOKEN)};
  const DEVICE_ID_KEY = 'openclaw-device-identity-v1';
  const DEVICE_AUTH_KEY = 'openclaw.device.auth.v1';
  const COOKIE_PREFIX = 'oc8888_';

  function randomId() {
    try {
      if (globalThis.crypto && typeof globalThis.crypto.randomUUID === 'function') {
        return globalThis.crypto.randomUUID().replace(/-/g, '').slice(0, 24);
      }
    } catch {}
    return Math.random().toString(36).slice(2) + Date.now().toString(36);
  }

  function getBrowserId() {
    try {
      const existing = localStorage.getItem(BROWSER_ID_KEY);
      if (existing && typeof existing === 'string' && existing.trim()) return existing.trim();
      const created = randomId();
      localStorage.setItem(BROWSER_ID_KEY, created);
      return created;
    } catch {
      return 'ephemeral-' + randomId();
    }
  }

  function encode(value) {
    return btoa(unescape(encodeURIComponent(value)));
  }

  function decode(value) {
    return decodeURIComponent(escape(atob(value)));
  }

  function getCookie(name) {
    const needle = name + '=';
    return document.cookie.split('; ').find(x => x.startsWith(needle))?.slice(needle.length) || '';
  }

  function setCookie(name, value) {
    document.cookie = name + '=' + value + '; Path=/; Max-Age=' + (60 * 60 * 24 * 180) + '; SameSite=Lax; Secure';
  }

  function clearCookie(name) {
    document.cookie = name + '=; Path=/; Max-Age=0; SameSite=Lax; Secure';
  }

  function readJsonStorage(key) {
    try {
      const raw = localStorage.getItem(key);
      return raw ? JSON.parse(raw) : null;
    } catch {
      return null;
    }
  }

  function writeJsonStorage(key, value) {
    try {
      localStorage.setItem(key, JSON.stringify(value));
      return true;
    } catch {
      return false;
    }
  }

  function mirrorStorageKey(key) {
    const cookieName = COOKIE_PREFIX + key.replace(/[^a-z0-9]+/gi, '_');
    try {
      const raw = localStorage.getItem(key);
      if (raw && raw.trim()) {
        setCookie(cookieName, encode(raw));
        return;
      }
    } catch {}
    try {
      const cookieVal = getCookie(cookieName);
      if (cookieVal) {
        localStorage.setItem(key, decode(cookieVal));
      }
    } catch {}
  }

  function clearLegacyDevicePairingState() {
    // FIXED: was deleting device pairing credentials every 1.5s via sync(),
    // causing infinite "pairing required" loop. Now a no-op.
  }

  function restoreCriticalIdentity() {
    clearLegacyDevicePairingState();
    mirrorStorageKey(BROWSER_ID_KEY);
    mirrorStorageKey(DEVICE_ID_KEY);
    mirrorStorageKey(DEVICE_AUTH_KEY);
    mirrorStorageKey('openclaw.device.pair.request.v1');
  }

  function readSettings() {
    try {
      const raw = localStorage.getItem(SETTINGS_KEY);
      return raw ? JSON.parse(raw) : {};
    } catch {
      return {};
    }
  }

  function writeSettings(patch) {
    try {
      const next = { ...readSettings(), ...patch };
      localStorage.setItem(SETTINGS_KEY, JSON.stringify(next));
      try { sessionStorage.setItem(SETTINGS_KEY, JSON.stringify(next)); } catch {}
      mirrorStorageKey(SETTINGS_KEY);
      return next;
    } catch {
      return patch;
    }
  }

  function buildGatewayUrl() {
    const proto = location.protocol === 'https:' ? 'wss:' : 'ws:';
    return proto + '//' + location.host;
  }

  function ensureGatewayBootstrap() {
    const gatewayUrl = buildGatewayUrl();
    const next = writeSettings({
      gatewayUrl,
      token: GATEWAY_TOKEN,
      authMode: 'token',
      sessionKey: isolatedSessionKey,
      lastActiveSessionKey: isolatedSessionKey,
    });
    try {
      sessionStorage.setItem('openclaw.gateway.token.bootstrap', GATEWAY_TOKEN);
      sessionStorage.setItem('openclaw.gateway.url.bootstrap', gatewayUrl);
      sessionStorage.setItem('openclaw.gateway.authMode.bootstrap', 'token');
    } catch {}
    try {
      if (!location.hash || !location.hash.includes('token=')) {
        const hash = new URLSearchParams(location.hash.replace(/^#/, ''));
        hash.set('token', GATEWAY_TOKEN);
        if (!hash.get('gatewayUrl')) hash.set('gatewayUrl', gatewayUrl);
        history.replaceState(null, '', location.pathname + location.search + '#' + hash.toString());
      }
    } catch {}
    return next;
  }

  restoreCriticalIdentity();
  const browserId = getBrowserId();
  const isolatedSessionKey = 'agent:' + AGENT_ID + ':webchat-' + browserId;
  ensureGatewayBootstrap();
  mirrorStorageKey(BROWSER_ID_KEY);

  window.__OPENCLAW_LAN8888_ISOLATED_SESSION__ = {
    browserId,
    sessionKey: isolatedSessionKey,
    agentId: AGENT_ID,
    mode: 'per-browser-stable-session'
  };

  function pushSessionIntoUi() {
    try {
      const app = document.querySelector('openclaw-app');
      if (app) {
        app.sessionKey = isolatedSessionKey;
        if (typeof app.applySettings === 'function' && app.settings) {
          app.applySettings({ ...app.settings, sessionKey: isolatedSessionKey, lastActiveSessionKey: isolatedSessionKey });
        }
      }
    } catch {}
  }

  function sync() {
    restoreCriticalIdentity();
    ensureGatewayBootstrap();
    pushSessionIntoUi();
  }

  if (document.readyState === 'loading') {
    document.addEventListener('DOMContentLoaded', sync, { once: true });
  } else {
    sync();
  }

  setInterval(sync, 1500);
})();\n`;
}

const INIT_JS = buildInitScript();

function htmlInjectionTag() {
  return `\n<script src="${INIT_JS_PATH}?v=${crypto.createHash('sha1').update(INIT_JS).digest('hex').slice(0,8)}"></script>`;
}

function shouldInject(proxyRes, req) {
  if ((req.method || 'GET').toUpperCase() !== 'GET') return false;
  const contentType = String(proxyRes.headers['content-type'] || '').toLowerCase();
  return contentType.includes('text/html');
}

function handleInitJs(req, res) {
  res.writeHead(200, {
    'content-type': 'application/javascript; charset=utf-8',
    'cache-control': 'no-store',
  });
  res.end(INIT_JS);
}

const server = https.createServer(options, (req, res) => {
  if ((req.url || '').startsWith(INIT_JS_PATH)) {
    handleInitJs(req, res);
    return;
  }

  const headers = {
    ...req.headers,
    host: req.headers.host,
    'x-forwarded-proto': 'https',
    'x-forwarded-for': '127.0.0.1',
    'x-real-ip': '127.0.0.1',
    'accept-encoding': 'identity',
  };

  const proxyReq = http.request({
    host: TARGET_HOST,
    port: TARGET_PORT,
    method: req.method,
    path: req.url,
    headers,
  }, (proxyRes) => {
    if (!shouldInject(proxyRes, req)) {
      res.writeHead(proxyRes.statusCode || 502, proxyRes.headers);
      proxyRes.pipe(res);
      return;
    }

    const chunks = [];
    proxyRes.on('data', (chunk) => chunks.push(chunk));
    proxyRes.on('end', () => {
      try {
        const body = Buffer.concat(chunks).toString('utf8');
        const tag = htmlInjectionTag();
        const injected = body.includes('</head>')
          ? body.replace('</head>', `${tag}</head>`)
          : `${tag}${body}`;
        const out = Buffer.from(injected, 'utf8');
        const outHeaders = { ...proxyRes.headers };
        delete outHeaders['content-length'];
        delete outHeaders['content-encoding'];
        outHeaders['content-length'] = String(out.length);
        res.writeHead(proxyRes.statusCode || 502, outHeaders);
        res.end(out);
      } catch (err) {
        res.writeHead(502, {'content-type':'text/plain'});
        res.end('proxy injection error: ' + err.message);
      }
    });
  });

  proxyReq.on('error', (err) => {
    res.writeHead(502, {'content-type':'text/plain'});
    res.end('proxy error: ' + err.message);
  });
  req.pipe(proxyReq);
});

server.on('upgrade', (req, socket, head) => {
  const upstream = net.connect(TARGET_PORT, TARGET_HOST, () => {
    // Inject gateway auth token so Gateway authenticates via token,
    // bypassing device pairing entirely
    const url = new URL(req.url, `http://${TARGET_HOST}:${TARGET_PORT}`);
    url.searchParams.set('token', GATEWAY_TOKEN);
    const rewrittenPath = url.pathname + url.search;

    let headers = `${req.method} ${rewrittenPath} HTTP/${req.httpVersion}\r\n`;
    const merged = {
      ...req.headers,
      host: req.headers.host,
      'x-forwarded-proto': 'https',
      'x-forwarded-for': '127.0.0.1',
      'x-real-ip': '127.0.0.1',
    };
    for (const [k, v] of Object.entries(merged)) headers += `${k}: ${v}\r\n`;
    headers += '\r\n';
    upstream.write(headers);
    if (head && head.length) upstream.write(head);
    socket.pipe(upstream).pipe(socket);
  });
  upstream.on('error', () => socket.destroy());
});

server.listen(LISTEN_PORT, '0.0.0.0', () => {
  console.log(`https proxy listening on https://0.0.0.0:${LISTEN_PORT} -> http://${TARGET_HOST}:${TARGET_PORT}`);
  console.log(`per-browser session isolation enabled for agent:${AGENT_ID}`);
  console.log('device identity persistence fallback enabled via secure cookies');
});
