package com.kmu.cs.action;

import com.kmu.cs.service.ServiceFactory;

/**
 * 用户端对话 Ajax 接口（/api/chat 命名空间，通配符 action name="*" method="{1}"，
 * 允许的方法在 struts.xml 的 allowed-methods 中声明 —— 严格方法调用 SMI）。
 * 前端 fetch 以表单格式提交，参数 sessionId / afterId / question / rating 直接注入 Action 属性；
 * 返回 &lt;result type="json"&gt;（root = result）。
 */
public class ChatApiAction extends JsonAction {

    private Long sessionId;
    private Long afterId;
    private String question;
    private Integer rating;

    /** GET /api/chat/poll.action?sessionId=&afterId=  轮询降级 */
    public String poll() {
        return json(() -> ServiceFactory.CHAT.poll(me(), sessionId, afterId));
    }

    /** GET /api/chat/sessions.action  我的会话列表 */
    public String sessions() {
        return json(() -> ServiceFactory.CHAT.mySessions(me().getId()));
    }

    /** POST /api/chat/ask.action  提问（AI 应答 / 人工模式下转发给客服） */
    public String ask() {
        return json(() -> ServiceFactory.CHAT.ask(me().getId(), sessionId, question));
    }

    /** POST /api/chat/human.action  转人工 */
    public String human() {
        return json(() -> ServiceFactory.CHAT.requestHuman(me().getId(), sessionId));
    }

    /** POST /api/chat/end.action  结束会话 */
    public String end() {
        return json(() -> {
            ServiceFactory.CHAT.end(me(), sessionId);
            return "ok";
        });
    }

    /** POST /api/chat/rate.action  满意度评价 */
    public String rate() {
        return json(() -> {
            ServiceFactory.CHAT.rate(me().getId(), sessionId, rating);
            return "ok";
        });
    }

    public void setSessionId(Long sessionId) { this.sessionId = sessionId; }
    public void setAfterId(Long afterId) { this.afterId = afterId; }
    public void setQuestion(String question) { this.question = question; }
    public void setRating(Integer rating) { this.rating = rating; }
}
