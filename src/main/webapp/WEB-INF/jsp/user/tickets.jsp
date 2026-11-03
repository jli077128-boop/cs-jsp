<%@ page contentType="text/html;charset=UTF-8" pageEncoding="UTF-8" %>
<%@ taglib prefix="c" uri="http://java.sun.com/jsp/jstl/core" %>
<c:set var="pageTitle" value="我的工单"/>
<c:set var="nav" value="tickets"/>
<%@ include file="../common/head.jspf" %>
<%@ include file="../common/user-nav.jspf" %>
<%-- 本页用 Struts 标签 + OGNL 渲染（对应课堂 00_strutsOGNL）：
     <s:iterator> 遍历值栈中 TicketAction.tickets / statusMap，<s:if> 判断，<s:url>/<s:a> 生成带参数的 .action 地址，
     <s:property> 输出（默认 HTML 转义）。iterator 的当前元素被压到栈顶，所以直接写 title、ticketNo 即可 --%>
<main class="u-main">
    <div class="page-head">
        <div><h1>我的工单</h1><p>提交的问题会由专属客服跟进，处理进度实时更新</p></div>
        <s:a cssClass="btn btn-primary" action="ticketNew" namespace="/user"><i class="ri-add-line"></i>提交新工单</s:a>
    </div>
    <div class="tabs mb-16">
        <s:a action="tickets" namespace="/user" cssClass="%{status == null || status == '' ? 'active' : ''}">全部<span class="count"><s:property value="total"/></span></s:a>
        <s:iterator value="statusMap">
            <s:url var="tabUrl" action="tickets" namespace="/user"><s:param name="status" value="key"/></s:url>
            <a href="<s:property value="#tabUrl"/>" class="<s:if test="key == status">active</s:if>"><s:property value="value"/><span class="count"><s:property value="counts[key]"/></span></a>
        </s:iterator>
    </div>
    <s:iterator value="tickets" var="t" status="st">
        <s:url var="detailUrl" action="detail" namespace="/ticket"><s:param name="id" value="id"/></s:url>
        <a class="ticket-card glass hover-lift rise" style="animation-delay:<s:property value="#st.index * 0.04"/>s" href="<s:property value="#detailUrl"/>">
            <div>
                <div class="flex items-center gap-8"><span class="no"><s:property value="ticketNo"/></span><span class="tag"><s:property value="category"/></span></div>
                <h3><s:property value="title"/></h3>
                <div class="meta">
                    <span class="pr pr-<s:property value="priority"/>"><s:property value="priorityText"/>优先级</span>
                    <span><i class="ri-time-line"></i> <s:property value="createTimeStr"/></span>
                    <span><i class="ri-customer-service-2-line"></i> <s:if test="assigneeName == null || assigneeName == ''">等待分配客服</s:if><s:else><s:property value="assigneeName"/></s:else></span>
                </div>
                <div class="progress-mini">
                    <i class="on"></i>
                    <i class="<s:if test="status != 'PENDING'">on</s:if>"></i>
                    <i class="<s:if test="status == 'RESOLVED' || status == 'CLOSED'">on</s:if>"></i>
                    <i class="<s:if test="status == 'CLOSED'">on</s:if>"></i>
                </div>
            </div>
            <div class="side">
                <span class="pill status-pill st-<s:property value="status"/>"><s:property value="statusText"/></span>
                <span class="btn btn-sm">查看进度 <i class="ri-arrow-right-s-line"></i></span>
            </div>
        </a>
    </s:iterator>
    <s:if test="tickets == null || tickets.isEmpty()">
        <div class="glass empty"><i class="ri-inbox-2-line"></i><p>暂无工单</p>
            <s:a cssClass="btn btn-primary mt-16" action="ticketNew" namespace="/user"><i class="ri-add-line"></i>提交工单</s:a></div>
    </s:if>
</main>
<%@ include file="../common/foot.jspf" %>
