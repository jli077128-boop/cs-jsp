package com.kmu.cs.service;

import com.kmu.cs.entity.ChatMessage;
import com.kmu.cs.entity.ChatSession;
import com.kmu.cs.entity.SysUser;

import java.util.List;
import java.util.Map;

public interface ChatService {
    List<ChatSession> mySessions(Long userId);

    ChatSession session(Long sessionId);

    /** 查看会话消息（用户只能看自己的） */
    List<ChatMessage> messages(Long sessionId, SysUser me);

    /** 用户提问：AI 模式走“知识库检索 + 大模型”，人工模式直接转发给客服 */
    Map<String, Object> ask(Long userId, Long sessionId, String question);

    void rate(Long userId, Long sessionId, Integer rating);

    Map<String, Object> requestHuman(Long userId, Long sessionId);

    void end(SysUser me, Long sessionId);

    /** Ajax 轮询：会话状态 + afterId 之后的新消息 */
    Map<String, Object> poll(SysUser me, Long sessionId, Long afterId);

    ChatMessage saveMsg(Long sessionId, String type, Long senderId, String content);
}
