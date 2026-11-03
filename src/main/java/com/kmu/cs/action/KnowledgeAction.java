package com.kmu.cs.action;

import com.kmu.cs.entity.KbArticle;
import com.kmu.cs.entity.KbCategory;
import com.kmu.cs.service.ServiceFactory;

import java.util.List;

/** 用户端知识库：列表 / 搜索 / 分类筛选（execute）与详情（detail） */
public class KnowledgeAction extends BaseAction {

    private Long cid;
    private String q;
    private Long id;
    private List<KbCategory> categories;
    private KbCategory currentCategory;
    private List<KbArticle> articles;
    private KbArticle article;
    private List<KbArticle> related;

    @Override
    public String execute() {
        categories = ServiceFactory.KNOWLEDGE.categories();
        currentCategory = ServiceFactory.KNOWLEDGE.category(cid);
        articles = ServiceFactory.KNOWLEDGE.articles(cid, q, true);
        return SUCCESS;
    }

    /** /user/kbDetail.action?id= */
    public String detail() {
        categories = ServiceFactory.KNOWLEDGE.categories();
        KbArticle a = id == null ? null : ServiceFactory.KNOWLEDGE.article(id);
        if (a == null || a.getStatus() != 1) {
            org.apache.struts2.ServletActionContext.getResponse().setStatus(404);
            return NOT_FOUND;
        }
        article = a;
        related = ServiceFactory.KNOWLEDGE.articles(a.getCategoryId(), null, true)
                .stream().filter(x -> !x.getId().equals(a.getId())).limit(5).toList();
        return SUCCESS;
    }

    public Long getCid() { return cid; }
    public void setCid(Long cid) { this.cid = cid; }
    public String getQ() { return q; }
    public void setQ(String q) { this.q = trim(q); }
    public void setId(Long id) { this.id = id; }
    public List<KbCategory> getCategories() { return categories; }
    public KbCategory getCurrentCategory() { return currentCategory; }
    public List<KbArticle> getArticles() { return articles; }
    public KbArticle getArticle() { return article; }
    public List<KbArticle> getRelated() { return related; }
}
