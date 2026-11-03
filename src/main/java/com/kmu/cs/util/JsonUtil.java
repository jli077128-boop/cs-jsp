package com.kmu.cs.util;

import com.google.gson.Gson;
import com.google.gson.GsonBuilder;
import com.google.gson.ToNumberPolicy;
import com.google.gson.TypeAdapter;
import com.google.gson.stream.JsonReader;
import com.google.gson.stream.JsonWriter;
import javax.servlet.http.HttpServletResponse;

import java.io.IOException;
import java.time.LocalDateTime;
import java.util.LinkedHashMap;
import java.util.Map;

/** JSON 工具：统一返回格式 {code, msg, data}，LocalDateTime 输出为 yyyy-MM-dd HH:mm */
public final class JsonUtil {

    public static final Gson GSON = new GsonBuilder()
            .registerTypeAdapter(LocalDateTime.class, new TypeAdapter<LocalDateTime>() {
                @Override
                public void write(JsonWriter out, LocalDateTime v) throws IOException {
                    if (v == null) out.nullValue();
                    else out.value(TimeFmt.full(v));
                }

                @Override
                public LocalDateTime read(JsonReader in) throws IOException {
                    in.skipValue();
                    return null;
                }
            })
            .setObjectToNumberStrategy(ToNumberPolicy.LONG_OR_DOUBLE)
            .create();

    private JsonUtil() {
    }

    public static String toJson(Object o) {
        return GSON.toJson(o);
    }

    public static void write(HttpServletResponse resp, int code, String msg, Object data) throws IOException {
        Map<String, Object> m = new LinkedHashMap<>();
        m.put("code", code);
        m.put("msg", msg);
        m.put("data", data);
        resp.setContentType("application/json;charset=UTF-8");
        if (code == 401 || code == 403) resp.setStatus(code);
        resp.getWriter().write(GSON.toJson(m));
    }

    public static void ok(HttpServletResponse resp, Object data) throws IOException {
        write(resp, 200, "ok", data);
    }

    public static void fail(HttpServletResponse resp, String msg) throws IOException {
        write(resp, 500, msg, null);
    }

    /**
     * 把任意对象（实体、List、Map）转换成只含 Map / List / String / Number / Boolean 的“纯数据”，
     * 交给 Struts2 json 插件（&lt;result type="json"&gt;）序列化。
     * 这样实体里的 LocalDateTime 仍按 yyyy-MM-dd HH:mm 输出，和原来 Servlet 版接口格式完全一致。
     */
    public static Object toPlain(Object o) {
        if (o == null) return null;
        return GSON.fromJson(GSON.toJson(o), Object.class);
    }

    /** 统一返回结构 {code, msg, data} */
    public static Map<String, Object> result(int code, String msg, Object data) {
        Map<String, Object> m = new LinkedHashMap<>();
        m.put("code", code);
        m.put("msg", msg);
        m.put("data", toPlain(data));
        return m;
    }
}
