package com.kmu.cs.entity;

import com.kmu.cs.util.Dict;
import com.kmu.cs.util.Md;
import com.kmu.cs.util.TimeFmt;

import java.time.LocalDateTime;

/** 聊天消息 */
public class ChatMessage {

    private Long id;
    private Long sessionId;
    private String senderType;
    private Long senderId;
    private String content;
    private LocalDateTime createTime;

    public Long getId() { return id; }
    public void setId(Long id) { this.id = id; }
    public Long getSessionId() { return sessionId; }
    public void setSessionId(Long sessionId) { this.sessionId = sessionId; }
    public String getSenderType() { return senderType; }
    public void setSenderType(String senderType) { this.senderType = senderType; }
    public Long getSenderId() { return senderId; }
    public void setSenderId(Long senderId) { this.senderId = senderId; }
    public String getContent() { return content; }
    public void setContent(String content) { this.content = content; }
    public LocalDateTime getCreateTime() { return createTime; }
    public void setCreateTime(LocalDateTime createTime) { this.createTime = createTime; }

    public String getTime() { return TimeFmt.hm(createTime); }
    /** 消息内容渲染成安全的 HTML（支持简单 Markdown） */
    public String getContentHtml() { return Md.render(content); }

}
