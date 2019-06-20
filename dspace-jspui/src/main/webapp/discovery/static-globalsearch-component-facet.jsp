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
	
	if (dali_ide_search) { /* AKO JE dali_ide_search true */

%>
		
<div class="row">
	<form id="searchglobalprocessor" name="searchglobalprocessor" class="col-md-12" action="<%= request.getContextPath() %>/simple-search" method="get">
		<div class="input-group" style="padding: 10px 0px 10px 0px;">
    		<input type="text" class="form-control" name="query"  id="query" placeholder="<fmt:message key="jsp.controlledvocabulary.search.term"/>">
    		<span class="input-group-btn">
        		<button class="btn btn-primary btn-src" type="submit"><i class="fa fa-search"></i></button>
			</span>    
    		<input type="hidden" name="location" value="global" id="search_param">         
		</div>
	</form>
</div>

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

		// AKO JE dali_ide_search false

	} else { 
%>

		<script>

		// nista ne ispisuje, samo puni javascript varijable
		
	
		var repoInfo = [];

			// istrazivaci

			<%
			if(facetsGlobalConf!=null) {
				
				for (DiscoverySearchFilterFacet facetConf : facetsGlobalConf) {
					
					String f = facetConf.getIndexFieldName(); 
					List<FacetResult> facet = mapGlobalFacetes.get(f);
					
						if(facet!=null) {
						for (FacetResult fvalue : facet) { 
							if(mapFacetFirstLevel.containsKey(fvalue.getAuthorityKey())) {
								String levoDesno = "";
								if (mapFacetFirstLevel.get(fvalue.getAuthorityKey()).contains("left")) {
									levoDesno = "left";
								}	
								else if (mapFacetFirstLevel.get(fvalue.getAuthorityKey()).contains("right")) {
									levoDesno = "right";
								}	
								else if (mapFacetFirstLevel.get(fvalue.getAuthorityKey()).contains("datasets")) {
									levoDesno = "right";
								}	
								else if (mapFacetFirstLevel.get(fvalue.getAuthorityKey()).contains("center")) {
									levoDesno = "center";
								}
								String fkey =  "jsp.home.group-" + levoDesno + "-info."+fvalue.getAuthorityKey(); %>
								repoInfo.push({"kljuc": "<%= fvalue.getAuthorityKey() %>", "poruka": "<fmt:message key="<%= fkey %>"/>", "broj" : <%= fvalue.getCount() %>, "link" : "<%= request.getContextPath() %>/simple-search?query=&location=<%=fvalue.getAuthorityKey()%>"});
				
							<% }
						}
					}
				}	    		    
				
			}

			%>
			

			</script>

<% } // KRAJ USLOVA AKO JE dali_ide_search false 
%>

<br>

		
