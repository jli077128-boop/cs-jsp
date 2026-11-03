package com.kmu.cs.action;

import com.kmu.cs.entity.SysUser;
import com.kmu.cs.service.ServiceFactory;
import com.kmu.cs.util.BizException;
import com.kmu.cs.util.WebUtil;
import org.apache.struts2.dispatcher.SessionMap;

/**
 * 登录 Action —— 参数接收方式一：Action 属性直接接收（对应课堂 01_strutsParams/login.jsp）。
 * 表单字段 username / password / redirect 由 params 拦截器调用 setter 自动注入。
 *   GET  /login.action  → 没有账号参数，返回 input 显示登录页
 *   POST /login.action  → 校验账号密码，成功后按角色重定向（result type="redirect" + OGNL ${target}）
 */
public class LoginAction extends BaseAction {

    private String username;
    private String password;
    private String redirect;
    /** 登录成功后跳转的地址（struts.xml 里 &lt;result type="redirect"&gt;${target}&lt;/result&gt; 读取） */
    private String target;

    @Override
    public String execute() {
        SysUser cur = me();
        if (username == null) {
            if (cur != null) { // 已登录再打开登录页：直接回自己的首页
                target = WebUtil.homeOf(cur.getRole());
                return SUCCESS;
            }
            return INPUT;
        }
        try {
            SysUser u = ServiceFactory.USER.login(trim(username), password);
            // 防止会话固定攻击：登录成功后让旧 session 失效，再放入登录用户（SessionMap 会新建 session）
            if (session instanceof SessionMap sm) sm.invalidate();
            u.setPassword(null);
            session.put(WebUtil.LOGIN_USER, u);
            String prefix = WebUtil.namespaceOf(u.getRole());
            target = redirect != null && redirect.startsWith(prefix) && !redirect.contains("//") ? redirect : WebUtil.homeOf(u.getRole());
            return SUCCESS;
        } catch (BizException e) {
            addActionError(e.getMessage());
            return INPUT;
        }
    }

    public String getUsername() {
        return username;
    }

    public void setUsername(String username) {
        this.username = username;
    }

    /** 只给 &lt;s:password&gt; 标签读取用，永远返回 null：密码不回显 */
    public String getPassword() {
        return null;
    }

    public void setPassword(String password) {
        this.password = password;
    }

    public String getRedirect() {
        return redirect;
    }

    public void setRedirect(String redirect) {
        this.redirect = redirect;
    }

    /** 注册成功跳转过来时带的 ?u=账号，用于自动填入账号框 */
    public String getPrefill() {
        if (username != null) return username;
        return request == null ? null : request.getParameter("u");
    }

    public String getTarget() {
        return target;
    }
}
