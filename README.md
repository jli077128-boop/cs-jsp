# 智服 AI —— AI 智能对话客服与工单系统（Struts 2 版）

> 课题 39A · 经典 **Java EE 8（`javax.*`）+ Struts 2 MVC** 实现：**Struts 2（Action / 拦截器 / OGNL / 标签库 / 校验 / 类型转换）+ JSP + DBCP 连接池 + JDBC/DAO + WebSocket**，不使用 Spring。
> 课堂案例 `00_strutsOGNL`、`01_strutsParams`、`02_strutsRegist`、`03_strutsParams`、`04_strutsConversion` 的知识点在项目里都有对应的真实功能，见「三、课堂知识点对照表」。
> 数据库表结构与演示数据和现代版（Spring Boot + Vue）完全相同，可以共用一个 `cs_db` 库。

| 技术 | 版本 |
| --- | --- |
| JDK | 17 ~ 24（代码按 `release 17` 编译） |
| MVC 框架 | **Struts 2 框架，6.x 系列最新版 6.12.0**（`struts2-core` + `struts2-json-plugin`） |
| JavaEE 规范 | **Java EE 8**（`javax.servlet` Servlet 4.0、JSP 2.3 + EL 3.0、JSTL 1.2、`javax.websocket` 1.1） |
| Web 容器 | **Apache Tomcat 9.0.x**（必须是 9） |
| 数据库 / 连接池 | MySQL 8.x / **Apache Commons DBCP2 2.14**（`dbcpconfig.properties`） |
| 页面 | JSP + **Struts 标签 `<s:…>`** + JSTL/EL，原生 JS fetch，ECharts 5 |
| 其他 | jBCrypt（密码加密）、Gson（JSON 序列化辅助）、Remix Icon（图标） |

> **为什么是 Struts 6 而不是 Struts 7？** Struts 7 已改用 Jakarta EE（`jakarta.servlet`），只能跑在 Tomcat 10+；
> Struts 6.x 是最后一个基于 `javax.servlet` 的版本线，正好对应 Java EE 8 + Tomcat 9，和老师课堂上用的 Struts 2 写法（`struts.xml`、`ActionSupport`、OGNL、`<s:>` 标签）完全一致。

---

## 一、架构：Struts 2 MVC

```
浏览器 ──► EncodingFilter（UTF-8）──► StrutsPrepareAndExecuteFilter（核心过滤器，/*）
                                        │   *.action → 找 struts.xml 中的 package/namespace/action
                                        │   /ws/.* 、/static/.* → excludePattern 排除，直接交给 Tomcat（WebSocket、CSS/JS）
                                        ▼
                     拦截器栈：AuthInterceptor（登录 + 角色） → defaultStack
                     （servletConfig、modelDriven、params、conversionError、validation、workflow、exception ...）
                                        ▼
                     Action（extends ActionSupport，action/ 包）── 调用 ── Service ── DAO ── DBCP 连接池 ── MySQL
                                        ▼
                     Result：dispatcher → /WEB-INF/jsp/**.jsp（OGNL + <s:> 标签）
                             redirect / redirectAction（PRG 防重复提交）
                             json（struts2-json-plugin，Ajax 接口）
```

- **Controller**：原来的 16 个 Servlet 全部换成了 `com.kmu.cs.action` 包下的 Action（不再有任何 `@WebServlet`）。
- **Model**：`service/`、`dao/`、`entity/` 三层保持不变。
- **View**：JSP 仍放在 `WEB-INF/jsp` 下，只能经 Action 转发访问；样式（极光渐变 + 玻璃拟态）完全不变。
- **WebSocket 转人工**（`websocket/ChatEndpoint`，`/ws/chat`）不经过 Struts，被 `struts.action.excludePattern` 排除。
- **请求后缀**：`struts.action.extension=action`，所有地址形如 `/cs/user/home.action`。

### struts.xml 包结构（`src/main/resources/struts.xml`，DTD 6.0）

