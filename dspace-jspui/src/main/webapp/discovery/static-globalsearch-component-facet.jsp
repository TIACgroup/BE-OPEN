<%--

    The contents of this file are subject to the license and copyright
    detailed in the LICENSE and NOTICE files at the root of the source
    tree and available online at

    http://www.dspace.org/license/

--%>
<%--
  - fragment JSP to be included in site, community or collection home to show discovery facets
  -
  - Attributes required:
  -    discovery.fresults    - the facets result to show
  -    discovery.facetsConf  - the facets configuration
  -    discovery.searchScope - the search scope 
  --%>

<%@page import="org.dspace.discovery.configuration.DiscoverySearchFilterFacet"%>
<%@ page import="java.util.HashMap"%>
<%@ page import="java.util.Set"%>
<%@ page import="java.util.Map"%>
<%@ page import="org.dspace.discovery.DiscoverResult.FacetResult"%>
<%@ page import="java.util.List"%>
<%@ page import="java.net.URLEncoder"%>
<%@ page import="org.apache.commons.lang.StringUtils"%>
<script type="text/javascript">
<!--
	jQuery(document).ready(function(){
		
			jQuery("#searchglobalprocessor .search-panel .dropdown-menu li a").click(function(){
				  jQuery('#search_param').val('');  
				  jQuery('#search_param').val(jQuery(this).attr('title'));
				  return jQuery('#searchglobalprocessor').submit();
			});
		
			jQuery("#group-left-info").popover({
			   	trigger: 'click',
			   	html: true,
				title: function(){
					return jQuery('#group-left-info-popover-head').html();
				},
				content: function(){
					return jQuery('#group-left-info-popover-content').html();
				}
			});
			
			jQuery('#group-left-info').on('click',function(){
				jQuery('#group-center-info').popover('hide');
				jQuery('#group-right-info').popover('hide');
			});
			
			jQuery('#group-center-info').popover({
			   	trigger: 'click',
			   	html: true,
				title: function(){
					return jQuery('#group-center-info-popover-head').html();
				},
				content: function(){
					return jQuery('#group-center-info-popover-content').html();
				}
			});
			jQuery('#group-center-info').on('click',function(){
				jQuery('#group-left-info').popover('hide');
				jQuery('#group-right-info').popover('hide');
			});
			
			jQuery('#group-right-info').popover({
			   	trigger: 'click',
			   	html: true,
				title: function(){
					return jQuery('#group-right-info-popover-head').html();
				},
				content: function(){
					return jQuery('#group-right-info-popover-content').html();
				}
			});
			jQuery('#group-right-info').on('click',function(){
				jQuery('#group-left-info').popover('hide');
				jQuery('#group-center-info').popover('hide');
			});
			

			
	});	
-->
</script>
<%

	String facetGlobalName = (String) request.getAttribute("facetGlobalName");
	List<DiscoverySearchFilterFacet> facetsGlobalConf = (List<DiscoverySearchFilterFacet>) request.getAttribute("facetsGlobalConfig");
	Map<String, List<FacetResult>> mapGlobalFacetes = (Map<String, List<FacetResult>>) request.getAttribute("discovery.global.fresults");
	
	Map<String, String> mapFacetFirstLevel = (Map<String, String>) request.getAttribute("facetGlobalFirstLevel");
	Map<String, String> mapFacetSecondLevel = (Map<String, String>) request.getAttribute("facetGlobalSecondLevel");
	
%>
		
		
<hr/>
<div class="row">
<form id="searchglobalprocessor" name="searchglobalprocessor" class="col-md-12" action="<%= request.getContextPath() %>/simple-search" method="get">
<div class="input-group" style="padding: 10px 0px 10px 0px;">
    <input type="text" class="form-control" name="query"  id="query" placeholder="<fmt:message key="jsp.controlledvocabulary.search.term"/>">
    <span class="input-group-btn">
        <button class="btn btn-primary btn-src" type="submit"><i class="fa fa-search"></i></button>
    </span>    
	<!-- SVAKAKO SU IZLISTANE KATEGORIJE PA OVO NIJE POTEBNO
		<div class="input-group-btn search-panel">
        <button type="button" class="btn btn-default dropdown-toggle" data-toggle="dropdown">
        	<span id="search_concept">All</span>&nbsp;&nbsp;&nbsp;&nbsp;&nbsp; <b><span class="caret"></b>
        </button>
        <ul class="dropdown-menu menu-global-processor" role="menu">
        <%
		if(facetsGlobalConf!=null) {
			for (DiscoverySearchFilterFacet facetConf : facetsGlobalConf)
			{
		    	String f = facetConf.getIndexFieldName();
		    	if(f.equals(facetGlobalName)) {
		    	List<FacetResult> facet = mapGlobalFacetes.get(f);
		    	
		    	if(facet!=null) {
				  	for (FacetResult fvalue : facet)
			    	{ 
		        %>

					<li class="menu-global-processor">
						<a href="#"
						title="<%=fvalue.getAuthorityKey()%>"><span class="badge pull-right"><%=fvalue.getCount()%></span> <%=StringUtils.abbreviate(fvalue.getDisplayedValue(), 36)%> &nbsp;&nbsp;&nbsp; <span class="badge invisible"><%=fvalue.getCount()%></span> </a></li>
					<%
			    	}
		    	}	    		    
				}
			}
		}
		%>
        
        
        </ul>
    </div>-->
    <input type="hidden" name="location" value="global" id="search_param">         
