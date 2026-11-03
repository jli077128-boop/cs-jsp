<%@ page contentType="text/html;charset=UTF-8" pageEncoding="UTF-8" %>
<%@ taglib prefix="c" uri="http://java.sun.com/jsp/jstl/core" %>
<c:set var="pageTitle" value="登录"/>
<%@ include file="common/head.jspf" %>
<div class="login-wrap">
    <div class="login-card glass-strong rise">
        <section class="login-left">
            <div class="logo"><%@ include file="common/logo.jspf" %><span class="name">智服 <b>AI</b></span></div>
            <h2>AI 智能对话客服<br><span class="grad-text">与工单系统</span></h2>
            <p class="sub">7×24 小时智能应答 · 一键转人工 · 工单全流程追踪</p>
            <img class="mascot" src="${ctx}/static/img/mascot.svg" alt="智服 AI 吉祥物">
            <div class="features">
                <div><i class="ri-robot-2-line"></i>知识库 + 大模型应答</div>
                <div><i class="ri-customer-service-2-line"></i>WebSocket 实时人工</div>
                <div><i class="ri-coupon-3-line"></i>工单流转时间线</div>
                <div><i class="ri-bar-chart-box-line"></i>运营数据看板</div>
            </div>
        </section>
        <section class="login-right">
            <h3>欢迎回来 👋</h3>
            <p class="sub">登录后自动进入对应角色的工作台</p>
            <%-- Struts 标签：<s:actionerror> 显示 LoginAction.addActionError() 的提示 --%>
            <s:if test="hasActionErrors()">
                <div class="alert alert-error"><i class="ri-error-warning-line"></i><s:actionerror theme="simple"/></div>
            </s:if>
            <s:elseif test="#parameters.u.defined">
                <div class="alert alert-ok"><i class="ri-checkbox-circle-line"></i>注册成功，已为您填好账号「<s:property value="prefill"/>」，输入密码即可登录</div>
            </s:elseif>
            <%-- 参数接收方式一：表单字段 username / password / redirect 直接对应 LoginAction 的属性 --%>
            <s:form action="login" namespace="/" method="post" id="loginForm" theme="simple" autocomplete="on">
                <s:hidden name="redirect"/>
                <div class="field">
                    <label for="username">账号</label>
                    <div class="input-icon"><i class="ri-user-3-line"></i>
                        <s:textfield id="username" name="username" value="%{prefill}" cssClass="input" placeholder="请输入账号" required="required"/>
                    </div>
                </div>
                <div class="field">
                    <label for="password">密码</label>
                    <div class="input-icon" style="position:relative"><i class="ri-lock-2-line"></i>
                        <s:password id="password" name="password" cssClass="input" placeholder="请输入密码" required="required"/>
                        <span class="pwd-toggle" onclick="var p=document.getElementById('password');p.type=p.type==='password'?'text':'password'"><i class="ri-eye-line"></i></span>
                    </div>
                </div>
                <button class="btn btn-primary btn-lg btn-block" type="submit"><i class="ri-login-circle-line"></i>登 录</button>
            </s:form>
            <p class="center muted mt-16">还没有账号？<s:a cssClass="grad-text" cssStyle="font-weight:700" action="registerForm" namespace="/">立即注册</s:a></p>
            <div class="divider">演示账号一键填入（密码均为 123456）</div>
            <div class="role-pick">
                <button type="button" data-u="user01"><i class="ri-user-smile-line"></i>普通用户<small>user01</small></button>
                <button type="button" data-u="agent01"><i class="ri-customer-service-2-line"></i>人工客服<small>agent01</small></button>
                <button type="button" data-u="admin"><i class="ri-shield-star-line"></i>管理员<small>admin</small></button>
            </div>
        </section>
    </div>
</div>
<script>
    document.querySelectorAll('.role-pick button').forEach(function (b) {
        b.addEventListener('click', function () {
            document.getElementById('username').value = b.dataset.u;
            document.getElementById('password').value = '123456';
            document.getElementById('loginForm').requestSubmit();
        });
    });
</script>
<%@ include file="common/foot.jspf" %>
