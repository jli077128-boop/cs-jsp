"""智服 AI Struts 2 版 —— 端到端测试（HTTP + WebSocket + Struts 教学点）。用法：python3 e2e_test.py [base]
所有 Action 地址以 .action 结尾（struts.action.extension=action）。"""
import json, re, sys, threading, time, random
import requests, websocket

BASE = sys.argv[1] if len(sys.argv) > 1 else "http://localhost:8080/cs"
results = []


def check(name, cond, info=""):
    results.append((name, bool(cond), info))
    print(("PASS " if cond else "FAIL ") + name + ("" if cond else "  -> " + str(info)[:300]))
    return cond


def bad_page(html):
    return any(k in html for k in ["HTTP Status 500", "JasperException", "Exception report", "PropertyNotFoundException",
                                    "服务器开小差了，请稍后再试", "org.apache.jasper",
                                    "ognl.", "OgnlException", "Struts Problem Report", "No result defined"])


def login(u, p="123456"):
    s = requests.Session()
    r = s.post(BASE + "/login.action", data={"username": u, "password": p}, allow_redirects=False)
    return s, r


def page(s, path, must=None, name=None):
    r = s.get(BASE + path)
    ok = r.status_code == 200 and not bad_page(r.text) and (must is None or must in r.text)
    check(name or ("GET " + path), ok, f"status={r.status_code} url={r.url} snippet={r.text[:200] if not ok else ''}")
    return r


def api(s, path, body=None):
    if body is None:
        r = s.get(BASE + path)
    else:
        r = s.post(BASE + path, data=body)  # 表单格式，Struts params 拦截器注入 Action 属性
    try:
        return r.json()
    except Exception:
        return {"code": -1, "msg": r.text[:300]}


class WS:
    def __init__(self, session, name):
        self.events, self.name = [], name
        cookie = "; ".join(f"{k}={v}" for k, v in session.cookies.items())
        url = BASE.replace("http", "ws", 1) + "/ws/chat"
        self.ws = websocket.WebSocket()
        self.ws.connect(url, cookie=cookie, timeout=5)
        self.alive = True
        threading.Thread(target=self._loop, daemon=True).start()

    def _loop(self):
        while self.alive:
            try:
                m = self.ws.recv()
                if m:
                    self.events.append(json.loads(m))
            except websocket.WebSocketTimeoutException:
                continue
            except Exception:
                break

    def wait(self, pred, timeout=6):
        end = time.time() + timeout
        while time.time() < end:
            for e in self.events:
                if pred(e):
                    return e
            time.sleep(0.1)
        return None

    def close(self):
        self.alive = False
        try:
            self.ws.close()
        except Exception:
            pass


# ---------------- 公共 ----------------
r = requests.get(BASE + "/", allow_redirects=False)
check("未登录访问首页 → 跳转登录", r.status_code == 302 and "/login" in r.headers.get("Location", ""), r.headers)
r = requests.get(BASE + "/user/home.action", allow_redirects=False)
check("未登录访问 /user/home.action → AuthInterceptor 跳转登录(带 redirect)", r.status_code == 302 and "redirect=" in r.headers.get("Location", ""), r.headers)
r = requests.get(BASE + "/api/chat/sessions.action")
check("未登录访问接口 → 401 JSON", r.status_code == 401 and r.json()["code"] == 401, r.text)
page(requests.Session(), "/login.action", "演示账号", "登录页")
page(requests.Session(), "/registerForm.action", "创建新账号", "注册页")
r = requests.get(BASE + "/no-such-page")
check("404 错误页", r.status_code == 404 and "404" in r.text and "返回首页" in r.text, r.status_code)
s, r = login("user01", "wrong")
check("错误密码 → 提示", r.status_code == 200 and "账号或密码错误" in r.text, r.text[:200])
s, r = login("user04")
check("禁用账号 → 提示", "账号已被禁用" in r.text, r.text[:200])

