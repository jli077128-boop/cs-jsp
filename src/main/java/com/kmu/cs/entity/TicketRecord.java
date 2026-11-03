package com.kmu.cs.entity;

import com.kmu.cs.util.Dict;
import com.kmu.cs.util.Md;
import com.kmu.cs.util.TimeFmt;

import java.time.LocalDateTime;

/** 工单处理记录（时间线） */
public class TicketRecord {

    private Long id;
    private Long ticketId;
    private Long operatorId;
    private String operatorName;
    private String action;
    private String content;
    private LocalDateTime createTime;

    public Long getId() { return id; }
    public void setId(Long id) { this.id = id; }
    public Long getTicketId() { return ticketId; }
    public void setTicketId(Long ticketId) { this.ticketId = ticketId; }
    public Long getOperatorId() { return operatorId; }
    public void setOperatorId(Long operatorId) { this.operatorId = operatorId; }
    public String getOperatorName() { return operatorName; }
    public void setOperatorName(String operatorName) { this.operatorName = operatorName; }
    public String getAction() { return action; }
    public void setAction(String action) { this.action = action; }
    public String getContent() { return content; }
    public void setContent(String content) { this.content = content; }
    public LocalDateTime getCreateTime() { return createTime; }
    public void setCreateTime(LocalDateTime createTime) { this.createTime = createTime; }

    public String getActionText() { return Dict.ACTION.getOrDefault(action, action); }
    public String getCreateTimeStr() { return TimeFmt.full(createTime); }

}
