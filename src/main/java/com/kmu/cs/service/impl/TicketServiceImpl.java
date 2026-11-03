package com.kmu.cs.service.impl;

import com.google.gson.JsonObject;
import com.google.gson.JsonParser;
import com.kmu.cs.dao.ChatSessionDao;
import com.kmu.cs.dao.TicketDao;
import com.kmu.cs.dao.TicketRecordDao;
import com.kmu.cs.dao.UserDao;
import com.kmu.cs.dao.impl.ChatSessionDaoImpl;
import com.kmu.cs.dao.impl.TicketDaoImpl;
import com.kmu.cs.dao.impl.TicketRecordDaoImpl;
import com.kmu.cs.dao.impl.UserDaoImpl;
import com.kmu.cs.entity.ChatSession;
import com.kmu.cs.entity.SysUser;
import com.kmu.cs.entity.Ticket;
import com.kmu.cs.entity.TicketRecord;
import com.kmu.cs.service.TicketService;
import com.kmu.cs.util.BizException;
import com.kmu.cs.util.DBUtil;
import com.kmu.cs.util.Dict;
import com.kmu.cs.util.LlmClient;
import com.kmu.cs.util.Rules;

import java.time.LocalDate;
import java.time.LocalDateTime;
import java.time.format.DateTimeFormatter;
import java.util.ArrayList;
import java.util.LinkedHashMap;
import java.util.List;
import java.util.Map;

/** 工单：提交、查询、状态流转、分配、处理记录、AI 分类（业务规则与现代版一致） */
public class TicketServiceImpl implements TicketService {

    private final TicketDao ticketDao = new TicketDaoImpl();
    private final TicketRecordDao recordDao = new TicketRecordDaoImpl();
    private final UserDao userDao = new UserDaoImpl();
    private final ChatSessionDao sessionDao = new ChatSessionDaoImpl();

    @Override
    public List<Ticket> my(Long userId) {
        return ticketDao.listByUser(userId);
    }

    @Override
    public List<Ticket> assigned(Long agentId, String status) {
        return ticketDao.listByAssignee(agentId, status);
    }

    @Override
    public List<Ticket> all(String status, String keyword) {
        return ticketDao.listAll(status, keyword);
    }

    @Override
    public Ticket detail(Long id, SysUser me) {
        Ticket t = ticketDao.findById(id);
        if (t == null) throw new BizException("工单不存在");
        if ("USER".equals(me.getRole()) && !t.getUserId().equals(me.getId())) throw new BizException("无权查看该工单");
        return t;
    }

    @Override
    public List<Ticket> recentOfUser(Long userId, int n) {
        List<Ticket> list = ticketDao.listByUser(userId);
        return list.size() > n ? list.subList(0, n) : list;
    }

    @Override
    public List<TicketRecord> records(Long ticketId) {
        return recordDao.listByTicket(ticketId);
    }

    /** 工单编号：TK + 日期 + 3 位当日序号，例如 TK20261022001 */
    private String nextNo() {
        String day = LocalDate.now().format(DateTimeFormatter.BASIC_ISO_DATE);
        String last = ticketDao.maxNoLike("TK" + day);
        int seq = last == null ? 1 : Integer.parseInt(last.substring(10)) + 1;
        return "TK" + day + String.format("%03d", seq);
    }

    private void addRecord(Long ticketId, Long opId, String opName, String action, String content) {
        TicketRecord r = new TicketRecord();
        r.setTicketId(ticketId);
        r.setOperatorId(opId);
        r.setOperatorName(opName);
        r.setAction(action);
        r.setContent(content);
        recordDao.insert(r);
    }

