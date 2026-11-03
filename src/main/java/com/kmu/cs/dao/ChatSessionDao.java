package com.kmu.cs.dao;

import com.kmu.cs.entity.ChatSession;

import java.time.LocalDateTime;
import java.util.List;

public interface ChatSessionDao {
    ChatSession findById(Long id);

    List<ChatSession> listByUser(Long userId, int limit);

    /** 客服工作台队列：排队中 + 该客服正在服务的 */
    List<ChatSession> listQueueAndMine(Long agentId);

    List<ChatSession> listSince(LocalDateTime from);

    long insert(ChatSession s);

    void update(ChatSession s);

    long countQueueBefore(Long id);

    long countQueue();
}
