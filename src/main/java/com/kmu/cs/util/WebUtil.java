package com.kmu.cs.util;

import com.kmu.cs.entity.SysUser;
import javax.servlet.http.HttpServletRequest;

/** Web 层常用的小工具：登录用户在 session 中的 key、按角色的首页 */
public final class WebUtil {
    /** session 中保存登录用户的 key（JSP 里用 #session.loginUser / ${sessionScope.loginUser} 读取） */
    public static final String LOGIN_USER = "loginUser";

    private WebUtil() {
    }

    public static SysUser me(HttpServletRequest req) {
        var s = req.getSession(false);
        return s == null ? null : (SysUser) s.getAttribute(LOGIN_USER);
    }

    /** 按角色返回登录后的首页（Struts Action 地址，不含 contextPath） */
    public static String homeOf(String role) {
        return switch (role == null ? "" : role) {
            case "ADMIN" -> "/admin/dashboard.action";
            case "AGENT" -> "/agent/workbench.action";
            default -> "/user/home.action";
        };
    }

    /** 角色对应的命名空间前缀（登录后只允许跳回本角色命名空间下的地址） */
    public static String namespaceOf(String role) {
        return switch (role == null ? "" : role) {
            case "ADMIN" -> "/admin/";
            case "AGENT" -> "/agent/";
            default -> "/user/";
        };
    }
}