    /** 新建工单的公共部分（在事务里执行） */
    private long doCreate(Ticket in, Long userId) {
        if (in.getTitle() == null || in.getTitle().isBlank()) throw new BizException("请填写问题标题");
        String text = in.getTitle() + (in.getContent() == null ? "" : in.getContent());
        String[] auto = Rules.classify(text);
        Ticket t = new Ticket();
        t.setTicketNo(nextNo());
        t.setUserId(userId);
        t.setSessionId(in.getSessionId());
        t.setTitle(in.getTitle().trim());
        t.setContent(in.getContent());
        t.setCategory(in.getCategory() != null && !in.getCategory().isBlank() ? in.getCategory() : auto[0]);
        t.setPriority(in.getPriority() != null && Dict.PRIORITY.containsKey(in.getPriority()) ? in.getPriority() : auto[1]);
        t.setStatus(in.getStatus() == null ? "PENDING" : in.getStatus());
        t.setAssigneeId(in.getAssigneeId());
        Map<String, Object> ai = classify(text);
        t.setAiSummary(in.getAiSummary() != null ? in.getAiSummary() : (String) ai.get("summary"));
        @SuppressWarnings("unchecked")
        List<String> tags = (List<String>) ai.get("tags");
        t.setAiTags(in.getAiTags() != null ? in.getAiTags() : String.join(",", tags));
        t.setCreateTime(LocalDateTime.now());
        t.setUpdateTime(LocalDateTime.now());
        long id = ticketDao.insert(t);
        in.setCategory(t.getCategory());
        in.setPriority(t.getPriority());
        // 来源会话标记为“没有被 AI 独立解决”，统计 AI 解决率时会用到
        if (in.getSessionId() != null) {
            ChatSession s = sessionDao.findById(in.getSessionId());
            if (s != null) {
                s.setAiSolved(0);
                sessionDao.update(s);
            }
        }
        return id;
    }

    @Override
    public Ticket create(Ticket in, SysUser creator) {
        try {
            DBUtil.beginTx();
            long id = doCreate(in, creator.getId());
            addRecord(id, creator.getId(), creator.getNickname(), "CREATE", in.getSessionId() != null ? "用户通过 AI 对话提交工单" : "用户提交工单");
            addRecord(id, null, "智服 AI", "AI", "自动分类为「" + in.getCategory() + "」，优先级判定：" + Dict.PRIORITY.getOrDefault(in.getPriority(), "中"));
            DBUtil.commit();
            return ticketDao.findById(id);
        } catch (BizException e) {
            DBUtil.rollback();
            throw e;
        } catch (Exception e) {
            DBUtil.rollback();
            throw new RuntimeException(e);
        }
    }

    @Override
    public Ticket createByAgent(Long sessionId, String title, String content, String priority, SysUser agent) {
        ChatSession s = sessionDao.findById(sessionId);
        if (s == null) throw new BizException("会话不存在");
        Ticket in = new Ticket();
        in.setSessionId(sessionId);
        in.setTitle(title == null || title.isBlank() ? s.getTitle() : title);
        in.setContent(content);
        in.setPriority(priority);
        in.setStatus("PROCESSING");
        in.setAssigneeId(agent.getId());
        try {
            DBUtil.beginTx();
            long id = doCreate(in, s.getUserId());
            addRecord(id, agent.getId(), agent.getNickname(), "CREATE", "客服根据人工会话创建工单");
            addRecord(id, null, "智服 AI", "AI", "自动分类为「" + in.getCategory() + "」，优先级判定：" + Dict.PRIORITY.getOrDefault(in.getPriority(), "中"));
            addRecord(id, agent.getId(), agent.getNickname(), "ASSIGN", "已分配给" + agent.getNickname());
            DBUtil.commit();
            return ticketDao.findById(id);
        } catch (BizException e) {
            DBUtil.rollback();
            throw e;
        } catch (Exception e) {
            DBUtil.rollback();
            throw new RuntimeException(e);
        }
    }

