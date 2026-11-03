package com.kmu.cs.action;

import com.kmu.cs.entity.SysUser;
import com.kmu.cs.service.ServiceFactory;
import com.kmu.cs.util.BizException;

import java.util.List;

/**
 * 管理员用户管理。struts.xml 中：
 *   &lt;action name="users"  ...&gt;                           → execute() 列表
 *   &lt;action name="user_*" ... method="{1}"&gt; + allowed-methods add,toggle,reset（严格方法调用）
 *     /admin/user_add.action、/admin/user_toggle.action、/admin/user_reset.action
 */
public class AdminUserAction extends BaseAction {

    private String role;
    private String q;
    private String filterRole;
    private Long id;
    private String username;
    private String nickname;
    private String phone;
    private String email;

    private List<SysUser> users;
    private int total;
    private long userCount;
    private long agentCount;
    private long adminCount;

    @Override
    public String execute() {
        var all = ServiceFactory.USER.list(null, null);
        users = ServiceFactory.USER.list(blank(role) ? null : role, blank(q) ? null : q);
        total = all.size();
        userCount = all.stream().filter(u -> "USER".equals(u.getRole())).count();
        agentCount = all.stream().filter(u -> "AGENT".equals(u.getRole())).count();
        adminCount = all.stream().filter(u -> "ADMIN".equals(u.getRole())).count();
        return SUCCESS;
    }

    public String add() {
        return run(() -> {
            ServiceFactory.USER.add(trim(username), trim(nickname), trim(role), trim(phone), trim(email));
            return "已添加账号，初始密码 123456";
        });
    }

    public String toggle() {
        return run(() -> {
            ServiceFactory.USER.toggleStatus(id, me().getId());
            return "账号状态已更新";
        });
    }

    public String reset() {
        return run(() -> {
            ServiceFactory.USER.resetPassword(id);
            return "密码已重置为 123456";
        });
    }

    private String run(java.util.function.Supplier<String> body) {
        try {
            flash(body.get());
        } catch (BizException e) {
            flashError(e.getMessage());
        }
        return SUCCESS;
    }

    /** 操作完成后回到原来的角色标签 */
    public String getBackRole() {
        return filterRole != null && filterRole.matches("[A-Z]+") ? filterRole : null;
    }

    public String getRole() { return role; }
    public void setRole(String role) { this.role = trim(role); }
    public String getQ() { return q; }
    public void setQ(String q) { this.q = trim(q); }
    public void setFilterRole(String filterRole) { this.filterRole = trim(filterRole); }
    public void setId(Long id) { this.id = id; }
    public void setUsername(String username) { this.username = username; }
    public void setNickname(String nickname) { this.nickname = nickname; }
    public void setPhone(String phone) { this.phone = phone; }
    public void setEmail(String email) { this.email = email; }
    public List<SysUser> getUsers() { return users; }
    public int getTotal() { return total; }
    public long getUserCount() { return userCount; }
    public long getAgentCount() { return agentCount; }
    public long getAdminCount() { return adminCount; }
}