| package | namespace | 拦截器栈 | 说明 |
| --- | --- | --- | --- |
| `cs-default`（abstract） | — | 定义 `auth` 拦截器和 `loginStack / userStack / agentStack / adminStack` | 继承 `json-default`；全局结果 `login / forbidden / notfound / input / error`；全局异常映射 `java.lang.Exception → error` |
| `public` | `/` | defaultStack | `login`、`logout`、`registerForm`、`register` |
| `user` | `/user` | userStack（role=USER） | `home`、`chat`、`kb`、`kbDetail`、`tickets`、`ticketNew`、`ticketSave` |
| `ticket` | `/ticket` | loginStack（role=ANY） | `detail`、`update`（三种角色共用的工单详情） |
| `agent` | `/agent` | agentStack（role=AGENT） | `workbench`、`tickets` |
| `admin` | `/admin` | adminStack（role=ADMIN） | `dashboard`、`tickets`、`ticketAssign`、`users`、`user_*`、`kb`、`kb_*`、`kbBatchForm`、`kbBatch` |
| `api-chat` / `api-agent` / `api-admin` | `/api/chat` 等 | 对应角色栈 | 通配符 `*` + `method="{1}"` + `<allowed-methods>`，`<result type="json">` |

- **严格方法调用（SMI）**：关闭了动态方法调用（`action!method`），改用通配符 `user_*`、`kb_*`、`*` + `<allowed-methods>` 白名单，例如 `/admin/user_reset.action` 调用 `AdminUserAction.reset()`。
- **结果类型**：页面用默认 `dispatcher`；表单提交成功后用 `redirectAction` / `redirect`（例如 `${target}`、`${newId}` 这类 OGNL 参数）；Ajax 用 `json`（`root=result`，输出 `{code,msg,data}`）。

---

## 二、运行步骤（Windows + Tomcat 9 + MySQL 8）

> ⚠️ **必须用 Tomcat 9.0.x**。Tomcat 10/10.1/11 改成了 `jakarta.*` 包名，无法运行 `javax.*` 应用（会出现 404、`ClassNotFoundException: javax.servlet.Filter` 等）。

### 1. 准备环境
1. **JDK 17 ~ 24**：`java -version` 能看到版本号即可。
2. **MySQL 8**：确保服务已启动（`services.msc` → `MySQL80` 正在运行）。
3. **Tomcat 9**：<https://tomcat.apache.org/download-90.cgi> 下载 Core 的 `64-bit Windows zip`，解压到没有中文和空格的目录，例如 `D:\dev\apache-tomcat-9.0.x`。

### 2. 建库：执行 `sql/init.sql`
脚本会 `CREATE DATABASE cs_db`、建 7 张表并插入演示数据（Navicat / IDEA Database / 命令行任选）：
```bat
mysql -uroot -p --default-character-set=utf8mb4 < sql\init.sql
```

### 3. 修改连接池配置 `src/main/resources/dbcpconfig.properties`
```properties
driverClassName=com.mysql.cj.jdbc.Driver
url=jdbc:mysql://localhost:3306/cs_db?useSSL=false&serverTimezone=Asia/Shanghai&allowPublicKeyRetrieval=true&characterEncoding=utf8
username=root
password=123456        # ← 改成你自己 MySQL 的密码（123456 只是占位）
initialSize=5
maxTotal=20
maxIdle=10
minIdle=2
maxWaitMillis=10000
```
`util/DBUtil` 用 `BasicDataSourceFactory.createDataSource(props)` 读取它创建 DBCP2 连接池（与课堂 `02_strutsRegist` / `04_strutsConversion` 的 `dbcpconfig.properties` 写法相同）。**改完需要重新部署**。

### 4. 部署运行
- **IDEA**：`File → Open` 选 `cs-jsp`（Maven 项目）→ `Run → Edit Configurations → + → Tomcat Server → Local`，Tomcat Home 选 **Tomcat 9**；Deployment 添加 `cs-jsp:war exploded`，`Application context` 填 **`/cs`**。
- **命令行**：
  ```bat
  cd cs-jsp
  mvn clean package
  copy target\cs.war D:\dev\apache-tomcat-9.0.x\webapps\
  D:\dev\apache-tomcat-9.0.x\bin\startup.bat
  ```
- 浏览器打开 **<http://localhost:8080/cs/>** → 自动跳到 `login.action`。登录页底部有三个演示账号按钮。

