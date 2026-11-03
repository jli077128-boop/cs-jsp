package com.kmu.cs.service.impl;

import com.kmu.cs.dao.UserDao;
import com.kmu.cs.dao.impl.UserDaoImpl;
import com.kmu.cs.entity.SysUser;
import com.kmu.cs.service.UserService;
import com.kmu.cs.util.BizException;
import org.mindrot.jbcrypt.BCrypt;

import java.util.List;

public class UserServiceImpl implements UserService {

    private static final String[] COLORS = {"#60a5fa", "#34d399", "#f97316", "#e879f9", "#a3e635", "#38bdf8", "#f472b6", "#fbbf24", "#8b5cf6"};
    private final UserDao userDao = new UserDaoImpl();

    @Override
    public SysUser login(String username, String password) {
        if (username == null || username.isBlank() || password == null || password.isEmpty()) throw new BizException("请输入账号和密码");
        SysUser u = userDao.findByUsername(username.trim());
        // BCrypt.checkpw 兼容现代版生成的 $2a$10$ 密文
        if (u == null || !BCrypt.checkpw(password, u.getPassword())) throw new BizException("账号或密码错误");
        if (u.getStatus() == null || u.getStatus() != 1) throw new BizException("账号已被禁用，请联系管理员");
        return u;
    }

    @Override
    public SysUser register(String username, String password, String nickname, String phone) {
        if (username == null || !username.matches("^[A-Za-z0-9_]{4,20}$")) throw new BizException("账号需为 4-20 位字母、数字或下划线");
        if (password == null || password.length() < 6) throw new BizException("密码至少 6 位");
        if (userDao.findByUsername(username) != null) throw new BizException("该账号已被注册");
        SysUser u = new SysUser();
        u.setUsername(username);
        u.setPassword(BCrypt.hashpw(password, BCrypt.gensalt(10)));
        u.setNickname(nickname == null || nickname.isBlank() ? username : nickname.trim());
        u.setPhone(phone);
        u.setRole("USER");
        u.setAvatarColor(COLORS[Math.abs(username.hashCode()) % COLORS.length]);
        long id = userDao.insert(u);
        return userDao.findById(id);
    }

    @Override
    public SysUser findById(Long id) {
        return userDao.findById(id);
    }

    @Override
    public List<SysUser> list(String role, String keyword) {
        return userDao.list(role, keyword);
    }

    @Override
    public void add(String username, String nickname, String role, String phone, String email) {
        if (username == null || !username.matches("^[A-Za-z0-9_]{3,20}$")) throw new BizException("账号需为 3-20 位字母、数字或下划线");
        if (!"USER".equals(role) && !"AGENT".equals(role) && !"ADMIN".equals(role)) throw new BizException("角色不正确");
        if (userDao.findByUsername(username) != null) throw new BizException("账号已存在");
        SysUser u = new SysUser();
        u.setUsername(username);
        u.setPassword(BCrypt.hashpw("123456", BCrypt.gensalt(10)));
        u.setNickname(nickname == null || nickname.isBlank() ? username : nickname);
        u.setRole(role);
        u.setPhone(phone);
        u.setEmail(email);
        u.setAvatarColor(COLORS[Math.abs(username.hashCode()) % COLORS.length]);
        userDao.insert(u);
    }

    @Override
    public void toggleStatus(Long id, Long operatorId) {
        SysUser u = userDao.findById(id);
        if (u == null) throw new BizException("用户不存在");
        if (u.getId().equals(operatorId)) throw new BizException("不能禁用自己");
        userDao.updateStatus(id, u.getStatus() == 1 ? 0 : 1);
    }

    @Override
    public void resetPassword(Long id) {
        if (userDao.findById(id) == null) throw new BizException("用户不存在");
        userDao.updatePassword(id, BCrypt.hashpw("123456", BCrypt.gensalt(10)));
    }

    @Override
    public void setOnline(Long id, boolean online) {
        userDao.updateOnline(id, online ? 1 : 0);
    }
}
