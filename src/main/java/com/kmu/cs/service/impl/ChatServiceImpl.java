package com.kmu.cs.service.impl;

import com.kmu.cs.dao.ChatMessageDao;
import com.kmu.cs.dao.ChatSessionDao;
import com.kmu.cs.dao.UserDao;
import com.kmu.cs.dao.impl.ChatMessageDaoImpl;
import com.kmu.cs.dao.impl.ChatSessionDaoImpl;
import com.kmu.cs.dao.impl.UserDaoImpl;
import com.kmu.cs.entity.ChatMessage;
import com.kmu.cs.entity.ChatSession;
import com.kmu.cs.entity.KbArticle;
import com.kmu.cs.entity.SysUser;
import com.kmu.cs.service.ChatService;
import com.kmu.cs.service.KnowledgeService;
import com.kmu.cs.util.BizException;
import com.kmu.cs.util.LlmClient;
import com.kmu.cs.util.Rules;
import com.kmu.cs.util.TimeFmt;
import com.kmu.cs.websocket.ChatHub;

import java.time.LocalDateTime;
import java.util.ArrayList;
import java.util.LinkedHashMap;
import java.util.List;
import java.util.Map;

/** AI 对话：会话列表、消息、提问（先检索知识库，再交给大模型组织语言）、评价、转人工、结束 */
public class ChatServiceImpl implements ChatService {

    private final ChatSessionDao sessionDao = new ChatSessionDaoImpl();
    private final ChatMessageDao messageDao = new ChatMessageDaoImpl();
    private final UserDao userDao = new UserDaoImpl();
    private final KnowledgeService knowledge = new KnowledgeServiceImpl();

    @Override
    public List<ChatSession> mySessions(Long userId) {
        return sessionDao.listByUser(userId, 30);
    }

    @Override
    public ChatSession session(Long sessionId) {
        return sessionDao.findById(sessionId);
    }

    @Override
    public List<ChatMessage> messages(Long sessionId, SysUser me) {
        ChatSession s = sessionDao.findById(sessionId);
        if (s == null) throw new BizException("会话不存在");
        if ("USER".equals(me.getRole()) && !s.getUserId().equals(me.getId())) throw new BizException("无权查看");
        return messageDao.listBySession(sessionId);
    }

    private ChatSession ownSession(Long userId, Long sessionId) {
        ChatSession s = sessionDao.findById(sessionId);
        if (s == null || !s.getUserId().equals(userId)) throw new BizException("会话不存在");
        return s;
    }

