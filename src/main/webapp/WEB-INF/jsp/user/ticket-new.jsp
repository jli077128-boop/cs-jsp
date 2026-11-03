<%@ page contentType="text/html;charset=UTF-8" pageEncoding="UTF-8" %>
<%@ taglib prefix="c" uri="http://java.sun.com/jsp/jstl/core" %>
<c:set var="pageTitle" value="提交工单"/>
<c:set var="nav" value="tickets"/>
<%@ include file="../common/head.jspf" %>
<%@ include file="../common/user-nav.jspf" %>
<main class="u-main">
    <div class="page-head">
        <div><h1>提交工单</h1><p>描述越详细，处理越快。提交后 AI 会自动分类并判断优先级</p></div>
        <s:a cssClass="btn" action="tickets" namespace="/user"><i class="ri-arrow-go-back-line"></i>返回我的工单</s:a>
    </div>
    <div class="detail-grid">
        <section class="glass-strong panel rise" style="padding:26px 28px">
            <s:if test="hasActionErrors()"><div class="alert alert-error"><i class="ri-error-warning-line"></i><s:actionerror theme="simple"/></div></s:if>
            <s:if test="fromSession != null">
                <div class="alert alert-ok"><i class="ri-chat-smile-3-line"></i>已关联 AI 对话「<s:property value="fromSession.title"/>」，客服可以直接查看聊天记录</div>
            </s:if>
            <%-- 参数接收方式三：ModelDriven<Ticket>。字段名直接写 title / content / category / priority / sessionId，
                 Struts 把它们注入到 TicketCreateAction.getModel() 返回的 Ticket 对象（值栈栈顶），回显时也从模型读取 --%>
            <s:form action="ticketSave" namespace="/user" method="post" theme="simple" id="ticketForm">
                <s:if test="fromSession != null"><s:hidden name="sessionId" value="%{fromSession.id}"/></s:if>
                <div class="field">
                    <label>问题标题 *</label>
                    <s:textfield name="title" cssClass="input" maxlength="100" required="required" placeholder="一句话概括您的问题，例如：退款一周还没到账"/>
                </div>
                <div class="field">
                    <label>详细描述</label>
                    <s:textarea name="content" cssClass="textarea" rows="6" maxlength="2000" placeholder="请描述问题发生的时间、订单号、已经尝试过的方法等"/>
                </div>
                <div class="row-2">
                    <div class="field">
                        <label>问题分类</label>
                        <%-- list 是 List<String>：选项的值和文字相同 --%>
                        <s:select name="category" list="categories" headerKey="" headerValue="让 AI 自动识别" cssClass="select"/>
                    </div>
                    <div class="field">
                        <label>紧急程度</label>
                        <%-- list 是 Map：key 作为 value，value 作为显示文字 --%>
                        <s:select name="priority" list="priorities" headerKey="" headerValue="让 AI 自动判断" cssClass="select"/>
                    </div>
                </div>
                <div class="flex gap-12 mt-8">
                    <button class="btn btn-primary btn-lg" type="submit"><i class="ri-send-plane-2-line"></i>提交工单</button>
                    <s:a cssClass="btn btn-lg" action="chat" namespace="/user">先问问 AI</s:a>
                </div>
            </s:form>
        </section>
        <aside class="glass panel rise rise-2">
            <div class="ai-box">
                <div class="t"><i class="ri-sparkling-2-fill"></i>AI 智能分单</div>
                <p class="text-2" style="font-size:13px">提交后系统会根据内容自动识别问题分类、判断优先级并生成摘要，紧急问题会被优先处理。</p>
            </div>
            <h3 class="section-title mt-24">处理流程</h3>
            <div class="timeline">
                <div class="tl-item a-CREATE"><span class="node"><i class="ri-edit-line"></i></span><div class="head"><b>提交工单</b></div><div class="body">填写问题并提交</div></div>
                <div class="tl-item a-AI"><span class="node"><i class="ri-sparkling-2-line"></i></span><div class="head"><b>AI 分析</b></div><div class="body">自动分类、判定优先级</div></div>
                <div class="tl-item a-ASSIGN"><span class="node"><i class="ri-user-received-line"></i></span><div class="head"><b>分配客服</b></div><div class="body">专属客服跟进处理</div></div>
                <div class="tl-item a-RESOLVE"><span class="node"><i class="ri-check-line"></i></span><div class="head"><b>解决关闭</b></div><div class="body">您确认后工单关闭</div></div>
            </div>
        </aside>
    </div>
</main>
<%@ include file="../common/foot.jspf" %>
