package com.kmu.cs.dao.impl;

import com.kmu.cs.dao.BaseDao;
import com.kmu.cs.dao.UserDao;
import com.kmu.cs.entity.SysUser;

import java.time.LocalDateTime;
import java.util.ArrayList;
import java.util.List;

public class UserDaoImpl extends BaseDao implements UserDao {

    private static final RowMapper<SysUser> MAPPER = rs -> {
        SysUser u = new SysUser();
        u.setId(rs.getLong("id"));
        u.setUsername(rs.getString("username"));
        u.setPassword(rs.getString("password"));
        u.setNickname(rs.getString("nickname"));
        u.setAvatar(rs.getString("avatar"));
        u.setAvatarColor(rs.getString("avatar_color"));
        u.setEmail(rs.getString("email"));
        u.setPhone(rs.getString("phone"));
        u.setRole(rs.getString("role"));
        u.setStatus(rs.getInt("status"));
        u.setOnline(rs.getInt("online"));
        u.setCreateTime(getTime(rs, "create_time"));
        return u;
    };

    @Override
    public SysUser findById(Long id) {
        return id == null ? null : queryOne("SELECT * FROM sys_user WHERE id = ?", MAPPER, id);
    }

    @Override
    public SysUser findByUsername(String username) {
        return queryOne("SELECT * FROM sys_user WHERE username = ?", MAPPER, username);
    }

    @Override
    public List<SysUser> list(String role, String keyword) {
        StringBuilder sql = new StringBuilder("SELECT * FROM sys_user WHERE 1=1");
        List<Object> args = new ArrayList<>();
        if (role != null && !role.isBlank()) {
            sql.append(" AND role = ?");
            args.add(role);
        }
        if (keyword != null && !keyword.isBlank()) {
            sql.append(" AND (username LIKE ? OR nickname LIKE ? OR phone LIKE ?)");
            String k = "%" + keyword + "%";
            args.add(k);
            args.add(k);
            args.add(k);
        }
        sql.append(" ORDER BY FIELD(role,'ADMIN','AGENT','USER'), id");
        return query(sql.toString(), MAPPER, args.toArray());
    }

    @Override
    public long insert(SysUser u) {
        return insert("INSERT INTO sys_user (username, password, nickname, avatar_color, email, phone, role, status, online, create_time) VALUES (?,?,?,?,?,?,?,1,0,?)",
                u.getUsername(), u.getPassword(), u.getNickname(), u.getAvatarColor(), u.getEmail(), u.getPhone(), u.getRole(), LocalDateTime.now());
    }

    @Override
    public void updateStatus(Long id, int status) {
        update("UPDATE sys_user SET status = ? WHERE id = ?", status, id);
    }

    @Override
    public void updatePassword(Long id, String hash) {
        update("UPDATE sys_user SET password = ? WHERE id = ?", hash, id);
    }

    @Override
    public void updateOnline(Long id, int online) {
        update("UPDATE sys_user SET online = ? WHERE id = ?", online, id);
    }

    @Override
    public long countByRole(String role) {
        return count("SELECT COUNT(*) FROM sys_user WHERE role = ?", role);
    }

    @Override
    public long countOnlineAgents() {
        return count("SELECT COUNT(*) FROM sys_user WHERE role = 'AGENT' AND online = 1");
    }
}
