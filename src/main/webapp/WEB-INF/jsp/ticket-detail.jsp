<%@ page contentType="text/html;charset=UTF-8" pageEncoding="UTF-8" %>
<%@ taglib prefix="c" uri="http://java.sun.com/jsp/jstl/core" %>
<%-- 工单详情：用户 / 客服 / 管理员共用，按角色切换布局和操作区 --%>
<c:set var="pageTitle" value="工单 ${t.ticketNo}"/>
<c:set var="nav" value="tickets"/>
<%@ include file="common/head.jspf" %>
<c:choose>
    <c:when test="${me.role eq 'USER'}"><%@ include file="common/user-nav.jspf" %><main class="u-main"></c:when>
    <c:otherwise><%@ include file="common/side-nav.jspf" %></c:otherwise>
</c:choose>
<c:set var="backUrl" value="${me.role eq 'USER' ? '/user/tickets.action' : (me.role eq 'ADMIN' ? '/admin/tickets.action' : '/agent/tickets.action')}"/>

<div class="page-head">
    <div>
        <a class="muted" href="${ctx}${backUrl}" style="font-size:13px"><i class="ri-arrow-left-line"></i> 返回工单列表</a>
        <h1 class="mt-8"><c:out value="${t.title}"/></h1>
        <div class="flex items-center gap-12 wrap mt-8">
            <span class="mono" style="color:#c4b5fd;font-family:ui-monospace,Menlo,Consolas,monospace">${t.ticketNo}</span>
            <span class="pill status-pill st-${t.status}">${t.statusText}</span>
            <span class="pr pr-${t.priority}">${t.priorityText}优先级</span>
            <span class="tag"><c:out value="${t.category}"/></span>
        </div>
    </div>
</div>

<!-- 进度步骤条 -->
<div class="glass panel rise mb-16">
    <div class="steps">
        <div class="step done"><span class="c"><i class="ri-edit-line"></i></span>已提交</div>
        <div class="step ${t.status ne 'PENDING' ? 'done' : ''}"><span class="c"><i class="ri-loader-4-line"></i></span>处理中</div>
        <div class="step ${t.status eq 'RESOLVED' or t.status eq 'CLOSED' ? 'done' : ''}"><span class="c"><i class="ri-check-line"></i></span>已解决</div>
        <div class="step ${t.status eq 'CLOSED' ? 'done' : ''}"><span class="c"><i class="ri-lock-line"></i></span>已关闭</div>
    </div>
</div>

