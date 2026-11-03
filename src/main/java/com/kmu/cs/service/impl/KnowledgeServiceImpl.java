package com.kmu.cs.service.impl;

import com.kmu.cs.dao.ArticleDao;
import com.kmu.cs.dao.CategoryDao;
import com.kmu.cs.dao.impl.ArticleDaoImpl;
import com.kmu.cs.dao.impl.CategoryDaoImpl;
import com.kmu.cs.entity.KbArticle;
import com.kmu.cs.entity.KbCategory;
import com.kmu.cs.service.KnowledgeService;
import com.kmu.cs.util.BizException;

import java.util.HashMap;
import java.util.List;
import java.util.Map;

public class KnowledgeServiceImpl implements KnowledgeService {

    private final CategoryDao categoryDao = new CategoryDaoImpl();
    private final ArticleDao articleDao = new ArticleDaoImpl();

    @Override
    public List<KbCategory> categories() {
        return categoryDao.listAll();
    }

    @Override
    public KbCategory category(Long id) {
        return id == null ? null : categoryDao.findById(id);
    }

    @Override
    public void saveCategory(KbCategory c) {
        if (c.getName() == null || c.getName().isBlank()) throw new BizException("分类名称不能为空");
        if (c.getColor() == null || c.getColor().isBlank()) c.setColor("#4f7cff,#22d3ee");
        if (c.getIcon() == null || c.getIcon().isBlank()) c.setIcon("Document");
        if (c.getSort() == null) c.setSort(99);
        if (c.getId() == null) categoryDao.insert(c);
        else categoryDao.update(c);
    }

    @Override
    public void deleteCategory(Long id) {
        if (articleDao.countByCategory(id) > 0) throw new BizException("该分类下还有问答，不能删除");
        categoryDao.delete(id);
    }

    @Override
    public List<KbArticle> articles(Long categoryId, String keyword, boolean onlyEnabled) {
        return articleDao.list(categoryId, keyword, onlyEnabled);
    }

    @Override
    public List<KbArticle> hot(int n) {
        return articleDao.hot(Math.max(1, Math.min(n, 50)));
    }

    @Override
    public KbArticle article(Long id) {
        return id == null ? null : articleDao.findById(id);
    }

    @Override
    public void saveArticle(KbArticle a) {
        if (a.getCategoryId() == null) throw new BizException("请选择分类");
        if (a.getQuestion() == null || a.getQuestion().isBlank()) throw new BizException("问题不能为空");
        if (a.getAnswer() == null || a.getAnswer().isBlank()) throw new BizException("答案不能为空");
        if (a.getStatus() == null) a.setStatus(1);
        if (a.getId() == null) articleDao.insert(a);
        else articleDao.update(a);
    }

    @Override
    public void deleteArticle(Long id) {
        articleDao.delete(id);
    }

    @Override
    public void toggleArticle(Long id, int status) {
        articleDao.updateStatus(id, status == 1 ? 1 : 0);
    }

    /**
     * 简单检索（与现代版一致）：命中关键词 +10 分，问题中的字在标准问题里出现一次 +1 分，
     * 总分 ≥ 10 才算相关，取分数最高的 topN 条。
     */
    @Override
    public List<KbArticle> search(String question, int topN) {
        Map<KbArticle, Integer> score = new HashMap<>();
        for (KbArticle a : articleDao.list(null, null, true)) {
            int s = 0;
            if (a.getKeywords() != null) {
                for (String k : a.getKeywords().split("[,，]")) {
                    if (!k.isBlank() && question.contains(k.trim())) s += 10;
                }
            }
            String q = a.getQuestion();
            for (char c : question.toCharArray()) {
                if (Character.isLetterOrDigit(c) && q.indexOf(c) >= 0) s += 1;
            }
            if (s >= 10) score.put(a, s);
        }
        return score.entrySet().stream()
                .sorted((x, y) -> y.getValue() - x.getValue())
                .limit(topN).map(Map.Entry::getKey).toList();
    }

    @Override
    public void hit(Long id) {
        articleDao.increaseHit(id);
    }
}