</div>
</form>
</div>
<br/>

<%
	long totGroupLeft = 0;
		long totGroupCenter = 0;
		long totGroupRight = 0;
		if (facetsGlobalConf != null) {
			for (DiscoverySearchFilterFacet facetConf : facetsGlobalConf) {
				String f = facetConf.getIndexFieldName();
				if(f.equals(facetGlobalName)) {
					List<FacetResult> facet = mapGlobalFacetes.get(f);
					if(facet!=null) {						
						for (FacetResult ft : facet) {
							if(mapFacetFirstLevel.containsKey(ft.getAuthorityKey())) {
								if(mapFacetFirstLevel.get(ft.getAuthorityKey()).equals("group-left")) {
									totGroupLeft += ft.getCount();	
								}
								if(mapFacetFirstLevel.get(ft.getAuthorityKey()).equals("group-center")) {
									totGroupCenter += ft.getCount();	
								}
								if(mapFacetFirstLevel.get(ft.getAuthorityKey()).equals("group-right")) {
									totGroupRight += ft.getCount();	
								}
							}
						}
					}
				}
			}
		}
%>

<div class="row">

	<!-- CENTRALNI BLOK ISTRAZIVACI -->
	
	<div class="col-md-12 text-center">
			<div id="group-left-info-popover-content">
				<ul class="list-group">
					<%
					if(facetsGlobalConf!=null) {
						for (DiscoverySearchFilterFacet facetConf : facetsGlobalConf)
						{
							String f = facetConf.getIndexFieldName();   	
							List<FacetResult> facet = mapGlobalFacetes.get(f);
							if(facet!=null) {
								for (FacetResult fvalue : facet)
								{ 
									if(mapFacetFirstLevel.containsKey(fvalue.getAuthorityKey())) {
										if(mapFacetFirstLevel.get(fvalue.getAuthorityKey()).equals("group-left")) {	
										String fkey =  "jsp.home.group-left-info."+fvalue.getAuthorityKey();
								%>
				
								<li class="list-group-item"> <span class="badge"><%= fvalue.getCount() %></span> <a href="<%= request.getContextPath() %>/simple-search?query=&location=<%=fvalue.getAuthorityKey()%>"><fmt:message key="<%= fkey %>"/></a></li>
						<%
										}
									}
								}
							}	    		    
							
						}
					
					%>
					<%
						for (DiscoverySearchFilterFacet facetConf : facetsGlobalConf)
						{
							String f = facetConf.getIndexFieldName();   
							if(mapFacetSecondLevel.containsKey(f)) {
								if(mapFacetFirstLevel.get(mapFacetSecondLevel.get(f)).equals("group-left")) {
									%>
									<li role="presentation" class="dropdown-header"><fmt:message key="jsp.home.group.dropdown.header.secondlevel"/></li>
									<%
							List<FacetResult> facet = mapGlobalFacetes.get(f);
							if(facet!=null) {
								for (FacetResult fvalue : facet)
								{ 
								%>
				
								<li class="list-group-item"> <span class="badge"><%= fvalue.getCount() %></span> <a href="<%= request.getContextPath()
									+ "/simple-search?filterquery="+URLEncoder.encode(fvalue.getAsFilterQuery(),"UTF-8")
									+ "&amp;filtername="+URLEncoder.encode(f,"UTF-8")
									+ "&amp;filtertype="+URLEncoder.encode(fvalue.getFilterType(),"UTF-8") %>"
									title="<fmt:message key="jsp.search.facet.narrow"><fmt:param><%=fvalue.getDisplayedValue() %></fmt:param></fmt:message>">
									<%= StringUtils.abbreviate(fvalue.getDisplayedValue(),36) %></a></li>
						<%
								}
							}
							}
							}	    		    
							
						}
					}
					%>
					</ul>
			</div>
	</div>
	
	<!-- CENTRALNI BLOK PROJEKTI -->
	
	<div class="col-md-12 text-center">
		<div id="group-left-info-popover-content">
			<ul class="list-group">
				<%
				if(facetsGlobalConf!=null) {
					for (DiscoverySearchFilterFacet facetConf : facetsGlobalConf)
					{
						String f = facetConf.getIndexFieldName();
						List<FacetResult> facet = mapGlobalFacetes.get(f);
						if(facet!=null) {
							for (FacetResult fvalue : facet)
							{ 
								if(mapFacetFirstLevel.containsKey(fvalue.getAuthorityKey())) {
									if(mapFacetFirstLevel.get(fvalue.getAuthorityKey()).equals("group-center")) {
									
									/* MORAM OVAKO JER SU STRING VARIJABLE VEZANE ZA BLOKOVE */ 
										
									String fkey =  "jsp.home.group-" + (fvalue.getAuthorityKey().equals("datasets") ? "right" : "center") + "-info."+fvalue.getAuthorityKey();

							%>
			
							<li class="list-group-item"> <span class="badge"><%= fvalue.getCount() %></span> <a href="<%= request.getContextPath() %>/simple-search?query=&location=<%=fvalue.getAuthorityKey()%>"><fmt:message key="<%= fkey %>"/></a></li>
					<%
									}
								}
							}
						}	    		    
						
					}
				
				%>
				<%
					for (DiscoverySearchFilterFacet facetConf : facetsGlobalConf)
					{
						String f = facetConf.getIndexFieldName();   
						if(mapFacetSecondLevel.containsKey(f)) {
							if(mapFacetFirstLevel.get(mapFacetSecondLevel.get(f)).equals("group-center")) {
								%>
								<li role="presentation" class="dropdown-header"><fmt:message key="jsp.home.group.dropdown.header.secondlevel"/></li>
								<%
						List<FacetResult> facet = mapGlobalFacetes.get(f);
						if(facet!=null) {
							for (FacetResult fvalue : facet)
							{ 
							%>
			
							<li class="list-group-item"> <span class="badge"><%= fvalue.getCount() %></span> <a href="<%= request.getContextPath()
								+ "/simple-search?filterquery="+URLEncoder.encode(fvalue.getAsFilterQuery(),"UTF-8")
								+ "&amp;filtername="+URLEncoder.encode(f,"UTF-8")
								+ "&amp;filtertype="+URLEncoder.encode(fvalue.getFilterType(),"UTF-8") %>"
								title="<fmt:message key="jsp.search.facet.narrow"><fmt:param><%=fvalue.getDisplayedValue() %></fmt:param></fmt:message>">
								<%= StringUtils.abbreviate(fvalue.getDisplayedValue(),36) %></a></li>
					<%
							}
						}
						}
						}	    		    
						
					}
				}
				%>
				</ul>
		</div>
	</div>
	
	<!-- CENTRALNI BLOK OSTALO -->
	
	<div class="col-md-12 text-center">
		<div id="group-left-info-popover-content">
			<ul class="list-group">
				<%
				if(facetsGlobalConf!=null) {
					for (DiscoverySearchFilterFacet facetConf : facetsGlobalConf)
					{
						String f = facetConf.getIndexFieldName();
						List<FacetResult> facet = mapGlobalFacetes.get(f);
						if(facet!=null) {
							for (FacetResult fvalue : facet)
							{ 
								if(mapFacetFirstLevel.containsKey(fvalue.getAuthorityKey())) {
									if(mapFacetFirstLevel.get(fvalue.getAuthorityKey()).equals("group-right")) {
									String fkey =  "jsp.home.group-right-info."+fvalue.getAuthorityKey();
							%>
			
							<li class="list-group-item"><span class="badge"><%= fvalue.getCount() %></span> <a href="<%= request.getContextPath() %>/simple-search?query=&location=<%=fvalue.getAuthorityKey()%>"><fmt:message key="<%= fkey %>"/></a></li>
					<%
									}
								}
							}
						}
								
						
					}
				
				%>
						<%
					for (DiscoverySearchFilterFacet facetConf : facetsGlobalConf)
					{
						String f = facetConf.getIndexFieldName();   
						if(mapFacetSecondLevel.containsKey(f)) {
							if(mapFacetFirstLevel.get(mapFacetSecondLevel.get(f)).equals("group-right")) {
								%>
								<li role="presentation" class="dropdown-header"><fmt:message key="jsp.home.group.dropdown.header.secondlevel"/></li>
								<%
						List<FacetResult> facet = mapGlobalFacetes.get(f);
						if(facet!=null) {
							for (FacetResult fvalue : facet)
							{ 
							%>
			
							<li class="list-group-item"> <span class="badge"><%= fvalue.getCount() %></span> <a href="<%= request.getContextPath()
								+ "/simple-search?filterquery="+URLEncoder.encode(fvalue.getAsFilterQuery(),"UTF-8")
								+ "&amp;filtername="+URLEncoder.encode(f,"UTF-8")
								+ "&amp;filtertype="+URLEncoder.encode(fvalue.getFilterType(),"UTF-8") %>"
								title="<fmt:message key="jsp.search.facet.narrow"><fmt:param><%=fvalue.getDisplayedValue() %></fmt:param></fmt:message>">
								<%= StringUtils.abbreviate(fvalue.getDisplayedValue(),36) %></a></li>
					<%
							}
						}
						}		    		    		    
						}
					}
				}
				%>
				</ul>
		</div>
	</div>
	
</div>

<br>

		
