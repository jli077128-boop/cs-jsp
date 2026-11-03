package com.kmu.cs.dao.impl;

import com.kmu.cs.dao.BaseDao;
import com.kmu.cs.dao.ChatMessageDao;
import com.kmu.cs.entity.ChatMessage;

import java.time.LocalDateTime;
import java.util.Collections;
import java.util.List;

public class ChatMessageDaoImpl extends BaseDao implements ChatMessageDao {

    private static final RowMapper<ChatMessage> MAPPER = rs -> {
        ChatMessage m = new ChatMessage();
        m.setId(rs.getLong("id"));
        m.setSessionId(rs.getLong("session_id"));
        m.setSenderType(rs.getString("sender_type"));
        m.setSenderId(getLong(rs, "sender_id"));
        m.setContent(rs.getString("content"));
        m.setCreateTime(getTime(rs, "create_time"));
        return m;
    };

    @Override
    public List<ChatMessage> listBySession(Long sessionId) {
        return query("SELECT * FROM chat_message WHERE session_id = ? ORDER BY id", MAPPER, sessionId);
    }

    @Override
    public List<ChatMessage> listAfter(Long sessionId, Long afterId) {
        return query("SELECT * FROM chat_message WHERE session_id = ? AND id > ? ORDER BY id", MAPPER, sessionId, afterId == null ? 0 : afterId);
    }

    @Override
    public List<ChatMessage> lastN(Long sessionId, int n) {
        List<ChatMessage> list = query("SELECT * FROM chat_message WHERE session_id = ? ORDER BY id DESC LIMIT ?", MAPPER, sessionId, n);
        Collections.reverse(list);
        return list;
    }

    @Override
    public long insert(ChatMessage m) {
        if (m.getCreateTime() == null) m.setCreateTime(LocalDateTime.now());
        return insert("INSERT INTO chat_message (session_id, sender_type, sender_id, content, create_time) VALUES (?,?,?,?,?)",
                m.getSessionId(), m.getSenderType(), m.getSenderId(), m.getContent(), m.getCreateTime());
    }
}
