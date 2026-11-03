"""浏览器端 UI 测试 + 截图（Playwright）。验证页面无 JS 报错、AI 对话、转人工 WebSocket 双端实时聊天，
以及 Struts 2 教学点页面（注册校验、日期类型转换、批量新增、ModelDriven 工单表单、403）。
用法：python3 ui_test.py [base] [截图目录]；环境变量 CHROMIUM 可指定浏览器路径（默认 /usr/bin/chromium，不存在则用 Playwright 自带）"""
import os, sys, re
from playwright.sync_api import sync_playwright, expect

BASE = sys.argv[1] if len(sys.argv) > 1 else "http://localhost:8080/cs"
OUT = sys.argv[2] if len(sys.argv) > 2 else "./shots"
results, errors = [], []


def check(name, cond, info=""):
    results.append((name, bool(cond)))
    print(("PASS " if cond else "FAIL ") + name + ("" if cond else "  -> " + str(info)[:300]))


def watch(page, tag):
    page.on("pageerror", lambda e: errors.append(f"[{tag}] pageerror {e}"))
    page.on("console", lambda m: m.type == "error" and "status of 403" not in m.text and errors.append(f"[{tag}] console {m.text}"))
    page.on("response", lambda r: r.status >= 500 and errors.append(f"[{tag}] HTTP {r.status} {r.url}"))
    page.on("dialog", lambda d: d.accept())


def snap(page, path, **kw):
    """截图前跳过入场动画（.rise 淡入）：多个页面同时打开时后台页的 CSS 动画会被浏览器节流，直接截图可能是空白"""
    page.add_style_tag(content=".rise{animation:none!important;opacity:1!important;transform:none!important}")
    page.wait_for_timeout(250)
    page.screenshot(path=path, **kw)


def login(browser, user, viewport=None):
    ctx = browser.new_context(viewport=viewport or {"width": 1440, "height": 900}, locale="zh-CN")
    p = ctx.new_page()
    watch(p, user)
    p.goto(BASE + "/login.action")
    p.fill("#username", user)
    p.fill("#password", "123456")
    p.click("#loginForm button[type=submit]")
    p.wait_for_load_state("networkidle")
    return ctx, p


