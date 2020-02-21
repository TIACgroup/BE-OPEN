<%@ taglib uri="http://java.sun.com/jsp/jstl/core" prefix="c"%>
<%@ taglib uri="http://java.sun.com/jsp/jstl/fmt" prefix="fmt"%>
<c:set var="root"><%=request.getContextPath()%></c:set>
<c:set var="citation" value="${extra['citation']}" />
<c:set var="sevenDaysBefore" value="${extra['sevenDaysBefore']}" />
<div class="col-sm-6 col-xs-12 box-scopus">
<div class="media scopus">
	<div class="media-body text-center">
	    <h4 class="media-heading"><fmt:message key="jsp.display-cris.citation.scopus_aggregate"/>
	</div>
	<div class="text-center">
	    <span id="metric-counter" class="metric-counter text-center">
	    ${citation}
	    </span>
	</div>
	<div class="row">
        <div class="col-lg-12 text-center small">
            <fmt:message
                key="jsp.display-cris.citation.time">
                <fmt:param value="${sevenDaysBefore}" />
            </fmt:message>
        </div>
    </div>
</div>
</div>

