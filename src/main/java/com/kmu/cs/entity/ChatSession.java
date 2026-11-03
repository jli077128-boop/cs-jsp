package com.kmu.cs.entity;

import com.kmu.cs.util.Dict;
import com.kmu.cs.util.Md;
import com.kmu.cs.util.TimeFmt;

import java.time.LocalDateTime;

/** 会话 */
public class ChatSession {

    private Long id;
    private Long userId;
    private Long agentId;
    private String title;
    private String mode;
    private String status;
    private Integer aiSolved;
    private Integer rating;
    private LocalDateTime startTime;
    private LocalDateTime endTime;
    private String lastMsg;
    private String userName;
    private String userColor;

    public Long getId() { return id; }
    public void setId(Long id) { this.id = id; }
    public Long getUserId() { return userId; }
    public void setUserId(Long userId) { this.userId = userId; }
    public Long getAgentId() { return agentId; }
    public void setAgentId(Long agentId) { this.agentId = agentId; }
    public String getTitle() { return title; }
    public void setTitle(String title) { this.title = title; }
    public String getMode() { return mode; }
    public void setMode(String mode) { this.mode = mode; }
    public String getStatus() { return status; }
    public void setStatus(String status) { this.status = status; }
    public Integer getAiSolved() { return aiSolved; }
    public void setAiSolved(Integer aiSolved) { this.aiSolved = aiSolved; }
    public Integer getRating() { return rating; }
    public void setRating(Integer rating) { this.rating = rating; }
    public LocalDateTime getStartTime() { return startTime; }
    public void setStartTime(LocalDateTime startTime) { this.startTime = startTime; }
    public LocalDateTime getEndTime() { return endTime; }
    public void setEndTime(LocalDateTime endTime) { this.endTime = endTime; }
    public String getLastMsg() { return lastMsg; }
    public void setLastMsg(String lastMsg) { this.lastMsg = lastMsg; }
    public String getUserName() { return userName; }
    public void setUserName(String userName) { this.userName = userName; }
    public String getUserColor() { return userColor; }
    public void setUserColor(String userColor) { this.userColor = userColor; }

    public String getStatusText() {
        return switch (status == null ? "" : status) { case "QUEUE" -> "排队中"; case "ENDED" -> "已结束"; default -> "进行中"; };
    }
    public String getStartTimeStr() { return TimeFmt.full(startTime); }
    public String getFriendlyTime() { return TimeFmt.friendly(startTime); }

}
