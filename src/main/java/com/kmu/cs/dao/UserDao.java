package com.kmu.cs.dao;

import com.kmu.cs.entity.SysUser;

import java.util.List;

public interface UserDao {
    SysUser findById(Long id);

    SysUser findByUsername(String username);

    List<SysUser> list(String role, String keyword);

    long insert(SysUser u);

    void updateStatus(Long id, int status);

    void updatePassword(Long id, String hash);

    void updateOnline(Long id, int online);

    long countByRole(String role);

    long countOnlineAgents();
}