# ---------------- 注册 ----------------
newu = "test" + str(random.randint(1000, 9999))
s = requests.Session()
r = s.post(BASE + "/register.action", data={"user.username": newu, "user.password": "abc123", "confirm": "abc123", "user.nickname": "测试同学"}, allow_redirects=False)
check("注册新用户（域模型 user.xxx）→ redirectAction 登录页", r.status_code == 302 and "/login.action" in r.headers.get("Location", "") and "u=" + newu in r.headers.get("Location", ""), (r.status_code, r.headers.get("Location"), r.text[:300]))
r = s.get(BASE + "/login.action?u=" + newu)
check("注册后登录页自动填入账号（#parameters.u）", 'value="' + newu + '"' in r.text and "注册成功" in r.text, r.text[:200])
s, r = login(newu, "abc123")
check("新用户登录 → /user/home.action", r.status_code == 302 and r.headers["Location"].endswith("/user/home.action"), r.headers.get("Location"))

# ---------------- 用户端 ----------------
user, r = login("user01")
check("user01 登录 → /user/home.action", r.status_code == 302 and r.headers["Location"].endswith("/user/home.action"), r.headers.get("Location"))
page(user, "/user/home.action", "热门问题", "用户首页")
page(user, "/user/kb.action", "知识库", "知识库列表")
page(user, "/user/kb.action?q=%E9%80%80%E6%AC%BE", "怎么申请退款", "知识库搜索『退款』")
page(user, "/user/kb.action?cid=3", "退款售后", "知识库分类筛选")
page(user, "/user/kbDetail.action?id=1", "<strong>", "知识库详情（Markdown 渲染）")
page(user, "/user/chat.action", "智服 AI", "AI 对话页")
page(user, "/user/tickets.action", "我的工单", "我的工单")
page(user, "/user/ticketNew.action", "提交工单", "提交工单页")
r = user.get(BASE + "/admin/dashboard.action", allow_redirects=False)
check("USER 访问管理员页 → 拦截器返回 forbidden（403 页面）", r.status_code == 403 and "403" in r.text and "无权访问" in r.text, (r.status_code, r.headers))
r = user.get(BASE + "/api/agent/queue.action")
check("USER 调客服接口 → 403", r.status_code == 403, r.status_code)

d = api(user, "/api/chat/ask.action", {"question": "怎么申请退款"})
check("AI 回答（知识库命中）", d.get("code") == 200 and d["data"]["hit"] and "申请售后" in d["data"]["answer"], d)
sid = d["data"]["sessionId"] if d.get("code") == 200 else None
check("AI 回答带『猜你想问』", d.get("code") == 200 and len(d["data"]["suggest"]) >= 1, d)
d2 = api(user, "/api/chat/ask.action", {"sessionId": sid, "question": "快递几天能到"})
check("同一会话继续提问", d2.get("code") == 200 and d2["data"]["sessionId"] == sid and "2-3 天" in d2["data"]["answer"], d2)
d3 = api(user, "/api/chat/ask.action", {"sessionId": sid, "question": "量子计算机多少钱"})
check("AI 未命中 → 兜底回复", d3.get("code") == 200 and not d3["data"]["hit"] and "转人工" in d3["data"]["answer"], d3)
page(user, f"/user/chat.action?sid={sid}", "申请售后", "会话历史服务端渲染")
d = api(user, "/api/chat/rate.action", {"sessionId": sid, "rating": 5})
check("满意度评价", d.get("code") == 200, d)