    @Override
    public Map<String, Object> ask(Long userId, Long sessionId, String question) {
        if (question == null || question.isBlank()) throw new BizException("问题不能为空");
        String q = question.trim();
        if (q.length() > 500) q = q.substring(0, 500);

        // 1. 没有会话（或会话已结束）就新建一个
        ChatSession s = sessionId == null ? null : ownSession(userId, sessionId);
        if (s == null || "ENDED".equals(s.getStatus())) {
            s = new ChatSession();
            s.setUserId(userId);
            s.setTitle(q.length() > 20 ? q.substring(0, 20) : q);
            s.setMode("AI");
            s.setStatus("ACTIVE");
            s.setAiSolved(1);
            s.setId(sessionDao.insert(s));
        }
        Map<String, Object> out = new LinkedHashMap<>();
        out.put("sessionId", s.getId());

        // 2. 人工模式：保存消息并通过 WebSocket 推给客服，不走 AI
        if ("HUMAN".equals(s.getMode())) {
            ChatMessage m = saveMsg(s.getId(), "USER", userId, q);
            if (s.getAgentId() != null) ChatHub.sendTo(s.getAgentId(), ChatHub.msgEvent(m));
            else ChatHub.broadcastToAgents(Map.of("type", "queue"));
            out.put("human", true);
            out.put("userMsgId", m.getId());
            out.put("time", m.getTime());
            return out;
        }

        // 3. AI 模式：先取历史（不含本次问题），再保存用户消息
        List<ChatMessage> history = messageDao.lastN(s.getId(), 10);
        ChatMessage um = saveMsg(s.getId(), "USER", userId, q);

        // 4. 检索知识库
        List<KbArticle> hits = knowledge.search(q, 3);
        if (!hits.isEmpty()) knowledge.hit(hits.get(0).getId());

        String answer = null;
        if (LlmClient.enabled()) {
            try {
                answer = LlmClient.chat(buildPrompt(history, q, hits));
            } catch (Exception e) {
                System.err.println("调用大模型失败，改用知识库回答：" + e.getMessage());
            }
        }
        if (answer == null || answer.isBlank()) {
            // 5. 没配大模型（或调用失败）：直接用知识库答案
            answer = hits.isEmpty() ? Rules.DEFAULT_REPLY
                    : "关于「" + hits.get(0).getQuestion() + "」，为您找到以下答案：\n\n" + hits.get(0).getAnswer()
                    + "\n\n如果还没解决，可以点击 **转人工** 或 **生成工单**。";
        }
        ChatMessage am = saveMsg(s.getId(), "AI", null, answer);
        out.put("human", false);
        out.put("userMsgId", um.getId());
        out.put("msgId", am.getId());
        out.put("answer", answer);
        out.put("hit", !hits.isEmpty());
        out.put("suggest", suggest(hits));
        out.put("time", am.getTime());
        out.put("title", s.getTitle());
        out.put("llm", LlmClient.enabled());
        return out;
    }

    private List<Map<String, String>> buildPrompt(List<ChatMessage> history, String q, List<KbArticle> hits) {
        StringBuilder sys = new StringBuilder("你是「智服 AI」电商平台的智能客服，语气亲切专业，回答简洁，使用 Markdown（可用列表、加粗）。"
                + "优先依据【参考资料】回答；资料里没有的内容不要编造，建议用户点击「转人工」或「生成工单」。");
        if (!hits.isEmpty()) {
            sys.append("\n\n【参考资料】");
            for (KbArticle a : hits) sys.append("\n问：").append(a.getQuestion()).append("\n答：").append(a.getAnswer());
        }
        List<Map<String, String>> msgs = new ArrayList<>();
        msgs.add(Map.of("role", "system", "content", sys.toString()));
        for (ChatMessage m : history) {
            msgs.add(Map.of("role", "USER".equals(m.getSenderType()) ? "user" : "assistant", "content", m.getContent()));
        }
        msgs.add(Map.of("role", "user", "content", q));
        return msgs;
    }

    /** 猜你想问：同分类下的其他热门问题 */
    private List<String> suggest(List<KbArticle> hits) {
        if (hits.isEmpty()) return List.of("转人工", "生成工单", "换个问题");
        List<String> out = new ArrayList<>();
        for (KbArticle a : knowledge.articles(hits.get(0).getCategoryId(), null, true)) {
            if (!a.getId().equals(hits.get(0).getId()) && out.size() < 2) out.add(a.getQuestion());
        }
        out.add("生成工单");
        return out;
    }

    @Override
    public ChatMessage saveMsg(Long sessionId, String type, Long senderId, String content) {
        ChatMessage m = new ChatMessage();
        m.setSessionId(sessionId);
        m.setSenderType(type);
        m.setSenderId(senderId);
        m.setContent(content);
        m.setCreateTime(LocalDateTime.now().withNano(0));
        m.setId(messageDao.insert(m));
        return m;
    }

    @Override
    public void rate(Long userId, Long sessionId, Integer rating) {
        ChatSession s = ownSession(userId, sessionId);
        if (rating == null || rating < 1 || rating > 5) throw new BizException("评分为 1-5 星");
        s.setRating(rating);
        sessionDao.update(s);
    }

