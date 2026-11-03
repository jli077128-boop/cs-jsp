<%@ page contentType="text/html;charset=UTF-8" pageEncoding="UTF-8" %>
<%@ taglib prefix="c" uri="http://java.sun.com/jsp/jstl/core" %>
<c:set var="pageTitle" value="数据看板"/>
<c:set var="nav" value="dashboard"/>
<%@ include file="../common/head.jspf" %>
<%@ include file="../common/side-nav.jspf" %>
<c:set var="k" value="${stats.kpi}"/>
<div class="topbar">
    <div><h1>数据看板</h1><p>实时统计 · 近 7 天会话 ${k.weekSessions} 次 · 当前在线 ${onlineSessions} 人（Session 监听器统计）</p></div>
    <div class="right">
        <c:if test="${applicationScope.llmEnabled}"><span class="pill st-ACTIVE status-pill">大模型已接入</span></c:if>
        <c:if test="${not applicationScope.llmEnabled}"><span class="pill st-PENDING status-pill">知识库匹配模式</span></c:if>
        <a class="btn btn-sm" href="${ctx}/admin/dashboard.action"><i class="ri-refresh-line"></i>刷新</a>
    </div>
</div>

<div class="kpis">
    <div class="kpi glass rise" style="--c:#4f7cff;--g:linear-gradient(135deg,#4f7cff,#22d3ee)">
        <span class="ic"><i class="ri-chat-3-line"></i></span><div class="label">今日会话</div>
        <div class="value">${k.todaySessions}<small>次</small></div><div class="trend">近 7 天共 <b>${k.weekSessions}</b> 次</div>
    </div>
    <div class="kpi glass rise rise-1" style="--c:#8b5cf6;--g:linear-gradient(135deg,#8b5cf6,#ec4899)">
        <span class="ic"><i class="ri-robot-2-line"></i></span><div class="label">AI 独立解决率</div>
        <div class="value">${k.aiResolveRate}<small>%</small></div><div class="trend">未转人工、未生成工单</div>
    </div>
    <div class="kpi glass rise rise-2" style="--c:#fbbf24;--g:linear-gradient(135deg,#f97316,#fbbf24)">
        <span class="ic"><i class="ri-coupon-3-line"></i></span><div class="label">待处理工单</div>
        <div class="value">${k.pendingTickets}<small>/ ${k.ticketTotal}</small></div><div class="trend">排队转人工 <b style="color:#fde68a">${k.queueCount}</b> 人</div>
    </div>
    <div class="kpi glass rise rise-3" style="--c:#34d399;--g:linear-gradient(135deg,#22d3ee,#34d399)">
        <span class="ic"><i class="ri-star-smile-line"></i></span><div class="label">平均满意度</div>
        <div class="value">${k.avgRating}<small>/ 5</small></div><div class="trend">在线客服 <b>${k.onlineAgents}</b> 人 · 用户 ${k.userCount} 人</div>
    </div>
</div>

<div class="charts">
    <section class="glass panel rise"><h3 class="section-title">近 7 天会话趋势</h3><div class="chart" id="trendChart"></div></section>
    <section class="glass panel rise rise-1"><h3 class="section-title">AI 解决率</h3><div class="chart" id="rateChart"></div></section>
</div>
<div class="charts" style="grid-template-columns:1fr 1fr 1fr">
    <section class="glass panel rise"><h3 class="section-title">工单状态分布</h3><div class="chart" id="statusChart"></div></section>
    <section class="glass panel rise rise-1"><h3 class="section-title">热门问题 Top5</h3><div class="chart" id="hotChart"></div></section>
    <section class="glass panel rise rise-2"><h3 class="section-title">工单分类占比</h3><div class="chart" id="catChart"></div></section>
</div>

<section class="glass panel rise">
    <h3 class="section-title">最新工单<a class="more" href="${ctx}/admin/tickets.action">工单管理 <i class="ri-arrow-right-s-line"></i></a></h3>
    <div class="table-wrap">
        <table class="table">
            <thead><tr><th>工单编号</th><th>标题</th><th>用户</th><th>优先级</th><th>状态</th><th>处理客服</th><th>提交时间</th></tr></thead>
            <tbody>
            <c:forEach items="${latestTickets}" var="t">
                <tr onclick="location.href='${ctx}/ticket/detail.action?id=${t.id}'" style="cursor:pointer">
                    <td class="mono">${t.ticketNo}</td><td class="strong"><c:out value="${t.title}"/></td><td><c:out value="${t.userName}"/></td>
                    <td><span class="pr pr-${t.priority}">${t.priorityText}</span></td><td><span class="pill status-pill st-${t.status}">${t.statusText}</span></td>
                    <td><c:out value="${empty t.assigneeName ? '—' : t.assigneeName}"/></td><td>${t.createTimeStr}</td>
                </tr>
            </c:forEach>
            </tbody>
        </table>
    </div>
</section>

