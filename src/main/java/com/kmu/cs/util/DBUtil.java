package com.kmu.cs.util;

import org.apache.commons.dbcp2.BasicDataSource;
import org.apache.commons.dbcp2.BasicDataSourceFactory;

import java.io.InputStream;
import java.sql.Connection;
import java.sql.SQLException;
import java.util.Properties;

/**
 * 数据库工具类：读取 src/main/resources/dbcpconfig.properties，
 * 用 BasicDataSourceFactory.createDataSource(props) 创建 Apache Commons DBCP2 连接池（与课堂 02_strutsRegist 相同）。
 * 另外用 ThreadLocal 绑定连接实现简单的“手动事务”（beginTx / commit / rollback），
 * 同一个线程里的多个 DAO 调用会共用同一个连接，从而处于同一个事务中。
 */
public final class DBUtil {

    private static volatile BasicDataSource dataSource;
    private static final ThreadLocal<Connection> TX = new ThreadLocal<>();

    private DBUtil() {
    }

    /** 由 AppContextListener 在应用启动时调用；第一次取连接时也会懒加载 */
    public static synchronized void init() {
        if (dataSource != null) return;
        Properties p = new Properties();
        try (InputStream in = DBUtil.class.getClassLoader().getResourceAsStream("dbcpconfig.properties")) {
            if (in == null) throw new IllegalStateException("找不到 dbcpconfig.properties");
            p.load(new java.io.InputStreamReader(in, java.nio.charset.StandardCharsets.UTF_8));
        } catch (java.io.IOException e) {
            throw new IllegalStateException("读取 dbcpconfig.properties 失败", e);
        }
        try {
            // DBCP 工厂方法：按 properties 里的 driverClassName/url/username/password/initialSize/maxTotal... 创建连接池
            dataSource = BasicDataSourceFactory.createDataSource(p);
        } catch (Exception e) {
            // 数据库没启动时应用也能先起来，访问时再重试并报错
            dataSource = null;
            System.err.println("[智服 AI] DBCP 连接池初始化失败（请检查 MySQL 是否启动、dbcpconfig.properties 账号密码）：" + e.getMessage());
        }
    }

    private static BasicDataSource ds() throws SQLException {
        if (dataSource == null) init();
        if (dataSource == null) throw new SQLException("数据库连接失败，请检查 MySQL 是否启动以及 dbcpconfig.properties 中的账号密码");
        return dataSource;
    }

    /** 取连接：如果当前线程开启了事务，返回事务连接 */
    public static Connection getConnection() throws SQLException {
        Connection tx = TX.get();
        if (tx != null) return tx;
        return ds().getConnection();
    }

    /** 当前连接是否是事务连接（事务连接由 commit/rollback 负责关闭） */
    public static boolean inTx(Connection c) {
        return c != null && c == TX.get();
    }

    public static void beginTx() throws SQLException {
        Connection c = ds().getConnection();
        c.setAutoCommit(false);
        TX.set(c);
    }

    public static void commit() {
        Connection c = TX.get();
        if (c == null) return;
        try {
            c.commit();
        } catch (SQLException e) {
            throw new RuntimeException(e);
        } finally {
            closeTx(c);
        }
    }

    public static void rollback() {
        Connection c = TX.get();
        if (c == null) return;
        try {
            c.rollback();
        } catch (SQLException ignored) {
        } finally {
            closeTx(c);
        }
    }

    private static void closeTx(Connection c) {
        TX.remove();
        try {
            c.setAutoCommit(true);
            c.close();
        } catch (SQLException ignored) {
        }
    }

    public static synchronized void shutdown() {
        if (dataSource != null) {
            try {
                dataSource.close();
            } catch (SQLException ignored) {
            }
            dataSource = null;
        }
    }
}
