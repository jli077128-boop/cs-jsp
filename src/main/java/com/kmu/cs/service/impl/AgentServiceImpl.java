package com.kmu.cs.service.impl;

import com.google.gson.JsonArray;
import com.google.gson.JsonParser;
import com.kmu.cs.dao.ChatMessageDao;
import com.kmu.cs.dao.ChatSessionDao;
import com.kmu.cs.dao.TicketDao;
import com.kmu.cs.dao.UserDao;
import com.kmu.cs.dao.impl.ChatMessageDaoImpl;
import com.kmu.cs.dao.impl.ChatSessionDaoImpl;
import com.kmu.cs.dao.impl.TicketDaoImpl;
import com.kmu.cs.dao.impl.UserDaoImpl;
import com.kmu.cs.entity.ChatMessage;
import com.kmu.cs.entity.ChatSession;
import com.kmu.cs.entity.SysUser;
import com.kmu.cs.entity.Ticket;
import com.kmu.cs.service.AgentService;
import com.kmu.cs.service.ChatService;
import com.kmu.cs.util.BizException;
import com.kmu.cs.util.LlmClient;
import com.kmu.cs.util.Rules;
import com.kmu.cs.util.TimeFmt;
import com.kmu.cs.websocket.ChatHub;

import java.util.ArrayList;
import java.util.LinkedHashMap;
import java.util.List;
import java.util.Map;

/** 客服工作台：排队队列、接入会话、发消息、AI 推荐回复、客户信息 */
public class AgentServiceImpl implements AgentService {

    private final ChatSessionDao sessionDao = new ChatSessionDaoImpl();
    private final ChatMessageDao messageDao = new ChatMessageDaoImpl();
    private final UserDao userDao = new UserDaoImpl();
    private final TicketDao ticketDao = new TicketDaoImpl();
    private final ChatService chatService = new ChatServiceImpl();

    @Override
    public List<Map<String, Object>> queue(Long agentId) {
        List<Map<String, Object>> out = new ArrayList<>();
        for (ChatSession s : sessionDao.listQueueAndMine(agentId)) {
            List<ChatMessage> msgs = messageDao.listBySession(s.getId());
            StringBuilder all = new StringBuilder(s.getTitle() == null ? "" : s.getTitle());
            List<Map<String, Object>> mv = new ArrayList<>();
            for (ChatMessage m : msgs) {
                all.append(m.getContent());
                mv.add(ChatHub.msgEvent(m));
            }
            ChatMessage last = msgs.isEmpty() ? null : msgs.get(msgs.size() - 1);
            Map<String, Object> m = new LinkedHashMap<>();
            m.put("id", s.getId());
            m.put("userId", s.getUserId());
            m.put("title", s.getTitle());
            m.put("name", s.getUserName() == null ? "用户" : s.getUserName());
            m.put("avatarColor", s.getUserColor() == null ? "#60a5fa" : s.getUserColor());
            m.put("status", s.getStatus());
            m.put("lastMsg", s.getLastMsg());
            m.put("time", TimeFmt.hm(last == null ? s.getStartTime() : last.getCreateTime()));
            m.put("tag", Rules.classify(all.toString())[0]);
            m.put("waitSec", ChatServiceImpl.waitSeconds(s));
            m.put("messages", mv);
            out.add(m);
        }
        return out;
    }

    @Override
    public void accept(Long agentId, Long sessionId) {
        ChatSession s = sessionDao.findById(sessionId);
        if (s == null) throw new BizException("会话不存在");
        if (!"QUEUE".equals(s.getStatus())) throw new BizException("该会话已被其他客服接入");
        SysUser agent = userDao.findById(agentId);
        s.setAgentId(agentId);
        s.setStatus("ACTIVE");
        sessionDao.update(s);
        ChatMessage hello = chatService.saveMsg(sessionId, "AGENT", agentId, "您好，我是" + agent.getNickname() + "，很高兴为您服务，请问有什么可以帮您？");
        ChatHub.sendTo(s.getUserId(), Map.of("type", "accepted", "sessionId", sessionId, "agentName", agent.getNickname()));
        ChatHub.sendTo(s.getUserId(), ChatHub.msgEvent(hello));
        ChatHub.broadcastToAgents(Map.of("type", "queue"));
    }

    @Override
    public Map<String, Object> send(Long agentId, Long sessionId, String content) {
        if (content == null || content.isBlank()) throw new BizException("消息不能为空");
        ChatSession s = sessionDao.findById(sessionId);
        if (s == null || !agentId.equals(s.getAgentId())) throw new BizException("请先接入该会话");
        if ("ENDED".equals(s.getStatus())) throw new BizException("会话已结束");
        ChatMessage m = chatService.saveMsg(sessionId, "AGENT", agentId, content.trim());
        Map<String, Object> e = ChatHub.msgEvent(m);
        ChatHub.sendTo(s.getUserId(), e);
        return e;
    }

    @Override
    public List<String> suggestions(String tag, Long sessionId) {
        if (LlmClient.enabled() && sessionId != null) {
            try {
                StringBuilder sb = new StringBuilder();
                for (ChatMessage m : messageDao.lastN(sessionId, 8)) {
                    sb.append("USER".equals(m.getSenderType()) ? "客户：" : "客服：").append(m.getContent()).append('\n');
                }
                String out = LlmClient.chat(List.of(Map.of("role", "user", "content",
                        "你是电商客服主管。根据下面的对话，给客服写 3 条可以直接发送的回复，每条不超过 40 字，语气亲切。"
                                + "只输出 JSON 字符串数组，例如 [\"...\",\"...\",\"...\"]。\n\n" + sb)));
                JsonArray arr = JsonParser.parseString(out.substring(out.indexOf('['), out.lastIndexOf(']') + 1)).getAsJsonArray();
                List<String> list = new ArrayList<>();
                arr.forEach(x -> list.add(x.getAsString()));
                if (!list.isEmpty()) return list;
            } catch (Exception e) {
                System.err.println("AI 推荐回复失败，使用预设话术：" + e.getMessage());
            }
        }
        return Rules.SUGGEST.getOrDefault(tag, Rules.SUGGEST.get("default"));
    }

    @Override
    public Map<String, Object> customer(Long userId) {
        SysUser u = userDao.findById(userId);
        if (u == null) throw new BizException("用户不存在");
        Map<String, Object> m = new LinkedHashMap<>();
        m.put("id", u.getId());
        m.put("nickname", u.getNickname());
        m.put("username", u.getUsername());
        m.put("avatarColor", u.getAvatarColor());
        m.put("phone", u.getPhone());
        m.put("email", u.getEmail());
        m.put("createTime", u.getCreateTimeStr());
        m.put("sessionCount", sessionDao.listByUser(userId, 1000).size());
        List<Map<String, Object>> tickets = new ArrayList<>();
        List<Ticket> list = ticketDao.listByUser(userId);
        for (Ticket t : list.subList(0, Math.min(4, list.size()))) {
            Map<String, Object> tm = new LinkedHashMap<>();
            tm.put("id", t.getId());
            tm.put("ticketNo", t.getTicketNo());
            tm.put("title", t.getTitle());
            tm.put("status", t.getStatus());
            tm.put("statusText", t.getStatusText());
            tickets.add(tm);
        }
        m.put("ticketCount", list.size());
        m.put("tickets", tickets);
        return m;
    }
}
