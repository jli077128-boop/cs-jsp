package com.kmu.cs.action;

import com.kmu.cs.entity.ChatSession;
import com.kmu.cs.entity.Ticket;
import com.kmu.cs.service.ServiceFactory;
import com.kmu.cs.util.BizException;
import com.kmu.cs.util.Dict;
import com.opensymphony.xwork2.ModelDriven;

import java.util.Arrays;
import java.util.List;
import java.util.Map;

/**
 * 用户提交工单 —— 参数接收方式三：ModelDriven&lt;Ticket&gt;（对应课堂 01_strutsParams/login2.jsp）。
 * modelDriven 拦截器把 getModel() 返回的 Ticket 压到值栈栈顶，
 * 表单字段直接写 title / content / category / priority / sessionId（不用加 "ticket." 前缀）。
 *   /user/ticketNew.action  → method="input" 显示表单（可带 ?sid= 关联 AI 对话）
 *   /user/ticketSave.action → execute 提交，成功后 redirectAction 到工单详情
 */
public class TicketCreateAction extends BaseAction implements ModelDriven<Ticket> {

    /** 模型对象必须自己 new 出来 */
    private final Ticket ticket = new Ticket();
    private Long sid;
    private ChatSession fromSession;
    private Long newId;

    @Override
    public Ticket getModel() {
        return ticket;
    }

    @Override
    public String input() {
        fromSession = ownSession(sid);
        if (fromSession != null && blank(ticket.getTitle())) ticket.setTitle(fromSession.getTitle());
        return INPUT;
    }

    @Override
    public String execute() {
        // 只取表单里允许填写的字段，避免通过参数篡改 status / userId 等属性
        Ticket in = new Ticket();
        in.setTitle(trim(ticket.getTitle()));
        in.setContent(trim(ticket.getContent()));
        in.setCategory(blank(ticket.getCategory()) ? null : ticket.getCategory().trim());
        in.setPriority(blank(ticket.getPriority()) ? null : ticket.getPriority().trim());
        fromSession = ownSession(ticket.getSessionId());
        if (fromSession != null) in.setSessionId(fromSession.getId());
        try {
            Ticket t = ServiceFactory.TICKET.create(in, me());
            newId = t.getId();
            flash("工单 " + t.getTicketNo() + " 提交成功，客服会尽快处理");
            return SUCCESS;
        } catch (BizException e) {
            addActionError(e.getMessage());
            return INPUT;
        }
    }

    private ChatSession ownSession(Long id) {
        if (id == null) return null;
        ChatSession s = ServiceFactory.CHAT.session(id);
        return s != null && s.getUserId().equals(me().getId()) ? s : null;
    }

    public void setSid(Long sid) { this.sid = sid; }
    public ChatSession getFromSession() { return fromSession; }
    public Long getNewId() { return newId; }
    public List<String> getCategories() { return Arrays.asList(Dict.TICKET_CATEGORIES); }
    public Map<String, String> getPriorities() { return Dict.PRIORITY; }
}
