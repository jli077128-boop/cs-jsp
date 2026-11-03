<%@ page contentType="text/html;charset=UTF-8" pageEncoding="UTF-8" %>
<%@ taglib prefix="c" uri="http://java.sun.com/jsp/jstl/core" %>
<%@ taglib prefix="fmt" uri="http://java.sun.com/jsp/jstl/fmt" %>
<c:set var="pageTitle" value="帮助中心"/>
<c:set var="nav" value="home"/>
<%@ include file="../common/head.jspf" %>
<%@ include file="../common/user-nav.jspf" %>
<main class="u-main">
    <!-- Hero + 搜索 -->
    <section class="hero glass-strong rise">
        <div>
            <span class="eyebrow"><i class="ri-sparkling-2-fill"></i>Hi，<c:out value="${me.nickname}"/>，今天遇到什么问题了？</span>
            <h1>有问题，<span class="grad-text">问智服 AI</span></h1>
            <p class="sub">知识库秒级检索 + 大模型智能应答，解决不了一键转人工</p>
            <form class="search-xl" action="${ctx}/user/kb.action" method="get">
                <i class="ri-search-2-line"></i>
                <input name="q" placeholder="搜索问题，例如：怎么申请退款" autocomplete="off">
                <button class="btn btn-primary" type="submit">搜索</button>
            </form>
            <div class="hot-words">
                <span><i class="ri-fire-line" style="color:#fb7185"></i> 大家都在搜：</span>
                <c:forEach items="${hot}" var="a" end="3">
                    <a href="${ctx}/user/kbDetail.action?id=${a.id}"><c:out value="${a.question}"/></a>
                </c:forEach>
            </div>
        </div>
        <div class="hero-art">
            <img class="mascot" src="${ctx}/static/img/mascot.svg" alt="智服 AI">
            <div class="bubble b1 glass">👋 我是智服 AI，7×24 在线</div>
            <div class="bubble b2 glass">平均 <b class="grad-text">1.8s</b> 响应</div>
        </div>
    </section>

    <!-- 我的概况 -->
    <section class="stat-strip">
        <a class="stat-mini glass hover-lift rise rise-1" href="${ctx}/user/chat.action">
            <span class="ic" style="background:linear-gradient(135deg,#4f7cff,#8b5cf6)"><i class="ri-robot-2-line"></i></span>
            <div><b>智能客服</b><span>AI 秒回 · 支持转人工</span></div>
        </a>
        <a class="stat-mini glass hover-lift rise rise-2" href="${ctx}/user/tickets.action">
            <span class="ic" style="background:linear-gradient(135deg,#8b5cf6,#ec4899)"><i class="ri-coupon-3-line"></i></span>
            <div><b>${ticketCount}</b><span>我的工单（${openCount} 个处理中）</span></div>
        </a>
        <a class="stat-mini glass hover-lift rise rise-3" href="${ctx}/user/ticketNew.action">
            <span class="ic" style="background:linear-gradient(135deg,#22d3ee,#34d399)"><i class="ri-edit-box-line"></i></span>
            <div><b>提交工单</b><span>24 小时内专人响应</span></div>
        </a>
    </section>

    <!-- 热门问题 -->
    <section class="mt-24">
        <h2 class="section-title">热门问题<a class="more" href="${ctx}/user/kb.action">查看全部 <i class="ri-arrow-right-s-line"></i></a></h2>
        <div class="grid-3">
            <c:forEach items="${hot}" var="a" varStatus="st">
                <a class="q-card glass hover-lift rise" style="animation-delay:${st.index * 0.05}s" href="${ctx}/user/kbDetail.action?id=${a.id}">
                    <div class="flex items-center gap-8">
                        <span class="rank ${st.index lt 3 ? 'top' : ''}">${st.count}</span>
                        <span class="tag"><c:out value="${a.categoryName}"/></span>
                    </div>
                    <h3><c:out value="${a.question}"/></h3>
                    <p><c:out value="${a.answerPlain}"/></p>
                    <div class="foot"><span><i class="ri-fire-line"></i> <fmt:formatNumber value="${a.hitCount}"/> 人看过</span><span>查看答案 <i class="ri-arrow-right-line"></i></span></div>
                </a>
            </c:forEach>
        </div>
    </section>

    <!-- 分类宫格 -->
    <section class="mt-24">
        <h2 class="section-title">问题分类</h2>
        <div class="grid-4">
            <c:forEach items="${categories}" var="cat" varStatus="st">
                <a class="cat-tile glass hover-lift rise" style="animation-delay:${st.index * 0.04}s" href="${ctx}/user/kb.action?cid=${cat.id}">
                    <span class="cat-icon" style="background:linear-gradient(135deg,${cat.color1},${cat.color2})"><i class="${cat.iconClass}"></i></span>
                    <b><c:out value="${cat.name}"/></b>
                    <span><c:out value="${cat.descr}"/> · ${cat.articleCount} 篇</span>
                </a>
            </c:forEach>
        </div>
    </section>

    <!-- 最近工单 -->
    <c:if test="${not empty recentTickets}">
        <section class="mt-24">
            <h2 class="section-title">最近工单<a class="more" href="${ctx}/user/tickets.action">全部工单 <i class="ri-arrow-right-s-line"></i></a></h2>
            <div class="glass panel">
                <div class="table-wrap">
                    <table class="table">
                        <thead><tr><th>工单编号</th><th>问题</th><th>状态</th><th>提交时间</th><th></th></tr></thead>
                        <tbody>
                        <c:forEach items="${recentTickets}" var="t">
                            <tr>
                                <td class="mono">${t.ticketNo}</td>
                                <td class="strong"><c:out value="${t.title}"/></td>
                                <td><span class="pill status-pill st-${t.status}">${t.statusText}</span></td>
                                <td>${t.createTimeStr}</td>
                                <td class="right"><a class="btn btn-sm" href="${ctx}/ticket/detail.action?id=${t.id}">查看进度</a></td>
                            </tr>
                        </c:forEach>
                        </tbody>
                    </table>
                </div>
            </div>
        </section>
    </c:if>
</main>
<footer class="u-footer">© 2026 智服 AI · AI 智能对话客服与工单系统（JavaEE 课程设计）</footer>
<a class="fab-chat" href="${ctx}/user/chat.action" title="智能客服">
    <img src="${ctx}/static/img/bot.svg" alt="" style="width:44px;height:44px">
    <span class="tip">有问题？问问智服 AI</span>
</a>
<%@ include file="../common/foot.jspf" %>
