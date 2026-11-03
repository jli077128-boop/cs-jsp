package com.kmu.cs.filter;

import javax.servlet.Filter;
import javax.servlet.FilterChain;
import javax.servlet.FilterConfig;
import javax.servlet.ServletException;
import javax.servlet.ServletRequest;
import javax.servlet.ServletResponse;

import java.io.IOException;

/**
 * 字符编码过滤器：所有请求、响应统一 UTF-8，解决中文乱码。
 * 在 web.xml 中声明并排在 Struts 核心过滤器之前（WebSocket、静态资源等不经过 Struts 的请求也能统一编码）。
 */
public class EncodingFilter implements Filter {

    private String encoding = "UTF-8";

    @Override
    public void init(FilterConfig cfg) {
        String e = cfg.getInitParameter("encoding");
        if (e != null && !e.isBlank()) encoding = e;
    }

    @Override
    public void doFilter(ServletRequest req, ServletResponse resp, FilterChain chain) throws IOException, ServletException {
        req.setCharacterEncoding(encoding);
        resp.setCharacterEncoding(encoding);
        chain.doFilter(req, resp);
    }
}