with sync_playwright() as pw:
    exe = os.environ.get("CHROMIUM", "/usr/bin/chromium")
    browser = pw.chromium.launch(args=["--no-sandbox"], executable_path=exe if os.path.exists(exe) else None)

    # 1. 登录页
    ctx = browser.new_context(viewport={"width": 1440, "height": 900}, locale="zh-CN")
    p = ctx.new_page(); watch(p, "anon")
    p.goto(BASE + "/login.action"); p.wait_for_timeout(800)
    snap(p, f"{OUT}/01-login.png")
    p.click(".role-pick button[data-u=user01]")
    p.wait_for_url(re.compile(r".*/user/home.action"))
    check("演示账号一键登录 → 用户首页", "/user/home.action" in p.url, p.url)
    ctx.close()

    # 2. 用户端
    uctx, up = login(browser, "user01")
    up.wait_for_timeout(900)
    snap(up, f"{OUT}/02-user-home.png", full_page=True)
    up.goto(BASE + "/user/kb.action?cid=3"); up.wait_for_timeout(600)
    snap(up, f"{OUT}/03-knowledge.png")
    up.goto(BASE + "/user/chat.action"); up.wait_for_timeout(500)
    up.fill("#input", "怎么申请退款")
    up.keyboard.press("Enter")
    up.wait_for_function("() => document.querySelector('#chatBody').innerText.includes('申请售后') && !document.querySelector('.typing')", timeout=10000)
    up.wait_for_timeout(1800)  # 打字机效果结束
    check("UI：AI 回答出现在气泡中", "申请售后" in up.inner_text("#chatBody"))
    check("UI：猜你想问已更新", up.locator("#quick .chip").count() >= 2)
    up.fill("#input", "快递几天能到")
    up.keyboard.press("Enter")
    up.wait_for_function("() => document.querySelector('#chatBody').innerText.includes('2-3 天')", timeout=10000)
    up.wait_for_timeout(1500)
    snap(up, f"{OUT}/04-user-chat.png")

    # 3. 转人工：用户点按钮 → 客服接入 → 双向实时聊天
    up.click("#btnHuman")
    up.wait_for_selector("#queueBanner:not(.hidden)")
    check("UI：转人工后显示排队提示", "转接人工" in up.inner_text("#queueText"))

    actx, ap = login(browser, "agent01")
    ap.wait_for_function("() => document.querySelector('#connMode').innerText.includes('WebSocket')", timeout=8000)
    check("UI：客服工作台 WebSocket 已连接", "WebSocket" in ap.inner_text("#connMode"))
    up.wait_for_function("() => document.querySelector('#statusLine').innerText.includes('WebSocket')", timeout=8000)
    check("UI：用户端 WebSocket 已连接", "WebSocket" in up.inner_text("#statusLine"), up.inner_text("#statusLine"))
    item = ap.locator(".q-item", has_text="张同学").filter(has_text="排队中").first
    item.click()
    ap.click("#btnAccept")
    up.wait_for_function("() => document.querySelector('#chatBody').innerText.includes('已接入')", timeout=8000)
    check("UI：用户实时看到客服已接入（WebSocket 推送）", "已接入" in up.inner_text("#chatBody"))
    up.fill("#input", "你好，我的退款一周了还没到账")
    up.keyboard.press("Enter")
    ap.wait_for_function("() => document.querySelector('#cBody').innerText.includes('一周了还没到账')", timeout=8000)
    check("UI：客服实时收到用户消息", True)
    ap.wait_for_selector("#suggests .chip")
    ap.locator("#suggests .chip").first.click()
    ap.click("#cSend")
    sent = ap.locator("#cBody .msg.right .bubble").last.inner_text()
    up.wait_for_function("(t) => document.querySelector('#chatBody').innerText.includes(t)", arg=sent[:10], timeout=8000)
    check("UI：用户实时收到客服回复（AI 推荐话术）", True)
    ap.wait_for_timeout(800)
    snap(ap, f"{OUT}/05-agent-workbench.png")
    up.wait_for_timeout(500)
    snap(up, f"{OUT}/06-user-chat-human.png")

    # 一键建单
    ap.click("#btnTicket")
    ap.wait_for_selector("#ticketDlg[open]")
    ap.click("#tSubmit")
    ap.wait_for_function("() => document.querySelector('#cBody').innerText.includes('已为您创建工单')", timeout=8000)
    check("UI：客服一键建单并通知用户", True)
    up.wait_for_function("() => document.querySelector('#chatBody').innerText.includes('已为您创建工单')", timeout=8000)

    # 用户结束会话 → 评价弹窗
    up.click("#btnEnd")
    up.wait_for_selector("#rateDlg[open]", timeout=5000)
    up.click("#stars i[data-v='5']")
    up.wait_for_timeout(400)
    snap(up, f"{OUT}/07-rating.png")
    up.click("#rateSubmit")
    up.wait_for_function("() => document.querySelector('#chatBody').innerText.includes('5 星')", timeout=5000)
    check("UI：结束会话 + 五星评价", True)
    ap.wait_for_function("() => document.querySelector('#chatPane').classList.contains('hidden')", timeout=8000)
    check("UI：客服端实时收到会话结束", True)

    # 工单详情
    up.goto(BASE + "/user/tickets.action"); up.wait_for_timeout(500)
    snap(up, f"{OUT}/08-user-tickets.png")
    up.locator(".ticket-card").first.click(); up.wait_for_load_state("networkidle"); up.wait_for_timeout(600)
    snap(up, f"{OUT}/09-ticket-detail.png", full_page=True)

    # 4. 管理员
    mctx, mp = login(browser, "admin")
    mp.wait_for_function("() => document.querySelectorAll('canvas').length >= 5", timeout=10000)
    mp.wait_for_timeout(1800)
    check("UI：看板 5 个 ECharts 图表已渲染", mp.locator("canvas").count() >= 5)
    snap(mp, f"{OUT}/10-admin-dashboard.png", full_page=True)
    mp.goto(BASE + "/admin/kb.action"); mp.wait_for_timeout(500)
    snap(mp, f"{OUT}/11-admin-kb.png")
    mp.locator("button", has_text="新增问答").click()
    mp.wait_for_selector("#artDlg[open]")
    mp.fill("#artDlg input[name=question]", "UI 测试：可以开发票吗？")
    mp.fill("#artDlg textarea[name=answer]", "可以，在订单详情点击 **申请开票**。")
    mp.fill("#artDlg input[name=keywords]", "UI测试")
    mp.click("#artDlg button[type=submit]")
    mp.wait_for_load_state("networkidle")
    check("UI：管理员通过弹窗新增问答", "UI 测试：可以开发票吗？" in mp.content())
    mp.locator("tr", has_text="UI 测试：可以开发票吗？").locator("button", has_text="编辑").click()
    mp.wait_for_selector("#artDlg[open]")
    check("UI：编辑弹窗回填数据", mp.input_value("#artDlg input[name=question]") == "UI 测试：可以开发票吗？")
    mp.keyboard.press("Escape")
    mp.locator("tr", has_text="UI 测试：可以开发票吗？").locator("button.btn-danger").click()
    mp.wait_for_load_state("networkidle")
    check("UI：删除问答", "UI 测试：可以开发票吗？" not in mp.content())
    mp.goto(BASE + "/admin/tickets.action"); mp.wait_for_timeout(500)
    snap(mp, f"{OUT}/12-admin-tickets.png")
    mp.goto(BASE + "/admin/users.action"); mp.wait_for_timeout(500)
    snap(mp, f"{OUT}/13-admin-users.png")
    ap.goto(BASE + "/agent/tickets.action"); ap.wait_for_timeout(500)
    snap(ap, f"{OUT}/14-agent-tickets.png")

    # 5. 手机端
    mctx2, mob = login(browser, "user01", {"width": 390, "height": 844})
    mob.wait_for_timeout(800)
    snap(mob, f"{OUT}/15-mobile-home.png")
    mob.goto(BASE + "/user/chat.action?q=" + "发票怎么开")
    mob.wait_for_function("() => document.querySelector('#chatBody').innerText.includes('开票')", timeout=10000)
    mob.wait_for_timeout(1500)
    snap(mob, f"{OUT}/16-mobile-chat.png")
    check("UI：首页带问题跳转聊天并自动提问（手机端）", "开票" in mob.inner_text("#chatBody"))

    # 6. Struts 2 教学点页面
    rctx = browser.new_context(viewport={"width": 1440, "height": 900}, locale="zh-CN")
    rp = rctx.new_page(); watch(rp, "register")
    rp.goto(BASE + "/registerForm.action")
    rp.fill("input[name='user.username']", "ab")
    rp.fill("input[name='user.phone']", "12345")
    rp.fill("input[name='user.password']", "123")
    rp.fill("input[name='confirm']", "456")
    rp.click("#registerForm button[type=submit]")
    rp.wait_for_load_state("networkidle"); rp.wait_for_timeout(700)
    check("UI：注册校验错误显示在各字段下方（s:fielderror）", rp.locator("ul.errorMessage").count() >= 3 and "账号需为 4-20 位" in rp.content())
    snap(rp, f"{OUT}/17-register-validation.png")
    rctx.close()

    mp.goto(BASE + "/admin/kbBatchForm.action"); mp.wait_for_timeout(500)
    mp.select_option("select[name='articles[0].categoryId']", index=1)
    mp.fill("input[name='articles[0].question']", "UI 批量：怎么修改昵称？")
    mp.fill("textarea[name='articles[0].answer']", "在 **个人中心** 修改昵称")
    mp.fill("input[name='articles[1].question']", "UI 批量：这一行故意不填答案")
    mp.click("#addRow")
    check("UI：批量页“再加一行”生成 articles[5]", mp.locator("input[name='articles[5].question']").count() == 1)
    mp.click("#batchForm button[type=submit]")
    mp.wait_for_load_state("networkidle"); mp.wait_for_timeout(600)
    check("UI：批量校验错误（第 2 行缺答案）并保留填写内容", "第 2 行：答案不能为空" in mp.content() and mp.input_value("input[name='articles[0].question']") == "UI 批量：怎么修改昵称？")
    snap(mp, f"{OUT}/18-admin-kb-batch.png", full_page=True)
    mp.fill("input[name='articles[1].question']", "")
    mp.click("#batchForm button[type=submit]")
    mp.wait_for_load_state("networkidle")
    check("UI：批量保存成功回到知识库", "/admin/kb.action" in mp.url and "UI 批量：怎么修改昵称？" in mp.content())
    mp.locator("tr", has_text="UI 批量：怎么修改昵称？").locator("button.btn-danger").click()
    mp.wait_for_load_state("networkidle")

    mp.goto(BASE + "/admin/tickets.action?startDate=2026/13/45"); mp.wait_for_timeout(500)
    check("UI：非法日期 → 类型转换错误提示", "开始日期格式不正确" in mp.content())
    mp.goto(BASE + "/admin/tickets.action"); mp.wait_for_timeout(300)
    mp.fill("input[name=startDate]", "2026-10-01")
    mp.fill("input[name=endDate]", "2026-12-31")
    mp.click("#ticketFilter button[type=submit]")
    mp.wait_for_load_state("networkidle"); mp.wait_for_timeout(600)
    check("UI：日期范围筛选（DateConverter）", "已按提交日期筛选" in mp.content() and "startDate=2026-10-01" in mp.url)
    snap(mp, f"{OUT}/19-admin-tickets-date-filter.png")

    up.goto(BASE + "/user/ticketNew.action"); up.wait_for_timeout(300)
    up.fill("textarea[name=content]", "ModelDriven UI 测试：标题故意留空")
    up.evaluate("document.querySelector('input[name=title]').removeAttribute('required')")
    up.click("#ticketForm button[type=submit]")
    up.wait_for_load_state("networkidle"); up.wait_for_timeout(500)
    check("UI：ModelDriven 表单回显 + actionerror", "请填写问题标题" in up.content() and "标题故意留空" in up.input_value("textarea[name=content]"))
    snap(up, f"{OUT}/20-user-ticket-new-modeldriven.png")
    up.goto(BASE + "/admin/users.action"); up.wait_for_timeout(400)
    check("UI：用户访问管理员页 → 403 页面", "403" in up.content() and "无权访问" in up.content())
    snap(up, f"{OUT}/21-forbidden-403.png")

    browser.close()

print("\nJS / HTTP errors:", len(errors))
for e in errors:
    print("  ", e)
passed = sum(1 for _, ok in results if ok)
print(f"==== UI {passed}/{len(results)} passed ====")
