package com.kmu.cs.entity;

import com.kmu.cs.util.Dict;
import com.kmu.cs.util.Md;
import com.kmu.cs.util.TimeFmt;

import java.time.LocalDateTime;

/** 用户（用户 / 客服 / 管理员 三种角色共用 sys_user 表） */
public class SysUser {

    private Long id;
    private String username;
    private String password;
    private String nickname;
    private String avatar;
    private String avatarColor;
    private String email;
    private String phone;
    private String role;
    private Integer status;
    private Integer online;
    private LocalDateTime createTime;

    public Long getId() { return id; }
    public void setId(Long id) { this.id = id; }
    public String getUsername() { return username; }
    public void setUsername(String username) { this.username = username; }
    public String getPassword() { return password; }
    public void setPassword(String password) { this.password = password; }
    public String getNickname() { return nickname; }
    public void setNickname(String nickname) { this.nickname = nickname; }
    public String getAvatar() { return avatar; }
    public void setAvatar(String avatar) { this.avatar = avatar; }
    public String getAvatarColor() { return avatarColor; }
    public void setAvatarColor(String avatarColor) { this.avatarColor = avatarColor; }
    public String getEmail() { return email; }
    public void setEmail(String email) { this.email = email; }
    public String getPhone() { return phone; }
    public void setPhone(String phone) { this.phone = phone; }
    public String getRole() { return role; }
    public void setRole(String role) { this.role = role; }
    public Integer getStatus() { return status; }
    public void setStatus(Integer status) { this.status = status; }
    public Integer getOnline() { return online; }
    public void setOnline(Integer online) { this.online = online; }
    public LocalDateTime getCreateTime() { return createTime; }
    public void setCreateTime(LocalDateTime createTime) { this.createTime = createTime; }

    /** 角色中文名，JSP 中用 ${u.roleText} */
    public String getRoleText() {
        return switch (role == null ? "" : role) { case "ADMIN" -> "管理员"; case "AGENT" -> "客服"; default -> "用户"; };
    }
    /** 头像上显示的首字 */
    public String getInitial() { return nickname == null || nickname.isEmpty() ? "?" : nickname.substring(0, 1); }
    public String getCreateTimeStr() { return TimeFmt.full(createTime); }

}
