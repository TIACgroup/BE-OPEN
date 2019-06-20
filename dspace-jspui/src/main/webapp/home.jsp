<%--

    The contents of this file are subject to the license and copyright
    detailed in the LICENSE and NOTICE files at the root of the source
    tree and available online at

    http://www.dspace.org/license/

--%>
<%--
  - Home page JSP
  -
  - Attributes:
  -    communities - Community[] all communities in DSpace
  -    recent.submissions - RecetSubmissions
  --%>

<%@ page contentType="text/html;charset=UTF-8" %>

<%@ taglib uri="http://java.sun.com/jsp/jstl/fmt" prefix="fmt" %>
<%@ taglib uri="http://java.sun.com/jsp/jstl/core" prefix="c" %>

<%@ taglib uri="http://www.dspace.org/dspace-tags.tld" prefix="dspace" %>

<%@ page import="java.io.File" %>
<%@ page import="java.util.Enumeration"%>
<%@ page import="java.util.Locale"%>
<%@ page import="javax.servlet.jsp.jstl.core.*" %>
<%@ page import="javax.servlet.jsp.jstl.fmt.LocaleSupport" %>
<%@ page import="org.dspace.app.webui.servlet.MyDSpaceServlet" %>
<%@ page import="org.dspace.core.I18nUtil" %>
<%@ page import="org.dspace.app.webui.util.UIUtil" %>
<%@ page import="org.dspace.app.webui.components.RecentSubmissions" %>
<%@ page import="org.dspace.content.Community" %>
<%@ page import="org.dspace.core.ConfigurationManager" %>
<%@ page import="org.dspace.core.NewsManager" %>
<%@ page import="org.dspace.browse.ItemCounter" %>
<%@ page import="org.dspace.content.Metadatum" %>
<%@ page import="org.dspace.content.Item" %>
<%@ page import="org.dspace.discovery.configuration.DiscoveryViewConfiguration" %>
<%@ page import="org.dspace.app.webui.components.MostViewedBean"%>
<%@ page import="org.dspace.app.webui.components.MostViewedItem"%>
<%@ page import="org.dspace.discovery.SearchUtils"%>
<%@ page import="org.dspace.discovery.IGlobalSearchResult"%>
<%@ page import="org.dspace.core.Utils"%>
<%@ page import="org.dspace.content.Bitstream"%>
<%@ page import="org.dspace.app.webui.util.LocaleUIHelper" %>

<%
    Community[] communities = (Community[]) request.getAttribute("communities");

    Locale sessionLocale = UIUtil.getSessionLocale(request);
    Config.set(request.getSession(), Config.FMT_LOCALE, sessionLocale);
    String topNews = NewsManager.readNewsFile(LocaleSupport.getLocalizedMessage(pageContext, "news-top.html"));
    String sideNews = NewsManager.readNewsFile(LocaleSupport.getLocalizedMessage(pageContext, "news-side.html"));

    boolean feedEnabled = ConfigurationManager.getBooleanProperty("webui.feed.enable");
    String feedData = "NONE";
    if (feedEnabled)
    {
        feedData = "ALL:" + ConfigurationManager.getProperty("webui.feed.formats");
    }
    
    ItemCounter ic = new ItemCounter(UIUtil.obtainContext(request));

    RecentSubmissions submissions = (RecentSubmissions) request.getAttribute("recent.submissions");
    MostViewedBean mostViewedItem = (MostViewedBean) request.getAttribute("mostViewedItem");
    MostViewedBean mostCitedItem = (MostViewedBean) request.getAttribute("mostCitedItem");
    MostViewedBean mostViewedBitstream = (MostViewedBean) request.getAttribute("mostDownloadedItem");
    boolean isRtl = StringUtils.isNotBlank(LocaleUIHelper.ifLtr(request, "","rtl"));
%>