### 5. 导入 MyEclipse（与课堂项目同一个 IDE）
- **推荐**：`File → Import → Maven → Existing Maven Projects` 选 `cs-jsp` 目录，MyEclipse 会按 `pom.xml` 自动下载 Struts 等依赖，`src/main/webapp` 就是课堂项目里的 **WebRoot**；然后在 Servers 视图里添加 **Tomcat 9**，`Add Deployment` 部署本项目，Context root 填 `cs`。
- **不用 Maven 时**（和课堂项目一样的结构）：新建 Web Project（Java EE 8 / Servlet 4.0），把 `src/main/java` 和 `src/main/resources` 的内容都复制到 `src`，把 `src/main/webapp` 的内容复制到 `WebRoot`；执行一次 `mvn dependency:copy-dependencies -DincludeScope=runtime` 后，把 `target/dependency/*.jar` 放进 `WebRoot/WEB-INF/lib`（`struts2-core-6.12.0`、`ognl`、`commons-dbcp2`、`commons-pool2`、`mysql-connector-j`、`jstl` 等）。
- 两种方式都**不要**选 Tomcat 10/11 或 Jakarta EE 9+ 的项目类型。

### 6. 部署到 Ubuntu 虚拟机（一键脚本）
适用于 Ubuntu 22.04 / 24.04（VMware / VirtualBox 都行，虚拟机要能上网）。在虚拟机终端里执行：

```bash
sudo apt update && sudo apt install -y git
git clone https://github.com/jli077128-boop/cs-jsp.git
cd cs-jsp
sudo bash deploy/install-ubuntu.sh
```

脚本会自动：安装 OpenJDK 17、Maven、MySQL 8 → 创建数据库账号 `cs / 123456` 并导入 `sql/init.sql` → 下载 Tomcat 9 到 `/opt/tomcat9` 并注册成 `tomcat9` 系统服务 → 用阿里云镜像 `mvn package` → 部署为 `/cs` 并启动。

- 结束时会打印访问地址，例如 `http://192.168.x.x:8080/cs/`，在虚拟机里或宿主机浏览器都能打开（VMware 用 NAT 或桥接网络均可）。
- 改了代码后：`git pull && sudo bash deploy/install-ubuntu.sh` 重新部署（数据保留）；加 `--reset-db` 会重置为演示数据。
- 日志：`sudo tail -f /opt/tomcat9/logs/catalina.out`；重启：`sudo systemctl restart tomcat9`。
- `git clone` 太慢时，可以在 GitHub 页面 Code → Download ZIP，拷进虚拟机解压后同样执行脚本。

---

## 三、课堂知识点对照表（答辩 / 写报告用）

