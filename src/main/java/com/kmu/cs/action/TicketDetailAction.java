package com.kmu.cs.action;

import com.kmu.cs.entity.ChatMessage;
import com.kmu.cs.entity.SysUser;
import com.kmu.cs.entity.Ticket;
import com.kmu.cs.entity.TicketRecord;
import com.kmu.cs.service.ServiceFactory;
import com.kmu.cs.util.BizException;
import com.kmu.cs.util.Dict;
import org.apache.struts2.ServletActionContext;

import java.util.List;
import java.util.Map;

/**
 * 工单详情（/ticket 命名空间，用户 / 客服 / 管理员共用，loginStack 只要求登录，具体权限在 Service 中校验）。
 *   /ticket/detail.action?id=  → detail()
 *   /ticket/update.action      → update()：op=status|note|assign，完成后 redirectAction 回详情（PRG）
 */
public class TicketDetailAction extends BaseAction {

    private Long id;
    private String op;
    private String status;
    private String remark;
    private Long agentId;

    private Ticket t;
    private List<TicketRecord> records;
    private List<ChatMessage> sessionMessages;
    private List<SysUser> agents;

    public String detail() {
        SysUser me = me();
        try {
            t = ServiceFactory.TICKET.detail(id, me);
        } catch (BizException e) {
            ServletActionContext.getResponse().setStatus(404);
            return NOT_FOUND;
        }
        records = ServiceFactory.TICKET.records(t.getId());
        if (t.getSessionId() != null && !"USER".equals(me.getRole())) {
            sessionMessages = ServiceFactory.CHAT.messages(t.getSessionId(), me);
        }
        if ("ADMIN".equals(me.getRole())) agents = ServiceFactory.USER.list("AGENT", null);
        return SUCCESS;
    }

    public String update() {
        SysUser me = me();
        try {
            switch (op == null ? "" : op) {
                case "status" -> {
                    ServiceFactory.TICKET.updateStatus(id, status, trim(remark), me);
                    flash("工单已更新为「" + Dict.TICKET_STATUS.getOrDefault(status, status) + "」");
                }
                case "note" -> {
                    if ("USER".equals(me.getRole())) throw new BizException("无权操作");
                    ServiceFactory.TICKET.addNote(id, trim(remark), me);
                    flash("已添加处理记录");
                }
                case "assign" -> {
                    if (!"ADMIN".equals(me.getRole())) throw new BizException("只有管理员可以分配工单");
                    ServiceFactory.TICKET.assign(id, agentId, me);
                    flash("已分配客服");
                }
                default -> throw new BizException("未知操作");
            }
        } catch (BizException e) {
            flashError(e.getMessage());
        }
        return SUCCESS;
    }

    public Long getId() { return id; }
    public void setId(Long id) { this.id = id; }
    public void setOp(String op) { this.op = op; }
    public void setStatus(String status) { this.status = trim(status); }
    public void setRemark(String remark) { this.remark = remark; }
    public void setAgentId(Long agentId) { this.agentId = agentId; }
    public Ticket getT() { return t; }
    public List<TicketRecord> getRecords() { return records; }
    public List<ChatMessage> getSessionMessages() { return sessionMessages; }
    public List<SysUser> getAgents() { return agents; }
    public Map<String, String> getStatusMap() { return Dict.TICKET_STATUS; }
}
