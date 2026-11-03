package com.kmu.cs.util;

import com.google.gson.JsonArray;
import com.google.gson.JsonObject;
import com.google.gson.JsonParser;

import java.io.InputStream;
import java.io.InputStreamReader;
import java.net.URI;
import java.net.http.HttpClient;
import java.net.http.HttpRequest;
import java.net.http.HttpResponse;
import java.nio.charset.StandardCharsets;
import java.time.Duration;
import java.util.List;
import java.util.Map;
import java.util.Properties;

/**
 * 大模型客户端：调用 OpenAI 兼容的 /chat/completions 接口（DeepSeek、通义千问、Kimi、智谱等都兼容）。
 * llm.properties 里 api-key 为空时 enabled() 返回 false，系统自动改用“知识库关键词匹配”回答。
 */
public final class LlmClient {

    private static final String BASE_URL;
    private static final String API_KEY;
    private static final String MODEL;
    private static final int TIMEOUT;
    private static final HttpClient HTTP = HttpClient.newBuilder().connectTimeout(Duration.ofSeconds(10)).build();

    static {
        Properties p = new Properties();
        try (InputStream in = LlmClient.class.getClassLoader().getResourceAsStream("llm.properties")) {
            if (in != null) p.load(new InputStreamReader(in, StandardCharsets.UTF_8));
        } catch (Exception ignored) {
        }
        BASE_URL = p.getProperty("llm.base-url", "").trim().replaceAll("/+$", "");
        API_KEY = p.getProperty("llm.api-key", "").trim();
        MODEL = p.getProperty("llm.model", "deepseek-chat").trim();
        TIMEOUT = Integer.parseInt(p.getProperty("llm.timeout-seconds", "30").trim());
    }

    private LlmClient() {
    }

    public static boolean enabled() {
        return !API_KEY.isEmpty() && !BASE_URL.isEmpty();
    }

    /** 一次性返回完整回答；messages 形如 [{role:system,content:..},{role:user,content:..}] */
    public static String chat(List<Map<String, String>> messages) throws Exception {
        JsonObject body = new JsonObject();
        body.addProperty("model", MODEL);
        body.addProperty("temperature", 0.5);
        JsonArray arr = new JsonArray();
        for (Map<String, String> m : messages) {
            JsonObject o = new JsonObject();
            o.addProperty("role", m.get("role"));
            o.addProperty("content", m.get("content"));
            arr.add(o);
        }
        body.add("messages", arr);
        HttpRequest req = HttpRequest.newBuilder(URI.create(BASE_URL + "/chat/completions"))
                .timeout(Duration.ofSeconds(TIMEOUT))
                .header("Content-Type", "application/json")
                .header("Authorization", "Bearer " + API_KEY)
                .POST(HttpRequest.BodyPublishers.ofString(body.toString(), StandardCharsets.UTF_8))
                .build();
        HttpResponse<String> resp = HTTP.send(req, HttpResponse.BodyHandlers.ofString(StandardCharsets.UTF_8));
        if (resp.statusCode() != 200) throw new RuntimeException("大模型接口返回 " + resp.statusCode() + "：" + resp.body());
        JsonObject json = JsonParser.parseString(resp.body()).getAsJsonObject();
        return json.getAsJsonArray("choices").get(0).getAsJsonObject()
                .getAsJsonObject("message").get("content").getAsString();
    }
}
