package com.kmu.cs.dao;

import com.kmu.cs.entity.Ticket;

import java.util.List;
import java.util.Map;

public interface TicketDao {
    Ticket findById(Long id);

    List<Ticket> listByUser(Long userId);

    List<Ticket> listByAssignee(Long agentId, String status);

    List<Ticket> listAll(String status, String keyword);

    String maxNoLike(String prefix);

    long insert(Ticket t);

    void update(Ticket t);

    long countByStatus(String status);

    /** status → 数量 */
    Map<String, Long> groupByStatus();

    /** category → 数量 */
    Map<String, Long> groupByCategory();
}
