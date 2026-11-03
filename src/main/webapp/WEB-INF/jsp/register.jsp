<%@ page contentType="text/html;charset=UTF-8" pageEncoding="UTF-8" %>
<%@ taglib prefix="c" uri="http://java.sun.com/jsp/jstl/core" %>
<c:set var="pageTitle" value="注册"/>
<%@ include file="common/head.jspf" %>
<div class="login-wrap">
    <div class="login-card glass-strong rise">
        <section class="login-left">
            <div class="logo"><%@ include file="common/logo.jspf" %><span class="name">智服 <b>AI</b></span></div>
            <h2>注册账号<br><span class="grad-text">开启智能服务</span></h2>
            <p class="sub">注册后即可使用 AI 客服、提交工单并实时跟踪处理进度</p>
            <img class="mascot" src="${ctx}/static/img/mascot.svg" alt="">
            <div class="features">
                <div><i class="ri-flashlight-line"></i>秒级智能回复</div>
                <div><i class="ri-shield-check-line"></i>BCrypt 加密存储</div>
                <div><i class="ri-time-line"></i>工单进度实时可见</div>
                <div><i class="ri-star-smile-line"></i>服务满意度评价</div>
            </div>
        </section>
        <section class="login-right">
            <h3>创建新账号</h3>
            <p class="sub">客服与管理员账号由管理员在后台添加</p>
            <%-- 输入校验结果：<s:actionerror> 显示业务错误；每个字段下方 <s:fielderror fieldName="..."> 显示该字段的错误
                 （来自 RegisterAction-validation.xml 声明式校验 + RegisterAction.validate() 编程式校验） --%>
            <s:if test="hasActionErrors()">
                <div class="alert alert-error"><i class="ri-error-warning-line"></i><s:actionerror theme="simple"/></div>
            </s:if>
            <s:elseif test="hasFieldErrors()">
                <div class="alert alert-error"><i class="ri-error-warning-line"></i>填写的信息有误，请按提示修改（共 <s:property value="fieldErrors.size()"/> 处）</div>
            </s:elseif>
            <%-- 参数接收方式二：域模型 user.xxx；novalidate 关闭浏览器自带校验，演示服务端 Struts 校验 --%>
            <s:form action="register" namespace="/" method="post" theme="simple" novalidate="novalidate" id="registerForm">
                <div class="row-2">
                    <div class="field"><label>账号 *</label><s:textfield name="user.username" cssClass="input" placeholder="4-20 位字母数字" maxlength="20"/><s:fielderror fieldName="user.username" theme="simple"/></div>
                    <div class="field"><label>昵称</label><s:textfield name="user.nickname" cssClass="input" placeholder="怎么称呼您" maxlength="16"/><s:fielderror fieldName="user.nickname" theme="simple"/></div>
                </div>
                <div class="field"><label>手机号</label><s:textfield name="user.phone" cssClass="input" placeholder="选填，11 位手机号" maxlength="20"/><s:fielderror fieldName="user.phone" theme="simple"/></div>
                <div class="row-2">
                    <div class="field"><label>密码 *</label><s:password name="user.password" cssClass="input" placeholder="至少 6 位"/><s:fielderror fieldName="user.password" theme="simple"/></div>
                    <div class="field"><label>确认密码 *</label><s:password name="confirm" cssClass="input" placeholder="再输一次"/><s:fielderror fieldName="confirm" theme="simple"/></div>
                </div>
                <button class="btn btn-primary btn-lg btn-block" type="submit"><i class="ri-user-add-line"></i>注 册</button>
            </s:form>
            <p class="center muted mt-16">已有账号？<s:a cssClass="grad-text" cssStyle="font-weight:700" action="login" namespace="/">返回登录</s:a></p>
        </section>
    </div>
</div>
<%@ include file="common/foot.jspf" %>