    @Override
    public void updateStatus(Long id, String status, String remark, SysUser me) {
        Ticket t = ticketDao.findById(id);
        if (t == null) throw new BizException("工单不存在");
        if (!Dict.STATUS_ACTION_TEXT.containsKey(status)) throw new BizException("状态不正确");
        // 用户只能关闭自己的工单（确认已解决）
        if ("USER".equals(me.getRole()) && (!t.getUserId().equals(me.getId()) || !"CLOSED".equals(status))) throw new BizException("无权操作");
        t.setStatus(status);
        // 客服开始处理一个没人负责的工单时，自动分配给自己
        if ("PROCESSING".equals(status) && t.getAssigneeId() == null && "AGENT".equals(me.getRole())) t.setAssigneeId(me.getId());
        t.setUpdateTime(LocalDateTime.now());
        ticketDao.update(t);
        String action = switch (status) {
            case "RESOLVED" -> "RESOLVE";
            case "CLOSED" -> "CLOSE";
            default -> "PROCESS";
        };
        addRecord(id, me.getId(), me.getNickname(), action, remark != null && !remark.isBlank() ? remark : Dict.STATUS_ACTION_TEXT.get(status));
    }

    @Override
    public void assign(Long id, Long agentId, SysUser me) {
        Ticket t = ticketDao.findById(id);
        SysUser agent = userDao.findById(agentId);
        if (t == null || agent == null || !"AGENT".equals(agent.getRole())) throw new BizException("工单或客服不存在");
        t.setAssigneeId(agentId);
        if ("PENDING".equals(t.getStatus())) t.setStatus("PROCESSING");
        t.setUpdateTime(LocalDateTime.now());
        ticketDao.update(t);
        addRecord(id, me.getId(), me.getNickname(), "ASSIGN", "已分配给" + agent.getNickname());
    }

    @Override
    public void addNote(Long id, String content, SysUser me) {
        if (content == null || content.isBlank()) throw new BizException("备注不能为空");
        if (ticketDao.findById(id) == null) throw new BizException("工单不存在");
        addRecord(id, me.getId(), me.getNickname(), "PROCESS", content);
    }

    /** AI 分类 + 摘要：有大模型用大模型，否则关键词规则 */
    @Override
    public Map<String, Object> classify(String text) {
        String t = text == null ? "" : text;
        Map<String, Object> out = new LinkedHashMap<>();
        if (LlmClient.enabled() && !t.isBlank()) {
            try {
                String s = LlmClient.chat(List.of(Map.of("role", "user", "content",
                        "对下面的客户问题做工单分类。分类只能从【账号安全、订单支付、退款售后、物流配送、发票报销、会员权益、技术支持、投诉建议、其他】中选；"
                                + "优先级只能是 LOW/MEDIUM/HIGH/URGENT。只输出 JSON："
                                + "{\"category\":\"\",\"priority\":\"\",\"summary\":\"30字内摘要\",\"tags\":[\"标签1\",\"标签2\"]}\n\n问题：" + t)));
                JsonObject n = JsonParser.parseString(s.substring(s.indexOf('{'), s.lastIndexOf('}') + 1)).getAsJsonObject();
                List<String> tags = new ArrayList<>();
                if (n.has("tags")) n.getAsJsonArray("tags").forEach(x -> tags.add(x.getAsString()));
                out.put("category", n.has("category") ? n.get("category").getAsString() : "其他");
                out.put("priority", n.has("priority") ? n.get("priority").getAsString() : "MEDIUM");
                out.put("summary", n.has("summary") ? n.get("summary").getAsString() : "");
                out.put("tags", tags);
                return out;
            } catch (Exception e) {
                System.err.println("AI 分类失败，使用规则：" + e.getMessage());
            }
        }
        String[] r = Rules.classify(t);
        out.put("category", r[0]);
        out.put("priority", r[1]);
        out.put("summary", t.isBlank() ? "" : "用户反馈：" + (t.length() > 28 ? t.substring(0, 28) + "…" : t));
        out.put("tags", List.of(r[0], "AI 识别"));
        return out;
    }
}
