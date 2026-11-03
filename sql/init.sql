-- =========================================================
-- 智服 AI —— AI 智能对话客服与工单系统  数据库初始化脚本
-- MySQL 8.x   执行方式：在 Navicat / IDEA Database / mysql 命令行里整段运行
-- 所有演示账号密码都是 123456
-- =========================================================
CREATE DATABASE IF NOT EXISTS cs_db DEFAULT CHARACTER SET utf8mb4 COLLATE utf8mb4_general_ci;
USE cs_db;

DROP TABLE IF EXISTS ticket_record;
DROP TABLE IF EXISTS ticket;
DROP TABLE IF EXISTS chat_message;
DROP TABLE IF EXISTS chat_session;
DROP TABLE IF EXISTS kb_article;
DROP TABLE IF EXISTS kb_category;
DROP TABLE IF EXISTS sys_user;

-- 1. 用户表（用户 / 客服 / 管理员 三种角色共用）
CREATE TABLE sys_user (
  id           BIGINT PRIMARY KEY AUTO_INCREMENT,
  username     VARCHAR(32)  NOT NULL UNIQUE COMMENT '登录名',
  password     VARCHAR(100) NOT NULL COMMENT 'BCrypt 加密后的密码',
  nickname     VARCHAR(32)  NOT NULL COMMENT '昵称',
  avatar       VARCHAR(255) DEFAULT NULL COMMENT '头像地址',
  avatar_color VARCHAR(16)  DEFAULT '#8b5cf6' COMMENT '无头像时的头像底色',
  email        VARCHAR(64)  DEFAULT NULL,
  phone        VARCHAR(20)  DEFAULT NULL,
  role         VARCHAR(10)  NOT NULL DEFAULT 'USER' COMMENT 'USER / AGENT / ADMIN',
  status       TINYINT      NOT NULL DEFAULT 1 COMMENT '1 正常 0 禁用',
  online       TINYINT      NOT NULL DEFAULT 0 COMMENT '1 在线 0 离线（客服用）',
  create_time  DATETIME     NOT NULL DEFAULT CURRENT_TIMESTAMP
) COMMENT '用户表';

-- 2. 知识库分类
CREATE TABLE kb_category (
  id    BIGINT PRIMARY KEY AUTO_INCREMENT,
  name  VARCHAR(32) NOT NULL,
  icon  VARCHAR(32) DEFAULT 'Document' COMMENT 'Element Plus 图标名',
  color VARCHAR(32) DEFAULT '#4f7cff,#22d3ee' COMMENT '宫格渐变色，两个颜色用逗号分隔',
  descr VARCHAR(64) DEFAULT NULL COMMENT '分类说明',
  sort  INT DEFAULT 0
) COMMENT '知识库分类';

-- 3. 知识库问答条目
CREATE TABLE kb_article (
  id          BIGINT PRIMARY KEY AUTO_INCREMENT,
  category_id BIGINT       NOT NULL,
  question    VARCHAR(200) NOT NULL COMMENT '标准问题',
  answer      TEXT         NOT NULL COMMENT '答案（支持 Markdown）',
  keywords    VARCHAR(200) DEFAULT NULL COMMENT '关键词，逗号分隔，用于检索',
  hit_count   INT          NOT NULL DEFAULT 0 COMMENT '命中次数',
  status      TINYINT      NOT NULL DEFAULT 1 COMMENT '1 启用 0 停用',
  create_time DATETIME     NOT NULL DEFAULT CURRENT_TIMESTAMP,
  update_time DATETIME     NOT NULL DEFAULT CURRENT_TIMESTAMP
) COMMENT '知识库问答';

-- 4. 会话
CREATE TABLE chat_session (
  id         BIGINT PRIMARY KEY AUTO_INCREMENT,
  user_id    BIGINT      NOT NULL,
  agent_id   BIGINT      DEFAULT NULL COMMENT '接入的人工客服',
  title      VARCHAR(64) DEFAULT '新对话',
  mode       VARCHAR(10) NOT NULL DEFAULT 'AI' COMMENT 'AI / HUMAN',
  status     VARCHAR(10) NOT NULL DEFAULT 'ACTIVE' COMMENT 'ACTIVE 进行中 / QUEUE 排队 / ENDED 结束',
  ai_solved  TINYINT     NOT NULL DEFAULT 1 COMMENT '1 AI 独立解决 0 转了人工或工单',
  rating     TINYINT     DEFAULT NULL COMMENT '满意度 1-5',
  start_time DATETIME    NOT NULL DEFAULT CURRENT_TIMESTAMP,
  end_time   DATETIME    DEFAULT NULL
) COMMENT '会话';

-- 5. 聊天消息
CREATE TABLE chat_message (
  id          BIGINT PRIMARY KEY AUTO_INCREMENT,
  session_id  BIGINT      NOT NULL,
  sender_type VARCHAR(10) NOT NULL COMMENT 'USER / AI / AGENT',
  sender_id   BIGINT      DEFAULT NULL,
  content     TEXT        NOT NULL,
  create_time DATETIME    NOT NULL DEFAULT CURRENT_TIMESTAMP
) COMMENT '聊天消息';

-- 6. 工单
CREATE TABLE ticket (
  id          BIGINT PRIMARY KEY AUTO_INCREMENT,
  ticket_no   VARCHAR(32)  NOT NULL UNIQUE COMMENT '工单编号',
  user_id     BIGINT       NOT NULL,
  session_id  BIGINT       DEFAULT NULL COMMENT '来源会话',
  title       VARCHAR(100) NOT NULL,
  content     TEXT,
  category    VARCHAR(20)  DEFAULT '其他',
  priority    VARCHAR(10)  NOT NULL DEFAULT 'MEDIUM' COMMENT 'LOW / MEDIUM / HIGH / URGENT',
  status      VARCHAR(12)  NOT NULL DEFAULT 'PENDING' COMMENT 'PENDING / PROCESSING / RESOLVED / CLOSED',
  assignee_id BIGINT       DEFAULT NULL COMMENT '处理客服',
  ai_summary  VARCHAR(255) DEFAULT NULL COMMENT 'AI 摘要',
  ai_tags     VARCHAR(100) DEFAULT NULL COMMENT 'AI 标签，逗号分隔',
  create_time DATETIME     NOT NULL DEFAULT CURRENT_TIMESTAMP,
  update_time DATETIME     NOT NULL DEFAULT CURRENT_TIMESTAMP
) COMMENT '工单';

-- 7. 工单处理记录（时间线）
CREATE TABLE ticket_record (
  id            BIGINT PRIMARY KEY AUTO_INCREMENT,
  ticket_id     BIGINT      NOT NULL,
  operator_id   BIGINT      DEFAULT NULL,
  operator_name VARCHAR(32) DEFAULT NULL COMMENT '操作人显示名',
  action        VARCHAR(12) NOT NULL COMMENT 'CREATE / AI / ASSIGN / PROCESS / RESOLVE / CLOSE',
  content       VARCHAR(255),
  create_time   DATETIME    NOT NULL DEFAULT CURRENT_TIMESTAMP
) COMMENT '工单处理记录';

-- ================== 演示数据 ==================

