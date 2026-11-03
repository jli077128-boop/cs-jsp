package com.kmu.cs.service;

import java.util.List;
import java.util.Map;

public interface AgentService {
    List<Map<String, Object>> queue(Long agentId);

    void accept(Long agentId, Long sessionId);

    Map<String, Object> send(Long agentId, Long sessionId, String content);

    List<String> suggestions(String tag, Long sessionId);

    /** 右侧客户信息：资料 + 历史会话数 + 最近工单 */
    Map<String, Object> customer(Long userId);
}
