<%@ page contentType="text/html;charset=UTF-8" pageEncoding="UTF-8" isErrorPage="true" %>
<%@ taglib prefix="c" uri="http://java.sun.com/jsp/jstl/core" %>
<c:set var="pageTitle" value="请求参数有误"/>
<%@ include file="../common/head.jspf" %>
<div class="err-page">
    <div class="glass-strong rise" style="padding:46px 56px;max-width:520px">
        <img src="${ctx}/static/img/mascot.svg" alt="" style="width:130px;animation:float 5s ease-in-out infinite">
        <div class="code grad-text">400</div>
        <p class="text-2 mt-8">请求参数格式不正确，请返回上一页检查后重试～</p>
        <div class="flex gap-12 mt-24" style="justify-content:center">
            <a class="btn btn-primary" href="${ctx}/"><i class="ri-home-5-line"></i>返回首页</a>
            <a class="btn" href="javascript:history.back()"><i class="ri-arrow-go-back-line"></i>返回上一页</a>
        </div>
    </div>
</div>
<%@ include file="../common/foot.jspf" %>
