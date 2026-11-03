package com.kmu.cs.websocket;

import com.kmu.cs.entity.SysUser;
import javax.websocket.CloseReason;
import javax.websocket.EndpointConfig;
import javax.websocket.OnClose;
import javax.websocket.OnError;
import javax.websocket.OnMessage;
import javax.websocket.OnOpen;
import javax.websocket.Session;
import javax.websocket.server.ServerEndpoint;

/**
 * 人工客服实时通道（Java EE javax.websocket，Tomcat 9 内置实现）。
 * 浏览器连接 ws://host/上下文/ws/chat，服务器用 ChatHub 主动推送：
 *   {type:"msg"}       新消息
 *   {type:"accepted"}  客服已接入
 *   {type:"queue"}     排队队列变化（推给客服）
 *   {type:"end"}       会话结束
 * 发送消息仍走普通的 Ajax POST（便于入库和权限校验），WebSocket 只负责“推”。
 */
@ServerEndpoint(value = "/ws/chat", configurator = HttpSessionConfigurator.class)
public class ChatEndpoint {

    private SysUser user;

    @OnOpen
    public void onOpen(Session session, EndpointConfig config) throws Exception {
        // Tomcat 为每次握手复制一份 EndpointConfig，所以 userProperties 是这个连接私有的
        Object u = config.getUserProperties().get("loginUser");
        if (!(u instanceof SysUser su)) {
            session.close(new CloseReason(CloseReason.CloseCodes.VIOLATED_POLICY, "not login"));
            return;
        }
        this.user = su;
        session.setMaxIdleTimeout(0);
        ChatHub.join(user.getId(), user.getRole(), session);
        session.getBasicRemote().sendText("{\"type\":\"hello\",\"role\":\"" + user.getRole() + "\"}");
    }

    @OnMessage
    public void onMessage(String text, Session session) throws Exception {
        // 心跳：客户端每 25 秒发一次 ping，防止代理断开空闲连接
        if (text != null && text.contains("ping")) {
            synchronized (session) {
                session.getBasicRemote().sendText("{\"type\":\"pong\"}");
            }
        }
    }

    @OnClose
    public void onClose(Session session) {
        if (user != null) ChatHub.leave(user.getId(), session);
    }

    @OnError
    public void onError(Session session, Throwable t) {
        if (user != null) ChatHub.leave(user.getId(), session);
    }
}