| 课堂案例 · 知识点 | 本项目中的文件 / 页面 | 怎么演示 |
| --- | --- | --- |
| **struts.xml 配置**（package / namespace / action / result、全局结果、全局异常映射） | `src/main/resources/struts.xml`、`web.xml`（`StrutsPrepareAndExecuteFilter` + `excludePattern`） | 打开 struts.xml 讲 `cs-default` 抽象包 → 各角色包；访问任意 `*.action` |
| **00_strutsOGNL**：值栈、OGNL、`<s:property>`、`<s:iterator>`、`<s:if>/<s:elseif>/<s:else>`、`<s:url>/<s:param>/<s:a>`、`#session`、`#parameters`、`#st`（迭代状态）、OGNL Map 常量 `#{1:'启用'}` | `user/tickets.jsp`（iterator + if + url/param + `#st.index`）、`admin/users.jsp`（`#session.loginUser.id` 判断不能禁用自己、`[1].role` 取值栈下一层）、`admin/tickets.jsp`（嵌套 iterator + `#t`、`<s:date>`）、`common/user-nav.jspf` / `side-nav.jspf`（`#session.loginUser.nickname`）、`user/kb.jsp`（`#parameters.q`）、`login.jsp`（`#parameters.u.defined`）、`admin/kb-batch.jsp`（`#{1:'启用', 0:'停用'}`） | 用户登录 → 我的工单切换状态标签；知识库搜“退款”看标题里的搜索词；管理员 → 用户管理（自己那一行没有“禁用”按钮） |
| **01_strutsParams ①**：Action 属性接收参数 | `action/LoginAction.java`（`username`/`password`/`redirect` 的 setter）、`login.jsp`（`<s:form>` + `<s:textfield name="username">`） | 登录页正常登录；输错密码看 `<s:actionerror>` |
| **01_strutsParams ②**：域模型（JavaBean）接收 | `action/RegisterAction.java`（`SysUser user`）、`register.jsp`（`name="user.username"`、`user.password` …） | 注册页注册新用户，成功后 `redirectAction` 回登录页并自动填入账号 |
| **01_strutsParams ③**：`ModelDriven<T>` | `action/TicketCreateAction.java`（`implements ModelDriven<Ticket>`）、`user/ticket-new.jsp`（字段直接写 `title`、`content`、`category`、`priority`、`sessionId`） | 用户 → 提交工单（或在 AI 对话里点“生成工单”自动带出会话标题）；标题留空提交看回显 |
| **03_strutsParams**：批量参数 `List<T>`（customerBatch.jsp） | `action/AdminKbBatchAction.java`（`List<KbArticle> articles`）、`admin/kb-batch.jsp`（`articles[0].question`、`articles[1].answer` …，可“再加一行”） | 管理员 → 知识库管理 → **批量新增**，填两三行一起保存；某行缺答案时看“第 N 行”错误提示 |
| **02_strutsRegist**：输入校验（`validate()` + `Action-validation.xml`）、`input` 结果、`<s:fielderror>`/`<s:actionerror>` | `resources/com/kmu/cs/action/RegisterAction-validation.xml`（requiredstring / regex / stringlength）、`RegisterAction.validate()`（两次密码一致、账号已存在）、`register.jsp`；另有 `AdminTicketAction.validateExecute()`、`AdminKbBatchAction.validate()`；错误文字在 `messages.properties` | 注册页填账号 `ab`、密码 `123`、确认 `456`、手机号 `12345` 提交 → 每个字段下方出现红色提示（表单加了 `novalidate`，浏览器不拦截，专门演示服务端校验） |
| **02/04 · DBCP 连接池** | `resources/dbcpconfig.properties` + `util/DBUtil.java`（`BasicDataSourceFactory.createDataSource`） | 讲配置项；改错密码重新部署会看到 500 页提示“检查 dbcpconfig.properties” |
| **04_strutsConversion**：自定义类型转换器 + 全局注册 | `converter/DateConverter.java`（`extends StrutsTypeConverter`，`yyyy-MM-dd` ⇄ `java.util.Date`）、`resources/xwork-conversion.properties`（课堂写法）与 `struts-conversion.properties`（Struts 6 推荐写法）、`AdminTicketAction.startDate/endDate`、`admin/tickets.jsp` | 管理员 → 工单管理 → 选开始 / 结束日期筛选（显示“已按提交日期筛选”）；地址栏改成 `startDate=2026/13/45` 回车 → 显示“开始日期格式不正确”（`TypeConversionException` → conversionError 拦截器 → input） |
| **拦截器**（自定义 Interceptor + 拦截器栈） | `interceptor/AuthInterceptor.java`（`extends AbstractInterceptor`，参数 `role`）、`struts.xml` 中 `userStack/agentStack/adminStack/loginStack` | 退出后直接访问 `/cs/user/tickets.action?status=PENDING` → 跳登录页（带 `redirect`），登录后自动回到该页；用户账号访问 `/cs/admin/users.action` → **403 无权访问**页；未登录调接口返回 401 JSON |
| **Action / ActionSupport / 结果类型** | `action/BaseAction.java`（`SessionAware` + `ServletRequestAware`，flash 提示）、`action/JsonAction.java`（json 结果）、各 Action | `redirectAction` 见注册、提交工单；`redirect` 见登录、知识库操作；`json` 见 AI 对话 |
| **Ajax + json 插件** | `struts2-json-plugin`、`ChatApiAction`、`AgentApiAction`、`static/js/app.js`（fetch 以表单格式提交，参数直接注入 Action 属性） | AI 对话、转人工、客服工作台的所有请求 |

---

## 四、演示账号（密码全部是 `123456`）

| 角色 | 账号 | 说明 |
| --- | --- | --- |
| 管理员 | `admin` | 数据看板、知识库（含批量新增）、工单（含日期筛选）、用户管理 |
| 客服 | `agent01` / `agent02` | `agent03` 已禁用 |
| 用户 | `user01`（推荐） ~ `user06` | `user04` 已禁用 |

