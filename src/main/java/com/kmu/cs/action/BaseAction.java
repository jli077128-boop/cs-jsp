package com.kmu.cs.action;

import com.kmu.cs.entity.SysUser;
import com.kmu.cs.util.WebUtil;
import com.opensymphony.xwork2.ActionSupport;
import org.apache.struts2.action.ServletRequestAware;
import org.apache.struts2.action.SessionAware;

import javax.servlet.http.HttpServletRequest;
import java.util.Map;

/**
 * 所有 Action 的父类（继承 ActionSupport）：
 *   - 实现 SessionAware：Struts 通过 servletConfig 拦截器注入 session（Map 形式，不直接依赖 Servlet API）
 *   - 实现 ServletRequestAware：少数地方需要原生 request（取请求方式、登录前地址等）
 *   - 提供 me()（当前登录用户）和 flash()（重定向后显示一次的提示，PRG 模式）
 */
public abstract class BaseAction extends ActionSupport implements SessionAware, ServletRequestAware {

    /** 自定义结果名：无权访问 / 资源不存在（在 struts.xml 的 global-results 中配置） */
    public static final String FORBIDDEN = "forbidden";
    public static final String NOT_FOUND = "notfound";

    protected Map<String, Object> session;
    protected HttpServletRequest request;

    @Override
    public void withSession(Map<String, Object> session) {
        this.session = session;
    }

    @Override
    public void withServletRequest(HttpServletRequest request) {
        this.request = request;
    }

    /** 当前登录用户（AuthInterceptor 已保证受保护的 Action 里不为 null） */
    protected SysUser me() {
        return session == null ? null : (SysUser) session.get(WebUtil.LOGIN_USER);
    }

    protected void flash(String msg) {
        session.put("flash", msg);
    }

    protected void flashError(String msg) {
        session.put("flashError", msg);
    }

    /** 未登录时 AuthInterceptor 记下的原地址，供全局结果 login 拼到 ?redirect= 上 */
    public String getBackUrl() {
        // 拦截器在 servletConfig 之前执行，此时 request 字段还没注入，所以直接从 ServletActionContext 取
        HttpServletRequest req = org.apache.struts2.ServletActionContext.getRequest();
        Object v = req == null ? null : req.getAttribute("backUrl");
        return v == null ? null : v.toString();
    }

    protected static boolean blank(String s) {
        return s == null || s.isBlank();
    }

    protected static String trim(String s) {
        return s == null ? null : s.trim();
    }
}
