package com.kmu.cs.websocket;

import com.kmu.cs.util.WebUtil;
import javax.servlet.http.HttpSession;
import javax.websocket.HandshakeResponse;
import javax.websocket.server.HandshakeRequest;
import javax.websocket.server.ServerEndpointConfig;

/** 握手时把 HttpSession 里的登录用户取出来，交给 WebSocket 端点使用（WebSocket 复用 Session 登录态） */
public class HttpSessionConfigurator extends ServerEndpointConfig.Configurator {
    @Override
    public void modifyHandshake(ServerEndpointConfig sec, HandshakeRequest request, HandshakeResponse response) {
        Object hs = request.getHttpSession();
        if (hs instanceof HttpSession session) {
            Object u = session.getAttribute(WebUtil.LOGIN_USER);
            if (u != null) sec.getUserProperties().put("loginUser", u);
        }
    }
}
