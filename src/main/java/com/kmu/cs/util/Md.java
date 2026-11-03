package com.kmu.cs.util;

/**
 * 极简 Markdown → HTML（服务端渲染知识库答案用）。
 * 先做 HTML 转义防 XSS，再处理 **加粗**、`代码`、- 列表、1. 列表、段落。
 */
public final class Md {
    private Md() {
    }

    public static String escape(String s) {
        if (s == null) return "";
        StringBuilder b = new StringBuilder(s.length() + 16);
        for (char c : s.toCharArray()) {
            switch (c) {
                case '<' -> b.append("&lt;");
                case '>' -> b.append("&gt;");
                case '&' -> b.append("&amp;");
                case '"' -> b.append("&quot;");
                case '\'' -> b.append("&#39;");
                default -> b.append(c);
            }
        }
        return b.toString();
    }

    private static String inline(String s) {
        return escape(s).replaceAll("\\*\\*(.+?)\\*\\*", "<strong>$1</strong>").replaceAll("`(.+?)`", "<code>$1</code>");
    }

    public static String render(String md) {
        if (md == null) return "";
        StringBuilder out = new StringBuilder();
        String list = null; // "ul" / "ol"
        StringBuilder para = new StringBuilder();
        for (String raw : md.split("\\r?\\n")) {
            String line = raw.trim();
            String item = null, type = null;
            if (line.matches("^[-*] .*")) {
                item = line.substring(2);
                type = "ul";
            } else if (line.matches("^\\d+[.、] .*")) {
                item = line.replaceFirst("^\\d+[.、] ", "");
                type = "ol";
            }
            if (item != null) {
                if (para.length() > 0) {
                    out.append("<p>").append(para).append("</p>");
                    para.setLength(0);
                }
                if (!type.equals(list)) {
                    if (list != null) out.append("</").append(list).append(">");
                    out.append("<").append(type).append(">");
                    list = type;
                }
                out.append("<li>").append(inline(item)).append("</li>");
                continue;
            }
            if (list != null) {
                out.append("</").append(list).append(">");
                list = null;
            }
            if (line.isEmpty()) {
                if (para.length() > 0) {
                    out.append("<p>").append(para).append("</p>");
                    para.setLength(0);
                }
            } else {
                if (para.length() > 0) para.append("<br>");
                para.append(inline(line));
            }
        }
        if (list != null) out.append("</").append(list).append(">");
        if (para.length() > 0) out.append("<p>").append(para).append("</p>");
        return out.toString();
    }
}