<script type="text/javascript" src="js/d3.4.min.js"></script>   
<dspace:layout locbar="nolink" titlekey="jsp.home.title" feedData="<%= feedData %>">
<div class="row">
	<div class="col-md-4 sm-12 pocDiv">
		<div class="vpora">
			<img src="image/openuns.png"><br>
			<span><%= topNews %></span>
		</div>
	</div>
	<div class="col-md-4 sm-12 pocDiv">
		<div class="vpora">
			<%
			int discovery_panel_cols = 8;
			int discovery_facet_cols = 4;
			boolean dali_ide_search = true;
			String processorSidebar = (String) request.getAttribute("processorSidebar");
			String processorGlobal = (String) request.getAttribute("processorGlobal");
			
		if(processorGlobal!=null && processorGlobal.equals("global")) {
			%>
		<%@ include file="discovery/static-globalsearch-component-facet.jsp" %>
		<% } %>        
			<form action="<%= request.getContextPath() %>/mydspace" method="post">
			    <input type="hidden" name="step" value="<%= MyDSpaceServlet.MAIN_PAGE %>" />
	            <input class="btn btn-success" type="submit" name="submit_new" value="<fmt:message key="jsp.mydspace.main.start.button"/>" />
			</form>
		</div>
	</div>
	<div class="col-md-4 sm-12"  id="repo-info">
		<%
		dali_ide_search = false;
		if(processorGlobal!=null && processorGlobal.equals("global")) {
			%>
		<%@ include file="discovery/static-globalsearch-component-facet.jsp" %>
		<% } %>        
	</div> 
</div> 
<div class="row">
	<div class="col-md-4 sm-12 <%= isRtl ? "pull-right":""%>">
		<%@ include file="components/most-downloaded.jsp" %>
	</div>
	<div class="col-md-4 sm-12 <%= isRtl ? "pull-right":""%>">
		<%@ include file="components/most-viewed.jsp" %>
	</div>
	<div class="col-md-4 sm-12 <%= isRtl ? "pull-right":""%>">
		<%@ include file="components/most-cited.jsp" %>
	</div>
</div>
<%
if (communities != null && communities.length != 0)
{
%>
<div class="row">
	<div class="col-md-5">		
               <h3><fmt:message key="jsp.home.com1"/></h3>
                <p><fmt:message key="jsp.home.com2"/></p>
				<div class="list-group">
<%
	boolean showLogos = ConfigurationManager.getBooleanProperty("jspui.home-page.logos", true);
    for (int i = 0; i < communities.length; i++)
    {
%><div class="list-group-item row">
<%  
		Bitstream logo = communities[i].getLogo();
		if (showLogos && logo != null) { %>
	<div class="col-md-3">
        <img alt="Logo" class="img-responsive" src="<%= request.getContextPath() %>/retrieve/<%= logo.getID() %>" /> 
	</div>
	<div class="col-md-9">
<% } else { %>
	<div class="col-md-12">
<% }  %>		
		<h4 class="list-group-item-heading"><a href="<%= request.getContextPath() %>/handle/<%= communities[i].getHandle() %>"><%= communities[i].getMetadata("name") %></a>
<%
        if (ConfigurationManager.getBooleanProperty("webui.strengths.show"))
        {
%>
		<span class="badge pull-right"><%= ic.getCount(communities[i]) %></span>
<%
        }

%>
		</h4>
		<p><%= communities[i].getMetadata("short_description") %></p>
    </div>
</div>                            
	
<%
}
}
    
    if(processorSidebar!=null && processorSidebar.equals("sidebar")) {
	%>
	<div class="col-md-7">
	<%@ include file="discovery/static-sidebar-facet.jsp" %>
	</div>
	<% } %>	
</div>
<div class="row">
	<%@ include file="discovery/static-tagcloud-facet.jsp" %>
</div>
<script type="text/javascript">

	function otvoriBlok (koji) {
		
		$(".panDesno").each(function() {
			
			idObj = $(this).attr("id");
			
			if(idObj == "blok"+koji) {
				$(this).slideToggle(300);
				$("#fa"+koji).toggleClass("fa-angle-double-down");
				$("#fa"+koji).toggleClass("fa-angle-double-up");
			}
			else {
				$(this).slideUp(300);
				$("#fa"+idObj).removeClass("fa-angle-double-up fa-angle-double-down").addClass("fa-angle-double-down");
			}
		
		});
		
	}

</script>
<style>
	
	/* STILOVI ZA FORCE DIRECTED */
	
	.link {
		stroke: #f1f1f1;
		stroke-width: 6px;
		fill: none;
	}
	.node circle {
		stroke-width: 3px;
		stroke:  #ffffff;
		cursor: pointer;
	}
	.node text {
		font-weight: 400;
		fill: #ffffff;
		cursor: pointer;
	}
	.node:hover .glavni, .node:hover text, .node text, .node circle {
		transition: all 0.30s linear 0s;
		-o-transition: all 0.30s linear 0s;
		-ms-transition: all 0.30s linear 0s;
		-moz-transition: all 0.30s linear 0s;
		-webkit-transition: all 0.30s linear 0s;
	}

