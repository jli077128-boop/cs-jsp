package com.kmu.cs.action;

import com.kmu.cs.entity.Ticket;
import com.kmu.cs.service.ServiceFactory;
import com.kmu.cs.util.Dict;

import java.util.LinkedHashMap;
import java.util.List;
import java.util.Map;

/** 用户端「我的工单」列表（按状态筛选）。页面 user/tickets.jsp 用 &lt;s:iterator&gt; / &lt;s:if&gt; / &lt;s:url&gt; 渲染 */
public class TicketAction extends BaseAction {

    private String status;
    private List<Ticket> tickets;
    private Map<String, Long> counts;
    private int total;

    @Override
    public String execute() {
        List<Ticket> all = ServiceFactory.TICKET.my(me().getId());
        counts = new LinkedHashMap<>();
        for (String k : Dict.TICKET_STATUS.keySet()) counts.put(k, all.stream().filter(t -> k.equals(t.getStatus())).count());
        total = all.size();
        tickets = blank(status) ? all : all.stream().filter(t -> status.equals(t.getStatus())).toList();
        return SUCCESS;
    }

    public String getStatus() { return status; }
    public void setStatus(String status) { this.status = trim(status); }
    public List<Ticket> getTickets() { return tickets; }
    public Map<String, Long> getCounts() { return counts; }
    public int getTotal() { return total; }
    public Map<String, String> getStatusMap() { return Dict.TICKET_STATUS; }
}