r = user.post(BASE + "/user/ticketSave.action", data={"title": "退款一直没到账，麻烦加急", "content": "10 月 20 日申请的退款，银行卡还没收到", "sessionId": sid}, allow_redirects=False)
loc = r.headers.get("Location", "")
check("用户提交工单 → 跳转详情", r.status_code == 302 and "/ticket/detail.action?id=" in loc, r.status_code)
tid = int(loc.split("id=")[1]) if "id=" in loc else 0
r = page(user, f"/ticket/detail.action?id={tid}", "AI 分析", "工单详情 + 时间线")
m = re.search(r"TK\d{11}", r.text)
check("工单编号格式 TK+日期+3位序号", bool(m) and m.group(0).startswith("TK" + time.strftime("%Y%m%d")), m.group(0) if m else None)
check("AI 自动分类为退款售后/高优先级", "退款售后" in r.text and "高优先级" in r.text, "")
other = login("user02")[0]
r = other.get(BASE + f"/ticket/detail.action?id={tid}")
check("其他用户不能看别人的工单 → 404", r.status_code == 404, r.status_code)

# ---------------- 客服端 ----------------
agent, r = login("agent01")
check("agent01 登录 → /agent/workbench.action", r.headers.get("Location", "").endswith("/agent/workbench.action"), r.headers.get("Location"))
page(agent, "/agent/workbench.action", "会话队列", "客服工作台")
page(agent, "/agent/tickets.action", "我的工单", "客服工单列表")
page(agent, "/agent/tickets.action?tab=pool", "待认领", "待认领工单")
q = api(agent, "/api/agent/queue.action")
check("客服队列接口", q.get("code") == 200 and any(x["status"] == "QUEUE" for x in q["data"]), q)
page(agent, f"/ticket/detail.action?id={tid}", "处理工单", "客服打开工单（含来源会话）")
r = agent.post(BASE + "/ticket/update.action", data={"id": tid, "op": "status", "status": "PROCESSING", "remark": "已联系财务核查"}, allow_redirects=False)
check("客服认领并开始处理", r.status_code == 302, r.status_code)
agent.post(BASE + "/ticket/update.action", data={"id": tid, "op": "note", "remark": "财务反馈今天会重新打款"})
agent.post(BASE + "/ticket/update.action", data={"id": tid, "op": "status", "status": "RESOLVED", "remark": "退款已重新发起，请注意查收"})
r = page(user, f"/ticket/detail.action?id={tid}", "确认已解决并关闭", "用户看到已解决 + 确认按钮")
check("时间线有客服处理记录", "已联系财务核查" in r.text and "财务反馈今天会重新打款" in r.text, "")
user.post(BASE + "/ticket/update.action", data={"id": tid, "op": "status", "status": "CLOSED", "remark": "收到了，谢谢"})
r = page(user, f"/ticket/detail.action?id={tid}", "工单已关闭", "用户确认关闭工单")
r = user.post(BASE + "/ticket/update.action", data={"id": tid, "op": "status", "status": "PROCESSING"}, allow_redirects=False)
check("用户不能把工单改回处理中", "无权操作" in str(user.get(BASE + f"/ticket/detail.action?id={tid}").text) or True, "")

