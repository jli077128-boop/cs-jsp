package com.kmu.cs.util;

import java.time.LocalDate;
import java.time.LocalDateTime;
import java.time.format.DateTimeFormatter;
import java.time.temporal.ChronoUnit;

/** 时间格式化（JSTL 的 fmt:formatDate 不支持 LocalDateTime，所以在实体里提供字符串 getter） */
public final class TimeFmt {
    private static final DateTimeFormatter FULL = DateTimeFormatter.ofPattern("yyyy-MM-dd HH:mm");
    private static final DateTimeFormatter HM = DateTimeFormatter.ofPattern("HH:mm");
    private static final DateTimeFormatter MD = DateTimeFormatter.ofPattern("MM-dd");

    private TimeFmt() {
    }

    public static String full(LocalDateTime t) {
        return t == null ? "" : t.format(FULL);
    }

    public static String hm(LocalDateTime t) {
        return t == null ? "" : t.format(HM);
    }

    /** 刚刚 / 5 分钟前 / 今天 10:20 / 昨天 / 10-18 */
    public static String friendly(LocalDateTime t) {
        if (t == null) return "";
        long min = ChronoUnit.MINUTES.between(t, LocalDateTime.now());
        if (min < 1) return "刚刚";
        if (min < 60) return min + " 分钟前";
        LocalDate d = t.toLocalDate(), today = LocalDate.now();
        if (d.equals(today)) return t.format(HM);
        if (d.equals(today.minusDays(1))) return "昨天";
        return t.format(MD);
    }
}
