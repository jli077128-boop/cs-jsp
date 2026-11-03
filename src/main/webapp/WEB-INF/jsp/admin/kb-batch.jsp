<%@ page contentType="text/html;charset=UTF-8" pageEncoding="UTF-8" %>
<%@ taglib prefix="c" uri="http://java.sun.com/jsp/jstl/core" %>
<c:set var="pageTitle" value="批量新增问答"/>
<c:set var="nav" value="kb"/>
<%@ include file="../common/head.jspf" %>
<%@ include file="../common/side-nav.jspf" %>
<%-- 批量参数接收演示（对应课堂 03_strutsParams/customerBatch.jsp）：
     每一行的字段名是 articles[下标].属性，例如 articles[0].question、articles[2].answer，
     提交后 Struts 根据 AdminKbBatchAction 中 List<KbArticle> articles 的泛型自动 new KbArticle() 并放到对应下标。
     name="articles[%{#st.index}].question" 中的 %{} 是 OGNL，#st 是 <s:iterator status="st"> 的迭代状态 --%>
<div class="topbar">
    <div><h1>批量新增问答</h1><p>一次录入多条知识库问答，问题为空的行会被忽略 · 字段名形如 <code>articles[0].question</code></p></div>
    <s:a cssClass="btn" action="kb" namespace="/admin"><i class="ri-arrow-go-back-line"></i>返回知识库</s:a>
</div>
<section class="glass panel rise">
    <s:if test="hasActionErrors()"><div class="alert alert-error"><i class="ri-error-warning-line"></i><s:actionerror theme="simple"/></div></s:if>
    <s:if test="hasFieldErrors()"><div class="alert alert-error"><i class="ri-error-warning-line"></i><s:fielderror theme="simple"/></div></s:if>
    <s:form action="kbBatch" namespace="/admin" method="post" theme="simple" id="batchForm">
        <div class="table-wrap">
            <table class="table batch-table">
                <thead><tr><th style="width:44px">#</th><th style="width:150px">分类 *</th><th>标准问题</th><th>答案 *</th><th style="width:160px">关键词</th><th style="width:112px">状态</th></tr></thead>
                <tbody id="batchRows">
                <s:iterator value="articles" status="st">
                    <tr>
                        <td class="mono muted"><s:property value="#st.count"/></td>
                        <td><s:select name="articles[%{#st.index}].categoryId" list="categories" listKey="id" listValue="name" headerKey="" headerValue="选择分类" cssClass="select"/></td>
                        <td><s:textfield name="articles[%{#st.index}].question" cssClass="input" maxlength="200" placeholder="例如：怎么修改绑定手机号？"/></td>
                        <td><s:textarea name="articles[%{#st.index}].answer" cssClass="textarea" rows="2" placeholder="支持 **加粗**、- 列表"/></td>
                        <td><s:textfield name="articles[%{#st.index}].keywords" cssClass="input" maxlength="200" placeholder="逗号分隔"/></td>
                        <%-- OGNL Map 常量 #{1:'启用', 0:'停用'} 直接作为下拉选项 --%>
                        <td><s:select name="articles[%{#st.index}].status" list="#{1:'启用', 0:'停用'}" cssClass="select"/></td>
                    </tr>
                </s:iterator>
                </tbody>
            </table>
        </div>
        <div class="flex gap-12 mt-16 items-center">
            <button class="btn" type="button" id="addRow"><i class="ri-add-line"></i>再加一行</button>
            <span class="muted" style="font-size:12.5px">共 <b id="rowCount"><s:property value="articles.size()"/></b> 行</span>
            <button class="btn btn-primary" type="submit" style="margin-left:auto"><i class="ri-save-3-line"></i>全部保存</button>
        </div>
    </s:form>
</section>
<script>
    // 复制最后一行，并把 name 中的下标 articles[n] 改成新的下标
    document.getElementById('addRow').addEventListener('click', function () {
        var body = document.getElementById('batchRows'), last = body.lastElementChild, n = body.children.length;
        var row = last.cloneNode(true);
        row.querySelectorAll('[name]').forEach(function (el) {
            el.name = el.name.replace(/articles\[\d+]/, 'articles[' + n + ']');
            if (el.id) el.id = el.id.replace(/\d+/, n);
            if (el.tagName === 'SELECT') el.selectedIndex = 0; else el.value = '';
        });
        row.querySelector('td').textContent = n + 1;
        body.appendChild(row);
        document.getElementById('rowCount').textContent = n + 1;
    });
</script>
<%@ include file="../common/foot.jspf" %>