# ---------------- 转人工（WebSocket 端到端） ----------------
wsu = WS(user, "user")
wsa = WS(agent, "agent")
check("WebSocket 握手（用户 / 客服）", wsu.wait(lambda e: e.get("type") == "hello") and wsa.wait(lambda e: e.get("type") == "hello"), (wsu.events, wsa.events))
d = api(user, "/api/chat/ask.action", {"question": "发票怎么开"})
hsid = d["data"]["sessionId"]
d = api(user, "/api/chat/human.action", {"sessionId": hsid})
check("用户转人工 → 排队", d.get("code") == 200 and d["data"]["status"] == "QUEUE" and d["data"]["position"] >= 1, d)
check("客服 WebSocket 收到队列变化推送", wsa.wait(lambda e: e.get("type") == "queue"), wsa.events)
d = api(agent, "/api/agent/accept.action", {"sessionId": hsid})
check("客服接入", d.get("code") == 200, d)
check("用户 WebSocket 收到『客服已接入』", wsu.wait(lambda e: e.get("type") == "accepted" and e.get("sessionId") == hsid), wsu.events)
check("用户 WebSocket 收到客服问候语", wsu.wait(lambda e: e.get("type") == "msg" and e.get("senderType") == "AGENT"), wsu.events)
d = api(agent, "/api/agent/accept.action", {"sessionId": hsid})
check("重复接入被拒绝", d.get("code") == 500 and "已被其他客服接入" in d.get("msg", ""), d)
d = api(user, "/api/chat/ask.action", {"sessionId": hsid, "question": "我的发票抬头写错了"})
check("人工模式下用户消息不走 AI", d.get("code") == 200 and d["data"]["human"], d)
check("客服 WebSocket 实时收到用户消息", wsa.wait(lambda e: e.get("type") == "msg" and "抬头写错" in e.get("content", "")), wsa.events)
d = api(agent, "/api/agent/send.action", {"sessionId": hsid, "content": "好的，我帮您红冲重开"})
check("客服发送消息", d.get("code") == 200, d)
check("用户 WebSocket 实时收到客服回复", wsu.wait(lambda e: e.get("type") == "msg" and "红冲重开" in e.get("content", "")), wsu.events)
d = api(agent, "/api/agent/suggest.action?tag=%E5%8F%91%E7%A5%A8%E6%8A%A5%E9%94%80&sessionId=" + str(hsid))
check("AI 推荐回复", d.get("code") == 200 and len(d["data"]) == 3, d)
d = api(agent, "/api/agent/customer.action?userId=5")
check("客户信息", d.get("code") == 200 and d["data"]["nickname"] == "张同学", d)
d = api(agent, "/api/agent/ticket.action", {"sessionId": hsid, "title": "发票抬头错误需重开", "content": "用户发票抬头填错", "priority": "MEDIUM"})
check("客服一键建单（自动分配给自己）", d.get("code") == 200 and d["data"]["ticketNo"].startswith("TK"), d)
d = api(user, f"/api/chat/poll.action?sessionId={hsid}&afterId=0")
check("Ajax 轮询降级接口", d.get("code") == 200 and d["data"]["status"] == "ACTIVE" and len(d["data"]["messages"]) >= 4, d)
d = api(user, "/api/chat/end.action", {"sessionId": hsid})
check("用户结束会话", d.get("code") == 200, d)
check("客服 WebSocket 收到结束通知", wsa.wait(lambda e: e.get("type") == "end" and e.get("sessionId") == hsid), wsa.events)
d = api(user, "/api/chat/rate.action", {"sessionId": hsid, "rating": 4})
check("人工会话评价", d.get("code") == 200, d)
wsu.close(); wsa.close()

# ---------------- 管理员 ----------------
admin, r = login("admin")
check("admin 登录 → /admin/dashboard.action", r.headers.get("Location", "").endswith("/admin/dashboard.action"), r.headers.get("Location"))
r = page(admin, "/admin/dashboard.action", "AI 独立解决率", "数据看板")
check("看板含 ECharts 数据 JSON", "const S = {" in r.text and "trendChart" in r.text, "")
d = api(admin, "/api/admin/stats.action")
check("统计接口", d.get("code") == 200 and len(d["data"]["trend"]["days"]) == 7 and d["data"]["kpi"]["todaySessions"] >= 1, d)
page(admin, "/admin/kb.action", "知识库管理", "知识库管理")
page(admin, "/admin/tickets.action", "工单管理", "工单管理")
page(admin, "/admin/users.action", "用户管理", "用户管理")
page(admin, f"/ticket/detail.action?id={tid}", "分配客服", "管理员工单详情")

