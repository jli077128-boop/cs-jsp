package com.kmu.cs.action;

import com.kmu.cs.entity.SysUser;
import com.kmu.cs.entity.Ticket;
import com.kmu.cs.service.ServiceFactory;
import com.kmu.cs.util.BizException;
import com.kmu.cs.util.Dict;
import com.opensymphony.xwork2.Preparable;

import java.time.LocalDateTime;
import java.time.ZoneId;
import java.util.Date;
import java.util.LinkedHashMap;
import java.util.List;
import java.util.Map;

/**
 * 管理员工单管理：
 *   /admin/tickets.action      → execute()：按状态 / 关键字 / 提交日期范围筛选
 *   /admin/ticketAssign.action → assign()：列表里直接分配客服
 *
 * 类型转换演示（对应课堂 04_strutsConversion）：startDate / endDate 是 java.util.Date，
 * 表单提交的是 "2026-10-01" 这样的字符串，由全局注册的 com.kmu.cs.converter.DateConverter 转换；
 * 格式错误时 conversionError 拦截器添加字段错误 → workflow 返回 input，页面用 &lt;s:fielderror&gt; 提示。
 * 实现 Preparable：prepare() 在参数注入前加载统计数，保证返回 input 时页面也有数据。
 */
public class AdminTicketAction extends BaseAction implements Preparable {

    private String status;
    private String q;
    private Date startDate;
    private Date endDate;
    private Long id;
    private Long agentId;

    private List<Ticket> all;
    private List<Ticket> tickets;
    private Map<String, Long> counts;
    private List<SysUser> agents;

    @Override
    public void prepare() {
        all = ServiceFactory.TICKET.all(null, null);
        counts = new LinkedHashMap<>();
        for (String k : Dict.TICKET_STATUS.keySet()) counts.put(k, all.stream().filter(t -> k.equals(t.getStatus())).count());
        agents = ServiceFactory.USER.list("AGENT", null);
    }

    /** 只在 execute 时做日期先后校验（validate + 方法名） */
    public void validateExecute() {
        if (startDate != null && endDate != null && startDate.after(endDate)) {
            addFieldError("endDate", getText("ticket.endDate.beforeStart"));
        }
    }

    @Override
    public String execute() {
        LocalDateTime from = startDate == null ? null : toLdt(startDate);
        LocalDateTime to = endDate == null ? null : toLdt(endDate).plusDays(1); // 结束日期当天也包含在内
        tickets = ServiceFactory.TICKET.all(blank(status) ? null : status, blank(q) ? null : q).stream()
                .filter(t -> from == null || (t.getCreateTime() != null && !t.getCreateTime().isBefore(from)))
                .filter(t -> to == null || (t.getCreateTime() != null && t.getCreateTime().isBefore(to)))
                .toList();
        return SUCCESS;
    }

    public String assign() {
        try {
            ServiceFactory.TICKET.assign(id, agentId, me());
            flash("分配成功");
        } catch (BizException e) {
            flashError(e.getMessage());
        }
        return SUCCESS;
    }

    private static LocalDateTime toLdt(Date d) {
        return d.toInstant().atZone(ZoneId.systemDefault()).toLocalDate().atStartOfDay();
    }

    /** 分配后回到原来的状态标签（只允许大写字母，防止拼接非法参数） */
    public String getBackStatus() {
        return status != null && status.matches("[A-Z]+") ? status : null;
    }

    public String getStatus() { return status; }
    public void setStatus(String status) { this.status = trim(status); }
    public String getQ() { return q; }
    public void setQ(String q) { this.q = trim(q); }
    public Date getStartDate() { return startDate; }
    public void setStartDate(Date startDate) { this.startDate = startDate; }
    public Date getEndDate() { return endDate; }
    public void setEndDate(Date endDate) { this.endDate = endDate; }
    public void setId(Long id) { this.id = id; }
    public void setAgentId(Long agentId) { this.agentId = agentId; }
    public List<Ticket> getTickets() { return tickets; }
    public Map<String, Long> getCounts() { return counts; }
    public int getTotal() { return all == null ? 0 : all.size(); }
    public List<SysUser> getAgents() { return agents; }
    public Map<String, String> getStatusMap() { return Dict.TICKET_STATUS; }
    /** 是否用了日期筛选（页面上显示“已按日期筛选”提示） */
    public boolean isDateFiltered() { return startDate != null || endDate != null; }
}
