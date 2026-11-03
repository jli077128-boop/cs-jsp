<%@ page contentType="text/html;charset=UTF-8" pageEncoding="UTF-8" %>
<%@ taglib prefix="c" uri="http://java.sun.com/jsp/jstl/core" %>
<%@ taglib prefix="fmt" uri="http://java.sun.com/jsp/jstl/fmt" %>
<c:set var="pageTitle" value="知识库管理"/>
<c:set var="nav" value="kb"/>
<%@ include file="../common/head.jspf" %>
<%@ include file="../common/side-nav.jspf" %>
<c:set var="backQs" value="${empty cid ? '' : '?cid='}${cid}"/>
<div class="topbar">
    <div><h1>知识库管理</h1><p>共 ${allCount} 条问答 · 启用的问答会被 AI 客服检索使用</p></div>
    <div class="right">
        <button class="btn" type="button" data-open="#catDlg" data-fill='{"id":"","name":"","descr":"","icon":"ri-file-text-line","color1":"#4f7cff","color2":"#22d3ee","sort":"99"}'><i class="ri-folder-add-line"></i>新增分类</button>
        <%-- 批量新增：List<KbArticle> 批量参数接收（对应 03_strutsParams/customerBatch.jsp） --%>
        <s:a cssClass="btn" action="kbBatchForm" namespace="/admin" id="btnBatch"><i class="ri-stack-line"></i>批量新增</s:a>
        <button class="btn btn-primary" type="button" data-open="#artDlg" data-fill='{"id":"","categoryId":"${empty cid ? (categories[0].id) : cid}","question":"","answer":"","keywords":"","status":"1"}'><i class="ri-add-line"></i>新增问答</button>
    </div>
</div>
<div class="kb-layout admin">
    <aside class="kb-side glass">
        <a href="${ctx}/admin/kb.action" class="${empty cid ? 'active' : ''}"><span class="ci" style="background:var(--grad)"><i class="ri-apps-2-line"></i></span>全部问答<span class="n">${allCount}</span></a>
        <c:forEach items="${categories}" var="cat">
            <div class="flex items-center" style="position:relative">
                <a href="${ctx}/admin/kb.action?cid=${cat.id}" class="flex-1 ${cid eq cat.id ? 'active' : ''}">
                    <span class="ci" style="background:linear-gradient(135deg,${cat.color1},${cat.color2})"><i class="${cat.iconClass}"></i></span>
                    <span class="ellipsis"><c:out value="${cat.name}"/></span><span class="n">${cat.articleCount}</span>
                </a>
                <button class="icon-btn" type="button" title="编辑分类" style="width:28px;height:28px;font-size:14px;margin-left:4px;border:none;background:transparent"
                        data-open="#catDlg" data-fill='{"id":"${cat.id}","name":"<c:out value="${cat.name}"/>","descr":"<c:out value="${cat.descr}"/>","icon":"${cat.iconClass}","color1":"${cat.color1}","color2":"${cat.color2}","sort":"${cat.sort}"}'><i class="ri-edit-line"></i></button>
            </div>
        </c:forEach>
    </aside>
    <section class="glass panel">
        <form class="toolbar" method="get" action="${ctx}/admin/kb.action">
            <c:if test="${not empty cid}"><input type="hidden" name="cid" value="${cid}"></c:if>
            <div class="input-icon"><i class="ri-search-2-line"></i><input class="input" name="q" value="<c:out value='${q}'/>" placeholder="搜索问题 / 关键词 / 答案"></div>
            <select class="select" name="status" onchange="this.form.submit()">
                <option value="">全部状态</option>
                <option value="1" ${status eq '1' ? 'selected' : ''}>已启用</option>
                <option value="0" ${status eq '0' ? 'selected' : ''}>已停用</option>
            </select>
            <button class="btn" type="submit">查询</button>
            <span class="muted" style="margin-left:auto;font-size:13px">当前 ${articles.size()} 条</span>
        </form>
        <div class="table-wrap">
            <table class="table">
                <thead><tr><th>问题</th><th>分类</th><th>关键词</th><th>命中</th><th>状态</th><th class="hide-lg">更新时间</th><th class="right">操作</th></tr></thead>
                <tbody>
                <c:forEach items="${articles}" var="a">
                    <tr class="${a.status ne 1 ? 'row-off' : ''}">
                        <td class="wrap-cell"><div class="strong"><c:out value="${a.question}"/></div><div class="muted ellipsis" style="font-size:12px;max-width:320px"><c:out value="${a.answerPlain}"/></div></td>
                        <td><span class="tag"><c:out value="${a.categoryName}"/></span></td>
                        <td><div class="flex gap-6"><c:forTokens items="${a.keywords}" delims=",，" var="kw" end="0"><span class="tag tag-cyan"><c:out value="${kw}"/></span></c:forTokens></div></td>
                        <td><fmt:formatNumber value="${a.hitCount}"/></td>
                        <td>
                            <form class="inline" method="post" action="${ctx}/admin/kb_articleToggle.action">
                                <input type="hidden" name="id" value="${a.id}"><input type="hidden" name="status" value="${a.status eq 1 ? 0 : 1}"><input type="hidden" name="back" value="${backQs}">
                                <label class="switch" title="点击切换启用状态"><input type="checkbox" ${a.status eq 1 ? 'checked' : ''} onchange="this.form.submit()"><span class="track"></span><span class="muted" style="font-size:12px">${a.status eq 1 ? '启用' : '停用'}</span></label>
                            </form>
                        </td>
                        <td class="hide-lg">${a.updateTimeStr}</td>
                        <td class="right" style="white-space:nowrap">
                            <textarea class="hidden" id="ans-${a.id}"><c:out value="${a.answer}"/></textarea>
                            <button class="btn btn-sm" type="button" onclick="editArticle(this)" data-id="${a.id}" data-category-id="${a.categoryId}" data-question="<c:out value='${a.question}'/>" data-keywords="<c:out value='${a.keywords}'/>" data-status="${a.status}"><i class="ri-edit-line"></i>编辑</button>
                            <form class="inline" method="post" action="${ctx}/admin/kb_articleDelete.action" data-confirm-submit="确定删除这条问答吗？删除后不可恢复">
                                <input type="hidden" name="id" value="${a.id}"><input type="hidden" name="back" value="${backQs}">
                                <button class="btn btn-sm btn-danger" type="submit"><i class="ri-delete-bin-6-line"></i></button>
                            </form>
                        </td>
                    </tr>
                </c:forEach>
                </tbody>
            </table>
            <c:if test="${empty articles}"><div class="empty"><i class="ri-book-open-line"></i><p>没有符合条件的问答</p></div></c:if>
        </div>
    </section>
