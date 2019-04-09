<%--

    The contents of this file are subject to the license and copyright
    detailed in the LICENSE and NOTICE files at the root of the source
    tree and available online at

    https://github.com/CILEA/dspace-cris/wiki/License

--%>
<%@page import="org.apache.commons.lang.StringUtils"%>
<%@page import="java.util.List"%>
<%@ page import="org.apache.commons.lang.StringEscapeUtils" %>
<%@ page import="java.net.URLEncoder"            %>
<%@ page import="org.dspace.sort.SortOption" %>
<%@ page import="java.util.Enumeration" %>
<%@ page import="java.util.Set" %>
<%@ page import="java.util.Map" %>
<%@ page import="org.dspace.browse.BrowseItem" %>
<%@page import="org.dspace.app.webui.cris.dto.ComponentInfoDTO"%>
<%@page import="it.cilea.osd.jdyna.web.Box"%>
<%@page import="org.dspace.discovery.configuration.*"%>
<%@page import="org.dspace.app.webui.util.UIUtil"%>
<%@page import="java.util.HashMap"%>
<%@page import="java.util.ArrayList"%>
<%@page import="org.dspace.discovery.DiscoverFacetField"%>
<%@page import="org.dspace.discovery.DiscoverFilterQuery"%>
<%@page import="org.dspace.discovery.DiscoverQuery"%>
<%@page import="org.apache.commons.lang.StringUtils"%>
<%@page import="java.util.Map"%>
<%@page import="org.dspace.discovery.DiscoverResult.FacetResult"%>
<%@page import="org.dspace.discovery.DiscoverResult.DSpaceObjectHighlightResult"%>
<%@page import="org.dspace.discovery.DiscoverResult"%>
<%@page import="org.dspace.core.Utils"%>

