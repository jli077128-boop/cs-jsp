package com.kmu.cs.action;

import com.kmu.cs.entity.KbArticle;
import com.kmu.cs.entity.KbCategory;
import com.kmu.cs.service.ServiceFactory;
import com.kmu.cs.util.BizException;

import java.util.ArrayList;
import java.util.List;

/**
 * 批量新增知识库问答 —— 批量参数接收 List&lt;KbArticle&gt;（对应课堂 03_strutsParams/customerBatch.jsp）。
 * 表单字段写成 articles[0].question、articles[0].answer、articles[1].question ...，
 * Struts 根据 List 的泛型 KbArticle 自动创建对象并按下标放进集合。
 *   /admin/kbBatchForm.action → method="input" 显示 5 行空表单
 *   /admin/kbBatch.action     → execute 保存（跳过问题为空的行），有错误返回 input 并保留已填写内容
 */
public class AdminKbBatchAction extends BaseAction {

    public static final int ROWS = 5;

    private List<KbArticle> articles = new ArrayList<>();
    private List<KbCategory> categories;
    private int savedCount;

    @Override
    public String input() {
        categories = ServiceFactory.KNOWLEDGE.categories();
        while (articles.size() < ROWS) articles.add(new KbArticle());
        return INPUT;
    }

    @Override
    public void validate() {
        boolean any = false;
        for (int i = 0; i < articles.size(); i++) {
            KbArticle a = articles.get(i);
            if (a == null || blank(a.getQuestion())) continue;
            any = true;
            if (a.getCategoryId() == null) addFieldError("articles[" + i + "].categoryId", "第 " + (i + 1) + " 行：请选择分类");
            if (blank(a.getAnswer())) addFieldError("articles[" + i + "].answer", "第 " + (i + 1) + " 行：答案不能为空");
        }
        if (!any) addActionError(getText("kb.batch.empty"));
        if (hasErrors()) input(); // 返回 input 时页面仍需要分类下拉框，并补足空行
    }

    @Override
    public String execute() {
        int n = 0;
        try {
            for (KbArticle a : articles) {
                if (a == null || blank(a.getQuestion())) continue;
                a.setId(null);
                a.setQuestion(a.getQuestion().trim());
                a.setKeywords(trim(a.getKeywords()));
                a.setStatus(a.getStatus() == null ? 1 : (a.getStatus() == 1 ? 1 : 0));
                ServiceFactory.KNOWLEDGE.saveArticle(a);
                n++;
            }
        } catch (BizException e) {
            addActionError(e.getMessage());
            input();
            return INPUT;
        }
        savedCount = n;
        flash("批量新增成功，共 " + n + " 条问答");
        return SUCCESS;
    }

    public List<KbArticle> getArticles() { return articles; }
    public void setArticles(List<KbArticle> articles) { this.articles = articles; }
    public List<KbCategory> getCategories() { return categories; }
    public int getSavedCount() { return savedCount; }
}
