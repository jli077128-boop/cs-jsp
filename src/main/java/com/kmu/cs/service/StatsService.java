package com.kmu.cs.service;

import java.util.Map;

public interface StatsService {
    /** 管理员看板：KPI + 近 7 天趋势 + 工单状态分布 + 热门问题 + 分类占比 */
    Map<String, Object> dashboard();
}