<%@page import="org.dspace.eperson.EPerson"%>
<%@ taglib uri="http://www.dspace.org/dspace-tags.tld" prefix="dspace" %>
<%@ taglib uri="http://java.sun.com/jsp/jstl/functions" prefix="fn"%>
<%@ taglib uri="http://java.sun.com/jsp/jstl/core" prefix="c"%>
<%@ taglib uri="http://java.sun.com/jsp/jstl/fmt" prefix="fmt"%>
<%@ taglib uri="jdynatags" prefix="dyna"%>
<c:set var="root"><%=request.getContextPath()%></c:set>
<c:set var="info" value="${componentinfomap}" scope="page" />
<%
	
	Box holder = (Box)request.getAttribute("holder");
	ComponentInfoDTO info = ((Map<String, ComponentInfoDTO>)(request.getAttribute("componentinfomap"))).get(holder.getShortName());
	String relationName = info.getRelationName();
	
	List<String[]> subLinks = (List<String[]>) request.getAttribute("activeTypes"+relationName);
	
	DiscoverResult qResults = (DiscoverResult) request.getAttribute("qResults"+relationName);
	List<String> appliedFilterQueries = (List<String>) request.getAttribute("appliedFilterQueries"+relationName);
	List<String[]> appliedFilters = (List<String[]>) request.getAttribute("appliedFilters"+relationName);
	Map<String, String> displayAppliedFilters = new HashMap<String, String>();
	
    String httpFilters ="";
	if (appliedFilters != null && appliedFilters.size() >0 ) 
	{
	    int idx = 1;
	    for (String[] filter : appliedFilters)
	    {
	        httpFilters += "&amp;filter_field_" + relationName + "_"+idx+"="+URLEncoder.encode(filter[0],"UTF-8");
	        httpFilters += "&amp;filter_type_" + relationName + "_"+idx+"="+URLEncoder.encode(filter[1],"UTF-8");
	        httpFilters += "&amp;filter_value_" + relationName + "_"+idx+"="+URLEncoder.encode(filter[2],"UTF-8");
	        idx++;
	    }
	}
		
	boolean globalShowFacets = false;
	if (info!=null && info.getItems()!=null && info.getItems().length > 0) {
%>
	
<c:set var="info" value="<%= info %>" scope="request" />

<% 
    boolean brefine = false;
    List<DiscoverySearchFilterFacet> facetsConf = (List<DiscoverySearchFilterFacet>) request.getAttribute("facetsConfig"+info.getRelationName());
    Map<String, Boolean> showFacets = new HashMap<String, Boolean>();
    
    for (DiscoverySearchFilterFacet facetConf : facetsConf)
    {
    	if(qResults!=null) {
    	    String f = facetConf.getIndexFieldName();
    	    List<FacetResult> facet = qResults.getFacetFieldResult(f);
    	    if (facet.size() == 0)
    	    {
    	        facet = qResults.getFacetResult(f+".year");
    		    if (facet.size() == 0)
    		    {
    		        showFacets.put(f, false);
    		        continue;
    		    }
    	    }
    	    boolean showFacet = false;
    	    for (FacetResult fvalue : facet)
    	    { 
    			if(!appliedFilterQueries.contains(f+"::"+fvalue.getFilterType()+"::"+fvalue.getAsFilterQuery()))
    		    {
    			    globalShowFacets = true;
    		        showFacet = true;
    		    }
    			else {
					displayAppliedFilters.put(f+"::"+fvalue.getFilterType()+"::"+fvalue.getAsFilterQuery(),
							fvalue.getDisplayedValue());
				}
    	    }
    	    showFacets.put(f, showFacet);
    	    brefine = brefine || showFacet;
    	}
    }
	%>
	

<div class="panel-group col-md-12 ${extraCSS}" id="${holder.shortName}">
	<div class="panel panel-default">
    	<div class="panel-heading">
    		<h4 class="panel-title">
        		<a data-toggle="collapse" data-parent="#${holder.shortName}" href="#collapseOne${holder.shortName}">
          			${holder.title}
        		</a>
        		<% if(subLinks!=null && subLinks.size()>0 && globalShowFacets) {%>
        			<jsp:include page="common/commonComponentGeneralFiltersAndFacets.jsp"></jsp:include>
				<% } else { %>
					<jsp:include page="common/commonComponentGeneralFilters.jsp"></jsp:include>
				<% } %>
			</h4>		
    	</div>
	<div id="collapseOne${holder.shortName}" class="panel-collapse collapse in">
		<div class="panel-body">
		
	<% if(subLinks!=null && subLinks.size()>0) { %>
		<jsp:include page="common/commonComponentFacets.jsp"></jsp:include>
	<% } %>		
	<p>


<!-- prepare pagination controls -->
<%
    // create the URLs accessing the previous and next search result pages
    StringBuilder sb = new StringBuilder();
	sb.append("<div class=\"block text-center\"><ul class=\"pagination\">");
	
    String prevURL = info.buildPrevURL(); 
    String nextURL = info.buildNextURL();


if (info.getPagefirst() != info.getPagecurrent()) {
  	  sb.append("<li><a class=\"\" href=\"");
  	  sb.append(prevURL);
  	  sb.append("\"><i class=\"fa fa-long-arrow-left\"> </i></a></li>");
}

for( int q = info.getPagefirst(); q <= info.getPagelast(); q++ )
{
   	String myLink = info.buildMyLink(q);
    sb.append("<li");
    if (q == info.getPagecurrent()) {
    	sb.append(" class=\"active\"");	
    }
    sb.append("> " + myLink+"</li>");
} // for


if (info.getPagetotal() > info.getPagecurrent()) {
  sb.append("<li><a class=\"\" href=\"");
  sb.append(nextURL);
  sb.append("\"><i class=\"fa fa-long-arrow-right\"> </i></a></li>");
}

sb.append("</ul></div>");

%>

<% if (appliedFilters.size() > 0 ) { %>	
	<jsp:include page="common/commonComponentFilterApplied.jsp"></jsp:include>
<% } %>
<div align="center" class="browse_range">

	<p align="center"><fmt:message key="jsp.search.results.results">
        <fmt:param><%=info.getStart()+1%></fmt:param>
        <fmt:param><%=info.getStart()+info.getItems().length%></fmt:param>
        <fmt:param><%=info.getTotal()%></fmt:param>
        <fmt:param><%=(float)info.getSearchTime() / 1000%></fmt:param>
    </fmt:message></p>

</div>
<%
if (info.getPagetotal() > 1)
{
%>
<%= sb %>
<%
	}
%>
<form id="sortform<%= info.getType() %>" action="#<%= info.getType() %>" method="get">
	   <input id="sort_by<%= info.getType() %>" type="hidden" name="sort_by<%= info.getType() %>" value=""/>
       <input id="order<%= info.getType() %>" type="hidden" name="order<%= info.getType() %>" value="<%= info.getOrder() %>" />
       <% if (appliedFilters != null && appliedFilters.size() >0 ) 
   		{
	   	    int idx = 1;
	   	    for (String[] filter : appliedFilters)
	   	    { %>
	   	    	<input id="filter_field_<%= relationName + "_" + idx %>" type="hidden" name="filter_field_<%= relationName + "_" + idx %>" value="<%= filter[0]%>"/>
	   	    	<input id="filter_type_<%= relationName + "_" + idx %>" type="hidden" name="filter_type_<%= relationName + "_" + idx %>" value="<%= filter[1]%>"/>
	   	    	<input id="filter_value_<%= relationName + "_" + idx %>" type="hidden" name="filter_value_<%= relationName + "_" + idx %>" value="<%= filter[2] %>"/>
	   	      <%  
	   	        idx++;
	   	    }
   		} %>
	   <input type="hidden" name="open" value="<%= info.getType() %>" />
</form>
			
<c:set var="browseType"><c:out value="${info[holder.shortName].browseType}"/>.<c:out value="${info[holder.shortName].type}"/></c:set>
<div class="row">
<div class="table-responsive">			
<dspace:browselist items="<%= (BrowseItem[])info.getItems() %>" config="${browseType}" sortBy="<%= new Integer(info.getSo().getNumber()).toString() %>" order="<%= info.getOrder() %>"/>
</div>
</div>

<script type="text/javascript"><!--
    function sortBy(sort_by, order) {
        j('#sort_by<%= info.getType() %>').val(sort_by);
        j('#order<%= info.getType() %>').val(order);
        j('#sortform<%= info.getType() %>').submit();        
    }
--></script>

<%-- show pagination controls at bottom --%>
<%
	if (info.getPagetotal() > 1)
	{
%>
<%= sb %>
<%
	}
%>


</p>
</div>
										  </div>
								   </div>
							</div>

<% } %>
