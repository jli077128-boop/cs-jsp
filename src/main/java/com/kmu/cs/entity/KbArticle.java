package com.kmu.cs.entity;

import com.kmu.cs.util.Dict;
import com.kmu.cs.util.Md;
import com.kmu.cs.util.TimeFmt;

import java.time.LocalDateTime;

/** 知识库问答 */
public class KbArticle {

    private Long id;
    private Long categoryId;
    private String question;
    private String answer;
    private String keywords;
    private Integer hitCount;
    private Integer status;
    private LocalDateTime createTime;
    private LocalDateTime updateTime;
    private String categoryName;

    public Long getId() { return id; }
    public void setId(Long id) { this.id = id; }
    public Long getCategoryId() { return categoryId; }
    public void setCategoryId(Long categoryId) { this.categoryId = categoryId; }
    public String getQuestion() { return question; }
    public void setQuestion(String question) { this.question = question; }
    public String getAnswer() { return answer; }
    public void setAnswer(String answer) { this.answer = answer; }
    public String getKeywords() { return keywords; }
    public void setKeywords(String keywords) { this.keywords = keywords; }
    public Integer getHitCount() { return hitCount; }
    public void setHitCount(Integer hitCount) { this.hitCount = hitCount; }
    public Integer getStatus() { return status; }
    public void setStatus(Integer status) { this.status = status; }
    public LocalDateTime getCreateTime() { return createTime; }
    public void setCreateTime(LocalDateTime createTime) { this.createTime = createTime; }
    public LocalDateTime getUpdateTime() { return updateTime; }
    public void setUpdateTime(LocalDateTime updateTime) { this.updateTime = updateTime; }
    public String getCategoryName() { return categoryName; }
    public void setCategoryName(String categoryName) { this.categoryName = categoryName; }

    /** 答案渲染成 HTML（已做转义，只支持加粗 / 列表等简单 Markdown） */
    public String getAnswerHtml() { return Md.render(answer); }
    /** 去掉 Markdown 符号的纯文本摘要 */
    public String getAnswerPlain() {
        String s = answer == null ? "" : answer.replaceAll("[*#>`]", "").replaceAll("\\s+", " ").trim();
        return s.length() > 60 ? s.substring(0, 60) + "…" : s;
    }
    public String getUpdateTimeStr() { return TimeFmt.full(updateTime); }

}
