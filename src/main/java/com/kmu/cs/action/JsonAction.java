package com.kmu.cs.action;

import com.kmu.cs.util.BizException;
import com.kmu.cs.util.JsonUtil;
import org.apache.logging.log4j.LogManager;
import org.apache.logging.log4j.Logger;

import java.util.Map;
import java.util.concurrent.Callable;

/**
 * Ajax 接口 Action 的父类：
 * 结果统一放在 result 属性里，struts.xml 中用 &lt;result type="json"&gt;&lt;param name="root"&gt;result&lt;/param&gt;&lt;/result&gt;
 * 交给 struts2-json-plugin 输出 {code, msg, data}，格式与原 Servlet 版完全一致，前端无需改解析逻辑。
 */
public abstract class JsonAction extends BaseAction {

    private static final Logger LOG = LogManager.getLogger(JsonAction.class);

    private Map<String, Object> result;

    /** json 结果的 root 对象 */
    public Map<String, Object> getResult() {
        return result;
    }

    /** 执行业务：成功 code=200；业务异常 code=500 + 提示信息 */
    protected String json(Callable<Object> body) {
        try {
            result = JsonUtil.result(200, "ok", body.call());
        } catch (BizException e) {
            result = JsonUtil.result(500, e.getMessage(), null);
        } catch (Exception e) {
            LOG.error("接口异常", e);
            result = JsonUtil.result(500, "服务器开小差了：" + e.getMessage(), null);
        }
        return SUCCESS;
    }
}
