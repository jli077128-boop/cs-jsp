package com.kmu.cs.dao;

import com.kmu.cs.entity.KbArticle;

import java.util.List;

public interface ArticleDao {
    /** categoryId / keyword 为空时不作为条件；onlyEnabled=true 只查启用的 */
    List<KbArticle> list(Long categoryId, String keyword, boolean onlyEnabled);

    List<KbArticle> hot(int limit);

    KbArticle findById(Long id);

    long insert(KbArticle a);

    void update(KbArticle a);

    void delete(Long id);

    void updateStatus(Long id, int status);

    void increaseHit(Long id);

    long countByCategory(Long categoryId);
}