<script src="${ctx}/static/vendor/echarts.min.js"></script>
<script>
(function () {
    // 统计数据由 Servlet 用 Gson 序列化后直接输出到页面（Gson 默认会转义 < > 等字符，避免 XSS）
    const S = ${statsJson};
    const text = 'rgba(226,230,255,.72)', line = 'rgba(255,255,255,.08)';
    const base = { textStyle: { fontFamily: 'PingFang SC, Microsoft YaHei, sans-serif', color: text }, tooltip: { backgroundColor: 'rgba(22,26,66,.94)', borderColor: 'rgba(255,255,255,.14)', textStyle: { color: '#eef0ff' } } };
    const grad = (a, b) => new echarts.graphic.LinearGradient(0, 0, 0, 1, [{ offset: 0, color: a }, { offset: 1, color: b }]);
    const charts = [];
    function make(id, opt) { const c = echarts.init(document.getElementById(id)); c.setOption(Object.assign({}, base, opt)); charts.push(c); }

    make('trendChart', {
        tooltip: Object.assign({ trigger: 'axis' }, base.tooltip),
        legend: { data: ['总会话', 'AI 解决', '转人工/工单'], textStyle: { color: text }, top: 0, right: 0 },
        grid: { left: 36, right: 16, top: 40, bottom: 28 },
        xAxis: { type: 'category', data: S.trend.days, axisLine: { lineStyle: { color: line } }, axisLabel: { color: text } },
        yAxis: { type: 'value', splitLine: { lineStyle: { color: line } }, axisLabel: { color: text }, minInterval: 1 },
        series: [
            { name: '总会话', type: 'line', smooth: true, data: S.trend.total, symbolSize: 8, lineStyle: { width: 3, color: '#8b5cf6' }, itemStyle: { color: '#8b5cf6' }, areaStyle: { color: grad('rgba(139,92,246,.45)', 'rgba(139,92,246,0)') } },
            { name: 'AI 解决', type: 'bar', barWidth: 14, data: S.trend.ai, itemStyle: { borderRadius: [6, 6, 0, 0], color: grad('#22d3ee', 'rgba(79,124,255,.4)') } },
            { name: '转人工/工单', type: 'bar', barWidth: 14, data: S.trend.human, itemStyle: { borderRadius: [6, 6, 0, 0], color: grad('#ec4899', 'rgba(236,72,153,.3)') } }
        ]
    });
    make('rateChart', {
        series: [{
            type: 'gauge', startAngle: 220, endAngle: -40, min: 0, max: 100, radius: '92%', center: ['50%', '56%'],
            progress: { show: true, width: 18, roundCap: true, itemStyle: { color: new echarts.graphic.LinearGradient(0, 0, 1, 0, [{ offset: 0, color: '#4f7cff' }, { offset: .5, color: '#8b5cf6' }, { offset: 1, color: '#ec4899' }]) } },
            axisLine: { roundCap: true, lineStyle: { width: 18, color: [[1, 'rgba(255,255,255,.08)']] } },
            pointer: { show: false }, axisTick: { show: false }, splitLine: { show: false }, axisLabel: { show: false },
            title: { show: true, offsetCenter: [0, '34%'], color: text, fontSize: 13 },
            detail: { valueAnimation: true, offsetCenter: [0, '-4%'], fontSize: 38, fontWeight: 800, color: '#fff', formatter: '{value}%' },
            data: [{ value: S.kpi.aiResolveRate, name: 'AI 独立解决' }]
        }]
    });
    make('statusChart', {
        tooltip: Object.assign({ trigger: 'item' }, base.tooltip),
        color: ['#fbbf24', '#60a5fa', '#34d399', '#94a3b8'],
        legend: { bottom: 0, textStyle: { color: text }, itemWidth: 10, itemHeight: 10 },
        series: [{ type: 'pie', radius: ['48%', '72%'], center: ['50%', '45%'], itemStyle: { borderRadius: 8, borderColor: 'rgba(10,12,40,.8)', borderWidth: 3 },
            label: { show: true, position: 'inside', color: '#fff', fontWeight: 700, formatter: '{c}' }, data: S.ticketStatus }]
    });
    make('hotChart', {
        tooltip: Object.assign({ trigger: 'axis', axisPointer: { type: 'shadow' } }, base.tooltip),
        grid: { left: 8, right: 40, top: 10, bottom: 10, containLabel: true },
        xAxis: { type: 'value', splitLine: { lineStyle: { color: line } }, axisLabel: { show: false } },
        yAxis: { type: 'category', inverse: true, data: S.hotTop.map(x => x.name), axisLine: { show: false }, axisTick: { show: false }, axisLabel: { color: text, width: 110, overflow: 'truncate' } },
        series: [{ type: 'bar', barWidth: 14, data: S.hotTop.map(x => x.value), label: { show: true, position: 'right', color: text },
            itemStyle: { borderRadius: 8, color: new echarts.graphic.LinearGradient(0, 0, 1, 0, [{ offset: 0, color: '#4f7cff' }, { offset: 1, color: '#ec4899' }]) } }]
    });
    make('catChart', {
        tooltip: Object.assign({ trigger: 'item', formatter: '{b}：{c}%' }, base.tooltip),
        color: ['#8b5cf6', '#22d3ee', '#ec4899', '#fbbf24', '#34d399', '#60a5fa', '#fb923c', '#a3e635'],
        legend: { type: 'scroll', bottom: 0, textStyle: { color: text, fontSize: 11 }, itemWidth: 10, itemHeight: 10, pageTextStyle: { color: text } },
        series: [{ type: 'pie', roseType: 'radius', radius: ['16%', '66%'], center: ['50%', '44%'], itemStyle: { borderRadius: 6, borderColor: 'rgba(10,12,40,.8)', borderWidth: 2 },
            label: { color: text, fontSize: 11, formatter: '{c}%' }, labelLine: { length: 6, length2: 6 }, data: S.categoryShare }]
    });
    window.addEventListener('resize', () => charts.forEach(c => c.resize()));
})();
</script>
<%@ include file="../common/foot.jspf" %>
