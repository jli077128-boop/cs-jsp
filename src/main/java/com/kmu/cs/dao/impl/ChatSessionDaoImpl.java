package com.kmu.cs.dao.impl;

import com.kmu.cs.dao.BaseDao;
import com.kmu.cs.dao.ChatSessionDao;
import com.kmu.cs.entity.ChatSession;

import java.time.LocalDateTime;
import java.util.List;

public class ChatSessionDaoImpl extends BaseDao implements ChatSessionDao {

    /** 顺带查出用户昵称、头像色和最后一条消息 */
    private static final String SELECT = "SELECT s.*, u.nickname AS user_name, u.avatar_color AS user_color, "
            + "(SELECT m.content FROM chat_message m WHERE m.session_id = s.id ORDER BY m.id DESC LIMIT 1) AS last_msg "
            + "FROM chat_session s LEFT JOIN sys_user u ON s.user_id = u.id ";

    private static final RowMapper<ChatSession> MAPPER = rs -> {
        ChatSession s = new ChatSession();
        s.setId(rs.getLong("id"));
        s.setUserId(rs.getLong("user_id"));
        s.setAgentId(getLong(rs, "agent_id"));
        s.setTitle(rs.getString("title"));
        s.setMode(rs.getString("mode"));
        s.setStatus(rs.getString("status"));
        s.setAiSolved(rs.getInt("ai_solved"));
        s.setRating(getInt(rs, "rating"));
        s.setStartTime(getTime(rs, "start_time"));
        s.setEndTime(getTime(rs, "end_time"));
        if (hasColumn(rs, "user_name")) {
            s.setUserName(rs.getString("user_name"));
            s.setUserColor(rs.getString("user_color"));
            String last = rs.getString("last_msg");
            if (last != null) {
                last = last.replaceAll("[*#>|`\\n-]", " ").replaceAll("\\s+", " ").trim();
                if (last.length() > 30) last = last.substring(0, 30) + "…";
            }
            s.setLastMsg(last == null ? "" : last);
        }
        return s;
    };

    @Override
    public ChatSession findById(Long id) {
        return id == null ? null : queryOne(SELECT + "WHERE s.id = ?", MAPPER, id);
    }

    @Override
    public List<ChatSession> listByUser(Long userId, int limit) {
        return query(SELECT + "WHERE s.user_id = ? ORDER BY s.start_time DESC, s.id DESC LIMIT ?", MAPPER, userId, limit);
    }

    @Override
    public List<ChatSession> listQueueAndMine(Long agentId) {
        return query(SELECT + "WHERE s.mode = 'HUMAN' AND (s.status = 'QUEUE' OR (s.status = 'ACTIVE' AND s.agent_id = ?)) ORDER BY s.start_time", MAPPER, agentId);
    }

    @Override
    public List<ChatSession> listSince(LocalDateTime from) {
        return query("SELECT * FROM chat_session WHERE start_time >= ?", MAPPER, from);
    }

    @Override
    public long insert(ChatSession s) {
        return insert("INSERT INTO chat_session (user_id, agent_id, title, mode, status, ai_solved, start_time) VALUES (?,?,?,?,?,?,?)",
                s.getUserId(), s.getAgentId(), s.getTitle(), s.getMode(), s.getStatus(), s.getAiSolved(), LocalDateTime.now());
    }

    @Override
    public void update(ChatSession s) {
        update("UPDATE chat_session SET agent_id = ?, title = ?, mode = ?, status = ?, ai_solved = ?, rating = ?, end_time = ? WHERE id = ?",
                s.getAgentId(), s.getTitle(), s.getMode(), s.getStatus(), s.getAiSolved(), s.getRating(), s.getEndTime(), s.getId());
    }

    @Override
    public long countQueueBefore(Long id) {
        return count("SELECT COUNT(*) FROM chat_session WHERE status = 'QUEUE' AND id < ?", id);
    }

    @Override
    public long countQueue() {
        return count("SELECT COUNT(*) FROM chat_session WHERE status = 'QUEUE'");
    }
}
