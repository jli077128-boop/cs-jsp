package com.kmu.cs.service;

import com.kmu.cs.service.impl.AgentServiceImpl;
import com.kmu.cs.service.impl.ChatServiceImpl;
import com.kmu.cs.service.impl.KnowledgeServiceImpl;
import com.kmu.cs.service.impl.StatsServiceImpl;
import com.kmu.cs.service.impl.TicketServiceImpl;
import com.kmu.cs.service.impl.UserServiceImpl;

/** 简单的“工厂”，代替 Spring 的依赖注入：所有 Servlet 共享同一套无状态的 Service 单例 */
public final class ServiceFactory {
    private ServiceFactory() {
    }

    public static final UserService USER = new UserServiceImpl();
    public static final KnowledgeService KNOWLEDGE = new KnowledgeServiceImpl();
    public static final TicketService TICKET = new TicketServiceImpl();
    public static final ChatService CHAT = new ChatServiceImpl();
    public static final AgentService AGENT = new AgentServiceImpl();
    public static final StatsService STATS = new StatsServiceImpl();
}
