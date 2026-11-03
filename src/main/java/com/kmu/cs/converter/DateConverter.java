package com.kmu.cs.converter;

import org.apache.struts2.conversion.TypeConversionException;
import org.apache.struts2.util.StrutsTypeConverter;

import java.text.ParseException;
import java.text.SimpleDateFormat;
import java.util.Date;
import java.util.Map;

/**
 * 自定义类型转换器（对应课堂 04_strutsConversion）：
 * 把表单提交的 "yyyy-MM-dd" 字符串转换成 java.util.Date，回显时再转回字符串。
 * 在 src/main/resources/xwork-conversion.properties（以及 Struts 6 推荐的 struts-conversion.properties）中全局注册：
 *     java.util.Date=com.kmu.cs.converter.DateConverter
 * 使用位置：管理员「工单管理」页的按日期范围筛选（AdminTicketAction.startDate / endDate）。
 * 格式不对时抛出 TypeConversionException，conversionError 拦截器会把它变成字段错误并返回 input。
 */
public class DateConverter extends StrutsTypeConverter {

    public static final String PATTERN = "yyyy-MM-dd";

    @Override
    @SuppressWarnings("rawtypes")
    public Object convertFromString(Map context, String[] values, Class toClass) {
        if (values == null || values.length == 0 || values[0] == null || values[0].isBlank()) return null;
        String v = values[0].trim();
        SimpleDateFormat f = new SimpleDateFormat(PATTERN);
        f.setLenient(false); // 2026-02-30 这种不存在的日期也算错误
        try {
            if (!v.matches("\\d{4}-\\d{1,2}-\\d{1,2}")) throw new ParseException(v, 0);
            return f.parse(v);
        } catch (ParseException e) {
            throw new TypeConversionException("日期格式应为 " + PATTERN + "：" + v);
        }
    }

    @Override
    @SuppressWarnings("rawtypes")
    public String convertToString(Map context, Object o) {
        return o instanceof Date d ? new SimpleDateFormat(PATTERN).format(d) : null;
    }
}
