package com.kmu.cs.dao;

import com.kmu.cs.entity.ChatMessage;

import java.util.List;

public interface ChatMessageDao {
    List<ChatMessage> listBySession(Long sessionId);

    /** 取 id 大于 afterId 的新消息（Ajax 轮询用） */
    List<ChatMessage> listAfter(Long sessionId, Long afterId);

    /** 最近 n 条（按时间正序） */
    List<ChatMessage> lastN(Long sessionId, int n);

    long insert(ChatMessage m);
}
