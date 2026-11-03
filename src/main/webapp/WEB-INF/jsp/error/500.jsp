<%@ page contentType="text/html;charset=UTF-8" pageEncoding="UTF-8" isErrorPage="true" %>
<%@ taglib prefix="c" uri="http://java.sun.com/jsp/jstl/core" %>
<c:set var="pageTitle" value="服务器开小差了"/>
<%@ include file="../common/head.jspf" %>
<div class="err-page">
    <div class="glass-strong rise" style="padding:46px 56px;max-width:620px">
        <img src="${ctx}/static/img/mascot.svg" alt="" style="width:130px;animation:float 5s ease-in-out infinite">
        <div class="code grad-text">500</div>
        <p class="text-2 mt-8">服务器开小差了，请稍后再试。</p>
        <%-- Tomcat 错误页转发时异常在 javax.servlet.error.exception；Struts 全局异常映射时异常在值栈的 exception 属性 --%>
        <c:set var="err" value="${not empty requestScope['javax.servlet.error.exception'] ? requestScope['javax.servlet.error.exception'] : exception}"/>
        <c:if test="${not empty err}">
            <p class="muted mt-8" style="font-size:12.5px;word-break:break-all"><c:out value="${err.message}"/></p>
        </c:if>
        <p class="muted" style="font-size:12px;margin-top:6px">常见原因：MySQL 未启动，或 dbcpconfig.properties 中的账号密码不正确。</p>
        <div class="flex gap-12 mt-24" style="justify-content:center">
            <a class="btn btn-primary" href="${ctx}/"><i class="ri-home-5-line"></i>返回首页</a>
        </div>
    </div>
</div>
<%@ include file="../common/foot.jspf" %>