<div class="detail-grid">
    <div>
        <section class="glass panel rise">
            <h3 class="section-title">问题描述</h3>
            <p class="text-2" style="white-space:pre-wrap;line-height:1.8"><c:out value="${empty t.content ? '（用户未填写详细描述）' : t.content}"/></p>
            <c:if test="${not empty t.aiSummary}">
                <div class="ai-box mt-16">
                    <div class="t"><i class="ri-sparkling-2-fill"></i>AI 摘要</div>
                    <p class="text-2" style="font-size:13.5px"><c:out value="${t.aiSummary}"/></p>
                    <div class="flex gap-6 wrap mt-8"><c:forEach items="${t.tagList}" var="tag"><span class="tag"><c:out value="${tag}"/></span></c:forEach></div>
                </div>
            </c:if>
        </section>

        <section class="glass panel rise rise-1">
            <h3 class="section-title">处理进度</h3>
            <div class="timeline">
                <c:forEach items="${records}" var="r">
                    <div class="tl-item a-${r.action}">
                        <span class="node">
                            <c:choose>
                                <c:when test="${r.action eq 'CREATE'}"><i class="ri-edit-line"></i></c:when>
                                <c:when test="${r.action eq 'AI'}"><i class="ri-sparkling-2-line"></i></c:when>
                                <c:when test="${r.action eq 'ASSIGN'}"><i class="ri-user-received-line"></i></c:when>
                                <c:when test="${r.action eq 'RESOLVE'}"><i class="ri-check-line"></i></c:when>
                                <c:when test="${r.action eq 'CLOSE'}"><i class="ri-lock-line"></i></c:when>
                                <c:otherwise><i class="ri-tools-line"></i></c:otherwise>
                            </c:choose>
                        </span>
                        <div class="head"><b>${r.actionText}</b><small><c:out value="${r.operatorName}"/> · ${r.createTimeStr}</small></div>
                        <div class="body"><c:out value="${r.content}"/></div>
                    </div>
                </c:forEach>
            </div>
        </section>

        <c:if test="${not empty sessionMessages}">
            <section class="glass panel rise rise-2">
                <h3 class="section-title">来源会话记录</h3>
                <div class="chat-body" style="max-height:360px;padding:6px 4px">
                    <c:forEach items="${sessionMessages}" var="m">
                        <div class="msg ${m.senderType eq 'USER' ? 'right' : 'left'} ${m.senderType eq 'AGENT' ? 'agent' : ''}">
                            <c:choose>
                                <c:when test="${m.senderType eq 'USER'}"><span class="avatar avatar-sm" style="background:${t.userColor}"><c:out value="${empty t.userName ? '?' : t.userName.substring(0,1)}"/></span></c:when>
                                <c:when test="${m.senderType eq 'AGENT'}"><span class="avatar avatar-sm agent-avatar"><i class="ri-customer-service-2-fill"></i></span></c:when>
                                <c:otherwise><span class="bot-avatar" style="width:28px;height:28px"><img src="${ctx}/static/img/bot.svg" alt=""></span></c:otherwise>
                            </c:choose>
                            <div><div class="bubble md" style="font-size:13px">${m.contentHtml}</div><div class="time">${m.time}</div></div>
                        </div>
                    </c:forEach>
                </div>
            </section>
        </c:if>
    </div>

    <aside>
        <section class="glass panel rise">
            <h3 class="section-title">工单信息</h3>
            <dl class="kv">
                <dt>工单编号</dt><dd class="mono">${t.ticketNo}</dd>
                <dt>提交人</dt><dd><span class="flex items-center gap-8"><span class="avatar avatar-sm" style="background:${t.userColor}"><c:out value="${empty t.userName ? '?' : t.userName.substring(0,1)}"/></span><c:out value="${t.userName}"/></span></dd>
                <dt>处理客服</dt><dd><c:out value="${empty t.assigneeName ? '待分配' : t.assigneeName}"/></dd>
                <dt>问题分类</dt><dd><c:out value="${t.category}"/></dd>
                <dt>优先级</dt><dd><span class="pr pr-${t.priority}">${t.priorityText}</span></dd>
                <dt>当前状态</dt><dd><span class="pill status-pill st-${t.status}">${t.statusText}</span></dd>
                <dt>提交时间</dt><dd>${t.createTimeStr}</dd>
                <dt>最近更新</dt><dd>${t.updateTimeStr}</dd>
                <c:if test="${not empty t.sessionId}"><dt>来源</dt><dd>AI 对话 #${t.sessionId}</dd></c:if>
            </dl>
        </section>

        <c:choose>
            <%-- 用户：已解决时可以确认关闭 --%>
            <c:when test="${me.role eq 'USER'}">
                <section class="glass panel rise rise-1">
                    <c:choose>
                        <c:when test="${t.status eq 'RESOLVED'}">
                            <h3 class="section-title">确认解决</h3>
                            <p class="muted" style="font-size:13px">客服已标记为已解决，如果问题确实解决了，请确认关闭工单。</p>
                            <form method="post" action="${ctx}/ticket/update.action" class="mt-12">
                                <input type="hidden" name="id" value="${t.id}"><input type="hidden" name="op" value="status"><input type="hidden" name="status" value="CLOSED">
                                <div class="field"><input class="input" name="remark" maxlength="200" placeholder="说点什么（选填）" value="用户确认问题已解决"></div>
                                <button class="btn btn-primary btn-block" type="submit"><i class="ri-check-double-line"></i>确认已解决并关闭</button>
                            </form>
                        </c:when>
                        <c:when test="${t.status eq 'CLOSED'}">
                            <div class="empty" style="padding:20px"><i class="ri-checkbox-circle-line"></i><p>工单已关闭，感谢您的耐心</p></div>
                        </c:when>
                        <c:otherwise>
                            <h3 class="section-title">需要帮助？</h3>
                            <p class="muted" style="font-size:13px">客服正在处理中，着急的话可以直接联系人工客服。</p>
                            <a class="btn btn-primary btn-block mt-12" href="${ctx}/user/chat.action"><i class="ri-customer-service-2-line"></i>联系客服</a>
                        </c:otherwise>
                    </c:choose>
                </section>
            </c:when>
            <%-- 客服 / 管理员：处理工单 --%>
            <c:otherwise>
                <c:if test="${me.role eq 'ADMIN'}">
                    <section class="glass panel rise rise-1">
                        <h3 class="section-title">分配客服</h3>
                        <form method="post" action="${ctx}/ticket/update.action" class="flex gap-8">
                            <input type="hidden" name="id" value="${t.id}"><input type="hidden" name="op" value="assign">
                            <select class="select flex-1" name="agentId" required>
                                <c:forEach items="${agents}" var="a"><option value="${a.id}" ${a.id eq t.assigneeId ? 'selected' : ''} ${a.status ne 1 ? 'disabled' : ''}><c:out value="${a.nickname}"/>${a.online eq 1 ? '（在线）' : ''}${a.status ne 1 ? '（已禁用）' : ''}</option></c:forEach>
                            </select>
                            <button class="btn btn-primary" type="submit">分配</button>
                        </form>
                    </section>
                </c:if>
                <section class="glass panel rise rise-2">
                    <h3 class="section-title">处理工单</h3>
                    <form method="post" action="${ctx}/ticket/update.action">
                        <input type="hidden" name="id" value="${t.id}"><input type="hidden" name="op" value="status">
                        <div class="field">
                            <label>变更状态</label>
                            <select class="select" name="status">
                                <c:forEach items="${statusMap}" var="e"><option value="${e.key}" ${e.key eq t.status ? 'selected' : ''}>${e.value}</option></c:forEach>
                            </select>
                        </div>
                        <div class="field">
                            <label>处理说明</label>
                            <textarea class="textarea" name="remark" rows="3" maxlength="255" placeholder="例如：已联系支付渠道核查，预计 24 小时内到账"></textarea>
                        </div>
                        <button class="btn btn-primary btn-block" type="submit"><i class="ri-save-3-line"></i>保存处理结果</button>
                    </form>
                    <form method="post" action="${ctx}/ticket/update.action" class="mt-16">
                        <input type="hidden" name="id" value="${t.id}"><input type="hidden" name="op" value="note">
                        <div class="field"><label>仅添加处理备注</label><input class="input" name="remark" maxlength="255" required placeholder="记录跟进情况，不改变状态"></div>
                        <button class="btn btn-block" type="submit"><i class="ri-chat-new-line"></i>添加备注</button>
                    </form>
                </section>
            </c:otherwise>
        </c:choose>
    </aside>
</div>
<c:if test="${me.role eq 'USER'}"></main></c:if>
<%@ include file="common/foot.jspf" %>
