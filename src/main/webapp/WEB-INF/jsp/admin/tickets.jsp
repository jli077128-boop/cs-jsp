<%@ page contentType="text/html;charset=UTF-8" pageEncoding="UTF-8" %>
<%@ taglib prefix="c" uri="http://java.sun.com/jsp/jstl/core" %>
<c:set var="pageTitle" value="工单管理"/>
<c:set var="nav" value="tickets"/>
<%@ include file="../common/head.jspf" %>
<%@ include file="../common/side-nav.jspf" %>
<%-- 工单管理：Struts 标签版。
     类型转换演示：开始 / 结束日期输入框提交 "yyyy-MM-dd" 字符串 → 全局 DateConverter 转成 AdminTicketAction 的 java.util.Date 属性；
     回显时 <s:textfield> 调用转换器的 convertToString；格式错误由 <s:fielderror> 显示 --%>
<div class="topbar">
    <div><h1>工单管理</h1><p>共 <s:property value="total"/> 个工单 · 待处理 <s:property value="counts['PENDING']"/> 个，可直接在列表中分配客服</p></div>
</div>
<section class="glass panel rise">
    <s:form cssClass="toolbar" action="tickets" namespace="/admin" method="get" theme="simple" id="ticketFilter">
        <div class="tabs">
            <s:a action="tickets" namespace="/admin" cssClass="%{status == null || status == '' ? 'active' : ''}">全部<span class="count"><s:property value="total"/></span></s:a>
            <s:iterator value="statusMap">
                <s:url var="tabUrl" action="tickets" namespace="/admin"><s:param name="status" value="key"/></s:url>
                <a href="<s:property value="#tabUrl"/>" class="<s:if test="key == status">active</s:if>"><s:property value="value"/><span class="count"><s:property value="counts[key]"/></span></a>
            </s:iterator>
        </div>
        <s:if test="status != null && status != ''"><s:hidden name="status"/></s:if>
        <div class="date-range" style="margin-left:auto" title="按提交日期筛选（自定义类型转换器 DateConverter：yyyy-MM-dd → java.util.Date）">
            <i class="ri-calendar-2-line"></i>
            <s:textfield name="startDate" cssClass="input" type="date" placeholder="开始 yyyy-MM-dd" aria-label="开始日期"/>
            <span class="muted">至</span>
            <s:textfield name="endDate" cssClass="input" type="date" placeholder="结束 yyyy-MM-dd" aria-label="结束日期"/>
        </div>
        <div class="input-icon search-sm"><i class="ri-search-2-line"></i><s:textfield name="q" cssClass="input" placeholder="工单编号 / 标题"/></div>
        <button class="btn" type="submit">筛选</button>
    </s:form>
    <s:if test="hasFieldErrors()">
        <div class="alert alert-error mb-16"><i class="ri-error-warning-line"></i>
            <s:fielderror theme="simple"><s:param>startDate</s:param><s:param>endDate</s:param></s:fielderror>
        </div>
    </s:if>
    <s:elseif test="dateFiltered">
        <div class="alert alert-ok mb-16"><i class="ri-calendar-check-line"></i>
            已按提交日期筛选：<s:if test="startDate != null"><s:date name="startDate" format="yyyy-MM-dd"/></s:if><s:else>不限</s:else>
            至 <s:if test="endDate != null"><s:date name="endDate" format="yyyy-MM-dd"/></s:if><s:else>不限</s:else>，
            共 <s:property value="tickets.size()"/> 个
            <s:a action="tickets" namespace="/admin" cssStyle="margin-left:8px;font-weight:600">清除日期</s:a>
        </div>
    </s:elseif>
    <div class="table-wrap">
        <table class="table">
            <thead><tr><th>工单编号</th><th>标题</th><th>用户</th><th>分类</th><th>优先级</th><th>状态</th><th>处理客服</th><th>提交时间</th><th class="right">操作</th></tr></thead>
            <tbody>
            <s:iterator value="tickets" var="t">
                <tr>
                    <td class="mono"><s:property value="ticketNo"/></td>
                    <td class="strong" style="max-width:240px"><div class="ellipsis"><s:property value="title"/></div></td>
                    <td><span class="flex items-center gap-8"><span class="avatar avatar-sm" style="background:<s:property value="userColor"/>"><s:property value="userName.substring(0,1)"/></span><s:property value="userName"/></span></td>
                    <td><span class="tag"><s:property value="category"/></span></td>
                    <td><span class="pr pr-<s:property value="priority"/>"><s:property value="priorityText"/></span></td>
                    <td><span class="pill status-pill st-<s:property value="status"/>"><s:property value="statusText"/></span></td>
                    <td>
                        <form class="inline flex gap-6 items-center" method="post" action="${ctx}/admin/ticketAssign.action">
                            <input type="hidden" name="id" value="<s:property value="id"/>"><input type="hidden" name="status" value="<s:property value="[1].status"/>">
                            <select class="select" name="agentId" style="height:30px;width:auto;min-width:118px;font-size:12.5px;border-radius:9px" onchange="this.form.submit()" <s:if test="status == 'CLOSED'">disabled</s:if>>
                                <s:if test="assigneeId == null"><option value="">未分配</option></s:if>
                                <%-- 嵌套迭代：栈顶变成客服对象，用 #t 引用外层的工单 --%>
                                <s:iterator value="agents" var="a">
                                    <s:if test="status == 1 || id == #t.assigneeId"><option value="<s:property value="id"/>" <s:if test="id == #t.assigneeId">selected</s:if>><s:property value="nickname"/></option></s:if>
                                </s:iterator>
                            </select>
                        </form>
                    </td>
                    <td><s:property value="createTimeStr"/></td>
                    <td class="right"><s:a cssClass="btn btn-sm" action="detail" namespace="/ticket"><s:param name="id" value="id"/>详情</s:a></td>
                </tr>
            </s:iterator>
            </tbody>
        </table>
        <s:if test="tickets == null || tickets.isEmpty()"><div class="empty"><i class="ri-inbox-2-line"></i><p>没有符合条件的工单</p></div></s:if>
    </div>
</section>
<%@ include file="../common/foot.jspf" %>
