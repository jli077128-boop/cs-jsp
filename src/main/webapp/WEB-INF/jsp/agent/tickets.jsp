<%@ page contentType="text/html;charset=UTF-8" pageEncoding="UTF-8" %>
<%@ taglib prefix="c" uri="http://java.sun.com/jsp/jstl/core" %>
<c:set var="pageTitle" value="我的工单"/>
<c:set var="nav" value="tickets"/>
<%@ include file="../common/head.jspf" %>
<%@ include file="../common/side-nav.jspf" %>
<div class="topbar">
    <div><h1>我的工单</h1><p>分配给我的工单，以及等待认领的新工单</p></div>
    <a class="btn" href="${ctx}/agent/workbench.action"><i class="ri-customer-service-2-line"></i>返回工作台</a>
</div>
<div class="kpis">
    <div class="kpi glass rise" style="--c:#60a5fa;--g:linear-gradient(135deg,#4f7cff,#60a5fa)"><span class="ic"><i class="ri-loader-4-line"></i></span><div class="label">处理中</div><div class="value">${counts['PROCESSING']}</div></div>
    <div class="kpi glass rise rise-1" style="--c:#fbbf24;--g:linear-gradient(135deg,#f97316,#fbbf24)"><span class="ic"><i class="ri-inbox-unarchive-line"></i></span><div class="label">待认领</div><div class="value">${unassignedCount}</div></div>
    <div class="kpi glass rise rise-2" style="--c:#34d399;--g:linear-gradient(135deg,#22d3ee,#34d399)"><span class="ic"><i class="ri-checkbox-circle-line"></i></span><div class="label">已解决</div><div class="value">${counts['RESOLVED']}</div></div>
    <div class="kpi glass rise rise-3" style="--c:#a78bfa;--g:linear-gradient(135deg,#8b5cf6,#ec4899)"><span class="ic"><i class="ri-archive-line"></i></span><div class="label">已关闭</div><div class="value">${counts['CLOSED']}</div></div>
</div>
<section class="glass panel rise">
    <div class="toolbar">
        <div class="tabs">
            <a href="${ctx}/agent/tickets.action" class="${empty status and tab ne 'pool' ? 'active' : ''}">全部<span class="count">${total}</span></a>
            <c:forEach items="${statusMap}" var="e">
                <a href="${ctx}/agent/tickets.action?status=${e.key}" class="${status eq e.key ? 'active' : ''}">${e.value}<span class="count">${counts[e.key]}</span></a>
            </c:forEach>
            <a href="${ctx}/agent/tickets.action?tab=pool" class="${tab eq 'pool' ? 'active' : ''}"><i class="ri-inbox-unarchive-line"></i>待认领<span class="count">${unassignedCount}</span></a>
        </div>
    </div>
    <div class="table-wrap">
        <table class="table">
            <thead><tr><th>工单编号</th><th>标题</th><th>用户</th><th>分类</th><th>优先级</th><th>状态</th><th>更新时间</th><th class="right">操作</th></tr></thead>
            <tbody>
            <c:forEach items="${tickets}" var="t">
                <tr>
                    <td class="mono">${t.ticketNo}</td>
                    <td class="strong"><c:out value="${t.title}"/></td>
                    <td><span class="flex items-center gap-8"><span class="avatar avatar-sm" style="background:${t.userColor}"><c:out value="${t.userName.substring(0,1)}"/></span><c:out value="${t.userName}"/></span></td>
                    <td><span class="tag"><c:out value="${t.category}"/></span></td>
                    <td><span class="pr pr-${t.priority}">${t.priorityText}</span></td>
                    <td><span class="pill status-pill st-${t.status}">${t.statusText}</span></td>
                    <td>${t.updateTimeStr}</td>
                    <td class="right">
                        <c:if test="${t.status eq 'PENDING' and empty t.assigneeId}">
                            <form class="inline" method="post" action="${ctx}/ticket/update.action">
                                <input type="hidden" name="id" value="${t.id}"><input type="hidden" name="op" value="status"><input type="hidden" name="status" value="PROCESSING"><input type="hidden" name="remark" value="客服认领工单，开始处理">
                                <button class="btn btn-sm btn-primary" type="submit">认领</button>
                            </form>
                        </c:if>
                        <a class="btn btn-sm" href="${ctx}/ticket/detail.action?id=${t.id}">处理</a>
                    </td>
                </tr>
            </c:forEach>
            </tbody>
        </table>
        <c:if test="${empty tickets}"><div class="empty"><i class="ri-inbox-2-line"></i><p>这里还没有工单</p></div></c:if>
    </div>
</section>
<%@ include file="../common/foot.jspf" %>
