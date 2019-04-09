<%--

    The contents of this file are subject to the license and copyright
    detailed in the LICENSE and NOTICE files at the root of the source
    tree and available online at

    https://github.com/CILEA/dspace-cris/wiki/License

--%>
<%@ page contentType="text/html;charset=UTF-8" %>
<%@ taglib prefix="c" uri="http://java.sun.com/jsp/jstl/core" %>
<%@ taglib prefix="fmt" uri="http://java.sun.com/jsp/jstl/fmt" %>
<%@ taglib uri="http://java.sun.com/jsp/jstl/functions" prefix="fn" %>
<%@ taglib uri="http://www.springframework.org/tags/form" prefix="form" %>
<%@ taglib uri="http://www.springframework.org/tags" prefix="spring" %>
<%@ taglib uri="http://www.dspace.org/dspace-tags.tld" prefix="dspace" %>
<%@ page import="java.util.Map" %>
<%@ page import="javax.servlet.jsp.jstl.fmt.LocaleSupport" %>

<script>

    function disableCheckBox(index) {
        $('input[type=checkbox]').each(function () {
            $(this).removeAttr("disabled");
        });

        $('#inlineCheckbox' + index).prop("checked", false);
        $('#inlineCheckbox' + index).attr("disabled", true);
    }

    function mergeSelected() {
        var original = '';
        var duplikati = [];

        $('input[type=radio]').each(function () {
            if ($(this).is(':checked')) {
                var id = $(this).attr('id');
                var index = id.substring(11, id.length);

                original = $('#utilInput' + index).val();
            }
        });

        $('input[type=checkbox]').each(function () {
            if ($(this).is(':checked')) {
                var id = $(this).attr('id');
                var index = id.substring(14, id.length);
                var duplikat = $('#utilInput' + index).val();

                duplikati.push(duplikat);
            }
        });

        if (duplikati.length === 0) {
            alert('<fmt:message key="jsp.rp-deduplication.alert.noneselected"/>');
        } else {
            $('#original').val(original);
            $('#duplikati').val(duplikati.toString());

            $('#postForm').submit();
        }
    }

</script>

<dspace:layout style="submission" navbar="admin" locbar="link" titlekey="jsp.layout.navbar-admin.rp.duplicate">

    <h1><fmt:message key="jsp.rp-deduplication.heading"/></h1>

    <div class="mt-5"><fmt:message key="jsp.rp-deduplication.label"/></div>

    <form method="get" action="">
        <div class="row">
            <%--<label class="col-md-2" for="thandle"><fmt:message key="jsp.tools.get-item-id.handle"/></label>--%>
            <span class="col-md-3"><input class="form-control" type="text" name="query" id="thandle" size="12"/></span>
            <input class="btn btn-default" type="submit" name="submit" value="<fmt:message key="jsp.tools.get-item-id.find.button"/>" />
        </div>
    </form>

    <form method="post" action="" id="postForm">
        <input type="hidden" id="original" name="original" value="">
        <input type="hidden" id="duplikati" name="duplikati" value="">
    </form>

    <div class="mt-3 bt-3">
        <hr>
    </div>

    <c:if test="${success}">
        <c:choose>
            <c:when test="${success eq true}">
                <div class="alert alert-success" role="alert">
                    <fmt:message key="jsp.rp-deduplication.message.success"/>
                </div>
            </c:when>
            <c:otherwise>
                <div class="alert alert-danger" role="alert">
                    <fmt:message key="jsp.rp-deduplication.message.error"/>
                </div>
            </c:otherwise>
        </c:choose>
    </c:if>

    <c:if test="${resultList ne null}">
        <table class="table table-striped">
            <thead>
            <tr>
                <th scope="col"><fmt:message key="jsp.rp-deduplication.table.crisid"/></th>
                <th scope="col"><fmt:message key="jsp.rp-deduplication.table.fullname"/></th>
                <th scope="col"></th>
                <th scope="col"></th>
            </tr>
            </thead>
            <tbody>
            <c:forEach items="${resultList}" var="rp" varStatus="status">
                <tr>
                    <td scope="row">
                        <a href="${pageContext.request.contextPath}/cris/rp/${rp.sourceID }">${rp.sourceID}</a>
                    </td>
                    <td>
                        <a href="${pageContext.request.contextPath}/cris/rp/${rp.sourceID }">${rp.fullName}</a></td>
                    <td>
                        <div class="form-check form-check-inline">
                            <input class="form-check-input" type="radio" name="inlineRadioOptions" id="inlineRadio${status.index}" value="${rp.sourceID}"
                                <c:if test="${status.index == 0}">checked</c:if>
                                onchange="disableCheckBox(${status.index})">
                            <label class="form-check-label" for="inlineRadio${status.index}"><fmt:message key="jsp.rp-deduplication.table.original"/></label>
                        </div>
                    </td>
                    <td>
                        <div class="form-check form-check-inline">
                            <input class="form-check-input" type="checkbox" id="inlineCheckbox${status.index}" value="${rp.sourceID}"
                            <c:if test="${status.index == 0}">disabled</c:if>>
                            <label class="form-check-label" for="inlineCheckbox${status.index}"><fmt:message key="jsp.rp-deduplication.table.duplicate"/></label>
                        </div>
                    </td>
                    <input type="hidden" id="utilInput${status.index}" name="utilInput${status.index}" value="${rp.sourceID}">
            </c:forEach>
            </tbody>
        </table>

        <button type="button" class="btn btn-primary pull-right" onclick="mergeSelected()"><fmt:message key="jsp.rp-deduplication.merge.selected"/></button>
    </c:if>

</dspace:layout>
