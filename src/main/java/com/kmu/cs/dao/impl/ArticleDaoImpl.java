package com.kmu.cs.dao.impl;

import com.kmu.cs.dao.ArticleDao;
import com.kmu.cs.dao.BaseDao;
import com.kmu.cs.entity.KbArticle;

import java.time.LocalDateTime;
import java.util.ArrayList;
import java.util.List;

public class ArticleDaoImpl extends BaseDao implements ArticleDao {

    private static final String SELECT = "SELECT a.*, c.name AS category_name FROM kb_article a LEFT JOIN kb_category c ON a.category_id = c.id ";

    private static final RowMapper<KbArticle> MAPPER = rs -> {
        KbArticle a = new KbArticle();
        a.setId(rs.getLong("id"));
        a.setCategoryId(rs.getLong("category_id"));
        a.setQuestion(rs.getString("question"));
        a.setAnswer(rs.getString("answer"));
        a.setKeywords(rs.getString("keywords"));
        a.setHitCount(rs.getInt("hit_count"));
        a.setStatus(rs.getInt("status"));
        a.setCreateTime(getTime(rs, "create_time"));
        a.setUpdateTime(getTime(rs, "update_time"));
        a.setCategoryName(rs.getString("category_name"));
        return a;
    };

    @Override
    public List<KbArticle> list(Long categoryId, String keyword, boolean onlyEnabled) {
        StringBuilder sql = new StringBuilder(SELECT).append("WHERE 1=1");
        List<Object> args = new ArrayList<>();
        if (categoryId != null) {
            sql.append(" AND a.category_id = ?");
            args.add(categoryId);
        }
        if (keyword != null && !keyword.isBlank()) {
            sql.append(" AND (a.question LIKE ? OR a.keywords LIKE ? OR a.answer LIKE ?)");
            String k = "%" + keyword.trim() + "%";
            args.add(k);
            args.add(k);
            args.add(k);
        }
        if (onlyEnabled) sql.append(" AND a.status = 1");
        sql.append(" ORDER BY a.hit_count DESC, a.id");
        return query(sql.toString(), MAPPER, args.toArray());
    }

    @Override
    public List<KbArticle> hot(int limit) {
        return query(SELECT + "WHERE a.status = 1 ORDER BY a.hit_count DESC LIMIT ?", MAPPER, limit);
    }

    @Override
    public KbArticle findById(Long id) {
        return queryOne(SELECT + "WHERE a.id = ?", MAPPER, id);
    }

    @Override
    public long insert(KbArticle a) {
        LocalDateTime now = LocalDateTime.now();
        return insert("INSERT INTO kb_article (category_id, question, answer, keywords, hit_count, status, create_time, update_time) VALUES (?,?,?,?,0,?,?,?)",
                a.getCategoryId(), a.getQuestion(), a.getAnswer(), a.getKeywords(), a.getStatus() == null ? 1 : a.getStatus(), now, now);
    }

    @Override
    public void update(KbArticle a) {
        update("UPDATE kb_article SET category_id = ?, question = ?, answer = ?, keywords = ?, status = ?, update_time = ? WHERE id = ?",
                a.getCategoryId(), a.getQuestion(), a.getAnswer(), a.getKeywords(), a.getStatus(), LocalDateTime.now(), a.getId());
    }

    @Override
    public void delete(Long id) {
        update("DELETE FROM kb_article WHERE id = ?", id);
    }

    @Override
    public void updateStatus(Long id, int status) {
        update("UPDATE kb_article SET status = ?, update_time = ? WHERE id = ?", status, LocalDateTime.now(), id);
    }

    @Override
    public void increaseHit(Long id) {
        update("UPDATE kb_article SET hit_count = hit_count + 1 WHERE id = ?", id);
    }

    @Override
    public long countByCategory(Long categoryId) {
        return count("SELECT COUNT(*) FROM kb_article WHERE category_id = ?", categoryId);
    }
}