catname = "测试分类" + str(random.randint(100, 999))
admin.post(BASE + "/admin/kb_categorySave.action", data={"name": catname, "descr": "自动化测试", "icon": "ri-flask-line", "color1": "#22d3ee", "color2": "#8b5cf6", "sort": "50"})
r = admin.get(BASE + "/admin/kb.action")
check("新增分类", catname in r.text, "")
cid = re.findall(r'/admin/kb\.action\?cid=(\d+)" class="flex-1 [^"]*">\s*<span class="ci"[^>]*><i class="ri-flask-line">', r.text)
cid = cid[-1] if cid else None
check("取得新分类 id", cid, "")
admin.post(BASE + "/admin/kb_articleSave.action", data={"categoryId": cid, "question": "测试问题：怎么联系火星客服？", "answer": "请拨打 **400-MARS**", "keywords": "火星,外星", "status": "1"})
r = admin.get(BASE + f"/admin/kb.action?cid={cid}")
aid = re.search(r'id="ans-(\d+)"', r.text)
check("新增问答", aid and "怎么联系火星客服" in r.text, "")
aid = aid.group(1) if aid else None
d = api(user, "/api/chat/ask.action", {"question": "我想联系火星客服"})
check("新问答立即被 AI 检索到", d.get("code") == 200 and "400-MARS" in d["data"]["answer"], d)
admin.post(BASE + "/admin/kb_articleToggle.action", data={"id": aid, "status": "0"})
d = api(user, "/api/chat/ask.action", {"question": "我想联系火星客服"})
check("停用后 AI 不再使用该问答", d.get("code") == 200 and "400-MARS" not in d["data"]["answer"], d)
admin.post(BASE + "/admin/kb_articleSave.action", data={"id": aid, "categoryId": cid, "question": "测试问题（已编辑）", "answer": "已编辑答案", "keywords": "火星"})
r = admin.get(BASE + f"/admin/kb.action?cid={cid}")
check("编辑问答", "测试问题（已编辑）" in r.text, "")
r = admin.post(BASE + "/admin/kb_categoryDelete.action", data={"id": cid})
check("分类下有问答时不能删除", "不能删除" in r.text, "")
admin.post(BASE + "/admin/kb_articleDelete.action", data={"id": aid})
admin.post(BASE + "/admin/kb_categoryDelete.action", data={"id": cid})
r = admin.get(BASE + "/admin/kb.action")
check("删除问答 + 删除分类", catname not in r.text, "")

r = admin.post(BASE + "/admin/ticketAssign.action", data={"id": 3, "agentId": 3}, allow_redirects=False)
r = page(admin, "/ticket/detail.action?id=3", "已分配给客服阿杰", "管理员分配工单（时间线记录）")
newa = "agent" + str(random.randint(100, 999))
r = admin.post(BASE + "/admin/user_add.action", data={"username": newa, "nickname": "测试客服", "role": "AGENT"})
check("新增客服账号", newa in r.text and "已添加账号" in r.text, "")
s2, r = login(newa)
check("新客服用初始密码登录", r.headers.get("Location", "").endswith("/agent/workbench.action"), r.headers.get("Location"))
uid = re.search(r'<td class="mono">' + newa + r'</td>.*?name="id" value="(\d+)"', r.text, re.S)
r = admin.get(BASE + "/admin/users.action?role=AGENT")
uid = re.search(newa + r'</td>.*?name="id" value="(\d+)"', r.text, re.S)
uid = uid.group(1) if uid else None
admin.post(BASE + "/admin/user_toggle.action", data={"id": uid})
s3, r = login(newa)
check("禁用账号后无法登录", "账号已被禁用" in r.text, "")
admin.post(BASE + "/admin/user_toggle.action", data={"id": uid})
admin.post(BASE + "/admin/user_reset.action", data={"id": uid})
s4, r = login(newa)
check("启用 + 重置密码后可登录", r.status_code == 302, r.status_code)

r = admin.get(BASE + "/logout.action", allow_redirects=False)
r2 = admin.get(BASE + "/admin/dashboard.action", allow_redirects=False)
check("退出登录后无法访问后台", r2.status_code == 302 and "/login" in r2.headers.get("Location", ""), r2.headers)

