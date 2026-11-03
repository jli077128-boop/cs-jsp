package com.kmu.cs.action;

import com.kmu.cs.entity.KbArticle;
import com.kmu.cs.entity.KbCategory;
import com.kmu.cs.service.ServiceFactory;
import com.kmu.cs.util.BizException;

import java.util.List;
import java.util.function.Supplier;

/**
 * 管理员知识库管理。struts.xml 中：
 *   kb   → execute() 列表（分类 / 关键字 / 状态筛选）
 *   kb_* → method="{1}"，allowed-methods: articleSave, articleToggle, articleDelete, categorySave, categoryDelete
 * 表单操作结束后 type="redirect" 回到列表（PRG 模式，提示放 session 显示一次）。
 */
public class AdminKnowledgeAction extends BaseAction {

    // 列表筛选
    private Long cid;
    private String q;
    private String status;
    private String back;
    // 问答 / 分类表单字段（Action 属性接收）
    private Long id;
    private Long categoryId;
    private String question;
    private String answer;
    private String keywords;
    private String name;
    private String descr;
    private String icon;
    private String color1;
    private String color2;
    private Integer sort;

    private List<KbCategory> categories;
    private List<KbArticle> articles;
    private int allCount;

    @Override
    public String execute() {
        var list = ServiceFactory.KNOWLEDGE.articles(cid, blank(q) ? null : q, false);
        if ("1".equals(status) || "0".equals(status)) {
            int st = Integer.parseInt(status);
            list = list.stream().filter(a -> a.getStatus() == st).toList();
        }
        categories = ServiceFactory.KNOWLEDGE.categories();
        articles = list;
        allCount = ServiceFactory.KNOWLEDGE.articles(null, null, false).size();
        return SUCCESS;
    }

    public String articleSave() {
        return run(() -> {
            KbArticle a = new KbArticle();
            a.setId(id);
            a.setCategoryId(categoryId);
            a.setQuestion(trim(question));
            a.setAnswer(answer);
            a.setKeywords(trim(keywords));
            a.setStatus("1".equals(status) ? 1 : 0);
            ServiceFactory.KNOWLEDGE.saveArticle(a);
            return id == null ? "问答已新增" : "问答已保存";
        });
    }

    public String articleToggle() {
        return run(() -> {
            int st = "1".equals(status) ? 1 : 0;
            ServiceFactory.KNOWLEDGE.toggleArticle(id, st);
            return st == 1 ? "已启用，AI 将使用这条问答" : "已停用，AI 不再使用这条问答";
        });
    }

    public String articleDelete() {
        return run(() -> {
            ServiceFactory.KNOWLEDGE.deleteArticle(id);
            return "问答已删除";
        });
    }

    public String categorySave() {
        return run(() -> {
            KbCategory c = new KbCategory();
            c.setId(id);
            c.setName(trim(name));
            c.setDescr(trim(descr));
            c.setIcon(trim(icon));
            if (!blank(color1) && !blank(color2)) c.setColor(color1.trim() + "," + color2.trim());
            c.setSort(sort);
            ServiceFactory.KNOWLEDGE.saveCategory(c);
            return id == null ? "分类已新增" : "分类已保存";
        });
    }

    public String categoryDelete() {
        return run(() -> {
            ServiceFactory.KNOWLEDGE.deleteCategory(id);
            return "分类已删除";
        });
    }

    private String run(Supplier<String> body) {
        try {
            flash(body.get());
        } catch (BizException e) {
            flashError(e.getMessage());
        }
        return SUCCESS;
    }

    /** 操作后回到的列表地址（只允许 ?cid=数字，防止开放重定向） */
    public String getReturnUrl() {
        return "/admin/kb.action" + (back != null && back.matches("^\\?cid=\\d+$") ? back : "");
    }

    public Long getCid() { return cid; }
    public void setCid(Long cid) { this.cid = cid; }
    public String getQ() { return q; }
    public void setQ(String q) { this.q = trim(q); }
    public String getStatus() { return status; }
    public void setStatus(String status) { this.status = trim(status); }
    public void setBack(String back) { this.back = back; }
    public void setId(Long id) { this.id = id; }
    public void setCategoryId(Long categoryId) { this.categoryId = categoryId; }
    public void setQuestion(String question) { this.question = question; }
    public void setAnswer(String answer) { this.answer = answer; }
    public void setKeywords(String keywords) { this.keywords = keywords; }
    public void setName(String name) { this.name = name; }
    public void setDescr(String descr) { this.descr = descr; }
    public void setIcon(String icon) { this.icon = icon; }
    public void setColor1(String color1) { this.color1 = color1; }
    public void setColor2(String color2) { this.color2 = color2; }
    public void setSort(Integer sort) { this.sort = sort; }
    public List<KbCategory> getCategories() { return categories; }
    public List<KbArticle> getArticles() { return articles; }
    public int getAllCount() { return allCount; }
}
