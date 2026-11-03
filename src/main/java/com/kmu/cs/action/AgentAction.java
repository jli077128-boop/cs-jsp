package com.kmu.cs.action;

import com.kmu.cs.entity.Ticket;
import com.kmu.cs.service.ServiceFactory;
import com.kmu.cs.util.Dict;

import java.util.LinkedHashMap;
import java.util.List;
import java.util.Map;

/**
 * 客服端页面（/agent 命名空间，agentStack 只允许 AGENT）：
 *   /agent/workbench.action → execute()  客服工作台（会话队列、实时对话都走 /api/agent 的 json 接口 + WebSocket）
 *   /agent/tickets.action   → tickets()  我的工单 / 待认领
 */
public class AgentAction extends BaseAction {

    private String status;
    private String tab;
    private long myProcessing;
    private long myResolved;
    private List<Ticket> tickets;
    private Map<String, Long> counts;
    private int total;
    private int unassignedCount;

    @Override
    public String execute() {
        var mine = ServiceFactory.TICKET.assigned(me().getId(), null);
        myProcessing = mine.stream().filter(t -> "PROCESSING".equals(t.getStatus())).count();
        myResolved = mine.stream().filter(t -> "RESOLVED".equals(t.getStatus()) || "CLOSED".equals(t.getStatus())).count();
        return SUCCESS;
    }

    public String tickets() {
        List<Ticket> mine = ServiceFactory.TICKET.assigned(me().getId(), null);
        List<Ticket> unassigned = ServiceFactory.TICKET.all("PENDING", null).stream().filter(t -> t.getAssigneeId() == null).toList();
        counts = new LinkedHashMap<>();
        for (String k : Dict.TICKET_STATUS.keySet()) counts.put(k, mine.stream().filter(t -> k.equals(t.getStatus())).count());
        total = mine.size();
        unassignedCount = unassigned.size();
        if ("pool".equals(tab)) tickets = unassigned;
        else tickets = blank(status) ? mine : mine.stream().filter(t -> status.equals(t.getStatus())).toList();
        return SUCCESS;
    }

    public String getStatus() { return status; }
    public void setStatus(String status) { this.status = trim(status); }
    public String getTab() { return tab; }
    public void setTab(String tab) { this.tab = trim(tab); }
    public long getMyProcessing() { return myProcessing; }
    public long getMyResolved() { return myResolved; }
    public Map<String, String> getPriorities() { return Dict.PRIORITY; }
    public List<Ticket> getTickets() { return tickets; }
    public Map<String, Long> getCounts() { return counts; }
    public int getTotal() { return total; }
    public int getUnassignedCount() { return unassignedCount; }
    public Map<String, String> getStatusMap() { return Dict.TICKET_STATUS; }
}
