package com.kmu.cs.dao.impl;

import com.kmu.cs.dao.BaseDao;
import com.kmu.cs.dao.TicketRecordDao;
import com.kmu.cs.entity.TicketRecord;

import java.time.LocalDateTime;
import java.util.List;

public class TicketRecordDaoImpl extends BaseDao implements TicketRecordDao {

    private static final RowMapper<TicketRecord> MAPPER = rs -> {
        TicketRecord r = new TicketRecord();
        r.setId(rs.getLong("id"));
        r.setTicketId(rs.getLong("ticket_id"));
        r.setOperatorId(getLong(rs, "operator_id"));
        r.setOperatorName(rs.getString("operator_name"));
        r.setAction(rs.getString("action"));
        r.setContent(rs.getString("content"));
        r.setCreateTime(getTime(rs, "create_time"));
        return r;
    };

    @Override
    public List<TicketRecord> listByTicket(Long ticketId) {
        return query("SELECT * FROM ticket_record WHERE ticket_id = ? ORDER BY create_time, id", MAPPER, ticketId);
    }

    @Override
    public long insert(TicketRecord r) {
        return insert("INSERT INTO ticket_record (ticket_id, operator_id, operator_name, action, content, create_time) VALUES (?,?,?,?,?,?)",
                r.getTicketId(), r.getOperatorId(), r.getOperatorName(), r.getAction(), r.getContent(), LocalDateTime.now());
    }
}
