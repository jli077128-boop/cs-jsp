package com.kmu.cs.action;

import com.kmu.cs.entity.SysUser;
import com.kmu.cs.service.ServiceFactory;
import com.kmu.cs.util.BizException;

/**
 * 注册 Action —— 参数接收方式二：域模型（JavaBean）接收（对应课堂 01_strutsParams/login1.jsp、02_strutsRegist）。
 * 表单字段写成 user.username / user.password / user.nickname / user.phone，
 * Struts 先 new SysUser() 再调用 user 的 setter 赋值。
 *
 * 输入校验两种方式同时使用（对应 02_strutsRegist）：
 *   1) 声明式：同目录资源 RegisterAction-validation.xml（必填、正则、长度）
 *   2) 编程式：重写 validate()（两次密码是否一致、账号是否已被注册）
 * 有错误时 workflow 拦截器返回 input → register.jsp，用 &lt;s:fielderror&gt; / &lt;s:actionerror&gt; 显示。
 *   /registerForm.action → method="input"（不做校验，只显示表单）
 *   /register.action     → execute（先校验再注册）
 */
public class RegisterAction extends BaseAction {

    private SysUser user;
    private String confirm;

    @Override
    public void validate() {
        if (user == null) return;
        String pwd = user.getPassword();
        if (pwd != null && !pwd.isEmpty() && confirm != null && !confirm.isEmpty() && !pwd.equals(confirm)) {
            addFieldError("confirm", getText("register.confirm.mismatch"));
        }
        String name = trim(user.getUsername());
        if (name != null && name.matches("^[A-Za-z0-9_]{4,20}$") && !hasFieldErrors()
                && ServiceFactory.USER.list(null, name).stream().anyMatch(u -> name.equalsIgnoreCase(u.getUsername()))) {
            addFieldError("user.username", getText("register.username.exists"));
        }
    }

    @Override
    public String execute() {
        try {
            ServiceFactory.USER.register(trim(user.getUsername()), user.getPassword(), trim(user.getNickname()), trim(user.getPhone()));
            flash("注册成功，请登录");
            return SUCCESS;
        } catch (BizException e) {
            addActionError(e.getMessage());
            return INPUT;
        }
    }

    public SysUser getUser() {
        return user;
    }

    public void setUser(SysUser user) {
        this.user = user;
    }

    public String getConfirm() {
        return confirm;
    }

    public void setConfirm(String confirm) {
        this.confirm = confirm;
    }
}