    /** 转人工：会话改成 HUMAN + 排队，通知在线客服刷新队列 */
    @Override
    public Map<String, Object> requestHuman(Long userId, Long sessionId) {
        ChatSession s = sessionId == null ? null : ownSession(userId, sessionId);
        if (s == null || "ENDED".equals(s.getStatus())) {
            s = new ChatSession();
            s.setUserId(userId);
            s.setTitle("人工客服咨询");
            s.setMode("HUMAN");
            s.setStatus("QUEUE");
            s.setAiSolved(0);
            s.setId(sessionDao.insert(s));
        } else if (!"HUMAN".equals(s.getMode())) {
            s.setMode("HUMAN");
            s.setStatus("QUEUE");
            s.setAiSolved(0);
            sessionDao.update(s);
        }
        long ahead = sessionDao.countQueueBefore(s.getId());
        ChatMessage tip = saveMsg(s.getId(), "AI", null, "已为您转接人工客服，当前排在第 **" + (ahead + 1) + "** 位，请稍候～");
        ChatHub.broadcastToAgents(Map.of("type", "queue"));
        Map<String, Object> out = new LinkedHashMap<>();
        out.put("sessionId", s.getId());
        out.put("status", s.getStatus());
        out.put("position", ahead + 1);
        out.put("estimateSec", (ahead + 1) * 30);
        out.put("tip", ChatHub.msgEvent(tip));
        if ("ACTIVE".equals(s.getStatus()) && s.getAgentId() != null) {
            SysUser a = userDao.findById(s.getAgentId());
            out.put("agentName", a == null ? "客服" : a.getNickname());
        }
        return out;
    }

    @Override
    public void end(SysUser me, Long sessionId) {
        ChatSession s = sessionDao.findById(sessionId);
        if (s == null) throw new BizException("会话不存在");
        if ("USER".equals(me.getRole()) && !s.getUserId().equals(me.getId())) throw new BizException("无权操作");
        if ("AGENT".equals(me.getRole()) && !me.getId().equals(s.getAgentId())) throw new BizException("这不是您接待的会话");
        if ("ENDED".equals(s.getStatus())) return;
        s.setStatus("ENDED");
        s.setEndTime(LocalDateTime.now());
        sessionDao.update(s);
        Map<String, Object> ev = Map.of("type", "end", "sessionId", sessionId, "by", me.getRole());
        if (s.getAgentId() != null) ChatHub.sendTo(s.getAgentId(), ev);
        ChatHub.sendTo(s.getUserId(), ev);
        ChatHub.broadcastToAgents(Map.of("type", "queue"));
    }

    @Override
    public Map<String, Object> poll(SysUser me, Long sessionId, Long afterId) {
        ChatSession s = sessionDao.findById(sessionId);
        if (s == null) throw new BizException("会话不存在");
        if ("USER".equals(me.getRole()) && !s.getUserId().equals(me.getId())) throw new BizException("无权查看");
        Map<String, Object> out = new LinkedHashMap<>();
        out.put("status", s.getStatus());
        out.put("mode", s.getMode());
        if (s.getAgentId() != null) {
            SysUser a = userDao.findById(s.getAgentId());
            out.put("agentName", a == null ? "客服" : a.getNickname());
        }
        if ("QUEUE".equals(s.getStatus())) out.put("position", sessionDao.countQueueBefore(s.getId()) + 1);
        List<Map<String, Object>> msgs = new ArrayList<>();
        for (ChatMessage m : messageDao.listAfter(sessionId, afterId)) msgs.add(ChatHub.msgEvent(m));
        out.put("messages", msgs);
        return out;
    }

    public static long waitSeconds(ChatSession s) {
        return s.getStartTime() == null ? 0 : java.time.Duration.between(s.getStartTime(), LocalDateTime.now()).getSeconds();
    }

    static String friendly(LocalDateTime t) {
        return TimeFmt.friendly(t);
    }
}
