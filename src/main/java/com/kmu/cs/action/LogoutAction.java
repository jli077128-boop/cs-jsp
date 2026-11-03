package com.kmu.cs.action;

import org.apache.struts2.dispatcher.SessionMap;

/** 退出登录：让 session 失效后重定向（redirectAction）到登录页 */
public class LogoutAction extends BaseAction {
    @Override
    public String execute() {
        if (session instanceof SessionMap sm) sm.invalidate();
        return SUCCESS;
    }
}