</div>

<!-- 问答编辑弹窗 -->
<dialog class="modal" id="artDlg" style="width:min(680px,calc(100vw - 32px))">
    <form method="post" action="${ctx}/admin/kb_articleSave.action">
        <div class="modal-head"><span data-title data-add="新增问答" data-edit="编辑问答">新增问答</span><button class="icon-btn" data-close type="button"><i class="ri-close-line"></i></button></div>
        <div class="modal-body">
            <input type="hidden" name="id"><input type="hidden" name="back" value="${backQs}">
            <div class="row-2">
                <div class="field"><label>所属分类 *</label>
                    <select class="select" name="categoryId" required><c:forEach items="${categories}" var="cat"><option value="${cat.id}"><c:out value="${cat.name}"/></option></c:forEach></select>
                </div>
                <div class="field"><label>关键词</label><input class="input" name="keywords" maxlength="200" placeholder="逗号分隔，例如：退款,售后"><span class="hint">AI 检索时命中关键词 +10 分</span></div>
            </div>
            <div class="field"><label>标准问题 *</label><input class="input" name="question" maxlength="200" required placeholder="例如：怎么申请退款？"></div>
            <div class="field"><label>答案 *（支持 **加粗**、- 列表）</label><textarea class="textarea" name="answer" rows="7" required></textarea></div>
            <label class="switch"><input type="checkbox" name="status" value="1"><span class="track"></span>启用（AI 可检索）</label>
        </div>
        <div class="modal-foot"><button class="btn" data-close type="button">取消</button><button class="btn btn-primary" type="submit"><i class="ri-save-3-line"></i>保存</button></div>
    </form>
</dialog>

<!-- 分类编辑弹窗 -->
<dialog class="modal" id="catDlg">
    <form method="post" action="${ctx}/admin/kb_categorySave.action">
        <div class="modal-head"><span data-title data-add="新增分类" data-edit="编辑分类">新增分类</span><button class="icon-btn" data-close type="button"><i class="ri-close-line"></i></button></div>
        <div class="modal-body">
            <input type="hidden" name="id">
            <div class="row-2">
                <div class="field"><label>分类名称 *</label><input class="input" name="name" maxlength="32" required></div>
                <div class="field"><label>排序</label><input class="input" type="number" name="sort" min="0" max="999"></div>
            </div>
            <div class="field"><label>说明</label><input class="input" name="descr" maxlength="64" placeholder="例如：登录、密码、绑定"></div>
            <div class="row-2">
                <div class="field"><label>图标（Remix Icon 类名）</label><input class="input" name="icon" maxlength="32" placeholder="ri-file-text-line"></div>
                <div class="field"><label>渐变色</label><div class="flex gap-8"><input class="input" type="color" name="color1" style="padding:4px;height:40px"><input class="input" type="color" name="color2" style="padding:4px;height:40px"></div></div>
            </div>
        </div>
        <div class="modal-foot">
            <button class="btn btn-danger" type="button" id="catDelete" style="margin-right:auto"><i class="ri-delete-bin-6-line"></i>删除分类</button>
            <button class="btn" data-close type="button">取消</button><button class="btn btn-primary" type="submit"><i class="ri-save-3-line"></i>保存</button>
        </div>
    </form>
</dialog>
<form id="catDeleteForm" method="post" action="${ctx}/admin/kb_categoryDelete.action" class="hidden"><input type="hidden" name="id"></form>

<script>
    function editArticle(btn) {
        const d = document.getElementById('artDlg'), f = d.querySelector('form');
        f.reset();
        f.id.value = btn.dataset.id;
        f.categoryId.value = btn.dataset.categoryId;
        f.question.value = btn.dataset.question;
        f.keywords.value = btn.dataset.keywords;
        f.answer.value = document.getElementById('ans-' + btn.dataset.id).value;
        f.status.checked = btn.dataset.status === '1';
        d.querySelector('[data-title]').textContent = '编辑问答';
        d.showModal();
    }
    document.getElementById('catDelete').addEventListener('click', function () {
        const id = document.querySelector('#catDlg form').id.value;
        if (!id) { document.getElementById('catDlg').close(); return; }
        if (!confirm('确定删除该分类吗？分类下还有问答时不能删除')) return;
        const f = document.getElementById('catDeleteForm'); f.id.value = id; f.submit();
    });
</script>
<%@ include file="../common/foot.jspf" %>
