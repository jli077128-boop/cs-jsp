package com.kmu.cs.service;

import com.kmu.cs.entity.SysUser;

import java.util.List;

public interface UserService {
    /** 登录成功返回用户；失败抛 BizException */
    SysUser login(String username, String password);

    SysUser register(String username, String password, String nickname, String phone);

    SysUser findById(Long id);

    List<SysUser> list(String role, String keyword);

    void add(String username, String nickname, String role, String phone, String email);

    void toggleStatus(Long id, Long operatorId);

    /** 重置为 123456 */
    void resetPassword(Long id);

    void setOnline(Long id, boolean online);
}
