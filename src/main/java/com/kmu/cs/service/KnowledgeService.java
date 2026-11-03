package com.kmu.cs.service;

import com.kmu.cs.entity.KbArticle;
import com.kmu.cs.entity.KbCategory;

import java.util.List;

public interface KnowledgeService {
    List<KbCategory> categories();

    KbCategory category(Long id);

    void saveCategory(KbCategory c);

    void deleteCategory(Long id);

    List<KbArticle> articles(Long categoryId, String keyword, boolean onlyEnabled);

    List<KbArticle> hot(int n);

    KbArticle article(Long id);

    void saveArticle(KbArticle a);

    void deleteArticle(Long id);

    void toggleArticle(Long id, int status);

    /** 关键词打分检索，返回最相关的 topN 条（给 AI 用） */
    List<KbArticle> search(String question, int topN);

    void hit(Long id);
}
