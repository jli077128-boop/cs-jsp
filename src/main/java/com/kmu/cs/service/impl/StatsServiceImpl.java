package com.kmu.cs.service.impl;

import com.kmu.cs.dao.ArticleDao;
import com.kmu.cs.dao.ChatSessionDao;
import com.kmu.cs.dao.TicketDao;
import com.kmu.cs.dao.UserDao;
import com.kmu.cs.dao.impl.ArticleDaoImpl;
import com.kmu.cs.dao.impl.ChatSessionDaoImpl;
import com.kmu.cs.dao.impl.TicketDaoImpl;
import com.kmu.cs.dao.impl.UserDaoImpl;
import com.kmu.cs.entity.ChatSession;
import com.kmu.cs.entity.KbArticle;
import com.kmu.cs.service.StatsService;
import com.kmu.cs.util.Dict;

import java.math.BigDecimal;
import java.math.RoundingMode;
import java.time.LocalDate;
import java.time.format.DateTimeFormatter;
import java.util.ArrayList;
import java.util.LinkedHashMap;
import java.util.List;
import java.util.Map;
import java.util.OptionalDouble;

/** 管理员数据看板：全部从数据库实时统计（口径与现代版一致） */
public class StatsServiceImpl implements StatsService {

    private final ChatSessionDao sessionDao = new ChatSessionDaoImpl();
    private final TicketDao ticketDao = new TicketDaoImpl();
    private final ArticleDao articleDao = new ArticleDaoImpl();
    private final UserDao userDao = new UserDaoImpl();

    @Override
    public Map<String, Object> dashboard() {
        LocalDate today = LocalDate.now();
        List<ChatSession> sessions = sessionDao.listSince(today.minusDays(6).atStartOfDay());

        // 近 7 天趋势
        List<String> days = new ArrayList<>();
        List<Integer> total = new ArrayList<>(), ai = new ArrayList<>(), human = new ArrayList<>();
        for (int i = 6; i >= 0; i--) {
            LocalDate d = today.minusDays(i);
            days.add(d.format(DateTimeFormatter.ofPattern("MM-dd")));
            int t = 0, a = 0;
            for (ChatSession s : sessions) {
                if (s.getStartTime().toLocalDate().equals(d)) {
                    t++;
                    if (s.getAiSolved() != null && s.getAiSolved() == 1) a++;
                }
            }
            total.add(t);
            ai.add(a);
            human.add(t - a);
        }

        // KPI
        int sum = total.stream().mapToInt(Integer::intValue).sum();
        int aiSum = ai.stream().mapToInt(Integer::intValue).sum();
        OptionalDouble avg = sessions.stream().filter(s -> s.getRating() != null).mapToInt(ChatSession::getRating).average();
        Map<String, Object> kpi = new LinkedHashMap<>();
        kpi.put("todaySessions", total.get(6));
        kpi.put("weekSessions", sum);
        kpi.put("aiResolveRate", sum == 0 ? 0 : round(aiSum * 100.0 / sum, 1));
        kpi.put("pendingTickets", ticketDao.countByStatus("PENDING"));
        kpi.put("avgRating", avg.isPresent() ? round(avg.getAsDouble(), 2) : 0);
        kpi.put("onlineAgents", userDao.countOnlineAgents());
        kpi.put("queueCount", sessionDao.countQueue());
        kpi.put("userCount", userDao.countByRole("USER"));

        // 工单状态分布
        Map<String, Long> byStatus = ticketDao.groupByStatus();
        List<Map<String, Object>> ticketStatus = new ArrayList<>();
        long ticketTotal = 0;
        for (Map.Entry<String, String> e : Dict.TICKET_STATUS.entrySet()) {
            long v = byStatus.getOrDefault(e.getKey(), 0L);
            ticketTotal += v;
            ticketStatus.add(Map.of("name", e.getValue(), "value", v));
        }
        kpi.put("ticketTotal", ticketTotal);

        // 分类占比（百分比）
        List<Map<String, Object>> categoryShare = new ArrayList<>();
        final long tt = Math.max(1, ticketTotal);
        ticketDao.groupByCategory().forEach((k, v) -> categoryShare.add(Map.of("name", k, "value", Math.round(v * 100.0 / tt))));

        // 热门问题 Top5（按知识库命中次数）
        List<Map<String, Object>> hotTop = new ArrayList<>();
        for (KbArticle a : articleDao.hot(5)) {
            hotTop.add(Map.of("name", a.getQuestion().replaceAll("[？?]$", ""), "value", a.getHitCount()));
        }

        Map<String, Object> out = new LinkedHashMap<>();
        out.put("kpi", kpi);
        out.put("trend", Map.of("days", days, "total", total, "ai", ai, "human", human));
        out.put("ticketStatus", ticketStatus);
        out.put("hotTop", hotTop);
        out.put("categoryShare", categoryShare);
        return out;
    }

    private static double round(double v, int scale) {
        return BigDecimal.valueOf(v).setScale(scale, RoundingMode.HALF_UP).doubleValue();
    }
}
