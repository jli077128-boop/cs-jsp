package com.kmu.cs.dao;

import com.kmu.cs.entity.TicketRecord;

import java.util.List;

public interface TicketRecordDao {
    List<TicketRecord> listByTicket(Long ticketId);

    long insert(TicketRecord r);
}