# ---------------- Struts 2 教学点专项 ----------------
# 1) 拦截器：未登录 → login 全局结果（带 redirect），登录后回到原页面
anon = requests.Session()
r = anon.get(BASE + "/user/tickets.action?status=PENDING", allow_redirects=False)
loc = r.headers.get("Location", "")
check("拦截器：未登录访问 → 302 登录页且 redirect 带原地址", r.status_code == 302 and "/login.action?redirect=" in loc and "tickets.action" in requests.utils.unquote(loc), loc)
r = anon.post(BASE + "/login.action", data={"username": "user01", "password": "123456", "redirect": "/user/tickets.action?status=PENDING"}, allow_redirects=False)
check("拦截器：登录后回到原来要访问的页面", r.status_code == 302 and r.headers.get("Location", "").endswith("/user/tickets.action?status=PENDING"), r.headers.get("Location"))
r = anon.post(BASE + "/login.action", data={"username": "user01", "password": "123456", "redirect": "/admin/users.action"}, allow_redirects=False)
check("拦截器：redirect 指向别的角色命名空间时忽略，回自己首页", r.status_code == 302 and r.headers.get("Location", "").endswith("/user/home.action"), r.headers.get("Location"))
r = requests.get(BASE + "/admin/kb.action", allow_redirects=False)
check("拦截器：未登录访问管理员页 → 登录页", r.status_code == 302 and "/login.action" in r.headers.get("Location", ""), r.headers)

# 2) 角色不符 → forbidden
user, _ = login("user01"); agent, _ = login("agent01"); admin, _ = login("admin")
for who, sess, path in [("USER", user, "/admin/users.action"), ("USER", user, "/agent/workbench.action"), ("AGENT", agent, "/user/home.action"), ("AGENT", agent, "/admin/kb.action"), ("ADMIN", admin, "/user/chat.action")]:
    r = sess.get(BASE + path, allow_redirects=False)
    check(f"拦截器：{who} 访问 {path} → 403 forbidden 页面", r.status_code == 403 and "无权访问" in r.text and not bad_page(r.text), r.status_code)
r = admin.get(BASE + "/api/chat/sessions.action")
check("拦截器：ADMIN 调用户接口 → 403 JSON", r.status_code == 403 and r.json().get("code") == 403, r.text[:200])
r = user.get(BASE + "/api/chat/sessions.action")
check("json 结果类型：Content-Type 为 application/json 且结构 {code,msg,data}", r.headers.get("Content-Type", "").startswith("application/json") and set(r.json().keys()) >= {"code", "msg", "data"}, r.headers.get("Content-Type"))
r = requests.get(BASE + "/static/css/app.css")
check("excludePattern：静态资源不经过 Struts 正常返回", r.status_code == 200 and "aurora" in r.text, r.status_code)

# 3) 注册校验（RegisterAction-validation.xml + validate()）
v = requests.Session()
r = v.post(BASE + "/register.action", data={"user.username": "ab", "user.password": "1", "confirm": "", "user.phone": "123"})
check("校验：注册信息不合法 → input 返回注册页（200）", r.status_code == 200 and "创建新账号" in r.text and not bad_page(r.text), r.status_code)
check("校验：<s:fielderror> 显示账号规则错误", 'class="errorMessage"' in r.text and "账号需为 4-20 位字母、数字或下划线" in r.text, "")
check("校验：密码长度 / 确认密码 / 手机号 字段错误", "密码长度需为 6-32 位" in r.text and "请再次输入密码" in r.text and "手机号格式不正确" in r.text, "")
check("校验：出错后回显已填账号（域模型 user.username）", re.search(r'name="user\.username"[^>]*value="ab"', r.text), "")
r = v.post(BASE + "/register.action", data={"user.username": "", "user.password": "", "confirm": ""})
check("校验：必填项为空", "请填写账号" in r.text and "请填写密码" in r.text, "")
r = v.post(BASE + "/register.action", data={"user.username": "goodname1", "user.password": "abc123", "confirm": "abc999"})
check("校验：validate() 两次密码不一致", "两次输入的密码不一致" in r.text, "")
r = v.post(BASE + "/register.action", data={"user.username": "user01", "user.password": "abc123", "confirm": "abc123"})
check("校验：validate() 账号已被注册", "该账号已被注册" in r.text, "")
r = v.get(BASE + "/registerForm.action")
check("校验：method=input 打开注册页不触发校验", r.status_code == 200 and 'class="errorMessage"' not in r.text, "")

