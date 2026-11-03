<%@ page contentType="text/html;charset=UTF-8" pageEncoding="UTF-8" %>
<%@ taglib prefix="c" uri="http://java.sun.com/jsp/jstl/core" %>
<c:set var="pageTitle" value="智能客服"/>
<c:set var="nav" value="chat"/>
<%@ include file="../common/head.jspf" %>
<%@ include file="../common/user-nav.jspf" %>
<main class="u-main" style="margin-top:16px">
    <div class="chat-shell">
        <!-- 左：会话列表（服务端渲染） -->
        <aside class="chat-sessions glass rise">
            <div class="top">
                <a class="btn btn-primary btn-block" href="${ctx}/user/chat.action"><i class="ri-add-line"></i>开启新对话</a>
            </div>
            <div class="session-list">
                <c:forEach items="${sessions}" var="s">
                    <a class="session-item ${current.id eq s.id ? 'active' : ''}" href="${ctx}/user/chat.action?sid=${s.id}">
                        <div class="t"><b class="ellipsis"><c:out value="${s.title}"/></b><small>${s.friendlyTime}</small></div>
                        <p class="ellipsis"><c:out value="${empty s.lastMsg ? '（暂无消息）' : s.lastMsg}"/></p>
                        <div class="badges">
                            <c:choose>
                                <c:when test="${s.mode eq 'HUMAN'}"><span class="pill tag-cyan"><i class="ri-customer-service-2-line"></i>人工</span></c:when>
                                <c:otherwise><span class="pill tag"><i class="ri-robot-2-line"></i>AI</span></c:otherwise>
                            </c:choose>
                            <span class="pill status-pill st-${s.status}">${s.statusText}</span>
                            <c:if test="${not empty s.rating}"><span class="rated"><c:forEach begin="1" end="${s.rating}"><i class="ri-star-fill"></i></c:forEach></span></c:if>
                        </div>
                    </a>
                </c:forEach>
                <c:if test="${empty sessions}"><div class="empty" style="padding:30px 10px"><i class="ri-chat-smile-3-line"></i><p>还没有咨询记录</p></div></c:if>
            </div>
        </aside>

        <!-- 中：聊天窗口 -->
        <section class="chat-main glass-strong rise rise-1" id="chatMain"
                 data-sid="${current.id}" data-status="${current.status}" data-mode="${current.mode}"
                 data-rating="${current.rating}" data-agent="<c:out value='${agent.nickname}'/>">
            <div class="chat-head">
                <span class="bot-avatar" id="headAvatar"><img src="${ctx}/static/img/bot.svg" alt=""></span>
                <div class="title flex-1">
                    <b id="headTitle"><c:out value="${empty current ? '智服 AI 智能客服' : current.title}"/></b>
                    <small id="statusLine"><span class="dot dot-on"></span>AI 在线 · 知识库实时检索</small>
                </div>
                <button class="btn btn-sm" id="btnHuman" type="button"><i class="ri-customer-service-2-line"></i>转人工</button>
                <a class="btn btn-sm" id="btnTicket" href="${ctx}/user/ticketNew.action${empty current ? '' : '?sid='}${current.id}"><i class="ri-coupon-3-line"></i><span class="hide-sm">生成工单</span></a>
                <button class="btn btn-sm btn-danger ${empty current or current.status eq 'ENDED' ? 'hidden' : ''}" id="btnEnd" type="button"><i class="ri-shut-down-line"></i>结束</button>
            </div>
            <div class="queue-banner hidden mt-12" id="queueBanner"><span class="spinner"></span><span id="queueText">正在为您转接人工客服…</span></div>

            <div class="chat-body" id="chatBody">
                <c:if test="${empty messages}">
                    <div class="welcome" id="welcome">
                        <img class="mascot" src="${ctx}/static/img/mascot.svg" alt="">
                        <h2>你好，我是 <span class="grad-text">智服 AI</span> 👋</h2>
                        <p>可以问我退款、物流、发票、账号等问题，我会从知识库里为你找答案</p>
                    </div>
                </c:if>
                <c:forEach items="${messages}" var="m">
                    <c:set var="lastId" value="${m.id}"/>
                    <c:choose>
                        <c:when test="${m.senderType eq 'USER'}">
                            <div class="msg right" data-id="${m.id}">
                                <span class="avatar" style="background:${me.avatarColor}"><c:out value="${me.initial}"/></span>
                                <div><div class="bubble md">${m.contentHtml}</div><div class="time">${m.time}</div></div>
                            </div>
                        </c:when>
                        <c:when test="${m.senderType eq 'AGENT'}">
                            <div class="msg left agent" data-id="${m.id}">
                                <span class="avatar agent-avatar"><i class="ri-customer-service-2-fill"></i></span>
                                <div><div class="who">人工客服 · <c:out value="${agent.nickname}"/></div><div class="bubble md">${m.contentHtml}</div><div class="time">${m.time}</div></div>
                            </div>
                        </c:when>
                        <c:otherwise>
                            <div class="msg left" data-id="${m.id}">
                                <span class="bot-avatar"><img src="${ctx}/static/img/bot.svg" alt=""></span>
                                <div><div class="bubble md">${m.contentHtml}</div><div class="time">${m.time}</div></div>
                            </div>
                        </c:otherwise>
                    </c:choose>
                </c:forEach>
                <c:if test="${current.status eq 'ENDED'}">
                    <div class="msg system"><span class="sys">本次会话已结束<c:if test="${not empty current.rating}"> · 您的评价 ${current.rating} 星</c:if>，继续提问将开启新对话</span></div>
                </c:if>
            </div>

            <div class="chat-foot">
                <div class="quick" id="quick">
                    <span><i class="ri-lightbulb-flash-line" style="color:#fbbf24"></i> 猜你想问：</span>
                    <c:forEach items="${welcomeSuggest}" var="w"><button class="chip" type="button"><c:out value="${w}"/></button></c:forEach>
                </div>
                <div class="composer">
                    <textarea id="input" rows="1" maxlength="500" placeholder="请输入您的问题，Enter 发送"></textarea>
                    <button class="send-btn" id="sendBtn" type="button" title="发送"><i class="ri-send-plane-2-fill"></i></button>
                </div>
            </div>
        </section>

        <!-- 右：热门问题 + 我的工单 -->
        <aside class="chat-aside rise rise-2">
            <div class="box glass">
                <h4><i class="ri-fire-line" style="color:#fb7185"></i>热门问题</h4>
                <div class="hot">
                    <c:forEach items="${hot}" var="a" varStatus="st">
                        <a href="javascript:void(0)" data-ask="<c:out value='${a.question}'/>"><span class="n">${st.count}</span><span><c:out value="${a.question}"/></span></a>
                    </c:forEach>
                </div>
            </div>
            <div class="box glass">
                <h4><i class="ri-coupon-3-line" style="color:#a78bfa"></i>我的工单<a class="muted" style="margin-left:auto;font-size:12px;font-weight:500" href="${ctx}/user/tickets.action">全部</a></h4>
                <div class="tk">
                    <c:forEach items="${myTickets}" var="t">
                        <a href="${ctx}/ticket/detail.action?id=${t.id}"><span class="ellipsis"><c:out value="${t.title}"/></span><span class="pill status-pill st-${t.status}">${t.statusText}</span></a>
                    </c:forEach>
                    <c:if test="${empty myTickets}"><p class="muted" style="font-size:13px">暂无工单</p></c:if>
                </div>
            </div>
            <div class="box glass">
                <h4><i class="ri-shield-check-line" style="color:#34d399"></i>服务说明</h4>
                <p class="muted" style="font-size:12.5px;line-height:1.8">AI 客服 7×24 小时在线；人工客服服务时间 9:00-22:00；工单 24 小时内响应。</p>
            </div>
        </aside>
    </div>
