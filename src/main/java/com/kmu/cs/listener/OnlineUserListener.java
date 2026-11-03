package com.kmu.cs.listener;

import com.kmu.cs.entity.SysUser;
import com.kmu.cs.service.ServiceFactory;
import com.kmu.cs.util.WebUtil;
import javax.servlet.ServletContext;
import javax.servlet.annotation.WebListener;
import javax.servlet.http.HttpSessionAttributeListener;
import javax.servlet.http.HttpSessionBindingEvent;
import javax.servlet.http.HttpSessionEvent;
import javax.servlet.http.HttpSessionListener;

import java.util.concurrent.atomic.AtomicInteger;

/**
 * 在线用户监听器：
 *   登录（session 放入 loginUser）→ 在线人数 +1，客服标记为在线
 *   退出 / session 超时销毁       → 在线人数 -1，客服标记为离线
 */
@WebListener
public class OnlineUserListener implements HttpSessionListener, HttpSessionAttributeListener {

    private static final AtomicInteger ONLINE = new AtomicInteger();

    public static int onlineCount() {
        return ONLINE.get();
    }

    @Override
    public void attributeAdded(HttpSessionBindingEvent e) {
        if (WebUtil.LOGIN_USER.equals(e.getName()) && e.getValue() instanceof SysUser u) {
            update(e.getSession().getServletContext(), ONLINE.incrementAndGet());
            if ("AGENT".equals(u.getRole())) ServiceFactory.USER.setOnline(u.getId(), true);
        }
    }

    @Override
    public void attributeRemoved(HttpSessionBindingEvent e) {
        if (WebUtil.LOGIN_USER.equals(e.getName()) && e.getValue() instanceof SysUser u) {
            update(e.getSession().getServletContext(), Math.max(0, ONLINE.decrementAndGet()));
            if ("AGENT".equals(u.getRole())) ServiceFactory.USER.setOnline(u.getId(), false);
        }
    }

    @Override
    public void sessionDestroyed(HttpSessionEvent e) {
        // session.invalidate() 时会先触发 attributeRemoved，这里无需重复处理
    }

    private void update(ServletContext ctx, int n) {
        ctx.setAttribute("onlineCount", n);
    }
}