</style>
<script type="text/javascript">

	var svg, simulation, repelForce, graf, link, node;
	var tooltip = d3.select("body")
		.append("div")
		.attr("class", "tooltip")
		.style("opacity", 0);		
	
	function nacrtaj() {

		// CRTA GRAF
		
		$("#repo-info").html("");
		
		svg = d3.select("#repo-info").append("svg")
			.attr("id", "kruzici")
			.attr("width", "100%")
			.attr("height", "100%");
			
		repelForce = d3.forceManyBody().strength(-350).distanceMax(350).distanceMin(50);
		simulation = d3.forceSimulation()
			.force("link", d3.forceLink().id(function(d) { return d.id; }).distance(function(d, i) { return d.duz; }))
			.force("repelForce",repelForce)
			.force("charge", d3.forceManyBody());

		link = svg.append("g").attr("class", "link").selectAll(".link");
		node = svg.append("g").selectAll(".node");

		link = link.data(graph.links, function(d) { return d.source.id + "-" + d.target.id; });
		link = link.enter().append("path");
		node = svg.selectAll(".node").data(graph.nodes).enter().append("g").attr("class","node");

		node.filter(function(d, i) { return i > 0 })
			.on('mouseover.tooltip', function(d) {
      			tooltip.transition()
        		.duration(300)
        		.style("opacity", 1);
      			tooltip.html(d.poruka)
        			.style("left", (d3.event.pageX+15) + "px")
		        	.style("top", (d3.event.pageY-10) + "px");
    		})
    		.on("mouseout.tooltip", function() {
	      		tooltip.transition()
	        		.duration(100)
	        		.style("opacity", 0);
	    	});

		node.call(d3.drag()
			.on("start", dragstarted)
			.on("drag", dragged)
			.on("end", dragended))
			.on("click", function(d,i) {
				vezaKrug = d.link;
				window.location = vezaKrug;
			});
					
		node.append("circle")
			.attr("class","glavni")
			.attr("id", function(d) { return "k"+d.id; })
			.style("fill", function(d) { return d.fill; })
			
		var ikonice = node.filter(function(d, i) { return i > 0 }).append("g");
		
		ikonice.append("circle")
			.attr("cx", -20)
			.attr("cy", -25)
			.attr("r", 16)
			.style("fill", function(d, i) { return d3.hsl(d.fill).darker(0.7);})
			.style("stroke", function(d, i) { return d.fill;})
			.style("stroke-width", "4px");

		ikonice
			.append("text")
			.attr("text-anchor", "middle")
			.attr("dy", -21)
			.attr("dx", -20)
			.text(function(d) { return d.ikona; })
			.style("fill", function(d, i) { return d3.hsl(d.fill).brighter(1.2);})
			.style("font-family", "FontAwesome")
			.style("font-size", "15px");

		
		node.filter(function(d, i) { return i == 0 })
			.append("svg:image")
			.attr("xlink:href", "image/samoo.png")
			.attr("x", -25)
			.attr("y", -25)
			.attr("height", 50)
			.attr("width", 50);

		node.append("text")
			.attr("text-anchor", "middle")
			.attr("dy", function(d) { return d.vel/3.5; })
			.attr("dx", 1)
			.text(function(d) { return d.tekst; })
			.style("font-size", "18px")

		simulation
			.nodes(graph.nodes)
			.on("tick", ticked);

		simulation.force("link")
			.links(graph.links);

	}
	
	function ticked() {
		
		// ITERIRANJE

		node.attr("transform", function(d,i) {
			cX = d.x;
			if (cX > $("#repo-info").innerWidth()) cX = $("#repo-info").innerWidth();
			if (cX < 10) cX = 10;
			cX = cX + 10;
			d.x = cX;
			cY = d.y;
			if (cY > $("#repo-info").innerHeight()) cY = $("#repo-info").innerHeight();
			if (cY < 20) cY = 20;
			cY = cY + 15;
			d.y = cY;
			return "translate(" + cX + "," + cY + ")";
		});

		link.attr("d", function(d) {
			var dx = d.target.x - d.source.x,
			dy = d.target.y - d.source.y,
			dr = Math.sqrt(dx * dx + dy * dy);
			return "M" + d.source.x + "," + d.source.y + "A" + dr + "," + dr + " 0 0,1 " + makniStrelicu(d)[0] + "," + makniStrelicu(d)[1];
		});

		function makniStrelicu(d){

			var t_radius = d.target.vel ^ 0.5; 
			var dx = d.target.x - d.source.x;
			var dy = d.target.y - d.source.y;
			var gamma = Math.atan2(dy,dx)+0.5; 
			var tx = d.target.x - (Math.cos(gamma) * t_radius);
			var ty = d.target.y - (Math.sin(gamma) * t_radius);
			return [tx,ty]; 

		}	

	}

	function dragstarted(d) {
		
		if (!d3.event.active) simulation.alphaTarget(0.3).restart();
		d.fx = d.x;
		d.fy = d.y;
	
	}

	function dragged(d) {

		d.fx = d3.event.x;
		d.fy = d3.event.y;
	
	}

	function dragended(d) {
		
		if (!d3.event.active) simulation.alphaTarget(0);
		d.fx = null;
		d.fy = null;
		
	}

	jQuery(document).ready(function($) {  
	
		//  KADA JE SVE SPREMNO PUSTA GRAF

		if (typeof repoInfo === 'undefined') return;
		
		var cvorovi = [{"id": "repo", "tekst": "", "vel": 20, "fill": "#ffffff", "link": ""}];
		var cvoroviIkone = [{}];
		var veze = [];

		var boje = ["#e62738", "#ffcb00", "#6f8a91", "#5bc3cd", "#66a53c", "#6f8a91", "#6f8a91"];

		for (nod=0;nod<repoInfo.length;nod++) {
			switch (repoInfo[nod].kljuc) {
				case "publications":
					ikona = "\uf0f6";
					break;
				case "theses":
					ikona = "\uf19d";
					break;
				case "patents":
					ikona = "\uf0eb";
					break;
				case "datasets":
					ikona = "\uf1c0";
					break;
				case "conferencematerials":
					ikona = "\uf130";
					break;
				case "community":
					ikona = "\uf0c0";
					break;
				case "collection":
					ikona = "\uf0c5";
					break;
				case "researcherprofiles":
					ikona = "\uf007";
					break;
				case "orgunits":
					ikona = "\uf19c";
					break;
				case "fundings":
					ikona = "\uf153";
					break;
				default:
					ikona = "\uf118";
					break;
			}
			cvorovi.push ({"ikona": ikona, "poruka": repoInfo[nod].poruka, "tip": "tekst", "id": "nod"+nod, "tekst": repoInfo[nod].broj, "vel": 27, "fill": boje[nod], "link": repoInfo[nod].link});
			veze.push ({"source": "nod"+nod, "target": "repo", "duz": 80});
		}

		graph = {nodes: cvorovi, links: veze};

		nacrtaj();
		velicina();

	});	
	
	function otvoriLink (koji) {
		if(koji.indexOf("http") > -1) {
			window.open(koji, "_blank");
		}
		else {
			window.location = koji;
		}
	}
	
	// PROMENA VELICINE PROZORA
	
	$(window).resize(function() {
		velicina();
	});     

	function velicina (dali) {
		
		// MENJA VELICINU GRAFA

		$("#repo-info").css("height", $("#vesti").innerHeight());
		if ($("#repo-info").innerHeight() > $("#repo-info").innerWidth()) $("#repo-info").css("height", $("#repo-info").innerWidth());
		if (simulation) {
			sirina = $("#repo-info").innerWidth();
			visina = $("#repo-info").innerHeight();
			$("#kruzici").css("height", visina);
			racio = sirina / visina;
			koef = sirina/100;
			d3.selectAll(".glavni").attr("r", function(d) { return d.vel + koef;})
			//d3.selectAll("text").style("font-size",function(d) { return (d.vel + (koef*0)) + "px";})
			simulation.force("link").distance(function(d, i) { return d.duz * (racio >= 1 ? 1 : racio); });
			simulation.force("center", d3.forceCenter(sirina * 0.45, visina * 0.5)); 
			simulation.alpha(1.5).restart(); 
		}
	} 
	
</script> 
</dspace:layout>