### 推荐演示流程（约 6 分钟）
> 用户和客服要分别用两个浏览器（或普通窗口 + 无痕窗口）登录，同一浏览器共用一个 Session。
1. **注册**：故意填错 → 看字段校验；再正确注册 → 自动跳回登录页并填好账号。
2. **用户 `user01`**：首页搜索“退款”→ 智能客服提问 → **转人工**；在“我的工单”切换状态标签；提交工单（ModelDriven）。
3. **客服 `agent01`**：工作台显示“WebSocket 实时连接”→ 接入会话 → 双方实时聊天 → 一键建单；用户结束会话并五星评价。
4. **管理员 `admin`**：看板 5 个 ECharts 图表 → 知识库 **批量新增** → 工单管理 **按日期筛选**（再演示非法日期）→ 用户管理。
5. **拦截器**：用 `user01` 访问 `/cs/admin/users.action` 看 403；退出后访问 `/cs/user/tickets.action` 被拦截到登录页。

---

## 五、项目结构

```
cs-jsp/
├── pom.xml                         Maven（war，release 17）：struts2-core / struts2-json-plugin 6.12.0、commons-dbcp2、jstl、mysql-connector-j …
├── sql/init.sql                    建库建表 + 演示数据（未改动）
├── src/main/java/com/kmu/cs/
│   ├── action/                     Struts Action（extends ActionSupport）
│   │   ├── BaseAction / JsonAction           公共父类（SessionAware、flash 提示）/ json 接口父类
│   │   ├── LoginAction / LogoutAction / RegisterAction
│   │   ├── UserHomeAction / ChatAction / ChatApiAction / KnowledgeAction / TicketAction / TicketCreateAction
│   │   ├── TicketDetailAction                工单详情（三角色共用）
│   │   ├── AgentAction / AgentApiAction
│   │   └── AdminDashboardAction / AdminTicketAction / AdminUserAction / AdminKnowledgeAction / AdminKbBatchAction
│   ├── interceptor/AuthInterceptor.java      登录 + 角色拦截器
│   ├── converter/DateConverter.java          自定义类型转换器
│   ├── filter/EncodingFilter.java            UTF-8（web.xml 中排在 Struts 过滤器之前）
│   ├── listener/                             AppContextListener（初始化/关闭 DBCP）、OnlineUserListener（在线人数）
│   ├── websocket/                            ChatEndpoint（/ws/chat）、ChatHub、HttpSessionConfigurator
│   ├── service/ + impl/                      业务层（未改动）
│   ├── dao/ + impl/                          DAO（未改动）
│   ├── entity/                               实体（未改动）
│   └── util/                                 DBUtil（DBCP + ThreadLocal 事务）、JsonUtil、LlmClient、Rules、Md …
├── src/main/resources/
│   ├── struts.xml                            Struts 核心配置
│   ├── com/kmu/cs/action/RegisterAction-validation.xml   声明式校验
│   ├── xwork-conversion.properties / struts-conversion.properties   全局类型转换器注册
│   ├── messages.properties                   校验 / 类型转换错误提示（\uXXXX 转义，中文写在注释里）
│   ├── dbcpconfig.properties                 DBCP 连接池
│   ├── llm.properties                        大模型（可选）
│   └── simplelogger.properties               日志级别
├── src/main/webapp/                          ← 对应 MyEclipse 的 WebRoot
│   ├── index.jsp                             欢迎页（按角色跳转到 *.action）
│   ├── WEB-INF/web.xml                       EncodingFilter + StrutsPrepareAndExecuteFilter、错误页、Session 超时
│   ├── WEB-INF/jsp/                          所有 JSP（common / user / agent / admin / error，含新增的 admin/kb-batch.jsp、error/403.jsp、error/400.jsp）
│   └── static/                               css / js / img / vendor（不经过 Struts）
├── screenshots/                              运行截图
└── test-scripts/                             自动化测试（Python，答辩不需要）
```

### 主要 URL（前缀 `/cs`）

