package com.kmu.cs.action;

import com.kmu.cs.entity.ChatMessage;
import com.kmu.cs.entity.ChatSession;
import com.kmu.cs.entity.KbArticle;
import com.kmu.cs.entity.SysUser;
import com.kmu.cs.entity.Ticket;
import com.kmu.cs.service.ServiceFactory;
import com.kmu.cs.util.Rules;

import java.util.List;

/** 智能客服对话页（页面 Action）。对话中的 Ajax 请求由 ChatApiAction（/api/chat 命名空间，json 结果）处理 */
public class ChatAction extends BaseAction {

    private Long sid;
    private String q;
    private List<ChatSession> sessions;
    private ChatSession current;
    private List<ChatMessage> messages;
    private SysUser agent;
    private List<KbArticle> hot;
    private List<Ticket> myTickets;

    @Override
    public String execute() {
        SysUser me = me();
        sessions = ServiceFactory.CHAT.mySessions(me.getId());
        if (sid != null) {
            ChatSession cur = ServiceFactory.CHAT.session(sid);
            if (cur != null && cur.getUserId().equals(me.getId())) {
                current = cur;
                messages = ServiceFactory.CHAT.messages(sid, me);
                if (cur.getAgentId() != null) agent = ServiceFactory.USER.findById(cur.getAgentId());
            }
        }
        hot = ServiceFactory.KNOWLEDGE.hot(5);
        List<Ticket> tickets = ServiceFactory.TICKET.my(me.getId());
        myTickets = tickets.subList(0, Math.min(4, tickets.size()));
        return SUCCESS;
    }

    public void setSid(Long sid) { this.sid = sid; }
    public Long getSid() { return sid; }
    /** 从首页 / 知识库带过来的问题，页面加载后自动发送 */
    public String getQ() { return q; }
    public void setQ(String q) { this.q = trim(q); }
    public List<ChatSession> getSessions() { return sessions; }
    public ChatSession getCurrent() { return current; }
    public List<ChatMessage> getMessages() { return messages; }
    public SysUser getAgent() { return agent; }
    public List<KbArticle> getHot() { return hot; }
    public List<Ticket> getMyTickets() { return myTickets; }
    public List<String> getWelcomeSuggest() { return Rules.WELCOME_SUGGEST; }
}
