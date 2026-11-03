package com.kmu.cs.interceptor;

import com.kmu.cs.entity.SysUser;
import com.kmu.cs.util.JsonUtil;
import com.kmu.cs.util.WebUtil;
import com.opensymphony.xwork2.Action;
import com.opensymphony.xwork2.ActionInvocation;
import com.opensymphony.xwork2.interceptor.AbstractInterceptor;
import org.apache.struts2.ServletActionContext;

import javax.servlet.http.HttpServletRequest;
import javax.servlet.http.HttpServletResponse;
import java.util.Arrays;
import java.util.Map;

/**
 * 登录 + 角色校验拦截器（取代原来的 LoginFilter）。
 * 在 struts.xml 中与 defaultStack 组成 userStack / agentStack / adminStack / loginStack，
 * 通过 &lt;param name="role"&gt; 指定允许的角色：USER、AGENT、ADMIN，或 ANY（登录即可）。
 *   - 未登录：页面请求返回全局结果 login（重定向到登录页并带上 redirect）；接口请求直接输出 401 JSON
 *   - 角色不符：页面请求返回全局结果 forbidden（403 页面）；接口请求输出 403 JSON
 */
public class AuthInterceptor extends AbstractInterceptor {

    private String role = "ANY";

    public void setRole(String role) {
        this.role = role;
    }

    @Override
    public String intercept(ActionInvocation invocation) throws Exception {
        Map<String, Object> session = invocation.getInvocationContext().getSession();
        SysUser me = session == null ? null : (SysUser) session.get(WebUtil.LOGIN_USER);
        HttpServletRequest req = ServletActionContext.getRequest();
        HttpServletResponse resp = ServletActionContext.getResponse();
        boolean api = invocation.getProxy().getNamespace().startsWith("/api/");

        if (me == null) {
            if (api) {
                JsonUtil.write(resp, 401, "登录已过期，请重新登录", null);
                return Action.NONE;
            }
            if ("GET".equalsIgnoreCase(req.getMethod())) {
                String back = req.getRequestURI().substring(req.getContextPath().length())
                        + (req.getQueryString() == null ? "" : "?" + req.getQueryString());
                req.setAttribute("backUrl", back);
            }
            return Action.LOGIN;
        }
        if (!"ANY".equals(role) && Arrays.stream(role.split(",")).map(String::trim).noneMatch(r -> r.equals(me.getRole()))) {
            if (api) {
                JsonUtil.write(resp, 403, "无权访问", null);
                return Action.NONE;
            }
            resp.setStatus(HttpServletResponse.SC_FORBIDDEN);
            return "forbidden";
        }
        // 页面不缓存，防止退出后按“后退”还能看到页面
        if (!api) resp.setHeader("Cache-Control", "no-store");
        return invocation.invoke();
    }
}