| 角色 | 页面 | 地址 |
| --- | --- | --- |
| 公共 | 登录 / 注册 / 退出 | `/login.action`、`/registerForm.action`（提交到 `/register.action`）、`/logout.action` |
| 用户 | 帮助中心 / 知识库 / 详情 | `/user/home.action`、`/user/kb.action?cid=&q=`、`/user/kbDetail.action?id=` |
| 用户 | AI 对话 | `/user/chat.action?sid=`（接口 `/api/chat/ask.action`、`human`、`end`、`rate`、`poll`、`sessions`） |
| 用户 | 我的工单 / 提交工单 | `/user/tickets.action?status=`、`/user/ticketNew.action?sid=` → `/user/ticketSave.action` |
| 共用 | 工单详情 / 处理 | `/ticket/detail.action?id=`、`POST /ticket/update.action` |
| 客服 | 工作台 / 我的工单 | `/agent/workbench.action`（接口 `/api/agent/*.action`）、`/agent/tickets.action?tab=pool` |
| 管理员 | 看板 / 知识库 / 批量新增 | `/admin/dashboard.action`（接口 `/api/admin/stats.action`）、`/admin/kb.action`、`/admin/kb_articleSave.action` 等、`/admin/kbBatchForm.action` |
| 管理员 | 工单 / 用户 | `/admin/tickets.action?status=&q=&startDate=&endDate=`、`/admin/ticketAssign.action`、`/admin/users.action`、`/admin/user_add.action` 等 |
| 实时 | WebSocket | `ws://localhost:8080/cs/ws/chat`（不经过 Struts） |

---

## 六、可选：接入大模型

编辑 `src/main/resources/llm.properties`（任意 OpenAI 兼容接口）：
```properties
llm.base-url=https://api.deepseek.com/v1
llm.api-key=sk-你的key
llm.model=deepseek-chat
```
留空时用知识库关键词匹配回答，离线也能完整演示。

---

## 七、常见问题

| 现象 | 解决办法 |
| --- | --- |
| 部署后全部 404，日志有 `javax.servlet` 的 `ClassNotFoundException` | 用成了 Tomcat 10/11，请换 **Tomcat 9.0.x** |
| 访问 `/cs/user/home`（没有 `.action`）404 | Struts 只处理 `*.action`，请用 `/cs/user/home.action` 或直接访问 `/cs/` |
| 页面 500，提示数据库连接失败 | MySQL 没启动，或 `dbcpconfig.properties` 账号密码不对；改完重新部署 |
| 启动日志有一行 `WARN … Instead of using deprecated xwork-conversion.properties …` | 正常。项目同时保留了课堂写法 `xwork-conversion.properties` 和 Struts 6 推荐的 `struts-conversion.properties`；删掉其中一个即可消除 |
| 想看 OGNL 详细报错 | 临时把 struts.xml 中 `struts.devMode` 改成 `true`（演示 / 提交时改回 `false`） |
| 控制台中文乱码 | Tomcat VM options 加 `-Dfile.encoding=UTF-8 -Dsun.stdout.encoding=UTF-8 -Dsun.stderr.encoding=UTF-8` |
| 用户和客服登录后互相“顶号” | 同一浏览器共用 Session，请用两个浏览器或无痕窗口 |

---

## 八、测试情况

`test-scripts/` 中是自动化测试（Python 3 + `requests`、`websocket-client`、`playwright`；`ui_test.py` 默认使用 `/usr/bin/chromium`，可用环境变量 `CHROMIUM` 指定）：

- `e2e_test.py`：134 项 HTTP + WebSocket 测试 —— 原有业务全流程（三种角色、AI 问答、工单流转、转人工实时聊天、知识库 / 用户 / 工单管理），以及 Struts 专项：拦截器登录跳转与回跳、403 forbidden、注册字段校验、DateConverter 合法 / 非法日期、`List<KbArticle>` 批量保存与校验、ModelDriven 回显与防篡改、OGNL 页面、json 结果、excludePattern。
- `ui_test.py`：25 项真实浏览器测试并截图（`screenshots/01~21`）。

测试环境：JDK 21 + **Tomcat 9.0.123** + MariaDB（MySQL 兼容），Struts 6.12.0，`struts.devMode=false`：e2e 134/134、UI 25/25 全部通过；无 500、无 JS 报错，Tomcat 日志中没有 OGNL / Struts 异常（只有上面提到的一条 conversion 文件过时 WARN）。
