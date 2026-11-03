package com.kmu.cs.dao.impl;

import com.kmu.cs.dao.BaseDao;
import com.kmu.cs.dao.CategoryDao;
import com.kmu.cs.entity.KbCategory;

import java.util.List;

public class CategoryDaoImpl extends BaseDao implements CategoryDao {

    private static final RowMapper<KbCategory> MAPPER = rs -> {
        KbCategory c = new KbCategory();
        c.setId(rs.getLong("id"));
        c.setName(rs.getString("name"));
        c.setIcon(rs.getString("icon"));
        c.setColor(rs.getString("color"));
        c.setDescr(rs.getString("descr"));
        c.setSort(rs.getInt("sort"));
        if (hasColumn(rs, "article_count")) c.setArticleCount(rs.getInt("article_count"));
        return c;
    };

    @Override
    public List<KbCategory> listAll() {
        return query("SELECT c.*, (SELECT COUNT(*) FROM kb_article a WHERE a.category_id = c.id AND a.status = 1) AS article_count "
                + "FROM kb_category c ORDER BY c.sort, c.id", MAPPER);
    }

    @Override
    public KbCategory findById(Long id) {
        return queryOne("SELECT * FROM kb_category WHERE id = ?", MAPPER, id);
    }

    @Override
    public long insert(KbCategory c) {
        return insert("INSERT INTO kb_category (name, icon, color, descr, sort) VALUES (?,?,?,?,?)",
                c.getName(), c.getIcon(), c.getColor(), c.getDescr(), c.getSort());
    }

    @Override
    public void update(KbCategory c) {
        update("UPDATE kb_category SET name = ?, icon = ?, color = ?, descr = ?, sort = ? WHERE id = ?",
                c.getName(), c.getIcon(), c.getColor(), c.getDescr(), c.getSort(), c.getId());
    }

    @Override
    public void delete(Long id) {
        update("DELETE FROM kb_category WHERE id = ?", id);
    }
}
