package com.kmu.cs.websocket;

import com.kmu.cs.entity.ChatMessage;
import com.kmu.cs.util.JsonUtil;
import javax.websocket.Session;

import java.util.LinkedHashMap;
import java.util.Map;
import java.util.Set;
import java.util.concurrent.ConcurrentHashMap;
import java.util.concurrent.CopyOnWriteArraySet;

/**
 * WebSocket 连接中心：记录“用户 id → 该用户打开的 WebSocket 连接”，
 * 业务层通过 sendTo / broadcastToAgents 主动把消息推送给浏览器。
 */
public final class ChatHub {

    private static final Map<Long, Set<Session>> USER_SESSIONS = new ConcurrentHashMap<>();
    private static final Set<Long> AGENTS = ConcurrentHashMap.newKeySet();

    private ChatHub() {
    }

    static void join(Long userId, String role, Session s) {
        USER_SESSIONS.computeIfAbsent(userId, k -> new CopyOnWriteArraySet<>()).add(s);
        if ("AGENT".equals(role)) AGENTS.add(userId);
    }

    static void leave(Long userId, Session s) {
        Set<Session> set = USER_SESSIONS.get(userId);
        if (set != null) {
            set.remove(s);
            if (set.isEmpty()) {
                USER_SESSIONS.remove(userId);
                AGENTS.remove(userId);
            }
        }
    }

    public static boolean isConnected(Long userId) {
        return USER_SESSIONS.containsKey(userId);
    }

    public static int connectionCount() {
        return USER_SESSIONS.values().stream().mapToInt(Set::size).sum();
    }

    /** 推送给某个用户的所有连接 */
    public static void sendTo(Long userId, Object payload) {
        if (userId == null) return;
        Set<Session> set = USER_SESSIONS.get(userId);
        if (set == null) return;
        String text = JsonUtil.toJson(payload);
        for (Session s : set) {
            if (!s.isOpen()) continue;
            synchronized (s) { // 同一个 Session 不能并发写
                try {
                    s.getBasicRemote().sendText(text);
                } catch (Exception ignored) {
                }
            }
        }
    }

    /** 通知所有在线客服（例如队列有变化） */
    public static void broadcastToAgents(Object payload) {
        for (Long id : AGENTS) sendTo(id, payload);
    }

    /** 聊天消息事件 */
    public static Map<String, Object> msgEvent(ChatMessage m) {
        Map<String, Object> e = new LinkedHashMap<>();
        e.put("type", "msg");
        e.put("id", m.getId());
        e.put("sessionId", m.getSessionId());
        e.put("senderType", m.getSenderType());
        e.put("content", m.getContent());
        e.put("time", m.getTime());
        return e;
    }
}
