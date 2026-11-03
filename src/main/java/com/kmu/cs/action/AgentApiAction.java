package com.kmu.cs.action;

import com.kmu.cs.entity.Ticket;
import com.kmu.cs.service.ServiceFactory;

import java.util.Map;

/**
 * 客服工作台 Ajax 接口（/api/agent 命名空间，通配符 + allowed-methods，json 结果）。
 * 实时消息推送仍由 WebSocket（/ws/chat，已在 struts.action.excludePattern 中排除）完成，这里是请求-响应部分。
 */
public class AgentApiAction extends JsonAction {

    private Long sessionId;
    private Long afterId;
    private Long userId;
    private String tag;
    private String content;
    private String title;
    private String priority;

    public String queue() {
        return json(() -> ServiceFactory.AGENT.queue(me().getId()));
    }

    public String customer() {
        return json(() -> ServiceFactory.AGENT.customer(userId));
    }

    public String suggest() {
        return json(() -> ServiceFactory.AGENT.suggestions(tag, sessionId));
    }

    public String poll() {
        return json(() -> ServiceFactory.CHAT.poll(me(), sessionId, afterId));
    }

    public String accept() {
        return json(() -> {
            ServiceFactory.AGENT.accept(me().getId(), sessionId);
            return "ok";
        });
    }

    public String send() {
        return json(() -> ServiceFactory.AGENT.send(me().getId(), sessionId, content));
    }

    public String end() {
        return json(() -> {
            ServiceFactory.CHAT.end(me(), sessionId);
            return "ok";
        });
    }

    /** 客服一键建单 */
    public String ticket() {
        return json(() -> {
            Ticket t = ServiceFactory.TICKET.createByAgent(sessionId, title, content, blank(priority) ? null : priority, me());
            return Map.of("id", t.getId(), "ticketNo", t.getTicketNo());
        });
    }

    public void setSessionId(Long sessionId) { this.sessionId = sessionId; }
    public void setAfterId(Long afterId) { this.afterId = afterId; }
    public void setUserId(Long userId) { this.userId = userId; }
    public void setTag(String tag) { this.tag = tag; }
    public void setContent(String content) { this.content = content; }
    public void setTitle(String title) { this.title = title; }
    public void setPriority(String priority) { this.priority = priority; }
}
