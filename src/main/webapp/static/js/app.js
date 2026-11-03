/* 智服 AI —— 公共脚本：Ajax 封装、提示、Markdown 渲染、WebSocket（带轮询降级） */
(function () {
  const CTX = window.CTX || '';

  /**
   * fetch 封装：POST 以表单格式（application/x-www-form-urlencoded）提交，
   * 这样 Struts2 的 params 拦截器能把参数直接注入到 Action 属性（如 sessionId、question）；
   * 后端 <result type="json"> 返回 {code,msg,data}，这里返回其中的 data，失败抛出 Error。
   * url 形如 '/api/chat/ask.action'（struts.action.extension=action）
   */
  async function api(url, body, method) {
    const opt = { method: method || (body === undefined ? 'GET' : 'POST'), headers: { 'X-Requested-With': 'fetch' }, credentials: 'same-origin' };
    if (body !== undefined) {
      const form = new URLSearchParams();
      Object.keys(body || {}).forEach(k => { if (body[k] !== null && body[k] !== undefined) form.append(k, body[k]); });
      opt.headers['Content-Type'] = 'application/x-www-form-urlencoded;charset=UTF-8';
      opt.body = form.toString();
    }
    const resp = await fetch(CTX + url, opt);
    let json;
    try { json = await resp.json(); } catch (e) { throw new Error('服务器返回异常（' + resp.status + '）'); }
    if (json.code === 401) { toast('登录已过期，请重新登录', 'err'); setTimeout(() => location.href = CTX + '/login.action', 900); throw new Error(json.msg); }
    if (json.code !== 200) throw new Error(json.msg || '请求失败');
    return json.data;
  }

  function toast(msg, type) {
    let box = document.querySelector('.toast-box');
    if (!box) { box = document.createElement('div'); box.className = 'toast-box'; document.body.appendChild(box); }
    const t = document.createElement('div');
    t.className = 'toast ' + (type === 'err' ? 'err' : 'ok');
    t.innerHTML = '<i class="' + (type === 'err' ? 'ri-error-warning-fill' : 'ri-checkbox-circle-fill') + '"></i><span></span>';
    t.querySelector('span').textContent = msg;
    box.appendChild(t);
    setTimeout(() => { t.style.transition = 'opacity .3s'; t.style.opacity = '0'; }, 2600);
    setTimeout(() => t.remove(), 3000);
  }

  function esc(s) {
    return String(s == null ? '' : s).replace(/[&<>"']/g, c => ({ '&': '&amp;', '<': '&lt;', '>': '&gt;', '"': '&quot;', "'": '&#39;' }[c]));
  }

  /** 极简 Markdown（与服务端 Md.java 规则一致）：先转义再处理加粗 / 列表 / 段落 */
  function md(src) {
    const inline = s => esc(s).replace(/\*\*(.+?)\*\*/g, '<strong>$1</strong>').replace(/`(.+?)`/g, '<code>$1</code>');
    let out = '', list = null, para = [];
    const flush = () => { if (para.length) { out += '<p>' + para.join('<br>') + '</p>'; para = []; } };
    String(src || '').split(/\r?\n/).forEach(raw => {
      const line = raw.trim();
      let m, type = null, item = null;
      if ((m = line.match(/^[-*] (.*)/))) { type = 'ul'; item = m[1]; }
      else if ((m = line.match(/^\d+[.、] (.*)/))) { type = 'ol'; item = m[1]; }
      if (item !== null) {
        flush();
        if (list !== type) { if (list) out += '</' + list + '>'; out += '<' + type + '>'; list = type; }
        out += '<li>' + inline(item) + '</li>';
        return;
      }
      if (list) { out += '</' + list + '>'; list = null; }
      if (!line) flush(); else para.push(inline(line));
    });
    if (list) out += '</' + list + '>';
    flush();
    return out;
  }

  /**
   * 实时通道：优先 WebSocket；连不上（或断开）时自动改为 Ajax 轮询。
   * onEvent(evt) 收到 {type:'msg'|'accepted'|'queue'|'end'...}
   * pollFn() 轮询函数（由页面提供），WebSocket 不可用时每 2.5 秒调用一次
   */
  function realtime(onEvent, pollFn) {
    let ws = null, timer = null, ping = null, retry = 0, mode = 'none';
    const listeners = [];
    const setMode = m => { mode = m; listeners.forEach(f => f(m)); };
    function startPoll() {
      if (timer || !pollFn) return;
      setMode('poll');
      timer = setInterval(() => pollFn().catch(() => {}), 2500);
    }
    function stopPoll() { if (timer) { clearInterval(timer); timer = null; } }
    function connect() {
      if (!('WebSocket' in window)) { startPoll(); return; }
      try {
        ws = new WebSocket((location.protocol === 'https:' ? 'wss://' : 'ws://') + location.host + CTX + '/ws/chat');
      } catch (e) { startPoll(); return; }
      ws.onopen = () => { retry = 0; stopPoll(); setMode('ws'); ping = setInterval(() => ws.readyState === 1 && ws.send('ping'), 25000); };
      ws.onmessage = e => { try { const d = JSON.parse(e.data); if (d.type !== 'pong' && d.type !== 'hello') onEvent(d); } catch (err) {} };
      ws.onclose = () => {
        clearInterval(ping);
        startPoll();
        if (retry < 5) setTimeout(connect, 2000 * (++retry));
      };
      ws.onerror = () => { try { ws.close(); } catch (e) {} };
    }
    connect();
    return { get mode() { return mode; }, onMode: f => { listeners.push(f); f(mode); }, pollNow: () => pollFn && pollFn() };
  }

  /** 原生 <dialog> 弹窗：data-open="#id" 打开，data-close 关闭 */
  document.addEventListener('click', e => {
    const o = e.target.closest('[data-open]');
    if (o) { const d = document.querySelector(o.dataset.open); if (d) { if (o.dataset.fill) fillForm(d, JSON.parse(o.dataset.fill)); d.showModal(); } }
    const c = e.target.closest('[data-close]');
    if (c) { const d = c.closest('dialog'); if (d) d.close(); }
    const cf = e.target.closest('[data-confirm]');
    if (cf && !confirm(cf.dataset.confirm)) { e.preventDefault(); e.stopPropagation(); }
  }, true);
  document.addEventListener('submit', e => {
    const f = e.target;
    if (f.dataset.confirmSubmit && !confirm(f.dataset.confirmSubmit)) { e.preventDefault(); return; }
    const b = f.querySelector('button[type=submit]');
    if (b && !f.dataset.noLock) { setTimeout(() => { b.disabled = true; }, 0); }
  });

  /** 用 data-fill 的 JSON 填充弹窗里的表单（编辑时用） */
  function fillForm(dialog, data) {
    const form = dialog.querySelector('form');
    if (!form) return;
    form.reset();
    Object.keys(data).forEach(k => {
      const el = form.elements[k];
      if (!el) return;
      if (el.type === 'checkbox') el.checked = !!data[k] && data[k] !== '0' && data[k] !== 0;
      else el.value = data[k] == null ? '' : data[k];
    });
    const title = dialog.querySelector('[data-title]');
    if (title) title.textContent = data.id ? title.dataset.edit : title.dataset.add;
  }

  /** 秒数 → “3 分 20 秒” */
  function dur(sec) {
    sec = Math.max(0, Math.floor(sec));
    if (sec < 60) return sec + ' 秒';
    if (sec < 3600) return Math.floor(sec / 60) + ' 分 ' + (sec % 60) + ' 秒';
    return Math.floor(sec / 3600) + ' 小时 ' + Math.floor(sec % 3600 / 60) + ' 分';
  }

  window.ZF = { api, toast, esc, md, realtime, dur, CTX, bot: CTX + '/static/img/bot.svg' };
})();