</main>

<!-- 满意度评价弹窗 -->
<dialog class="modal" id="rateDlg" style="width:min(420px,calc(100vw - 32px))">
    <div class="modal-head"><span>本次服务满意吗？</span><button class="icon-btn" data-close type="button"><i class="ri-close-line"></i></button></div>
    <div class="modal-body center">
        <img src="${ctx}/static/img/mascot.svg" alt="" style="width:90px">
        <p class="text-2">您的评价会帮助我们做得更好</p>
        <div class="stars" id="stars"><i class="ri-star-fill" data-v="1"></i><i class="ri-star-fill" data-v="2"></i><i class="ri-star-fill" data-v="3"></i><i class="ri-star-fill" data-v="4"></i><i class="ri-star-fill" data-v="5"></i></div>
        <p class="muted" id="rateText" style="font-size:13px;min-height:20px"></p>
    </div>
    <div class="modal-foot"><button class="btn" data-close type="button">下次再说</button><button class="btn btn-primary" id="rateSubmit" type="button">提交评价</button></div>
</dialog>

<span id="lastIdHolder" data-id="${empty lastId ? 0 : lastId}" hidden></span>
<span id="meHolder" data-color="${me.avatarColor}" data-initial="<c:out value='${me.initial}'/>" data-q="<c:out value='${q}'/>" hidden></span>

