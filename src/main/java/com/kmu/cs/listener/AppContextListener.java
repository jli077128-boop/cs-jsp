package com.kmu.cs.listener;

import com.kmu.cs.util.DBUtil;
import com.kmu.cs.util.LlmClient;
import javax.servlet.ServletContext;
import javax.servlet.ServletContextEvent;
import javax.servlet.ServletContextListener;
import javax.servlet.annotation.WebListener;

import java.sql.Driver;
import java.sql.DriverManager;
import java.util.Enumeration;

/** 应用启动 / 关闭监听器：启动时初始化连接池，关闭时释放连接池和 JDBC 驱动，避免 Tomcat 报内存泄漏警告 */
@WebListener
public class AppContextListener implements ServletContextListener {

    @Override
    public void contextInitialized(ServletContextEvent e) {
        ServletContext ctx = e.getServletContext();
        DBUtil.init();
        ctx.setAttribute("appName", "智服 AI");
        ctx.setAttribute("llmEnabled", LlmClient.enabled());
        ctx.setAttribute("onlineCount", 0);
        ctx.log("[智服 AI] 应用启动完成，连接池已初始化；大模型：" + (LlmClient.enabled() ? "已配置" : "未配置（使用知识库匹配）"));
    }

    @Override
    public void contextDestroyed(ServletContextEvent e) {
        DBUtil.shutdown();
        try {
            com.mysql.cj.jdbc.AbandonedConnectionCleanupThread.checkedShutdown();
        } catch (Throwable ignored) {
        }
        ClassLoader cl = Thread.currentThread().getContextClassLoader();
        Enumeration<Driver> drivers = DriverManager.getDrivers();
        while (drivers.hasMoreElements()) {
            Driver d = drivers.nextElement();
            if (d.getClass().getClassLoader() == cl) {
                try {
                    DriverManager.deregisterDriver(d);
                } catch (Exception ignored) {
                }
            }
        }
    }
}
