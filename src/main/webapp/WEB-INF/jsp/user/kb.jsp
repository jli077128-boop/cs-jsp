<%@ page contentType="text/html;charset=UTF-8" pageEncoding="UTF-8" %>
<%@ taglib prefix="c" uri="http://java.sun.com/jsp/jstl/core" %>
<%@ taglib prefix="fmt" uri="http://java.sun.com/jsp/jstl/fmt" %>
<c:set var="pageTitle" value="知识库"/>
<c:set var="nav" value="kb"/>
<%@ include file="../common/head.jspf" %>
<%@ include file="../common/user-nav.jspf" %>
<%-- OGNL 演示：#parameters.q 直接读取请求参数（与 Action 属性 q 的值相同） --%>
<main class="u-main">
    <div class="page-head">
        <div>
            <h1><c:choose><c:when test="${not empty currentCategory}"><c:out value="${currentCategory.name}"/></c:when><c:otherwise>知识库</c:otherwise></c:choose></h1>
            <p><c:choose>
                <c:when test="${not empty q}">“<s:property value="#parameters.q"/>” 的搜索结果，共 <s:property value="articles.size()"/> 条</c:when>
                <c:otherwise>共 ${articles.size()} 个常见问题，找不到答案可以直接问智服 AI</c:otherwise>
            </c:choose></p>
        </div>
        <form class="flex gap-8" action="${ctx}/user/kb.action" method="get" style="min-width:min(420px,100%)">
            <c:if test="${not empty cid}"><input type="hidden" name="cid" value="${cid}"></c:if>
            <div class="input-icon flex-1"><i class="ri-search-2-line"></i><input class="input" name="q" value="<c:out value='${q}'/>" placeholder="搜索问题或关键词"></div>
            <button class="btn btn-primary" type="submit">搜索</button>
        </form>
    </div>
    <div class="kb-layout">
        <aside class="kb-side glass">
            <a href="${ctx}/user/kb.action" class="${empty cid ? 'active' : ''}"><span class="ci" style="background:var(--grad)"><i class="ri-apps-2-line"></i></span>全部分类</a>
            <c:forEach items="${categories}" var="cat">
                <a href="${ctx}/user/kb.action?cid=${cat.id}" class="${cid eq cat.id ? 'active' : ''}">
                    <span class="ci" style="background:linear-gradient(135deg,${cat.color1},${cat.color2})"><i class="${cat.iconClass}"></i></span>
                    <c:out value="${cat.name}"/><span class="n">${cat.articleCount}</span>
                </a>
            </c:forEach>
        </aside>
        <section>
            <c:forEach items="${articles}" var="a" varStatus="st">
                <a class="kb-item glass hover-lift rise" style="animation-delay:${st.index * 0.03}s" href="${ctx}/user/kbDetail.action?id=${a.id}">
                    <span class="qi">Q</span>
                    <div class="flex-1">
                        <h3><c:out value="${a.question}"/></h3>
                        <p><c:out value="${a.answerPlain}"/></p>
                        <div class="meta"><span class="tag"><c:out value="${a.categoryName}"/></span><span><i class="ri-eye-line"></i> <fmt:formatNumber value="${a.hitCount}"/></span><span><i class="ri-time-line"></i> 更新于 ${a.updateTimeStr}</span></div>
                    </div>
                    <i class="ri-arrow-right-s-line muted" style="font-size:20px;align-self:center"></i>
                </a>
            </c:forEach>
            <c:if test="${empty articles}">
                <div class="glass empty">
                    <i class="ri-search-eye-line"></i>
                    <p>没有找到相关问题</p>
                    <c:url var="askUrl" value="/user/chat.action"><c:param name="q" value="${q}"/></c:url>
                    <a class="btn btn-primary mt-16" href="${askUrl}"><i class="ri-robot-2-line"></i>问问智服 AI</a>
                </div>
            </c:if>
        </section>
    </div>
</main>
<a class="fab-chat" href="${ctx}/user/chat.action" title="智能客服"><img src="${ctx}/static/img/bot.svg" alt="" style="width:44px;height:44px"><span class="tip">有问题？问问智服 AI</span></a>
<%@ include file="../common/foot.jspf" %>
