<%@ page contentType="text/html;charset=UTF-8" pageEncoding="UTF-8" %>
<%@ taglib prefix="c" uri="http://java.sun.com/jsp/jstl/core" %>
<c:set var="pageTitle" value="客服工作台"/>
<c:set var="nav" value="workbench"/>
<%@ include file="../common/head.jspf" %>
<%@ include file="../common/side-nav.jspf" %>
<div class="topbar">
    <div>
        <h1>客服工作台</h1>
        <p>你好，<c:out value="${me.nickname}"/> · 处理中工单 ${myProcessing} 个 · 已解决 ${myResolved} 个</p>
    </div>
    <div class="right">
        <span class="pill st-ACTIVE status-pill" id="connMode">连接中…</span>
        <a class="btn btn-sm" href="${ctx}/agent/tickets.action"><i class="ri-coupon-3-line"></i>我的工单</a>
    </div>
</div>

<div class="wb">
    <!-- 左：排队队列 -->
    <section class="col col-queue glass rise">
        <div class="col-head">
            <b><i class="ri-team-line" style="color:#fbbf24"></i>会话队列</b>
            <span class="muted" style="font-size:12px">排队 <b id="qCount" style="color:#fde68a">0</b> · 接待中 <b id="aCount" style="color:#6ee7b7">0</b></span>
        </div>
        <div class="col-body" id="queueList"><div class="empty"><i class="ri-loader-4-line"></i><p>加载中…</p></div></div>
    </section>

    <!-- 中：聊天窗口 -->
    <section class="col col-chat glass-strong rise rise-1">
        <div id="chatEmpty" class="wb-empty">
            <div>
                <img class="mascot" src="${ctx}/static/img/mascot.svg" alt="">
                <h3 class="mt-12">从左侧选择一个会话</h3>
                <p class="mt-8">排队中的用户点击「接入」即可开始实时对话</p>
            </div>
        </div>
        <div id="chatPane" class="hidden" style="display:flex;flex-direction:column;height:100%">
            <div class="chat-head">
                <span class="avatar" id="cAvatar">?</span>
                <div class="title flex-1"><b id="cName">-</b><small id="cSub">-</small></div>
                <button class="btn btn-sm btn-primary hidden" id="btnAccept" type="button"><i class="ri-phone-line"></i>接入会话</button>
                <button class="btn btn-sm" id="btnTicket" type="button"><i class="ri-coupon-3-line"></i>一键建单</button>
                <button class="btn btn-sm btn-danger" id="btnEnd" type="button"><i class="ri-shut-down-line"></i>结束</button>
            </div>
            <div class="chat-body" id="cBody"></div>
            <div class="chat-foot">
                <div class="suggests" id="suggests"></div>
                <div class="composer">
                    <textarea id="cInput" rows="1" maxlength="500" placeholder="输入回复内容，Enter 发送"></textarea>
                    <button class="send-btn" id="cSend" type="button"><i class="ri-send-plane-2-fill"></i></button>
                </div>
            </div>
        </div>
    </section>

    <!-- 右：客户信息 -->
    <section class="col col-cust glass rise rise-2">
        <div class="col-head"><b><i class="ri-user-heart-line" style="color:#f472b6"></i>客户信息</b></div>
        <div class="col-body" id="custBox"><div class="empty"><i class="ri-user-search-line"></i><p>选择会话后显示客户资料</p></div></div>
    </section>
</div>

<!-- 一键建单弹窗 -->
<dialog class="modal" id="ticketDlg">
    <div class="modal-head"><span><i class="ri-coupon-3-line"></i> 根据当前会话创建工单</span><button class="icon-btn" data-close type="button"><i class="ri-close-line"></i></button></div>
    <div class="modal-body">
        <div class="ai-box mb-16"><div class="t"><i class="ri-sparkling-2-fill"></i>AI 已识别</div><p class="text-2" style="font-size:13px" id="tAi">-</p></div>
        <div class="field"><label>工单标题</label><input class="input" id="tTitle" maxlength="100"></div>
        <div class="field"><label>问题描述</label><textarea class="textarea" id="tContent" rows="4"></textarea></div>
        <div class="field"><label>优先级</label>
            <select class="select" id="tPriority"><option value="">AI 自动判断</option><c:forEach items="${priorities}" var="p"><option value="${p.key}">${p.value}</option></c:forEach></select>
        </div>
        <p class="muted" style="font-size:12.5px">创建后工单自动分配给你，状态为「处理中」，用户可在“我的工单”中查看进度。</p>
    </div>
    <div class="modal-foot"><button class="btn" data-close type="button">取消</button><button class="btn btn-primary" id="tSubmit" type="button"><i class="ri-check-line"></i>创建工单</button></div>
