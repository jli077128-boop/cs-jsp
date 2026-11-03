<%@ page contentType="text/html;charset=UTF-8" pageEncoding="UTF-8" %>
<%@ taglib prefix="c" uri="http://java.sun.com/jsp/jstl/core" %>
<c:set var="pageTitle" value="用户管理"/>
<c:set var="nav" value="users"/>
<%@ include file="../common/head.jspf" %>
<%@ include file="../common/side-nav.jspf" %>
<div class="topbar">
    <div><h1>用户管理</h1><p>管理普通用户、客服与管理员账号，新账号初始密码为 123456</p></div>
    <button class="btn btn-primary" type="button" data-open="#userDlg"><i class="ri-user-add-line"></i>新增账号</button>
</div>
<div class="kpis">
    <div class="kpi glass rise" style="--c:#8b5cf6;--g:linear-gradient(135deg,#4f7cff,#8b5cf6)"><span class="ic"><i class="ri-team-line"></i></span><div class="label">全部账号</div><div class="value">${total}</div></div>
    <div class="kpi glass rise rise-1" style="--c:#60a5fa;--g:linear-gradient(135deg,#22d3ee,#60a5fa)"><span class="ic"><i class="ri-user-smile-line"></i></span><div class="label">普通用户</div><div class="value">${userCount}</div></div>
    <div class="kpi glass rise rise-2" style="--c:#22d3ee;--g:linear-gradient(135deg,#22d3ee,#34d399)"><span class="ic"><i class="ri-customer-service-2-line"></i></span><div class="label">客服</div><div class="value">${agentCount}</div></div>
    <div class="kpi glass rise rise-3" style="--c:#ec4899;--g:linear-gradient(135deg,#8b5cf6,#ec4899)"><span class="ic"><i class="ri-shield-star-line"></i></span><div class="label">管理员</div><div class="value">${adminCount}</div></div>
</div>
<section class="glass panel rise">
    <form class="toolbar" method="get" action="${ctx}/admin/users.action">
        <div class="tabs">
            <a href="${ctx}/admin/users.action" class="${empty role ? 'active' : ''}">全部</a>
            <a href="${ctx}/admin/users.action?role=USER" class="${role eq 'USER' ? 'active' : ''}">用户</a>
            <a href="${ctx}/admin/users.action?role=AGENT" class="${role eq 'AGENT' ? 'active' : ''}">客服</a>
            <a href="${ctx}/admin/users.action?role=ADMIN" class="${role eq 'ADMIN' ? 'active' : ''}">管理员</a>
        </div>
        <c:if test="${not empty role}"><input type="hidden" name="role" value="<c:out value='${role}'/>"></c:if>
        <div class="input-icon" style="margin-left:auto"><i class="ri-search-2-line"></i><input class="input" name="q" value="<c:out value='${q}'/>" placeholder="账号 / 昵称 / 手机号"></div>
        <button class="btn" type="submit">搜索</button>
    </form>
    <div class="table-wrap">
        <table class="table">
            <thead><tr><th>用户</th><th>账号</th><th>角色</th><th>手机号</th><th>邮箱</th><th>在线</th><th>状态</th><th>注册时间</th><th class="right">操作</th></tr></thead>
            <tbody>
            <%-- OGNL：<s:iterator> 遍历 AdminUserAction.users；#session.loginUser 取当前登录的管理员，不能禁用自己 --%>
            <s:iterator value="users">
                <tr class="<s:if test="status != 1">row-off</s:if>">
                    <td><span class="flex items-center gap-8"><span class="avatar avatar-sm" style="background:<s:property value="avatarColor"/>"><s:property value="initial"/></span><span class="strong"><s:property value="nickname"/></span></span></td>
                    <td class="mono"><s:property value="username"/></td>
                    <td><span class="tag tag-role-<s:property value="role"/>"><s:property value="roleText"/></span></td>
                    <td><s:property value="phone == null || phone == '' ? '—' : phone"/></td>
                    <td><s:property value="email == null || email == '' ? '—' : email"/></td>
                    <td><span class="dot <s:property value="online == 1 ? 'dot-on' : 'dot-off'"/>"></span> <s:property value="online == 1 ? '在线' : '离线'"/></td>
                    <td><span class="pill status-pill <s:property value="status == 1 ? 'st-RESOLVED' : 'st-CLOSED'"/>"><s:property value="status == 1 ? '正常' : '已禁用'"/></span></td>
                    <td><s:property value="createTimeStr"/></td>
                    <td class="right" style="white-space:nowrap">
                        <s:if test="id != #session.loginUser.id">
                            <form class="inline" method="post" action="${ctx}/admin/user_toggle.action" data-confirm-submit="<s:property value="status == 1 ? '确定禁用该账号吗？禁用后无法登录' : '确定启用该账号吗？'"/>">
                                <input type="hidden" name="id" value="<s:property value="id"/>"><input type="hidden" name="filterRole" value="<s:property value="[1].role"/>">
                                <button class="btn btn-sm <s:property value="status == 1 ? 'btn-danger' : 'btn-success'"/>" type="submit"><s:property value="status == 1 ? '禁用' : '启用'"/></button>
                            </form>
                        </s:if>
                        <form class="inline" method="post" action="${ctx}/admin/user_reset.action" data-confirm-submit="确定将该账号密码重置为 123456 吗？">
                            <input type="hidden" name="id" value="<s:property value="id"/>"><input type="hidden" name="filterRole" value="<s:property value="[1].role"/>">
                            <button class="btn btn-sm" type="submit"><i class="ri-key-2-line"></i>重置密码</button>
                        </form>
                    </td>
                </tr>
            </s:iterator>
            </tbody>
        </table>
        <s:if test="users.isEmpty()"><div class="empty"><i class="ri-user-search-line"></i><p>没有找到用户</p></div></s:if>
    </div>
</section>

<dialog class="modal" id="userDlg">
    <form method="post" action="${ctx}/admin/user_add.action">
        <div class="modal-head"><span>新增账号</span><button class="icon-btn" data-close type="button"><i class="ri-close-line"></i></button></div>
        <div class="modal-body">
            <input type="hidden" name="filterRole" value="<c:out value='${role}'/>">
            <div class="row-2">
                <div class="field"><label>账号 *</label><input class="input" name="username" required pattern="[A-Za-z0-9_]{3,20}" title="3-20 位字母、数字或下划线"></div>
                <div class="field"><label>昵称</label><input class="input" name="nickname" maxlength="32"></div>
            </div>
            <div class="field"><label>角色 *</label>
                <select class="select" name="role"><option value="AGENT">客服</option><option value="USER">普通用户</option><option value="ADMIN">管理员</option></select>
            </div>
            <div class="row-2">
                <div class="field"><label>手机号</label><input class="input" name="phone" maxlength="20"></div>
                <div class="field"><label>邮箱</label><input class="input" type="email" name="email" maxlength="64"></div>
            </div>
            <p class="muted" style="font-size:12.5px"><i class="ri-information-line"></i> 初始密码为 123456，密码使用 BCrypt 加密存储</p>
        </div>
        <div class="modal-foot"><button class="btn" data-close type="button">取消</button><button class="btn btn-primary" type="submit"><i class="ri-check-line"></i>创建</button></div>
    </form>
</dialog>
<%@ include file="../common/foot.jspf" %>