INSERT INTO sys_user (id, username, password, nickname, role, status, online, avatar_color, email, phone, create_time) VALUES
(1, 'admin', '$2a$10$hCvYihibbI9HQQnMwOaznul.BnoQ6Hnpz7DqoIQUtDMZVdLkUPJXa', '系统管理员', 'ADMIN', 1, 1, '#8b5cf6', 'admin@zhifu.ai', '13800000001', '2026-09-01 09:00'),
(2, 'agent01', '$2a$10$hCvYihibbI9HQQnMwOaznul.BnoQ6Hnpz7DqoIQUtDMZVdLkUPJXa', '客服小林', 'AGENT', 1, 1, '#22d3ee', 'lin@zhifu.ai', '13800000002', '2026-09-02 10:12'),
(3, 'agent02', '$2a$10$hCvYihibbI9HQQnMwOaznul.BnoQ6Hnpz7DqoIQUtDMZVdLkUPJXa', '客服阿杰', 'AGENT', 1, 0, '#f472b6', 'jie@zhifu.ai', '13800000003', '2026-09-03 14:20'),
(4, 'agent03', '$2a$10$hCvYihibbI9HQQnMwOaznul.BnoQ6Hnpz7DqoIQUtDMZVdLkUPJXa', '客服小雨', 'AGENT', 0, 0, '#fbbf24', 'yu@zhifu.ai', '13800000004', '2026-09-05 08:40'),
(5, 'user01', '$2a$10$hCvYihibbI9HQQnMwOaznul.BnoQ6Hnpz7DqoIQUtDMZVdLkUPJXa', '张同学', 'USER', 1, 1, '#60a5fa', 'zhang@qq.com', '13900001201', '2026-09-10 19:02'),
(6, 'user02', '$2a$10$hCvYihibbI9HQQnMwOaznul.BnoQ6Hnpz7DqoIQUtDMZVdLkUPJXa', '李女士', 'USER', 1, 0, '#34d399', 'li@163.com', '13700003345', '2026-09-12 11:30'),
(7, 'user03', '$2a$10$hCvYihibbI9HQQnMwOaznul.BnoQ6Hnpz7DqoIQUtDMZVdLkUPJXa', '王先生', 'USER', 1, 1, '#f97316', 'wang@gmail.com', '13600008890', '2026-09-18 16:45'),
(8, 'user04', '$2a$10$hCvYihibbI9HQQnMwOaznul.BnoQ6Hnpz7DqoIQUtDMZVdLkUPJXa', '陈小姐', 'USER', 0, 0, '#e879f9', 'chen@qq.com', '13500006612', '2026-09-21 21:08'),
(9, 'user05', '$2a$10$hCvYihibbI9HQQnMwOaznul.BnoQ6Hnpz7DqoIQUtDMZVdLkUPJXa', '赵同学', 'USER', 1, 0, '#a3e635', 'zhao@outlook.com', '13300007781', '2026-10-02 13:15'),
(10, 'user06', '$2a$10$hCvYihibbI9HQQnMwOaznul.BnoQ6Hnpz7DqoIQUtDMZVdLkUPJXa', '周先生', 'USER', 1, 1, '#38bdf8', 'zhou@qq.com', '13100002209', '2026-10-08 10:01');

INSERT INTO kb_category (id, name, icon, color, descr, sort) VALUES
(1, '账号安全', 'User', '#4f7cff,#22d3ee', '登录、密码、绑定', 1),
(2, '订单支付', 'Wallet', '#8b5cf6,#ec4899', '支付方式、扣款', 2),
(3, '退款售后', 'RefreshLeft', '#f472b6,#fb923c', '退货、退款进度', 3),
(4, '物流配送', 'Van', '#22d3ee,#34d399', '发货、查件、改地址', 4),
(5, '发票报销', 'Tickets', '#fbbf24,#f97316', '电子发票、抬头', 5),
(6, '会员权益', 'Trophy', '#a78bfa,#60a5fa', '积分、优惠券', 6),
(7, '技术支持', 'Monitor', '#38bdf8,#818cf8', 'App 异常、闪退', 7),
(8, '投诉建议', 'ChatLineSquare', '#fb7185,#c084fc', '意见反馈', 8);