</dialog>

<script>
(function () {
    const st = { list: [], cur: null, lastId: 0, shown: new Set(), rt: null };
    const $ = id => document.getElementById(id);

    function avatarHtml(name, color, cls) { return '<span class="avatar ' + (cls || '') + '" style="background:' + ZF.esc(color) + '">' + ZF.esc((name || '?').slice(0, 1)) + '</span>'; }

    // ---------- 队列 ----------
    async function loadQueue() {
        try {
            st.list = await ZF.api('/api/agent/queue.action');
            renderQueue();
            if (st.cur) {
                const fresh = st.list.find(s => s.id === st.cur.id);
                if (fresh) { st.cur.status = fresh.status; renderHead(); }
            }
        } catch (e) { ZF.toast(e.message, 'err'); }
    }
    function renderQueue() {
        const box = $('queueList');
        const q = st.list.filter(s => s.status === 'QUEUE'), a = st.list.filter(s => s.status === 'ACTIVE');
        $('qCount').textContent = q.length; $('aCount').textContent = a.length;
        const badge = $('queueBadge'); if (badge) { badge.textContent = q.length; badge.classList.toggle('hidden', q.length === 0); }
        if (!st.list.length) { box.innerHTML = '<div class="empty"><i class="ri-cup-line"></i><p>暂时没有排队的用户，喝口水吧～</p></div>'; return; }
        box.innerHTML = '';
        st.list.forEach(s => {
            const d = document.createElement('div');
            d.className = 'q-item' + (st.cur && st.cur.id === s.id ? ' active' : '');
            d.innerHTML = avatarHtml(s.name, s.avatarColor) +
                '<div class="info"><div class="row1"><b class="ellipsis">' + ZF.esc(s.name) + '</b><small>' + ZF.esc(s.time) + '</small></div>' +
                '<p class="ellipsis">' + ZF.esc(s.lastMsg || s.title || '') + '</p>' +
                '<div class="row3"><span class="pill status-pill st-' + s.status + '">' + (s.status === 'QUEUE' ? '排队中' : '接待中') + '</span>' +
                '<span class="tag">' + ZF.esc(s.tag) + '</span>' +
                (s.status === 'QUEUE' ? '<span class="wait"><i class="ri-time-line"></i>' + ZF.dur(s.waitSec) + '</span>' : '') + '</div></div>';
            d.addEventListener('click', () => open(s.id));
            box.appendChild(d);
        });
    }

    // ---------- 打开会话 ----------
    function open(id) {
        const s = st.list.find(x => x.id === id);
        if (!s) return;
        st.cur = Object.assign({}, s);
        st.shown = new Set(); st.lastId = 0;
        $('chatEmpty').classList.add('hidden'); $('chatPane').classList.remove('hidden');
        $('cBody').innerHTML = '';
        s.messages.forEach(m => append(m));
        renderHead(); renderQueue(); loadCustomer(s.userId); loadSuggest();
    }
    function renderHead() {
        const s = st.cur; if (!s) return;
        $('cAvatar').outerHTML = avatarHtml(s.name, s.avatarColor).replace('<span class="avatar ', '<span id="cAvatar" class="avatar ');
        $('cName').textContent = s.name + ' · ' + (s.title || '');
        $('cSub').innerHTML = (s.status === 'QUEUE' ? '<span class="dot" style="background:#fbbf24"></span>排队等待中，接入后才能回复' : '<span class="dot dot-on"></span>接待中 · 话题：' + ZF.esc(s.tag));
        $('btnAccept').classList.toggle('hidden', s.status !== 'QUEUE');
        $('btnEnd').classList.toggle('hidden', s.status !== 'ACTIVE');
        $('btnTicket').classList.toggle('hidden', s.status !== 'ACTIVE');
        $('cInput').disabled = s.status !== 'ACTIVE'; $('cSend').disabled = s.status !== 'ACTIVE';
        $('cInput').placeholder = s.status === 'ACTIVE' ? '输入回复内容，Enter 发送' : '请先点击右上角「接入会话」';
    }
    function append(m) {
        if (m.id && st.shown.has(m.id)) return;
        if (m.id) { st.shown.add(m.id); st.lastId = Math.max(st.lastId, m.id); }
        const s = st.cur, d = document.createElement('div');
        let av;
        if (m.senderType === 'USER') { d.className = 'msg left'; av = avatarHtml(s.name, s.avatarColor); }
        else if (m.senderType === 'AGENT') { d.className = 'msg right'; av = '<span class="avatar agent-avatar"><i class="ri-customer-service-2-fill"></i></span>'; }
        else { d.className = 'msg left'; av = '<span class="bot-avatar"><img src="' + ZF.bot + '" alt=""></span>'; }
        const who = m.senderType === 'AI' ? '<div class="who">智服 AI</div>' : '';
        d.innerHTML = av + '<div>' + who + '<div class="bubble md">' + ZF.md(m.content) + '</div><div class="time">' + ZF.esc(m.time || '') + '</div></div>';
        $('cBody').appendChild(d);
        $('cBody').scrollTop = $('cBody').scrollHeight;
    }
    async function loadCustomer(uid) {
        try {
            const c = await ZF.api('/api/agent/customer.action?userId=' + uid);
            let tk = c.tickets.map(t => '<a class="flex between items-center gap-8" style="padding:7px 0;border-bottom:1px dashed rgba(255,255,255,.08);font-size:13px" href="' + ZF.CTX + '/ticket/detail.action?id=' + t.id + '"><span class="ellipsis">' + ZF.esc(t.title) + '</span><span class="pill status-pill st-' + t.status + '">' + t.statusText + '</span></a>').join('');
            $('custBox').innerHTML = '<div class="cust" style="padding:6px">' +
                '<div class="top">' + avatarHtml(c.nickname, c.avatarColor, 'avatar-lg') + '<div><b>' + ZF.esc(c.nickname) + '</b><span class="muted" style="font-size:12.5px">@' + ZF.esc(c.username) + '</span></div></div>' +
                '<dl class="kv"><dt>手机</dt><dd>' + ZF.esc(c.phone || '-') + '</dd><dt>邮箱</dt><dd class="ellipsis">' + ZF.esc(c.email || '-') + '</dd><dt>注册时间</dt><dd>' + ZF.esc(c.createTime) + '</dd></dl>' +
                '<div class="nums"><div><b class="grad-text">' + c.sessionCount + '</b><span>历史咨询</span></div><div><b class="grad-text">' + c.ticketCount + '</b><span>工单数</span></div></div>' +
                '<h4 style="margin:6px 0 4px;font-size:14px">最近工单</h4>' + (tk || '<p class="muted" style="font-size:13px">暂无工单</p>') +
                '<button class="btn btn-primary btn-block mt-16" type="button" id="custTicket"><i class="ri-coupon-3-line"></i>一键创建工单</button></div>';
            $('custTicket').addEventListener('click', () => { if (st.cur && st.cur.status === 'ACTIVE') openTicketDlg(); else ZF.toast('请先接入会话', 'err'); });
        } catch (e) { $('custBox').innerHTML = '<div class="empty"><p>' + ZF.esc(e.message) + '</p></div>'; }
    }
    async function loadSuggest() {
        const box = $('suggests'); box.innerHTML = '';
        if (!st.cur) return;
        try {
            const list = await ZF.api('/api/agent/suggest.action?tag=' + encodeURIComponent(st.cur.tag) + '&sessionId=' + st.cur.id);
            box.innerHTML = '<span class="muted" style="font-size:12.5px;align-self:center"><i class="ri-sparkling-2-fill" style="color:#c4b5fd"></i> AI 推荐回复：</span>';
            list.forEach(t => { const b = document.createElement('button'); b.className = 'chip'; b.type = 'button'; b.textContent = t; b.onclick = () => { $('cInput').value = t; $('cInput').focus(); }; box.appendChild(b); });
        } catch (e) { }
    }

    // ---------- 操作 ----------
    $('btnAccept').addEventListener('click', async () => {
        try {
            await ZF.api('/api/agent/accept.action', { sessionId: st.cur.id });
            ZF.toast('已接入，开始为用户服务吧');
            st.cur.status = 'ACTIVE';
            await loadQueue();
            await pollCur();
            renderHead();
        } catch (e) { ZF.toast(e.message, 'err'); loadQueue(); }
    });
    async function send() {
        const text = $('cInput').value.trim();
        if (!text || !st.cur) return;
        $('cSend').disabled = true;
        try {
            const m = await ZF.api('/api/agent/send.action', { sessionId: st.cur.id, content: text });
            append(m);
            $('cInput').value = '';
        } catch (e) { ZF.toast(e.message, 'err'); }
        finally { $('cSend').disabled = false; $('cInput').focus(); }
    }
    $('cSend').addEventListener('click', send);
    $('cInput').addEventListener('keydown', e => { if (e.key === 'Enter' && !e.shiftKey && !e.isComposing) { e.preventDefault(); send(); } });
    $('btnEnd').addEventListener('click', async () => {
        if (!confirm('确定结束与该用户的会话吗？')) return;
        try {
            await ZF.api('/api/agent/end.action', { sessionId: st.cur.id });
            ZF.toast('会话已结束');
            closeCur();
        } catch (e) { ZF.toast(e.message, 'err'); }
    });
    function closeCur() {
        st.cur = null;
        $('chatPane').classList.add('hidden'); $('chatEmpty').classList.remove('hidden');
        $('custBox').innerHTML = '<div class="empty"><i class="ri-user-search-line"></i><p>选择会话后显示客户资料</p></div>';
        loadQueue();
    }
    function openTicketDlg() {
        const s = st.cur;
        const userText = [...$('cBody').querySelectorAll('.msg.left:not(:has(.bot-avatar)) .bubble')].map(b => b.textContent.trim()).join('；');
        $('tTitle').value = s.title || '';
        $('tContent').value = userText.slice(0, 500);
        $('tPriority').value = '';
        $('tAi').textContent = '话题「' + s.tag + '」，将自动生成摘要与标签，并关联本次会话记录';
        $('ticketDlg').showModal();
    }
    $('btnTicket').addEventListener('click', openTicketDlg);
    $('tSubmit').addEventListener('click', async () => {
        try {
            const r = await ZF.api('/api/agent/ticket.action', { sessionId: st.cur.id, title: $('tTitle').value, content: $('tContent').value, priority: $('tPriority').value || null });
            $('ticketDlg').close();
            ZF.toast('工单 ' + r.ticketNo + ' 已创建');
            const msg = '已为您创建工单 **' + r.ticketNo + '**，我会持续跟进，您可以在「我的工单」查看进度。';
            const m = await ZF.api('/api/agent/send.action', { sessionId: st.cur.id, content: msg });
            append(m);
        } catch (e) { ZF.toast(e.message, 'err'); }
    });

    // ---------- 实时：WebSocket 推送 + 轮询降级 ----------
    async function pollCur() {
        if (!st.cur) return;
        const d = await ZF.api('/api/agent/poll.action?sessionId=' + st.cur.id + '&afterId=' + st.lastId);
        d.messages.forEach(append);
        if (d.status === 'ENDED' && st.cur.status !== 'ENDED') { ZF.toast('用户已结束会话'); closeCur(); }
    }
    let tick = 0;
    async function poll() { // 降级模式：每 2.5 秒拉一次当前会话，每 10 秒刷新一次队列
        await pollCur();
        if (++tick % 4 === 0) loadQueue();
    }
    st.rt = ZF.realtime(e => {
        if (e.type === 'queue') loadQueue();
        else if (e.type === 'msg') {
            if (st.cur && e.sessionId === st.cur.id) append(e);
            else { const s = st.list.find(x => x.id === e.sessionId); if (s) { s.lastMsg = e.content; s.messages.push(e); renderQueue(); ZF.toast('收到 ' + s.name + ' 的新消息'); } }
        } else if (e.type === 'end') {
            if (st.cur && e.sessionId === st.cur.id && e.by === 'USER') { ZF.toast('用户已结束会话'); closeCur(); } else loadQueue();
        }
    }, poll);
    st.rt.onMode(m => {
        const el = $('connMode');
        el.className = 'pill status-pill ' + (m === 'ws' ? 'st-ACTIVE' : 'st-PENDING');
        el.textContent = m === 'ws' ? 'WebSocket 实时连接' : (m === 'poll' ? 'Ajax 轮询模式' : '连接中…');
    });
    setInterval(() => { if (st.rt.mode === 'ws') loadQueue(); }, 30000); // 刷新等待时长
    loadQueue();
})();
</script>
<%@ include file="../common/foot.jspf" %>
