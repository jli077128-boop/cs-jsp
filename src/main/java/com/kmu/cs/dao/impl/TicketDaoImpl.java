package com.kmu.cs.dao.impl;

import com.kmu.cs.dao.BaseDao;
import com.kmu.cs.dao.TicketDao;
import com.kmu.cs.entity.Ticket;

import java.util.ArrayList;
import java.util.LinkedHashMap;
import java.util.List;
import java.util.Map;

public class TicketDaoImpl extends BaseDao implements TicketDao {

    private static final String SELECT = "SELECT t.*, u.nickname AS user_name, u.avatar_color AS user_color, a.nickname AS assignee_name "
            + "FROM ticket t LEFT JOIN sys_user u ON t.user_id = u.id LEFT JOIN sys_user a ON t.assignee_id = a.id ";

    private static final RowMapper<Ticket> MAPPER = rs -> {
        Ticket t = new Ticket();
        t.setId(rs.getLong("id"));
        t.setTicketNo(rs.getString("ticket_no"));
        t.setUserId(rs.getLong("user_id"));
        t.setSessionId(getLong(rs, "session_id"));
        t.setTitle(rs.getString("title"));
        t.setContent(rs.getString("content"));
        t.setCategory(rs.getString("category"));
        t.setPriority(rs.getString("priority"));
        t.setStatus(rs.getString("status"));
        t.setAssigneeId(getLong(rs, "assignee_id"));
        t.setAiSummary(rs.getString("ai_summary"));
        t.setAiTags(rs.getString("ai_tags"));
        t.setCreateTime(getTime(rs, "create_time"));
        t.setUpdateTime(getTime(rs, "update_time"));
        t.setUserName(rs.getString("user_name"));
        t.setUserColor(rs.getString("user_color"));
        String an = rs.getString("assignee_name");
        t.setAssigneeName(an == null ? "" : an);
        return t;
    };

    @Override
    public Ticket findById(Long id) {
        return id == null ? null : queryOne(SELECT + "WHERE t.id = ?", MAPPER, id);
    }

    @Override
    public List<Ticket> listByUser(Long userId) {
        return query(SELECT + "WHERE t.user_id = ? ORDER BY t.create_time DESC", MAPPER, userId);
    }

    @Override
    public List<Ticket> listByAssignee(Long agentId, String status) {
        if (status != null && !status.isBlank()) {
            return query(SELECT + "WHERE t.assignee_id = ? AND t.status = ? ORDER BY t.update_time DESC", MAPPER, agentId, status);
        }
        return query(SELECT + "WHERE t.assignee_id = ? ORDER BY FIELD(t.status,'PROCESSING','PENDING','RESOLVED','CLOSED'), t.update_time DESC", MAPPER, agentId);
    }

    @Override
    public List<Ticket> listAll(String status, String keyword) {
        StringBuilder sql = new StringBuilder(SELECT).append("WHERE 1=1");
        List<Object> args = new ArrayList<>();
        if (status != null && !status.isBlank()) {
            sql.append(" AND t.status = ?");
            args.add(status);
        }
        if (keyword != null && !keyword.isBlank()) {
            sql.append(" AND (t.title LIKE ? OR t.ticket_no LIKE ?)");
            args.add("%" + keyword + "%");
            args.add("%" + keyword + "%");
        }
        sql.append(" ORDER BY t.create_time DESC");
        return query(sql.toString(), MAPPER, args.toArray());
    }

    @Override
    public String maxNoLike(String prefix) {
        return queryOne("SELECT ticket_no FROM ticket WHERE ticket_no LIKE ? ORDER BY ticket_no DESC LIMIT 1", rs -> rs.getString(1), prefix + "%");
    }

    @Override
    public long insert(Ticket t) {
        return insert("INSERT INTO ticket (ticket_no, user_id, session_id, title, content, category, priority, status, assignee_id, ai_summary, ai_tags, create_time, update_time) "
                        + "VALUES (?,?,?,?,?,?,?,?,?,?,?,?,?)",
                t.getTicketNo(), t.getUserId(), t.getSessionId(), t.getTitle(), t.getContent(), t.getCategory(), t.getPriority(),
                t.getStatus(), t.getAssigneeId(), t.getAiSummary(), t.getAiTags(), t.getCreateTime(), t.getUpdateTime());
    }

    @Override
    public void update(Ticket t) {
        update("UPDATE ticket SET status = ?, priority = ?, assignee_id = ?, update_time = ? WHERE id = ?",
                t.getStatus(), t.getPriority(), t.getAssigneeId(), t.getUpdateTime(), t.getId());
    }

    @Override
    public long countByStatus(String status) {
        return count("SELECT COUNT(*) FROM ticket WHERE status = ?", status);
    }

    @Override
    public Map<String, Long> groupByStatus() {
        Map<String, Long> m = new LinkedHashMap<>();
        query("SELECT status, COUNT(*) c FROM ticket GROUP BY status", rs -> m.put(rs.getString(1), rs.getLong(2)));
        return m;
    }

    @Override
    public Map<String, Long> groupByCategory() {
        Map<String, Long> m = new LinkedHashMap<>();
        query("SELECT IFNULL(category,'其他'), COUNT(*) c FROM ticket GROUP BY IFNULL(category,'其他') ORDER BY c DESC", rs -> m.put(rs.getString(1), rs.getLong(2)));
        return m;
    }
}
