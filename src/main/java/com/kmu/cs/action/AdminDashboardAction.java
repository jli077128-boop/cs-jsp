package com.kmu.cs.action;

import com.kmu.cs.entity.Ticket;
import com.kmu.cs.listener.OnlineUserListener;
import com.kmu.cs.service.ServiceFactory;
import com.kmu.cs.util.JsonUtil;

import java.util.List;
import java.util.Map;

/**
 * 管理员数据看板：
 *   /admin/dashboard.action → execute()，页面（ECharts 数据以 JSON 内嵌到页面）
 *   /api/admin/stats.action → stats()，json 结果
 */
public class AdminDashboardAction extends JsonAction {

    private Map<String, Object> stats;
    private String statsJson;
    private int onlineSessions;
    private List<Ticket> latestTickets;

    @Override
    public String execute() {
        stats = ServiceFactory.STATS.dashboard();
        statsJson = JsonUtil.toJson(stats);
        onlineSessions = OnlineUserListener.onlineCount();
        latestTickets = ServiceFactory.TICKET.all(null, null).stream().limit(5).toList();
        return SUCCESS;
    }

    public String stats() {
        return json(() -> ServiceFactory.STATS.dashboard());
    }

    public Map<String, Object> getStats() { return stats; }
    public String getStatsJson() { return statsJson; }
    public int getOnlineSessions() { return onlineSessions; }
    public List<Ticket> getLatestTickets() { return latestTickets; }
}