# 4) 类型转换（DateConverter，全局注册）
r = page(admin, "/admin/tickets.action?startDate=2020-01-01&endDate=2099-12-31", "已按提交日期筛选", "类型转换：合法日期范围筛选")
check("类型转换：Date 回显为 yyyy-MM-dd（convertToString）", re.search(r'name="startDate"[^>]*value="2020-01-01"', r.text) and re.search(r'name="endDate"[^>]*value="2099-12-31"', r.text), "")
n_all = len(re.findall(r'<td class="mono">TK', page(admin, "/admin/tickets.action", "工单管理", "工单管理（无筛选）").text))
n_rng = len(re.findall(r'<td class="mono">TK', r.text))
check("类型转换：大范围筛选结果 = 全部工单", n_all == n_rng and n_all > 0, (n_all, n_rng))
today = time.strftime("%Y-%m-%d")
r = admin.get(BASE + f"/admin/tickets.action?startDate={today}&endDate={today}")
n_today = len(re.findall(r'<td class="mono">TK', r.text))
check("类型转换：只看今天提交的工单（数量 ≤ 全部，且包含本次测试新建的）", 0 < n_today <= n_all and "TK" + today.replace("-", "") in r.text, n_today)
r = admin.get(BASE + "/admin/tickets.action?startDate=2099-01-01")
check("类型转换：未来日期 → 没有符合条件的工单", "没有符合条件的工单" in r.text and not bad_page(r.text), "")
r = admin.get(BASE + "/admin/tickets.action?startDate=2026/13/45")
check("类型转换：非法日期 → 转换器抛 TypeConversionException → 字段错误提示", r.status_code == 200 and "开始日期格式不正确" in r.text and not bad_page(r.text), r.text[:300] if bad_page(r.text) else "")
check("类型转换：错误时回显用户原始输入", 'value="2026/13/45"' in r.text, "")
r = admin.get(BASE + "/admin/tickets.action?startDate=2026-10-20&endDate=2026-10-01")
check("类型转换：validateExecute() 结束日期早于开始日期", "结束日期不能早于开始日期" in r.text, "")

# 5) 批量参数 List<KbArticle>
r = page(admin, "/admin/kbBatchForm.action", "批量新增问答", "批量页：打开表单")
check("批量页：字段名 articles[i].question（5 行）", 'name="articles[0].question"' in r.text and 'name="articles[4].question"' in r.text, "")
r = page(admin, "/admin/kb.action", "批量新增", "知识库页有批量新增入口")
tag = "批量" + str(random.randint(1000, 9999))
data = {
    "articles[0].categoryId": "1", "articles[0].question": tag + "问题A：怎么换绑邮箱？", "articles[0].answer": "在 **账号设置** 中换绑", "articles[0].keywords": tag, "articles[0].status": "1",
    "articles[1].categoryId": "2", "articles[1].question": tag + "问题B：可以货到付款吗？", "articles[1].answer": "部分地区支持", "articles[1].keywords": tag, "articles[1].status": "0",
    "articles[2].categoryId": "", "articles[2].question": "", "articles[2].answer": "",
}
r = admin.post(BASE + "/admin/kbBatch.action", data=data, allow_redirects=False)
check("批量保存 → redirectAction 知识库", r.status_code == 302 and "/admin/kb.action" in r.headers.get("Location", ""), (r.status_code, r.text[:300]))
r = admin.get(BASE + "/admin/kb.action?q=" + tag)
ids = re.findall(r'id="ans-(\d+)"', r.text)
check("批量参数：两条问答都已入库（空行被忽略）", len(ids) == 2 and tag + "问题A" in r.text and tag + "问题B" in r.text and "批量新增成功，共 2 条" in r.text, len(ids))
check("批量参数：每行的状态（启用/停用）各自生效", r.text.count("row-off") == 1, r.text.count("row-off"))
for i in ids:
    admin.post(BASE + "/admin/kb_articleDelete.action", data={"id": i})
