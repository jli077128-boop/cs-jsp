package com.kmu.cs.service;

import com.kmu.cs.entity.SysUser;
import com.kmu.cs.entity.Ticket;
import com.kmu.cs.entity.TicketRecord;

import java.util.List;
import java.util.Map;

public interface TicketService {
    List<Ticket> my(Long userId);

    List<Ticket> assigned(Long agentId, String status);

    List<Ticket> all(String status, String keyword);

    /** 查看详情（带权限校验） */
    Ticket detail(Long id, SysUser me);

    List<Ticket> recentOfUser(Long userId, int n);

    List<TicketRecord> records(Long ticketId);

    /** 用户提交工单 */
    Ticket create(Ticket in, SysUser creator);

    /** 客服在会话中一键建单（自动分配给自己） */
    Ticket createByAgent(Long sessionId, String title, String content, String priority, SysUser agent);

    void updateStatus(Long id, String status, String remark, SysUser me);

    void assign(Long id, Long agentId, SysUser me);

    void addNote(Long id, String content, SysUser me);

    Map<String, Object> classify(String text);
}
