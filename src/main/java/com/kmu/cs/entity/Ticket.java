package com.kmu.cs.entity;

import com.kmu.cs.util.Dict;
import com.kmu.cs.util.Md;
import com.kmu.cs.util.TimeFmt;

import java.time.LocalDateTime;

/** 工单 */
public class Ticket {

    private Long id;
    private String ticketNo;
    private Long userId;
    private Long sessionId;
    private String title;
    private String content;
    private String category;
    private String priority;
    private String status;
    private Long assigneeId;
    private String aiSummary;
    private String aiTags;
    private LocalDateTime createTime;
    private LocalDateTime updateTime;
    private String userName;
    private String userColor;
    private String assigneeName;

    public Long getId() { return id; }
    public void setId(Long id) { this.id = id; }
    public String getTicketNo() { return ticketNo; }
    public void setTicketNo(String ticketNo) { this.ticketNo = ticketNo; }
    public Long getUserId() { return userId; }
    public void setUserId(Long userId) { this.userId = userId; }
    public Long getSessionId() { return sessionId; }
    public void setSessionId(Long sessionId) { this.sessionId = sessionId; }
    public String getTitle() { return title; }
    public void setTitle(String title) { this.title = title; }
    public String getContent() { return content; }
    public void setContent(String content) { this.content = content; }
    public String getCategory() { return category; }
    public void setCategory(String category) { this.category = category; }
    public String getPriority() { return priority; }
    public void setPriority(String priority) { this.priority = priority; }
    public String getStatus() { return status; }
    public void setStatus(String status) { this.status = status; }
    public Long getAssigneeId() { return assigneeId; }
    public void setAssigneeId(Long assigneeId) { this.assigneeId = assigneeId; }
    public String getAiSummary() { return aiSummary; }
    public void setAiSummary(String aiSummary) { this.aiSummary = aiSummary; }
    public String getAiTags() { return aiTags; }
    public void setAiTags(String aiTags) { this.aiTags = aiTags; }
    public LocalDateTime getCreateTime() { return createTime; }
    public void setCreateTime(LocalDateTime createTime) { this.createTime = createTime; }
    public LocalDateTime getUpdateTime() { return updateTime; }
    public void setUpdateTime(LocalDateTime updateTime) { this.updateTime = updateTime; }
    public String getUserName() { return userName; }
    public void setUserName(String userName) { this.userName = userName; }
    public String getUserColor() { return userColor; }
    public void setUserColor(String userColor) { this.userColor = userColor; }
    public String getAssigneeName() { return assigneeName; }
    public void setAssigneeName(String assigneeName) { this.assigneeName = assigneeName; }

    public String getStatusText() { return Dict.TICKET_STATUS.getOrDefault(status, status); }
    public String getPriorityText() { return Dict.PRIORITY.getOrDefault(priority, priority); }
    public String getCreateTimeStr() { return TimeFmt.full(createTime); }
    public String getUpdateTimeStr() { return TimeFmt.full(updateTime); }
    public String[] getTagList() { return aiTags == null || aiTags.isBlank() ? new String[0] : aiTags.split("[,，]"); }

}