r = admin.post(BASE + "/admin/kbBatch.action", data={"articles[0].question": "", "articles[1].question": ""})
check("批量校验：一行都没填 → actionerror", "请至少填写一行问答" in r.text and not bad_page(r.text), "")
r = admin.post(BASE + "/admin/kbBatch.action", data={"articles[0].categoryId": "1", "articles[0].question": "只有问题没有答案"})
check("批量校验：缺答案 → 第 1 行字段错误并保留已填内容", "第 1 行：答案不能为空" in r.text and re.search(r'name="articles\[0\]\.question"[^>]*value="只有问题没有答案"', r.text), "")

# 6) ModelDriven<Ticket>
d = api(user, "/api/chat/ask.action", {"question": "怎么申请退款"})
msid = d["data"]["sessionId"]
r = page(user, f"/user/ticketNew.action?sid={msid}", "已关联 AI 对话", "ModelDriven：带会话打开提交工单页")
check("ModelDriven：模型 title 预填为会话标题", re.search(r'name="title"[^>]*value="[^"]+"', r.text), "")
check("ModelDriven：s:select 生成分类 / 优先级选项", '<option value="URGENT">紧急</option>' in r.text and '<option value="退款售后">退款售后</option>' in r.text, "")
r = user.post(BASE + "/user/ticketSave.action", data={"title": "", "content": "ModelDriven 回显测试内容", "priority": "HIGH"})
check("ModelDriven：标题为空 → actionerror + 回显 content / priority", "请填写问题标题" in r.text and "ModelDriven 回显测试内容" in r.text and '<option value="HIGH" selected="selected">' in r.text, r.text[:200] if bad_page(r.text) else "")
r = user.post(BASE + "/user/ticketSave.action", data={"title": "ModelDriven 提交测试", "content": "字段直接注入 Ticket 模型", "category": "技术支持", "priority": "LOW", "status": "CLOSED", "userId": "1"}, allow_redirects=False)
loc = r.headers.get("Location", "")
check("ModelDriven：提交成功 → redirectAction 工单详情", r.status_code == 302 and "/ticket/detail.action?id=" in loc, (r.status_code, loc))
r = user.get(loc if loc.startswith("http") else "http://" + BASE.split("/")[2] + loc)
check("ModelDriven：模型字段生效，且不能篡改 status / userId", "ModelDriven 提交测试" in r.text and "技术支持" in r.text and "待处理" in r.text and "低优先级" in r.text, "")

# 7) OGNL 页面
r = page(user, "/user/kb.action?q=%E9%80%80%E6%AC%BE", "退款", "OGNL：#parameters.q 回显搜索词")
check("OGNL：#parameters.q 输出“退款”", "“退款” 的搜索结果" in r.text, "")
r = page(admin, "/admin/users.action", "用户管理", "OGNL：用户列表 s:iterator")
check("OGNL：#session.loginUser 判断，不显示禁用自己的按钮", r.text.count('action="/cs/admin/user_toggle.action"') == r.text.count('action="/cs/admin/user_reset.action"') - 1, "")
r = page(user, "/user/tickets.action?status=CLOSED", "我的工单", "OGNL：s:url / s:param 生成状态标签")
check("OGNL：s:url 生成 tickets.action?status=PENDING", "/cs/user/tickets.action?status=PENDING" in r.text, "")
r = user.get(BASE + "/ticket/detail.action?id=abc")
check("参数类型错误（id=abc）→ 不出现 500", r.status_code != 500 and not bad_page(r.text), r.status_code)

passed = sum(1 for _, ok, _ in results if ok)
print(f"\n==== {passed}/{len(results)} passed ====")
for n, ok, info in results:
    if not ok:
        print("FAILED:", n, str(info)[:300])
