package com.kmu.cs.action;

import com.kmu.cs.entity.KbArticle;
import com.kmu.cs.entity.KbCategory;
import com.kmu.cs.entity.Ticket;
import com.kmu.cs.service.ServiceFactory;

import java.util.List;

/** 用户端首页（帮助中心）：热门问题、分类、最近工单 */
public class UserHomeAction extends BaseAction {

    private List<KbArticle> hot;
    private List<KbCategory> categories;
    private List<Ticket> recentTickets;
    private int ticketCount;
    private long openCount;

    @Override
    public String execute() {
        hot = ServiceFactory.KNOWLEDGE.hot(6);
        categories = ServiceFactory.KNOWLEDGE.categories();
        List<Ticket> mine = ServiceFactory.TICKET.my(me().getId());
        ticketCount = mine.size();
        openCount = mine.stream().filter(t -> "PENDING".equals(t.getStatus()) || "PROCESSING".equals(t.getStatus())).count();
        recentTickets = mine.subList(0, Math.min(3, mine.size()));
        return SUCCESS;
    }

    public List<KbArticle> getHot() { return hot; }
    public List<KbCategory> getCategories() { return categories; }
    public List<Ticket> getRecentTickets() { return recentTickets; }
    public int getTicketCount() { return ticketCount; }
    public long getOpenCount() { return openCount; }
}
