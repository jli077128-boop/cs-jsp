package com.kmu.cs.dao;

import com.kmu.cs.entity.KbCategory;

import java.util.List;

public interface CategoryDao {
    List<KbCategory> listAll();

    KbCategory findById(Long id);

    long insert(KbCategory c);

    void update(KbCategory c);

    void delete(Long id);
}
