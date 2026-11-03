<%@ page contentType="text/html;charset=UTF-8" pageEncoding="UTF-8" %>
<%@ taglib prefix="c" uri="http://java.sun.com/jsp/jstl/core" %>
<%@ taglib prefix="fmt" uri="http://java.sun.com/jsp/jstl/fmt" %>
<c:set var="pageTitle" value="${article.question}"/>
<c:set var="nav" value="kb"/>
<%@ include file="../common/head.jspf" %>
<%@ include file="../common/user-nav.jspf" %>
<main class="u-main">
    <div class="detail-grid">
        <article class="article glass-strong rise">
            <div class="flex items-center gap-8 muted" style="font-size:13px">
                <a href="${ctx}/user/kb.action">知识库</a><i class="ri-arrow-right-s-line"></i>
                <a href="${ctx}/user/kb.action?cid=${article.categoryId}"><c:out value="${article.categoryName}"/></a>
            </div>
            <h1><c:out value="${article.question}"/></h1>
            <div class="flex gap-12 wrap muted" style="font-size:12.5px">
                <span class="tag"><c:out value="${article.categoryName}"/></span>
                <span><i class="ri-eye-line"></i> <fmt:formatNumber value="${article.hitCount}"/> 人看过</span>
                <span><i class="ri-time-line"></i> 更新于 ${article.updateTimeStr}</span>
            </div>
            <%-- answerHtml 在 Java 端已做 HTML 转义，再把 **加粗** / 列表转成标签，所以这里可以直接输出 --%>
            <div class="answer md">${article.answerHtml}</div>
            <c:if test="${not empty article.keywords}">
                <div class="flex gap-6 wrap mt-16"><span class="muted" style="font-size:12.5px">关键词：</span>
                    <c:forTokens items="${article.keywords}" delims=",，" var="k"><span class="tag tag-cyan"><c:out value="${k}"/></span></c:forTokens>
                </div>
            </c:if>
            <div class="helpful">
                <div><b>没有解决您的问题？</b><p class="muted" style="font-size:13px">智服 AI 可以结合您的具体情况回答，也可以转人工客服</p></div>
                <div class="flex gap-8">
                    <a class="btn btn-primary" href="${ctx}/user/chat.action"><i class="ri-robot-2-line"></i>问智服 AI</a>
                    <a class="btn" href="${ctx}/user/ticketNew.action"><i class="ri-edit-box-line"></i>提交工单</a>
                </div>
            </div>
        </article>
        <aside class="glass panel rise rise-2">
            <h3 class="section-title">相关问题</h3>
            <c:forEach items="${related}" var="r">
                <a class="flex items-center gap-8" style="padding:9px 0;border-bottom:1px dashed rgba(255,255,255,.08);color:var(--text-2)" href="${ctx}/user/kbDetail.action?id=${r.id}">
                    <i class="ri-question-line" style="color:#c4b5fd"></i><span class="flex-1"><c:out value="${r.question}"/></span>
                </a>
            </c:forEach>
            <c:if test="${empty related}"><p class="muted">暂无相关问题</p></c:if>
            <h3 class="section-title mt-24">全部分类</h3>
            <div class="flex wrap gap-8">
                <c:forEach items="${categories}" var="cat"><a class="chip" href="${ctx}/user/kb.action?cid=${cat.id}"><c:out value="${cat.name}"/></a></c:forEach>
            </div>
        </aside>
    </div>
</main>
<%@ include file="../common/foot.jspf" %>
