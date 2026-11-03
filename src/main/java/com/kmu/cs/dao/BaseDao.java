package com.kmu.cs.dao;

import com.kmu.cs.util.DBUtil;

import java.sql.Connection;
import java.sql.PreparedStatement;
import java.sql.ResultSet;
import java.sql.SQLException;
import java.sql.Statement;
import java.time.LocalDateTime;
import java.util.ArrayList;
import java.util.List;

/**
 * DAO 基类：封装 JDBC 的 PreparedStatement 模板代码（获取连接 → 设置参数 → 执行 → 映射结果 → 关闭资源）。
 * 所有 SQL 都用 ? 占位符，防止 SQL 注入。
 */
public abstract class BaseDao {

    /** 结果集一行 → 一个对象 */
    @FunctionalInterface
    public interface RowMapper<T> {
        T map(ResultSet rs) throws SQLException;
    }

    private void bind(PreparedStatement ps, Object... args) throws SQLException {
        for (int i = 0; i < args.length; i++) ps.setObject(i + 1, args[i]);
    }

    private void release(Connection c) {
        if (c != null && !DBUtil.inTx(c)) {
            try {
                c.close();
            } catch (SQLException ignored) {
            }
        }
    }

    protected <T> List<T> query(String sql, RowMapper<T> mapper, Object... args) {
        Connection c = null;
        try {
            c = DBUtil.getConnection();
            try (PreparedStatement ps = c.prepareStatement(sql)) {
                bind(ps, args);
                try (ResultSet rs = ps.executeQuery()) {
                    List<T> list = new ArrayList<>();
                    while (rs.next()) list.add(mapper.map(rs));
                    return list;
                }
            }
        } catch (SQLException e) {
            throw new RuntimeException("数据库查询失败：" + e.getMessage(), e);
        } finally {
            release(c);
        }
    }

    protected <T> T queryOne(String sql, RowMapper<T> mapper, Object... args) {
        List<T> list = query(sql, mapper, args);
        return list.isEmpty() ? null : list.get(0);
    }

    protected long count(String sql, Object... args) {
        Long v = queryOne(sql, rs -> rs.getLong(1), args);
        return v == null ? 0 : v;
    }

    protected int update(String sql, Object... args) {
        Connection c = null;
        try {
            c = DBUtil.getConnection();
            try (PreparedStatement ps = c.prepareStatement(sql)) {
                bind(ps, args);
                return ps.executeUpdate();
            }
        } catch (SQLException e) {
            throw new RuntimeException("数据库更新失败：" + e.getMessage(), e);
        } finally {
            release(c);
        }
    }

    /** 执行 INSERT 并返回自增主键 */
    protected long insert(String sql, Object... args) {
        Connection c = null;
        try {
            c = DBUtil.getConnection();
            try (PreparedStatement ps = c.prepareStatement(sql, Statement.RETURN_GENERATED_KEYS)) {
                bind(ps, args);
                ps.executeUpdate();
                try (ResultSet rs = ps.getGeneratedKeys()) {
                    return rs.next() ? rs.getLong(1) : 0;
                }
            }
        } catch (SQLException e) {
            throw new RuntimeException("数据库插入失败：" + e.getMessage(), e);
        } finally {
            release(c);
        }
    }

    // ---------- 结果集读取小工具（处理 NULL） ----------
    protected static Long getLong(ResultSet rs, String col) throws SQLException {
        long v = rs.getLong(col);
        return rs.wasNull() ? null : v;
    }

    protected static Integer getInt(ResultSet rs, String col) throws SQLException {
        int v = rs.getInt(col);
        return rs.wasNull() ? null : v;
    }

    protected static LocalDateTime getTime(ResultSet rs, String col) throws SQLException {
        return rs.getObject(col, LocalDateTime.class);
    }

    protected static boolean hasColumn(ResultSet rs, String col) throws SQLException {
        var md = rs.getMetaData();
        for (int i = 1; i <= md.getColumnCount(); i++) {
            if (col.equalsIgnoreCase(md.getColumnLabel(i))) return true;
        }
        return false;
    }
}