<script>
(function () {
    const main = document.getElementById('chatMain'), body = document.getElementById('chatBody');
    const input = document.getElementById('input'), sendBtn = document.getElementById('sendBtn');
    const meEl = document.getElementById('meHolder');
    const st = {
        sid: main.dataset.sid ? Number(main.dataset.sid) : null,
        status: main.dataset.status || '',
        mode: main.dataset.mode || 'AI',
        agent: main.dataset.agent || '',
        lastId: Number(document.getElementById('lastIdHolder').dataset.id || 0),
        busy: false, rt: null, rating: 0
    };
    const shown = new Set([...body.querySelectorAll('.msg[data-id]')].map(e => Number(e.dataset.id)));

    function scroll() { body.scrollTop = body.scrollHeight; }
    function removeWelcome() { const w = document.getElementById('welcome'); if (w) w.remove(); }

    /** 追加一条消息气泡（与 JSP 服务端渲染的结构一致） */
    function append(type, content, time, id) {
        if (id && shown.has(id)) return null;
        if (id) { shown.add(id); st.lastId = Math.max(st.lastId, id); }
        removeWelcome();
        const div = document.createElement('div');
        let avatar, who = '';
        if (type === 'USER') {
            div.className = 'msg right';
            avatar = '<span class="avatar" style="background:' + ZF.esc(meEl.dataset.color) + '">' + ZF.esc(meEl.dataset.initial) + '</span>';
        } else if (type === 'AGENT') {
            div.className = 'msg left agent';
            avatar = '<span class="avatar agent-avatar"><i class="ri-customer-service-2-fill"></i></span>';
            who = '<div class="who">人工客服 · ' + ZF.esc(st.agent || '客服') + '</div>';
        } else {
            div.className = 'msg left';
            avatar = '<span class="bot-avatar"><img src="' + ZF.bot + '" alt=""></span>';
        }
        if (id) div.dataset.id = id;
        div.innerHTML = avatar + '<div>' + who + '<div class="bubble md">' + (content === null ? '<span class="typing"><i></i><i></i><i></i></span>' : ZF.md(content)) + '</div><div class="time">' + ZF.esc(time || '') + '</div></div>';
        body.appendChild(div);
        scroll();
        return div;
    }
    function system(text) {
        const d = document.createElement('div');
        d.className = 'msg system';
        d.innerHTML = '<span class="sys"></span>';
        d.firstChild.textContent = text;
        body.appendChild(d); scroll();
    }
    /** 打字机效果逐字显示 AI 回答 */
    function typewrite(el, text, done) {
        const bubble = el.querySelector('.bubble');
        let i = 0;
        const step = () => {
            i = Math.min(text.length, i + 3);
            bubble.innerHTML = ZF.md(text.slice(0, i));
            scroll();
            if (i < text.length) setTimeout(step, 18); else if (done) done();
        };
        step();
    }
    function setQuick(list) {
        const q = document.getElementById('quick');
        q.innerHTML = '<span><i class="ri-lightbulb-flash-line" style="color:#fbbf24"></i> 猜你想问：</span>';
        (list || []).forEach(t => { const b = document.createElement('button'); b.type = 'button'; b.className = 'chip'; b.textContent = t; q.appendChild(b); });
    }
    function setSid(id) {
        if (st.sid === id) return;
        st.sid = id;
        history.replaceState(null, '', ZF.CTX + '/user/chat.action?sid=' + id);
        document.getElementById('btnTicket').href = ZF.CTX + '/user/ticketNew.action?sid=' + id;
    }
    /** 新会话插入到左侧列表顶部 */
    function addSessionItem(d) {
        const list = document.querySelector('.session-list');
        if (!list) return;
        list.querySelectorAll('.session-item.active').forEach(a => a.classList.remove('active'));
        const empty = list.querySelector('.empty'); if (empty) empty.remove();
        const a = document.createElement('a');
        a.className = 'session-item active';
        a.href = ZF.CTX + '/user/chat.action?sid=' + d.sessionId;
        a.innerHTML = '<div class="t"><b class="ellipsis"></b><small>刚刚</small></div><p class="ellipsis"></p>' +
            '<div class="badges"><span class="pill tag"><i class="ri-robot-2-line"></i>AI</span><span class="pill status-pill st-ACTIVE">进行中</span></div>';
        a.querySelector('b').textContent = d.title || '新对话';
        a.querySelector('p').textContent = (d.answer || '').replace(/[*#>`\n-]/g, ' ').slice(0, 30);
        list.prepend(a);
    }
    function refreshHead() {
        const line = document.getElementById('statusLine'), banner = document.getElementById('queueBanner'), txt = document.getElementById('queueText');
        const btnHuman = document.getElementById('btnHuman'), btnEnd = document.getElementById('btnEnd'), av = document.getElementById('headAvatar');
        btnEnd.classList.toggle('hidden', !st.sid || st.status === 'ENDED');
        btnHuman.classList.toggle('hidden', st.mode === 'HUMAN' && st.status !== 'ENDED');
        banner.classList.add('hidden');
        if (st.mode === 'HUMAN' && st.status === 'QUEUE') {
            banner.classList.remove('hidden', 'live');
            banner.querySelector('.spinner').style.display = '';
            txt.textContent = '正在为您转接人工客服' + (st.position ? '，前方还有 ' + (st.position - 1) + ' 人' : '') + '，请稍候…';
            line.innerHTML = '<span class="dot" style="background:#fbbf24"></span>排队中 · ' + (st.rt ? (st.rt.mode === 'ws' ? 'WebSocket 已连接' : 'Ajax 轮询中') : '');
        } else if (st.mode === 'HUMAN' && st.status === 'ACTIVE') {
            banner.classList.remove('hidden'); banner.classList.add('live');
            banner.querySelector('.spinner').style.display = 'none';
            txt.textContent = '人工客服「' + (st.agent || '客服') + '」正在为您服务';
            av.className = 'avatar agent-avatar'; av.innerHTML = '<i class="ri-customer-service-2-fill"></i>';
            line.innerHTML = '<span class="dot dot-on"></span>人工客服 ' + ZF.esc(st.agent) + ' · ' + (st.rt && st.rt.mode === 'poll' ? 'Ajax 轮询' : 'WebSocket 实时');
        } else if (st.status === 'ENDED') {
            line.innerHTML = '<span class="dot dot-off"></span>会话已结束';
        } else {
            line.innerHTML = '<span class="dot dot-on"></span>AI 在线 · 知识库实时检索';
        }
    }

    // ---------- 实时通道（仅人工模式时启用） ----------
    function onEvent(e) {
        if (e.sessionId && e.sessionId !== st.sid) return;
        if (e.type === 'msg' && e.senderType !== 'USER') append(e.senderType, e.content, e.time, e.id);
        else if (e.type === 'accepted') { st.status = 'ACTIVE'; st.agent = e.agentName; system('客服「' + e.agentName + '」已接入，可以开始对话啦'); refreshHead(); }
        else if (e.type === 'end') onEnded(e.by === 'AGENT' ? '客服已结束本次会话' : '本次会话已结束');
    }
    async function poll() {
        if (!st.sid) return;
        const d = await ZF.api('/api/chat/poll.action?sessionId=' + st.sid + '&afterId=' + st.lastId);
        d.messages.forEach(m => { if (m.senderType !== 'USER') append(m.senderType, m.content, m.time, m.id); else { shown.add(m.id); st.lastId = Math.max(st.lastId, m.id); } });
        if (d.agentName) st.agent = d.agentName;
        st.position = d.position;
        if (d.status !== st.status) {
            if (d.status === 'ACTIVE' && st.status === 'QUEUE') system('客服「' + (d.agentName || '') + '」已接入，可以开始对话啦');
            if (d.status === 'ENDED') { onEnded('客服已结束本次会话'); return; }
            st.status = d.status;
        }
        refreshHead();
    }
    function startRealtime() {
        if (st.rt) return;
        st.rt = ZF.realtime(onEvent, poll);
        st.rt.onMode(() => refreshHead());
    }
    function onEnded(text) {
        if (st.status === 'ENDED') return;
        st.status = 'ENDED';
        system(text + '，继续提问将开启新对话');
        refreshHead();
        openRate();
    }

    // ---------- 发送 ----------
    async function send(text) {
        text = (text || '').trim();
        if (!text || st.busy) return;
        if (st.status === 'ENDED') { // 已结束的会话：清空窗口开启新对话
            st.sid = null; st.status = ''; st.mode = 'AI'; st.agent = '';
            body.innerHTML = ''; history.replaceState(null, '', ZF.CTX + '/user/chat.action');
            document.getElementById('headTitle').textContent = '智服 AI 智能客服';
            const av = document.getElementById('headAvatar'); av.className = 'bot-avatar'; av.innerHTML = '<img src="' + ZF.bot + '" alt="">';
        }
        st.busy = true; sendBtn.disabled = true;
        input.value = ''; input.style.height = '';
        const now = new Date().toTimeString().slice(0, 5);
        const mine = append('USER', text, now);
        try {
            if (st.mode === 'HUMAN') {
                const d = await ZF.api('/api/chat/ask.action', { sessionId: st.sid, question: text });
                if (d.userMsgId) { shown.add(d.userMsgId); st.lastId = Math.max(st.lastId, d.userMsgId); mine.dataset.id = d.userMsgId; }
                if (d.time) mine.querySelector('.time').textContent = d.time;
            } else {
                const holder = append('AI', null, '');
                const d = await ZF.api('/api/chat/ask.action', { sessionId: st.sid, question: text });
                const isNew = st.sid !== d.sessionId;
                setSid(d.sessionId);
                if (isNew) addSessionItem(d);
                mine.querySelector('.time').textContent = d.time;
                if (!st.status) { st.status = 'ACTIVE'; document.getElementById('headTitle').textContent = d.title || '智服 AI 智能客服'; }
                shown.add(d.userMsgId); shown.add(d.msgId); st.lastId = Math.max(st.lastId, d.msgId);
                holder.dataset.id = d.msgId;
                holder.querySelector('.time').textContent = d.time;
                typewrite(holder, d.answer, () => setQuick(d.suggest));
                refreshHead();
            }
        } catch (e) {
            ZF.toast(e.message, 'err');
            const typing = body.querySelector('.typing');
            if (typing) typing.closest('.msg').remove();
        } finally {
            st.busy = false; sendBtn.disabled = false; input.focus();
        }
    }
    async function toHuman() {
        try {
            const d = await ZF.api('/api/chat/human.action', { sessionId: st.sid });
            setSid(d.sessionId);
            st.mode = 'HUMAN'; st.status = d.status; st.position = d.position;
            if (d.agentName) st.agent = d.agentName;
            if (d.tip) append(d.tip.senderType, d.tip.content, d.tip.time, d.tip.id);
            setQuick([]);
            startRealtime();
            refreshHead();
        } catch (e) { ZF.toast(e.message, 'err'); }
    }

    // ---------- 评价 ----------
    const rateDlg = document.getElementById('rateDlg'), stars = document.querySelectorAll('#stars i');
    const RATE_TEXT = ['', '非常不满意', '不满意', '一般', '满意', '非常满意'];
    function paint(v) { stars.forEach(s => s.classList.toggle('on', Number(s.dataset.v) <= v)); document.getElementById('rateText').textContent = RATE_TEXT[v] || ''; }
    stars.forEach(s => { s.addEventListener('mouseenter', () => paint(Number(s.dataset.v))); s.addEventListener('click', () => { st.rating = Number(s.dataset.v); paint(st.rating); }); });
    document.getElementById('stars').addEventListener('mouseleave', () => paint(st.rating));
    function openRate() { if (!main.dataset.rating && st.sid) { st.rating = 5; paint(5); rateDlg.showModal(); } }
    document.getElementById('rateSubmit').addEventListener('click', async () => {
        try {
            await ZF.api('/api/chat/rate.action', { sessionId: st.sid, rating: st.rating || 5 });
            main.dataset.rating = st.rating;
            rateDlg.close();
            ZF.toast('感谢您的评价！');
            system('您给本次服务打了 ' + st.rating + ' 星，感谢反馈');
        } catch (e) { ZF.toast(e.message, 'err'); }
    });

    // ---------- 事件绑定 ----------
    sendBtn.addEventListener('click', () => send(input.value));
    input.addEventListener('keydown', e => { if (e.key === 'Enter' && !e.shiftKey && !e.isComposing) { e.preventDefault(); send(input.value); } });
    input.addEventListener('input', () => { input.style.height = 'auto'; input.style.height = Math.min(120, input.scrollHeight) + 'px'; });
    document.getElementById('quick').addEventListener('click', e => {
        const b = e.target.closest('.chip'); if (!b) return;
        const t = b.textContent.trim();
        if (t === '转人工') toHuman();
        else if (t === '生成工单') location.href = ZF.CTX + '/user/ticketNew.action' + (st.sid ? '?sid=' + st.sid : '');
        else if (t === '换个问题') input.focus();
        else send(t);
    });
    document.querySelectorAll('[data-ask]').forEach(a => a.addEventListener('click', () => send(a.dataset.ask)));
    document.getElementById('btnHuman').addEventListener('click', toHuman);
    document.getElementById('btnEnd').addEventListener('click', async () => {
        if (!confirm('确定结束本次会话吗？')) return;
        try { await ZF.api('/api/chat/end.action', { sessionId: st.sid }); onEnded('您已结束本次会话'); } catch (e) { ZF.toast(e.message, 'err'); }
    });

    // 页面加载：人工会话进行中则连上实时通道；从首页带过来的问题自动发送
    if (st.mode === 'HUMAN' && st.status !== 'ENDED') startRealtime();
    refreshHead();
    scroll();
    if (meEl.dataset.q) send(meEl.dataset.q);
})();
</script>
<%@ include file="../common/foot.jspf" %>
