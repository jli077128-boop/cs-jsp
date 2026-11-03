package com.kmu.cs.entity;

import com.kmu.cs.util.Dict;
import com.kmu.cs.util.Md;
import com.kmu.cs.util.TimeFmt;

import java.time.LocalDateTime;

/** 知识库分类 */
public class KbCategory {

    private Long id;
    private String name;
    private String icon;
    private String color;
    private String descr;
    private Integer sort;
    private Integer articleCount;

    public Long getId() { return id; }
    public void setId(Long id) { this.id = id; }
    public String getName() { return name; }
    public void setName(String name) { this.name = name; }
    public String getIcon() { return icon; }
    public void setIcon(String icon) { this.icon = icon; }
    public String getColor() { return color; }
    public void setColor(String color) { this.color = color; }
    public String getDescr() { return descr; }
    public void setDescr(String descr) { this.descr = descr; }
    public Integer getSort() { return sort; }
    public void setSort(Integer sort) { this.sort = sort; }
    public Integer getArticleCount() { return articleCount; }
    public void setArticleCount(Integer articleCount) { this.articleCount = articleCount; }

    /** 把现代版存的 Element Plus 图标名映射成 Remix Icon 的 class */
    public String getIconClass() {
        if (icon != null && icon.startsWith("ri-")) return icon;
        return switch (icon == null ? "" : icon) {
            case "User" -> "ri-shield-user-line";
            case "Wallet" -> "ri-wallet-3-line";
            case "RefreshLeft" -> "ri-refund-2-line";
            case "Van" -> "ri-truck-line";
            case "Tickets" -> "ri-bill-line";
            case "Trophy" -> "ri-vip-crown-2-line";
            case "Monitor" -> "ri-smartphone-line";
            case "ChatLineSquare" -> "ri-feedback-line";
            default -> "ri-file-text-line";
        };
    }
    public String getColor1() { return color == null ? "#4f7cff" : color.split(",")[0]; }
    public String getColor2() { String[] c = color == null ? new String[0] : color.split(","); return c.length > 1 ? c[1] : getColor1(); }

}