INSERT INTO kb_article (id, category_id, question, answer, keywords, hit_count, status, create_time, update_time) VALUES
(1, 3, '怎么申请退款？', '在 **我的订单** 中找到对应订单，点击「申请售后」→ 选择「仅退款」或「退货退款」，填写原因后提交即可。

- 未发货订单：一般 **1 小时内** 自动退款
- 已发货订单：商家确认收货后 **1-3 个工作日** 原路退回', '退款,售后,退钱', 1284, 1, '2026-09-02 10:00', '2026-10-18 15:20'),
(2, 4, '下单后可以修改收货地址吗？', '订单 **未发货** 前可以修改：进入订单详情 → 点击「修改地址」。

已发货订单请联系快递或转人工客服协助拦截改派。', '地址,修改,收货', 962, 1, '2026-09-02 10:05', '2026-10-12 09:30'),
(3, 5, '发票怎么开？', '订单完成后，在订单详情页点击「申请开票」，选择 **个人 / 企业** 抬头，电子发票会在 24 小时内发送到你的邮箱。', '发票,开票,抬头,报销', 845, 1, '2026-09-03 11:00', '2026-10-10 17:00'),
(4, 1, '忘记密码怎么办？', '在登录页点击「忘记密码」，通过 **手机验证码** 或 **绑定邮箱** 重置。若手机号已停用，请转人工核验身份。', '密码,忘记,重置,登录', 731, 1, '2026-09-03 14:00', '2026-10-01 08:00'),
(5, 4, '快递几天能到？', '一般地区 **2-3 天**，偏远地区 **4-7 天**。可在订单详情查看实时物流轨迹。', '物流,快递,几天,到货', 688, 1, '2026-09-04 09:00', '2026-10-05 10:00'),
(6, 2, '支持哪些支付方式？', '支持 **微信支付、支付宝、银联云闪付** 以及部分信用卡分期。', '支付,付款,方式', 502, 1, '2026-09-05 10:00', '2026-09-28 16:00'),
(7, 2, '付款成功但订单显示未支付？', '支付状态同步可能有 **1-5 分钟** 延迟，请稍后刷新。超过 30 分钟仍未更新，请提交工单并附上支付截图。', '支付,未支付,扣款', 433, 1, '2026-09-06 10:00', '2026-10-15 11:00'),
(8, 6, '会员积分怎么使用？', '积分可在结算页 **抵扣现金**（100 积分 = 1 元），也可在「会员中心」兑换优惠券。', '积分,会员,抵扣', 389, 1, '2026-09-07 10:00', '2026-10-02 13:00'),
(9, 7, 'App 打开闪退怎么办？', '1. 升级到最新版本
2. 清除缓存后重启
3. 仍无法解决请提交工单，并注明 **手机型号与系统版本**', '闪退,崩溃,打不开', 276, 1, '2026-09-08 10:00', '2026-10-09 18:00'),
(10, 3, '退货运费谁承担？', '因商品质量问题退货，运费由商家承担；7 天无理由退货运费由买家承担（已购运费险可理赔）。', '运费,退货,运费险', 241, 1, '2026-09-09 10:00', '2026-10-11 10:00'),
(11, 1, '如何更换绑定手机号？', '进入「账号设置 → 安全中心 → 更换手机号」，需验证原手机号或进行人脸核验。', '手机号,绑定,更换', 198, 0, '2026-09-10 10:00', '2026-09-30 10:00'),
(12, 8, '如何投诉商家？', '在订单详情点击「投诉商家」，或在本页提交工单，我们会在 **24 小时内** 响应。', '投诉,商家,举报', 167, 1, '2026-09-11 10:00', '2026-10-06 10:00');

INSERT INTO ticket (id, ticket_no, user_id, session_id, title, content, category, priority, status, assignee_id, ai_summary, ai_tags, create_time, update_time) VALUES
(1, 'TK20261022001', 5, NULL, '退款一周还没到账', '10 月 15 日申请的退款，显示商家已同意，但一直没有到账。', '退款售后', 'HIGH', 'PROCESSING', 2, '退款审核通过后 7 天未到账，疑似支付渠道延迟', '退款,到账延迟', '2026-10-22 09:12', '2026-10-22 10:40'),
(2, 'TK20261021014', 5, NULL, '发票抬头填错需要重开', '企业发票抬头少写了“有限公司”，需要作废重开。', '发票报销', 'MEDIUM', 'RESOLVED', 2, '发票抬头错误，申请红冲重开', '发票,重开', '2026-10-21 14:30', '2026-10-21 17:05'),
(3, 'TK20261020008', 5, NULL, '快递显示签收但没收到', '物流显示昨天已签收，但我家里和快递柜都没有。', '物流配送', 'URGENT', 'PENDING', NULL, '物流异常签收，需联系快递核实', '物流,异常签收', '2026-10-20 20:18', '2026-10-20 20:18'),
(4, 'TK20261018003', 5, NULL, '账号被异地登录', '收到异地登录提醒，担心账号被盗。', '账号安全', 'HIGH', 'CLOSED', 3, '疑似账号被盗，已协助冻结并修改密码', '账号安全', '2026-10-18 08:02', '2026-10-19 11:20'),
(5, 'TK20261022006', 6, NULL, '支付成功订单仍显示待付款', '微信已扣款 199 元，订单还是待付款。', '订单支付', 'HIGH', 'PENDING', NULL, '支付回调未同步，需核对交易流水', '支付,状态不同步', '2026-10-22 11:05', '2026-10-22 11:05'),
(6, 'TK20261022007', 7, NULL, 'App 更新后闪退', '安卓 14，更新到 5.2.0 后一打开就闪退。', '技术支持', 'MEDIUM', 'PROCESSING', 2, '安卓 14 + v5.2.0 启动崩溃，疑似兼容性问题', '闪退,Android', '2026-10-22 08:40', '2026-10-22 09:55'),
(7, 'TK20261021020', 8, NULL, '会员积分清零', '上个月还有 3000 积分，今天看变成 0 了。', '会员权益', 'MEDIUM', 'PENDING', NULL, '积分异常清零，需查询积分流水', '积分,异常', '2026-10-21 22:10', '2026-10-21 22:10'),
(8, 'TK20261020015', 9, NULL, '商家拒绝七天无理由退货', '商品未拆封，商家却拒绝退货。', '投诉建议', 'HIGH', 'PROCESSING', 3, '商家违规拒绝无理由退货，需平台介入', '投诉,退货', '2026-10-20 15:33', '2026-10-21 10:00'),
(9, 'TK20261019009', 10, NULL, '想修改已发货订单地址', '搬家了，订单已经发货，想改到新地址。', '物流配送', 'LOW', 'RESOLVED', 2, '已发货改址，已联系快递改派', '改地址', '2026-10-19 10:21', '2026-10-19 16:45'),
(10, 'TK20261017002', 6, NULL, '优惠券无法使用', '满 200 减 30 的券在结算页提示不可用。', '会员权益', 'LOW', 'CLOSED', 3, '优惠券限定品类，已解释说明', '优惠券', '2026-10-17 18:00', '2026-10-18 09:00');

INSERT INTO ticket_record (ticket_id, operator_id, operator_name, action, content, create_time) VALUES
(1, 5, '张同学', 'CREATE', '用户通过 AI 对话提交工单', '2026-10-22 09:12'),
(1, NULL, '智服 AI', 'AI', '自动分类为「退款售后」，优先级判定：高', '2026-10-22 09:12'),
(1, NULL, '系统', 'ASSIGN', '已分配给客服小林', '2026-10-22 09:30'),
(1, 2, '客服小林', 'PROCESS', '已联系支付渠道核查，预计 24 小时内到账', '2026-10-22 10:40'),
(2, 5, '张同学', 'CREATE', '用户提交工单', '2026-10-21 14:30'),
(2, NULL, '系统', 'ASSIGN', '已分配给客服小林', '2026-10-21 14:42'),
(2, 2, '客服小林', 'PROCESS', '原发票已红冲作废', '2026-10-21 16:10'),
(2, 2, '客服小林', 'RESOLVE', '新发票已发送至邮箱，请查收', '2026-10-21 17:05'),
(3, 5, '张同学', 'CREATE', '用户提交工单', '2026-10-20 20:18'),
(3, NULL, '智服 AI', 'AI', '自动分类为「物流配送」，优先级判定：紧急', '2026-10-20 20:18'),
(4, 5, '张同学', 'CREATE', '用户提交工单', '2026-10-18 08:02'),
(4, NULL, '系统', 'ASSIGN', '已分配给客服阿杰', '2026-10-18 08:10'),
(4, 3, '客服阿杰', 'PROCESS', '已临时冻结账号，引导用户修改密码', '2026-10-18 08:35'),
(4, 3, '客服阿杰', 'RESOLVE', '账号已解冻，开启登录保护', '2026-10-18 15:00'),
(4, 5, '张同学', 'CLOSE', '用户确认解决并评价 5 星', '2026-10-19 11:20'),
(5, 6, '用户', 'CREATE', '用户提交工单', '2026-10-22 11:05'),
(5, NULL, '智服 AI', 'AI', '自动分类为「订单支付」并生成摘要', '2026-10-22 11:05'),
(6, 7, '用户', 'CREATE', '用户提交工单', '2026-10-22 08:40'),
(6, NULL, '智服 AI', 'AI', '自动分类为「技术支持」并生成摘要', '2026-10-22 08:40'),
(7, 8, '用户', 'CREATE', '用户提交工单', '2026-10-21 22:10'),
(7, NULL, '智服 AI', 'AI', '自动分类为「会员权益」并生成摘要', '2026-10-21 22:10'),
(8, 9, '用户', 'CREATE', '用户提交工单', '2026-10-20 15:33'),
(8, NULL, '智服 AI', 'AI', '自动分类为「投诉建议」并生成摘要', '2026-10-20 15:33'),
(9, 10, '用户', 'CREATE', '用户提交工单', '2026-10-19 10:21'),
(9, NULL, '智服 AI', 'AI', '自动分类为「物流配送」并生成摘要', '2026-10-19 10:21'),
(10, 6, '用户', 'CREATE', '用户提交工单', '2026-10-17 18:00'),
(10, NULL, '智服 AI', 'AI', '自动分类为「会员权益」并生成摘要', '2026-10-17 18:00');

-- 会话与消息：时间按『执行脚本的当天』往前推，这样看板的近 7 天趋势总有数据
INSERT INTO chat_session (id, user_id, agent_id, title, mode, status, ai_solved, rating, start_time, end_time) VALUES
(1, 5, NULL, '退款一周还没到账', 'AI', 'ENDED', 0, 4, DATE_SUB(NOW(), INTERVAL 60 MINUTE), DATE_SUB(NOW(), INTERVAL 60 MINUTE)),
(2, 5, 2, '发票抬头填错', 'HUMAN', 'ENDED', 0, 5, DATE_SUB(NOW(), INTERVAL 1500 MINUTE), DATE_SUB(NOW(), INTERVAL 1500 MINUTE)),
(3, 5, NULL, '快递显示签收没收到', 'AI', 'ENDED', 1, 3, DATE_SUB(NOW(), INTERVAL 2940 MINUTE), DATE_SUB(NOW(), INTERVAL 2940 MINUTE)),
(4, 5, NULL, '修改收货地址', 'AI', 'ENDED', 1, 5, DATE_SUB(NOW(), INTERVAL 4380 MINUTE), DATE_SUB(NOW(), INTERVAL 4380 MINUTE)),
(5, 5, NULL, '会员积分怎么用', 'AI', 'ENDED', 1, 5, DATE_SUB(NOW(), INTERVAL 8700 MINUTE), DATE_SUB(NOW(), INTERVAL 8700 MINUTE)),
(6, 6, NULL, '会员积分怎么使用', 'AI', 'ENDED', 1, 5, DATE_SUB(NOW(), INTERVAL 218 MINUTE), DATE_SUB(NOW(), INTERVAL 213 MINUTE)),
(7, 5, NULL, '支持哪些支付方式', 'AI', 'ENDED', 1, 4, DATE_SUB(NOW(), INTERVAL 1109 MINUTE), DATE_SUB(NOW(), INTERVAL 1104 MINUTE)),
(8, 5, NULL, '快递几天能到', 'AI', 'ENDED', 1, 4, DATE_SUB(NOW(), INTERVAL 213 MINUTE), DATE_SUB(NOW(), INTERVAL 208 MINUTE)),
(9, 5, 2, '会员积分怎么使用', 'HUMAN', 'ENDED', 0, 3, DATE_SUB(NOW(), INTERVAL 1228 MINUTE), DATE_SUB(NOW(), INTERVAL 1223 MINUTE)),
(10, 6, NULL, '怎么申请退款', 'AI', 'ENDED', 1, 3, DATE_SUB(NOW(), INTERVAL 882 MINUTE), DATE_SUB(NOW(), INTERVAL 877 MINUTE)),
(11, 6, NULL, '怎么申请退款', 'AI', 'ENDED', 1, 4, DATE_SUB(NOW(), INTERVAL 342 MINUTE), DATE_SUB(NOW(), INTERVAL 337 MINUTE)),
(12, 9, NULL, '发票怎么开', 'AI', 'ENDED', 1, 4, DATE_SUB(NOW(), INTERVAL 1239 MINUTE), DATE_SUB(NOW(), INTERVAL 1234 MINUTE)),
(13, 10, 2, '发票怎么开', 'HUMAN', 'ENDED', 0, 5, DATE_SUB(NOW(), INTERVAL 1239 MINUTE), DATE_SUB(NOW(), INTERVAL 1234 MINUTE)),
(14, 6, 2, '支持哪些支付方式', 'HUMAN', 'ENDED', 0, 5, DATE_SUB(NOW(), INTERVAL 198 MINUTE), DATE_SUB(NOW(), INTERVAL 193 MINUTE)),
(15, 5, NULL, '忘记密码怎么办', 'AI', 'ENDED', 1, 5, DATE_SUB(NOW(), INTERVAL 1158 MINUTE), DATE_SUB(NOW(), INTERVAL 1153 MINUTE)),
(16, 7, NULL, 'App 打开闪退怎么办', 'AI', 'ENDED', 1, 4, DATE_SUB(NOW(), INTERVAL 998 MINUTE), DATE_SUB(NOW(), INTERVAL 993 MINUTE)),
(17, 7, NULL, '忘记密码怎么办', 'AI', 'ENDED', 1, 3, DATE_SUB(NOW(), INTERVAL 569 MINUTE), DATE_SUB(NOW(), INTERVAL 564 MINUTE)),
(18, 10, NULL, '下单后可以修改收货地址吗', 'AI', 'ENDED', 1, 5, DATE_SUB(NOW(), INTERVAL 773 MINUTE), DATE_SUB(NOW(), INTERVAL 768 MINUTE)),
(19, 9, NULL, '下单后可以修改收货地址吗', 'AI', 'ENDED', 1, 3, DATE_SUB(NOW(), INTERVAL 219 MINUTE), DATE_SUB(NOW(), INTERVAL 214 MINUTE)),
(20, 6, NULL, '支持哪些支付方式', 'AI', 'ENDED', 1, 5, DATE_SUB(NOW(), INTERVAL 2511 MINUTE), DATE_SUB(NOW(), INTERVAL 2506 MINUTE)),
(21, 5, NULL, '快递几天能到', 'AI', 'ENDED', 1, 4, DATE_SUB(NOW(), INTERVAL 2683 MINUTE), DATE_SUB(NOW(), INTERVAL 2678 MINUTE)),
(22, 7, NULL, '支持哪些支付方式', 'AI', 'ENDED', 1, 5, DATE_SUB(NOW(), INTERVAL 2697 MINUTE), DATE_SUB(NOW(), INTERVAL 2692 MINUTE)),
(23, 5, NULL, '快递几天能到', 'AI', 'ENDED', 1, 5, DATE_SUB(NOW(), INTERVAL 2480 MINUTE), DATE_SUB(NOW(), INTERVAL 2475 MINUTE)),
(24, 5, NULL, '怎么申请退款', 'AI', 'ENDED', 1, 5, DATE_SUB(NOW(), INTERVAL 2144 MINUTE), DATE_SUB(NOW(), INTERVAL 2139 MINUTE)),
(25, 10, NULL, 'App 打开闪退怎么办', 'AI', 'ENDED', 1, 5, DATE_SUB(NOW(), INTERVAL 2300 MINUTE), DATE_SUB(NOW(), INTERVAL 2295 MINUTE)),
(26, 7, NULL, '怎么申请退款', 'AI', 'ENDED', 1, 4, DATE_SUB(NOW(), INTERVAL 2237 MINUTE), DATE_SUB(NOW(), INTERVAL 2232 MINUTE)),
(27, 10, NULL, '快递几天能到', 'AI', 'ENDED', 1, 4, DATE_SUB(NOW(), INTERVAL 1956 MINUTE), DATE_SUB(NOW(), INTERVAL 1951 MINUTE)),
(28, 6, NULL, '忘记密码怎么办', 'AI', 'ENDED', 1, 3, DATE_SUB(NOW(), INTERVAL 2526 MINUTE), DATE_SUB(NOW(), INTERVAL 2521 MINUTE)),
(29, 6, NULL, 'App 打开闪退怎么办', 'AI', 'ENDED', 1, 4, DATE_SUB(NOW(), INTERVAL 2079 MINUTE), DATE_SUB(NOW(), INTERVAL 2074 MINUTE)),
(30, 9, NULL, '下单后可以修改收货地址吗', 'AI', 'ENDED', 1, 5, DATE_SUB(NOW(), INTERVAL 2244 MINUTE), DATE_SUB(NOW(), INTERVAL 2239 MINUTE)),
(31, 9, NULL, '忘记密码怎么办', 'AI', 'ENDED', 1, 4, DATE_SUB(NOW(), INTERVAL 1870 MINUTE), DATE_SUB(NOW(), INTERVAL 1865 MINUTE)),
(32, 6, 2, '忘记密码怎么办', 'HUMAN', 'ENDED', 0, 4, DATE_SUB(NOW(), INTERVAL 2716 MINUTE), DATE_SUB(NOW(), INTERVAL 2711 MINUTE)),
(33, 7, 2, '下单后可以修改收货地址吗', 'HUMAN', 'ENDED', 0, 5, DATE_SUB(NOW(), INTERVAL 2368 MINUTE), DATE_SUB(NOW(), INTERVAL 2363 MINUTE)),
(34, 7, NULL, '支持哪些支付方式', 'AI', 'ENDED', 1, 5, DATE_SUB(NOW(), INTERVAL 2565 MINUTE), DATE_SUB(NOW(), INTERVAL 2560 MINUTE)),
(35, 9, NULL, '会员积分怎么使用', 'AI', 'ENDED', 1, 3, DATE_SUB(NOW(), INTERVAL 3757 MINUTE), DATE_SUB(NOW(), INTERVAL 3752 MINUTE)),
(36, 9, 2, '会员积分怎么使用', 'HUMAN', 'ENDED', 0, 4, DATE_SUB(NOW(), INTERVAL 3087 MINUTE), DATE_SUB(NOW(), INTERVAL 3082 MINUTE)),
(37, 9, 2, '发票怎么开', 'HUMAN', 'ENDED', 0, 3, DATE_SUB(NOW(), INTERVAL 4180 MINUTE), DATE_SUB(NOW(), INTERVAL 4175 MINUTE)),
(38, 5, NULL, '怎么申请退款', 'AI', 'ENDED', 1, 3, DATE_SUB(NOW(), INTERVAL 4048 MINUTE), DATE_SUB(NOW(), INTERVAL 4043 MINUTE)),
(39, 7, 2, '怎么申请退款', 'HUMAN', 'ENDED', 0, 5, DATE_SUB(NOW(), INTERVAL 3375 MINUTE), DATE_SUB(NOW(), INTERVAL 3370 MINUTE)),
(40, 9, NULL, '发票怎么开', 'AI', 'ENDED', 1, 5, DATE_SUB(NOW(), INTERVAL 3661 MINUTE), DATE_SUB(NOW(), INTERVAL 3656 MINUTE)),
(41, 7, 2, 'App 打开闪退怎么办', 'HUMAN', 'ENDED', 0, 5, DATE_SUB(NOW(), INTERVAL 3949 MINUTE), DATE_SUB(NOW(), INTERVAL 3944 MINUTE)),
(42, 9, NULL, 'App 打开闪退怎么办', 'AI', 'ENDED', 1, 3, DATE_SUB(NOW(), INTERVAL 3245 MINUTE), DATE_SUB(NOW(), INTERVAL 3240 MINUTE)),
(43, 7, NULL, '下单后可以修改收货地址吗', 'AI', 'ENDED', 1, 5, DATE_SUB(NOW(), INTERVAL 3280 MINUTE), DATE_SUB(NOW(), INTERVAL 3275 MINUTE)),
(44, 6, NULL, '支持哪些支付方式', 'AI', 'ENDED', 1, 3, DATE_SUB(NOW(), INTERVAL 5502 MINUTE), DATE_SUB(NOW(), INTERVAL 5497 MINUTE)),
(45, 10, NULL, '下单后可以修改收货地址吗', 'AI', 'ENDED', 1, 5, DATE_SUB(NOW(), INTERVAL 4576 MINUTE), DATE_SUB(NOW(), INTERVAL 4571 MINUTE)),
(46, 7, NULL, '支持哪些支付方式', 'AI', 'ENDED', 1, 4, DATE_SUB(NOW(), INTERVAL 5118 MINUTE), DATE_SUB(NOW(), INTERVAL 5113 MINUTE)),
(47, 10, NULL, '支持哪些支付方式', 'AI', 'ENDED', 1, 4, DATE_SUB(NOW(), INTERVAL 4789 MINUTE), DATE_SUB(NOW(), INTERVAL 4784 MINUTE)),
(48, 9, NULL, '忘记密码怎么办', 'AI', 'ENDED', 1, 4, DATE_SUB(NOW(), INTERVAL 5399 MINUTE), DATE_SUB(NOW(), INTERVAL 5394 MINUTE)),
(49, 5, NULL, '怎么申请退款', 'AI', 'ENDED', 1, 4, DATE_SUB(NOW(), INTERVAL 5357 MINUTE), DATE_SUB(NOW(), INTERVAL 5352 MINUTE)),
(50, 6, NULL, '支持哪些支付方式', 'AI', 'ENDED', 1, 4, DATE_SUB(NOW(), INTERVAL 5105 MINUTE), DATE_SUB(NOW(), INTERVAL 5100 MINUTE)),
(51, 5, 2, '忘记密码怎么办', 'HUMAN', 'ENDED', 0, 4, DATE_SUB(NOW(), INTERVAL 5352 MINUTE), DATE_SUB(NOW(), INTERVAL 5347 MINUTE)),
(52, 7, NULL, '忘记密码怎么办', 'AI', 'ENDED', 1, 5, DATE_SUB(NOW(), INTERVAL 4393 MINUTE), DATE_SUB(NOW(), INTERVAL 4388 MINUTE)),
(53, 5, NULL, '快递几天能到', 'AI', 'ENDED', 1, 5, DATE_SUB(NOW(), INTERVAL 6238 MINUTE), DATE_SUB(NOW(), INTERVAL 6233 MINUTE)),
(54, 6, NULL, '会员积分怎么使用', 'AI', 'ENDED', 1, 3, DATE_SUB(NOW(), INTERVAL 6510 MINUTE), DATE_SUB(NOW(), INTERVAL 6505 MINUTE)),
(55, 9, NULL, 'App 打开闪退怎么办', 'AI', 'ENDED', 1, 5, DATE_SUB(NOW(), INTERVAL 6003 MINUTE), DATE_SUB(NOW(), INTERVAL 5998 MINUTE)),
(56, 6, NULL, '发票怎么开', 'AI', 'ENDED', 1, 4, DATE_SUB(NOW(), INTERVAL 5886 MINUTE), DATE_SUB(NOW(), INTERVAL 5881 MINUTE)),
(57, 10, NULL, 'App 打开闪退怎么办', 'AI', 'ENDED', 1, 5, DATE_SUB(NOW(), INTERVAL 6129 MINUTE), DATE_SUB(NOW(), INTERVAL 6124 MINUTE)),
(58, 10, NULL, 'App 打开闪退怎么办', 'AI', 'ENDED', 1, 4, DATE_SUB(NOW(), INTERVAL 6547 MINUTE), DATE_SUB(NOW(), INTERVAL 6542 MINUTE)),
(59, 10, 2, '发票怎么开', 'HUMAN', 'ENDED', 0, 5, DATE_SUB(NOW(), INTERVAL 6040 MINUTE), DATE_SUB(NOW(), INTERVAL 6035 MINUTE)),
(60, 6, NULL, '会员积分怎么使用', 'AI', 'ENDED', 1, 4, DATE_SUB(NOW(), INTERVAL 6228 MINUTE), DATE_SUB(NOW(), INTERVAL 6223 MINUTE)),
(61, 5, NULL, '下单后可以修改收货地址吗', 'AI', 'ENDED', 1, 4, DATE_SUB(NOW(), INTERVAL 6856 MINUTE), DATE_SUB(NOW(), INTERVAL 6851 MINUTE)),
(62, 10, NULL, '支持哪些支付方式', 'AI', 'ENDED', 1, 4, DATE_SUB(NOW(), INTERVAL 6688 MINUTE), DATE_SUB(NOW(), INTERVAL 6683 MINUTE)),
(63, 5, NULL, '支持哪些支付方式', 'AI', 'ENDED', 1, 5, DATE_SUB(NOW(), INTERVAL 7024 MINUTE), DATE_SUB(NOW(), INTERVAL 7019 MINUTE)),
(64, 9, NULL, '发票怎么开', 'AI', 'ENDED', 1, 5, DATE_SUB(NOW(), INTERVAL 6902 MINUTE), DATE_SUB(NOW(), INTERVAL 6897 MINUTE)),
(65, 5, NULL, 'App 打开闪退怎么办', 'AI', 'ENDED', 1, 4, DATE_SUB(NOW(), INTERVAL 5838 MINUTE), DATE_SUB(NOW(), INTERVAL 5833 MINUTE)),
(66, 6, NULL, '发票怎么开', 'AI', 'ENDED', 1, 5, DATE_SUB(NOW(), INTERVAL 6076 MINUTE), DATE_SUB(NOW(), INTERVAL 6071 MINUTE)),
(67, 7, NULL, 'App 打开闪退怎么办', 'AI', 'ENDED', 1, 5, DATE_SUB(NOW(), INTERVAL 7487 MINUTE), DATE_SUB(NOW(), INTERVAL 7482 MINUTE)),
(68, 5, NULL, '忘记密码怎么办', 'AI', 'ENDED', 1, 3, DATE_SUB(NOW(), INTERVAL 7356 MINUTE), DATE_SUB(NOW(), INTERVAL 7351 MINUTE)),
(69, 10, NULL, 'App 打开闪退怎么办', 'AI', 'ENDED', 1, 5, DATE_SUB(NOW(), INTERVAL 7399 MINUTE), DATE_SUB(NOW(), INTERVAL 7394 MINUTE)),
(70, 7, NULL, '忘记密码怎么办', 'AI', 'ENDED', 1, 5, DATE_SUB(NOW(), INTERVAL 8196 MINUTE), DATE_SUB(NOW(), INTERVAL 8191 MINUTE)),
(71, 10, NULL, 'App 打开闪退怎么办', 'AI', 'ENDED', 1, 5, DATE_SUB(NOW(), INTERVAL 7777 MINUTE), DATE_SUB(NOW(), INTERVAL 7772 MINUTE)),
(72, 10, NULL, '下单后可以修改收货地址吗', 'AI', 'ENDED', 1, 5, DATE_SUB(NOW(), INTERVAL 7684 MINUTE), DATE_SUB(NOW(), INTERVAL 7679 MINUTE)),
(73, 6, 2, '会员积分怎么使用', 'HUMAN', 'ENDED', 0, 4, DATE_SUB(NOW(), INTERVAL 8175 MINUTE), DATE_SUB(NOW(), INTERVAL 8170 MINUTE)),
(74, 5, NULL, '忘记密码怎么办', 'AI', 'ENDED', 1, 5, DATE_SUB(NOW(), INTERVAL 7705 MINUTE), DATE_SUB(NOW(), INTERVAL 7700 MINUTE)),
(75, 7, NULL, '快递几天能到', 'AI', 'ENDED', 1, 5, DATE_SUB(NOW(), INTERVAL 7586 MINUTE), DATE_SUB(NOW(), INTERVAL 7581 MINUTE)),
(76, 6, NULL, '下单后可以修改收货地址吗', 'AI', 'ENDED', 1, 4, DATE_SUB(NOW(), INTERVAL 9667 MINUTE), DATE_SUB(NOW(), INTERVAL 9662 MINUTE)),
(77, 5, NULL, '会员积分怎么使用', 'AI', 'ENDED', 1, 5, DATE_SUB(NOW(), INTERVAL 9043 MINUTE), DATE_SUB(NOW(), INTERVAL 9038 MINUTE)),
(78, 6, NULL, '发票怎么开', 'AI', 'ENDED', 1, 5, DATE_SUB(NOW(), INTERVAL 9765 MINUTE), DATE_SUB(NOW(), INTERVAL 9760 MINUTE)),
(79, 7, NULL, '会员积分怎么使用', 'AI', 'ENDED', 1, 3, DATE_SUB(NOW(), INTERVAL 9362 MINUTE), DATE_SUB(NOW(), INTERVAL 9357 MINUTE)),
(80, 7, NULL, '怎么申请退款', 'AI', 'ENDED', 1, 5, DATE_SUB(NOW(), INTERVAL 9649 MINUTE), DATE_SUB(NOW(), INTERVAL 9644 MINUTE)),
(81, 5, NULL, '会员积分怎么使用', 'AI', 'ENDED', 1, 5, DATE_SUB(NOW(), INTERVAL 9315 MINUTE), DATE_SUB(NOW(), INTERVAL 9310 MINUTE)),
(82, 5, NULL, '快递几天能到', 'AI', 'ENDED', 1, 3, DATE_SUB(NOW(), INTERVAL 9178 MINUTE), DATE_SUB(NOW(), INTERVAL 9173 MINUTE)),
(83, 5, NULL, '下单后可以修改收货地址吗', 'AI', 'ENDED', 1, 4, DATE_SUB(NOW(), INTERVAL 9081 MINUTE), DATE_SUB(NOW(), INTERVAL 9076 MINUTE)),
(84, 6, NULL, '会员积分怎么使用', 'AI', 'ENDED', 1, 5, DATE_SUB(NOW(), INTERVAL 9239 MINUTE), DATE_SUB(NOW(), INTERVAL 9234 MINUTE)),
(85, 6, NULL, 'App 打开闪退怎么办', 'AI', 'ENDED', 1, 4, DATE_SUB(NOW(), INTERVAL 8893 MINUTE), DATE_SUB(NOW(), INTERVAL 8888 MINUTE)),
(86, 5, NULL, '发票怎么开', 'AI', 'ENDED', 1, 4, DATE_SUB(NOW(), INTERVAL 8858 MINUTE), DATE_SUB(NOW(), INTERVAL 8853 MINUTE)),
(87, 5, NULL, '快递几天能到', 'AI', 'ENDED', 1, 5, DATE_SUB(NOW(), INTERVAL 8881 MINUTE), DATE_SUB(NOW(), INTERVAL 8876 MINUTE)),
(88, 6, NULL, '快递几天能到', 'AI', 'ENDED', 1, 5, DATE_SUB(NOW(), INTERVAL 8959 MINUTE), DATE_SUB(NOW(), INTERVAL 8954 MINUTE)),
(89, 5, NULL, '支持哪些支付方式', 'AI', 'ENDED', 1, 4, DATE_SUB(NOW(), INTERVAL 9565 MINUTE), DATE_SUB(NOW(), INTERVAL 9560 MINUTE));

INSERT INTO chat_message (session_id, sender_type, sender_id, content, create_time) VALUES
(1, 'USER', 5, '我上周申请的退款还没到账', DATE_SUB(NOW(), INTERVAL 60 MINUTE)),
(1, 'AI', NULL, '别着急～退款审核通过后，一般 **1-3 个工作日** 原路退回。请问您是哪天申请的呢？', DATE_SUB(NOW(), INTERVAL 59 MINUTE)),
(1, 'USER', 5, '10 月 15 号，已经一周了', DATE_SUB(NOW(), INTERVAL 58 MINUTE)),
(1, 'AI', NULL, '已超过正常时效，我已为您生成工单 **TK20261022001**，客服会优先跟进。', DATE_SUB(NOW(), INTERVAL 57 MINUTE)),
(2, 'USER', 5, '发票抬头填错了怎么办', DATE_SUB(NOW(), INTERVAL 1500 MINUTE)),
(2, 'AGENT', 2, '您好，我帮您把原发票红冲后重开，请稍等～', DATE_SUB(NOW(), INTERVAL 1499 MINUTE)),
(2, 'AGENT', 2, '好的，新发票已经发送到您的邮箱', DATE_SUB(NOW(), INTERVAL 1498 MINUTE)),
(3, 'USER', 5, '快递显示签收了但我没收到', DATE_SUB(NOW(), INTERVAL 2940 MINUTE)),
(3, 'AI', NULL, '建议您先联系快递员确认投递位置，仍有问题我帮您生成工单。', DATE_SUB(NOW(), INTERVAL 2939 MINUTE)),
(4, 'USER', 5, '怎么修改收货地址', DATE_SUB(NOW(), INTERVAL 4380 MINUTE)),
(4, 'AI', NULL, '订单 **未发货** 前可以直接在订单详情修改地址哦', DATE_SUB(NOW(), INTERVAL 4379 MINUTE)),
(5, 'USER', 5, '会员积分怎么用', DATE_SUB(NOW(), INTERVAL 8700 MINUTE)),
(5, 'AI', NULL, '结算页可以直接抵扣现金，**100 积分可以抵扣 1 元**。', DATE_SUB(NOW(), INTERVAL 8699 MINUTE)),
(6, 'USER', 6, '会员积分怎么使用？', DATE_SUB(NOW(), INTERVAL 218 MINUTE)),
(7, 'USER', 5, '支持哪些支付方式？', DATE_SUB(NOW(), INTERVAL 1109 MINUTE)),
(8, 'USER', 5, '快递几天能到？', DATE_SUB(NOW(), INTERVAL 213 MINUTE)),
(9, 'USER', 5, '会员积分怎么使用？', DATE_SUB(NOW(), INTERVAL 1228 MINUTE)),
(10, 'USER', 6, '怎么申请退款？', DATE_SUB(NOW(), INTERVAL 882 MINUTE)),
(11, 'USER', 6, '怎么申请退款？', DATE_SUB(NOW(), INTERVAL 342 MINUTE)),
(12, 'USER', 9, '发票怎么开？', DATE_SUB(NOW(), INTERVAL 1239 MINUTE)),
(13, 'USER', 10, '发票怎么开？', DATE_SUB(NOW(), INTERVAL 1239 MINUTE)),
(14, 'USER', 6, '支持哪些支付方式？', DATE_SUB(NOW(), INTERVAL 198 MINUTE)),
(15, 'USER', 5, '忘记密码怎么办？', DATE_SUB(NOW(), INTERVAL 1158 MINUTE)),
(16, 'USER', 7, 'App 打开闪退怎么办？', DATE_SUB(NOW(), INTERVAL 998 MINUTE)),
(17, 'USER', 7, '忘记密码怎么办？', DATE_SUB(NOW(), INTERVAL 569 MINUTE)),
(18, 'USER', 10, '下单后可以修改收货地址吗？', DATE_SUB(NOW(), INTERVAL 773 MINUTE)),
(19, 'USER', 9, '下单后可以修改收货地址吗？', DATE_SUB(NOW(), INTERVAL 219 MINUTE)),
(20, 'USER', 6, '支持哪些支付方式？', DATE_SUB(NOW(), INTERVAL 2511 MINUTE)),
(21, 'USER', 5, '快递几天能到？', DATE_SUB(NOW(), INTERVAL 2683 MINUTE)),
(22, 'USER', 7, '支持哪些支付方式？', DATE_SUB(NOW(), INTERVAL 2697 MINUTE)),
(23, 'USER', 5, '快递几天能到？', DATE_SUB(NOW(), INTERVAL 2480 MINUTE)),
(24, 'USER', 5, '怎么申请退款？', DATE_SUB(NOW(), INTERVAL 2144 MINUTE)),
(25, 'USER', 10, 'App 打开闪退怎么办？', DATE_SUB(NOW(), INTERVAL 2300 MINUTE)),
(26, 'USER', 7, '怎么申请退款？', DATE_SUB(NOW(), INTERVAL 2237 MINUTE)),
(27, 'USER', 10, '快递几天能到？', DATE_SUB(NOW(), INTERVAL 1956 MINUTE)),
(28, 'USER', 6, '忘记密码怎么办？', DATE_SUB(NOW(), INTERVAL 2526 MINUTE)),
(29, 'USER', 6, 'App 打开闪退怎么办？', DATE_SUB(NOW(), INTERVAL 2079 MINUTE)),
(30, 'USER', 9, '下单后可以修改收货地址吗？', DATE_SUB(NOW(), INTERVAL 2244 MINUTE)),
(31, 'USER', 9, '忘记密码怎么办？', DATE_SUB(NOW(), INTERVAL 1870 MINUTE)),
(32, 'USER', 6, '忘记密码怎么办？', DATE_SUB(NOW(), INTERVAL 2716 MINUTE)),
(33, 'USER', 7, '下单后可以修改收货地址吗？', DATE_SUB(NOW(), INTERVAL 2368 MINUTE)),
(34, 'USER', 7, '支持哪些支付方式？', DATE_SUB(NOW(), INTERVAL 2565 MINUTE)),
(35, 'USER', 9, '会员积分怎么使用？', DATE_SUB(NOW(), INTERVAL 3757 MINUTE)),
(36, 'USER', 9, '会员积分怎么使用？', DATE_SUB(NOW(), INTERVAL 3087 MINUTE)),
(37, 'USER', 9, '发票怎么开？', DATE_SUB(NOW(), INTERVAL 4180 MINUTE)),
(38, 'USER', 5, '怎么申请退款？', DATE_SUB(NOW(), INTERVAL 4048 MINUTE)),
(39, 'USER', 7, '怎么申请退款？', DATE_SUB(NOW(), INTERVAL 3375 MINUTE)),
(40, 'USER', 9, '发票怎么开？', DATE_SUB(NOW(), INTERVAL 3661 MINUTE)),
(41, 'USER', 7, 'App 打开闪退怎么办？', DATE_SUB(NOW(), INTERVAL 3949 MINUTE)),
(42, 'USER', 9, 'App 打开闪退怎么办？', DATE_SUB(NOW(), INTERVAL 3245 MINUTE)),
(43, 'USER', 7, '下单后可以修改收货地址吗？', DATE_SUB(NOW(), INTERVAL 3280 MINUTE)),
(44, 'USER', 6, '支持哪些支付方式？', DATE_SUB(NOW(), INTERVAL 5502 MINUTE)),
(45, 'USER', 10, '下单后可以修改收货地址吗？', DATE_SUB(NOW(), INTERVAL 4576 MINUTE)),
(46, 'USER', 7, '支持哪些支付方式？', DATE_SUB(NOW(), INTERVAL 5118 MINUTE)),
(47, 'USER', 10, '支持哪些支付方式？', DATE_SUB(NOW(), INTERVAL 4789 MINUTE)),
(48, 'USER', 9, '忘记密码怎么办？', DATE_SUB(NOW(), INTERVAL 5399 MINUTE)),
(49, 'USER', 5, '怎么申请退款？', DATE_SUB(NOW(), INTERVAL 5357 MINUTE)),
(50, 'USER', 6, '支持哪些支付方式？', DATE_SUB(NOW(), INTERVAL 5105 MINUTE)),
(51, 'USER', 5, '忘记密码怎么办？', DATE_SUB(NOW(), INTERVAL 5352 MINUTE)),
(52, 'USER', 7, '忘记密码怎么办？', DATE_SUB(NOW(), INTERVAL 4393 MINUTE)),
(53, 'USER', 5, '快递几天能到？', DATE_SUB(NOW(), INTERVAL 6238 MINUTE)),
(54, 'USER', 6, '会员积分怎么使用？', DATE_SUB(NOW(), INTERVAL 6510 MINUTE)),
(55, 'USER', 9, 'App 打开闪退怎么办？', DATE_SUB(NOW(), INTERVAL 6003 MINUTE)),
(56, 'USER', 6, '发票怎么开？', DATE_SUB(NOW(), INTERVAL 5886 MINUTE)),
(57, 'USER', 10, 'App 打开闪退怎么办？', DATE_SUB(NOW(), INTERVAL 6129 MINUTE)),
(58, 'USER', 10, 'App 打开闪退怎么办？', DATE_SUB(NOW(), INTERVAL 6547 MINUTE)),
(59, 'USER', 10, '发票怎么开？', DATE_SUB(NOW(), INTERVAL 6040 MINUTE)),
(60, 'USER', 6, '会员积分怎么使用？', DATE_SUB(NOW(), INTERVAL 6228 MINUTE)),
(61, 'USER', 5, '下单后可以修改收货地址吗？', DATE_SUB(NOW(), INTERVAL 6856 MINUTE)),
(62, 'USER', 10, '支持哪些支付方式？', DATE_SUB(NOW(), INTERVAL 6688 MINUTE)),
(63, 'USER', 5, '支持哪些支付方式？', DATE_SUB(NOW(), INTERVAL 7024 MINUTE)),
(64, 'USER', 9, '发票怎么开？', DATE_SUB(NOW(), INTERVAL 6902 MINUTE)),
(65, 'USER', 5, 'App 打开闪退怎么办？', DATE_SUB(NOW(), INTERVAL 5838 MINUTE)),
(66, 'USER', 6, '发票怎么开？', DATE_SUB(NOW(), INTERVAL 6076 MINUTE)),
(67, 'USER', 7, 'App 打开闪退怎么办？', DATE_SUB(NOW(), INTERVAL 7487 MINUTE)),
(68, 'USER', 5, '忘记密码怎么办？', DATE_SUB(NOW(), INTERVAL 7356 MINUTE)),
(69, 'USER', 10, 'App 打开闪退怎么办？', DATE_SUB(NOW(), INTERVAL 7399 MINUTE)),
(70, 'USER', 7, '忘记密码怎么办？', DATE_SUB(NOW(), INTERVAL 8196 MINUTE)),
(71, 'USER', 10, 'App 打开闪退怎么办？', DATE_SUB(NOW(), INTERVAL 7777 MINUTE)),
(72, 'USER', 10, '下单后可以修改收货地址吗？', DATE_SUB(NOW(), INTERVAL 7684 MINUTE)),
(73, 'USER', 6, '会员积分怎么使用？', DATE_SUB(NOW(), INTERVAL 8175 MINUTE)),
(74, 'USER', 5, '忘记密码怎么办？', DATE_SUB(NOW(), INTERVAL 7705 MINUTE)),
(75, 'USER', 7, '快递几天能到？', DATE_SUB(NOW(), INTERVAL 7586 MINUTE)),
(76, 'USER', 6, '下单后可以修改收货地址吗？', DATE_SUB(NOW(), INTERVAL 9667 MINUTE)),
(77, 'USER', 5, '会员积分怎么使用？', DATE_SUB(NOW(), INTERVAL 9043 MINUTE)),
(78, 'USER', 6, '发票怎么开？', DATE_SUB(NOW(), INTERVAL 9765 MINUTE)),
(79, 'USER', 7, '会员积分怎么使用？', DATE_SUB(NOW(), INTERVAL 9362 MINUTE)),
(80, 'USER', 7, '怎么申请退款？', DATE_SUB(NOW(), INTERVAL 9649 MINUTE)),
(81, 'USER', 5, '会员积分怎么使用？', DATE_SUB(NOW(), INTERVAL 9315 MINUTE)),
(82, 'USER', 5, '快递几天能到？', DATE_SUB(NOW(), INTERVAL 9178 MINUTE)),
(83, 'USER', 5, '下单后可以修改收货地址吗？', DATE_SUB(NOW(), INTERVAL 9081 MINUTE)),
(84, 'USER', 6, '会员积分怎么使用？', DATE_SUB(NOW(), INTERVAL 9239 MINUTE)),
(85, 'USER', 6, 'App 打开闪退怎么办？', DATE_SUB(NOW(), INTERVAL 8893 MINUTE)),
(86, 'USER', 5, '发票怎么开？', DATE_SUB(NOW(), INTERVAL 8858 MINUTE)),
(87, 'USER', 5, '快递几天能到？', DATE_SUB(NOW(), INTERVAL 8881 MINUTE)),
(88, 'USER', 6, '快递几天能到？', DATE_SUB(NOW(), INTERVAL 8959 MINUTE)),
(89, 'USER', 5, '支持哪些支付方式？', DATE_SUB(NOW(), INTERVAL 9565 MINUTE));

-- 正在排队 / 人工处理中的会话（客服工作台演示用）
INSERT INTO chat_session (id, user_id, agent_id, title, mode, status, ai_solved, start_time) VALUES
(90, 7, 2, 'App 更新后闪退', 'HUMAN', 'ACTIVE', 0, DATE_SUB(NOW(), INTERVAL 10 MINUTE)),
(91, 6, 2, '支付成功仍显示待付款', 'HUMAN', 'ACTIVE', 0, DATE_SUB(NOW(), INTERVAL 13 MINUTE)),
(92, 9, NULL, '商家拒绝退货', 'HUMAN', 'QUEUE', 0, DATE_SUB(NOW(), INTERVAL 16 MINUTE)),
(93, 10, NULL, '积分清零', 'HUMAN', 'QUEUE', 0, DATE_SUB(NOW(), INTERVAL 19 MINUTE));

INSERT INTO chat_message (session_id, sender_type, sender_id, content, create_time) VALUES
(90, 'USER', 7, '你好，App 更新之后一打开就闪退', DATE_SUB(NOW(), INTERVAL 10 MINUTE)),
(90, 'USER', 7, '试过清缓存了还是不行，帮我转人工', DATE_SUB(NOW(), INTERVAL 9 MINUTE)),
(90, 'AI', NULL, '（AI 已尝试）建议清除缓存后重启 App。', DATE_SUB(NOW(), INTERVAL 10 MINUTE)),
(91, 'USER', 6, '微信扣款了，订单还是待付款', DATE_SUB(NOW(), INTERVAL 13 MINUTE)),
(92, 'USER', 9, '商家拒绝我七天无理由退货怎么办', DATE_SUB(NOW(), INTERVAL 16 MINUTE)),
(93, 'USER', 10, '我的积分怎么没了？上个月还有 3000', DATE_SUB(NOW(), INTERVAL 19 MINUTE)),
(91, 'AGENT', 2, '您好，我帮您查一下交易流水，请稍等～', DATE_SUB(NOW(), INTERVAL 11 MINUTE));
