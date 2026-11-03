package com.kmu.cs.util;

import java.util.LinkedHashMap;
import java.util.Map;

/** 字典：状态 / 优先级 / 操作 的中文名（和现代版保持一致） */
public final class Dict {
    private Dict() {
    }

    public static final Map<String, String> TICKET_STATUS = new LinkedHashMap<>();
    public static final Map<String, String> PRIORITY = new LinkedHashMap<>();
    public static final Map<String, String> ACTION = new LinkedHashMap<>();
    /** 工单状态变更时，时间线默认写的文字 */
    public static final Map<String, String> STATUS_ACTION_TEXT = new LinkedHashMap<>();
    public static final String[] TICKET_CATEGORIES = {"账号安全", "订单支付", "退款售后", "物流配送", "发票报销", "会员权益", "技术支持", "投诉建议", "其他"};

    static {
        TICKET_STATUS.put("PENDING", "待处理");
        TICKET_STATUS.put("PROCESSING", "处理中");
        TICKET_STATUS.put("RESOLVED", "已解决");
        TICKET_STATUS.put("CLOSED", "已关闭");

        PRIORITY.put("LOW", "低");
        PRIORITY.put("MEDIUM", "中");
        PRIORITY.put("HIGH", "高");
        PRIORITY.put("URGENT", "紧急");

        ACTION.put("CREATE", "提交工单");
        ACTION.put("AI", "AI 分析");
        ACTION.put("ASSIGN", "分配客服");
        ACTION.put("PROCESS", "处理中");
        ACTION.put("RESOLVE", "已解决");
        ACTION.put("CLOSE", "已关闭");

        STATUS_ACTION_TEXT.put("PENDING", "退回待处理");
        STATUS_ACTION_TEXT.put("PROCESSING", "开始处理");
        STATUS_ACTION_TEXT.put("RESOLVED", "标记为已解决");
        STATUS_ACTION_TEXT.put("CLOSED", "关闭工单");
    }
}
