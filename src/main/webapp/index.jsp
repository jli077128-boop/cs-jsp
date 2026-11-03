<%@ page contentType="text/html;charset=UTF-8" pageEncoding="UTF-8" %>
<%@ taglib prefix="c" uri="http://java.sun.com/jsp/jstl/core" %>
<%-- 欢迎页：已登录按角色跳转首页，未登录跳转登录页 --%>
<c:choose>
    <c:when test="${sessionScope.loginUser.role eq 'ADMIN'}"><c:redirect url="/admin/dashboard.action"/></c:when>
    <c:when test="${sessionScope.loginUser.role eq 'AGENT'}"><c:redirect url="/agent/workbench.action"/></c:when>
    <c:when test="${not empty sessionScope.loginUser}"><c:redirect url="/user/home.action"/></c:when>
    <c:otherwise><c:redirect url="/login.action"/></c:otherwise>
</c:choose>
