package com.kmu.cs.util;

/** 业务异常：Servlet 捕获后把 message 作为提示返回给页面 */
public class BizException extends RuntimeException {
    public BizException(String msg) {
        super(msg);
    }
}
