package com.kmu.cs.util;

import java.util.LinkedHashMap;
import java.util.List;
import java.util.Map;

/**
 * 不调大模型时的“规则版 AI”：关键词 → 分类 / 优先级 / 推荐回复。
 * 与现代版（Spring Boot 版）的 Rules 保持一致。
 */
public final class Rules {
    private Rules() {
    }

    /** 关键词 → {分类, 优先级} */
    private static final String[][] CLASSIFY = {
            {"退款", "退款售后", "HIGH"}, {"退货", "退款售后", "MEDIUM"}, {"发票", "发票报销", "MEDIUM"},
            {"快递", "物流配送", "MEDIUM"}, {"物流", "物流配送", "MEDIUM"}, {"签收", "物流配送", "HIGH"},
            {"发货", "物流配送", "LOW"}, {"地址", "物流配送", "LOW"},
            {"密码", "账号安全", "HIGH"}, {"登录", "账号安全", "HIGH"}, {"盗", "账号安全", "URGENT"},
            {"支付", "订单支付", "HIGH"}, {"扣款", "订单支付", "HIGH"}, {"付款", "订单支付", "HIGH"},
            {"闪退", "技术支持", "MEDIUM"}, {"崩溃", "技术支持", "MEDIUM"}, {"打不开", "技术支持", "MEDIUM"},
            {"积分", "会员权益", "LOW"}, {"优惠券", "会员权益", "LOW"}, {"会员", "会员权益", "LOW"},
            {"投诉", "投诉建议", "HIGH"}, {"拒绝", "投诉建议", "HIGH"}
    };

    public static String[] classify(String text) {
        if (text != null) {
            for (String[] r : CLASSIFY) {
                if (text.contains(r[0])) return new String[]{r[1], r[2]};
            }
        }
        return new String[]{"其他", "MEDIUM"};
    }

    /** 客服端 AI 推荐回复（规则版） */
    public static final Map<String, List<String>> SUGGEST = new LinkedHashMap<>();

    static {
        SUGGEST.put("技术支持", List.of("非常抱歉给您带来不便，请问您的手机型号和系统版本是？", "您可以先卸载后重新安装最新版本试试～", "我已为您登记问题，技术同事会在 24 小时内修复"));
        SUGGEST.put("订单支付", List.of("已查到您的支付记录，系统正在同步，预计 5 分钟内更新", "麻烦提供一下支付截图，我帮您加急处理", "如 30 分钟未更新，将为您全额退款"));
        SUGGEST.put("物流配送", List.of("已为您备注加急，仓库会优先打包发货", "当前预计明天上午发出，发货后会短信通知您", "如需修改地址，请告诉我新地址"));
        SUGGEST.put("投诉建议", List.of("非常理解您的心情，平台会介入处理", "请上传商品未拆封的照片，我帮您发起平台仲裁", "处理结果会在 24 小时内通知您"));
        SUGGEST.put("会员权益", List.of("我帮您查询一下积分流水，请稍等", "积分会在每年 12 月 31 日清零上一年度积分哦", "核实为系统异常的话会为您补发积分"));
        SUGGEST.put("退款售后", List.of("已为您催促财务加急处理", "退款会原路退回，银行卡可能有 1-3 天延迟", "我为您创建工单，专人跟进到账情况"));
        SUGGEST.put("账号安全", List.of("为了您的账号安全，请先修改登录密码", "我帮您临时冻结账号，核验身份后再解冻", "建议开启「登录保护」，异地登录需要验证码"));
        SUGGEST.put("发票报销", List.of("我帮您把原发票红冲后重新开具", "请提供正确的发票抬头和税号", "新发票会在 24 小时内发送到您的邮箱"));
        SUGGEST.put("default", List.of("您好，很高兴为您服务，请问有什么可以帮您？", "好的，我马上为您处理", "还有其他问题需要帮助吗？"));
    }

    public static final String DEFAULT_REPLY = "我理解您的问题啦 🤖\n\n目前知识库里没有找到 **完全匹配** 的答案，您可以：\n\n"
            + "- 换个说法再问问我\n- 点击下方 **转人工**，由专业客服为您解答\n- 或者直接 **生成工单**，我们会在 24 小时内回复";

    public static final List<String> WELCOME_SUGGEST = List.of("怎么退款", "修改收货地址", "发票怎么开", "忘记密码");
}
