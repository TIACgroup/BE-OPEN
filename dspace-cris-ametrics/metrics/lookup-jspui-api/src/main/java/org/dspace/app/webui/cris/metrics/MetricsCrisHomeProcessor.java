/**
 * The contents of this file are subject to the license and copyright
 * detailed in the LICENSE and NOTICE files at the root of the source
 * tree and available online at
 *
 * https://github.com/CILEA/dspace-cris/wiki/License
 */
package org.dspace.app.webui.cris.metrics;
import java.sql.SQLException;
import java.util.ArrayList;
import java.util.Date;
import java.util.HashMap;
import java.util.Iterator;
import java.util.List;
import java.util.Map;

import javax.servlet.http.HttpServletRequest;
import javax.servlet.http.HttpServletResponse;

import org.apache.log4j.Logger;
import org.apache.solr.client.solrj.SolrQuery;
import org.apache.solr.client.solrj.response.QueryResponse;
import org.apache.solr.common.SolrDocument;
import org.apache.solr.common.SolrDocumentList;
import org.dspace.app.cris.metrics.common.model.ConstantMetrics;
import org.dspace.app.cris.model.ACrisObject;
import org.dspace.app.cris.util.ICrisHomeProcessor;
import org.dspace.authorize.AuthorizeException;
import org.dspace.content.Item;
import org.dspace.core.Constants;
import org.dspace.core.Context;
import org.dspace.core.LogManager;
import org.dspace.discovery.SearchService;
import org.dspace.discovery.SearchServiceException;
import org.dspace.plugin.PluginException;
import org.dspace.utils.DSpace;

public class MetricsCrisHomeProcessor<ACO extends ACrisObject> implements ICrisHomeProcessor<ACO> {
	private Logger log = Logger.getLogger(this.getClass());
	private List<Integer> rankingLevels;
	private List<String> metricTypes;
	private Class<ACO> clazz;
	private SearchService searchService;
	private MetricsProcessorConfigurator configurator;
	
	@Override
	public void process(Context context, HttpServletRequest request, HttpServletResponse response, ACO item)
			throws PluginException, AuthorizeException {

		SolrQuery query = new SolrQuery("author_authority:" + item.getCrisID());
	    SolrQuery solrQuery = new SolrQuery();

		solrQuery.setQuery("search.uniqueid:"+ item.getType() + "-"+item.getID());
		solrQuery.setRows(1);
		String field = ConstantMetrics.PREFIX_FIELD;
        for (String t : metricTypes) {
			solrQuery.addField(field+t);
			solrQuery.addField(field+t+"_last1");
			solrQuery.addField(field+t+"_last2");
			solrQuery.addField(field+t+"_ranking");
			solrQuery.addField(field+t+"_remark");
			solrQuery.addField(field+t+"_time");
		}
		try {
			QueryResponse resp = searchService.search(solrQuery);
			if (resp.getResults().getNumFound() != 1) {
				return;
			}
			SolrDocument doc = resp.getResults().get(0);
			List<ItemMetricsDTO> metricsList = new ArrayList<ItemMetricsDTO>();
			for (String t : metricTypes) {
				ItemMetricsDTO dto = new ItemMetricsDTO();
				dto.type=t;
				dto.setFormatter(configurator.getFormatter(t));
				dto.counter=(Double) doc.getFieldValue(field+t);
				dto.last1=(Double) doc.getFieldValue(field+t+"_last1");
				dto.last2=(Double) doc.getFieldValue(field+t+"_last2");;
				dto.ranking=(Double) doc.getFieldValue(field+t+"_ranking");
				dto.time=(Date) doc.getFieldValue(field+t+"_time");
				if (dto.ranking != null) {
					for (int lev : rankingLevels) {
						if ((dto.ranking * 100) < lev) {
							dto.rankingLev = lev;
							break;
						}
					}
				}
				dto.moreLink=(String) doc.getFieldValue(field+t+"_remark");
				metricsList.add(dto);
			}

			SolrDocumentList docList = searchService.search(query).getResults();
			Iterator<SolrDocument> solrDoc = docList.iterator();
			Integer viewCounter = 0;
			Integer downloadCounter = 0;
			while (solrDoc.hasNext())
			{
				SolrDocument docWithPublication = solrDoc.next();
				Integer itemId = (Integer) docWithPublication.getFirstValue("search.resourceid");
				try {
					Item publication = Item.find(context, itemId);
					Double[] values = getPageViewsAndDownloads(context, publication);
					viewCounter += values[0].intValue();
					downloadCounter += values[1].intValue();;

				} catch (SQLException e) {
					log.error(LogManager.getHeader(context, "MetricsItemHomeProcessor", e.getMessage()), e);
				}
			}

			Map<String, ItemMetricsDTO> metrics = getMapFromList(metricsList);
			Map<String, Object> extra = new HashMap<String, Object>();
			Map<String, Object> extraTotal = new HashMap<String, Object>();
			extraTotal.put("views", viewCounter);
			extraTotal.put("downloads", downloadCounter);
			extra.put("metricTypes", metricTypes);
			extra.put("metrics", metrics);
			request.setAttribute("extraTotal", extraTotal);
			request.setAttribute("extra", extra);
		} catch (SearchServiceException e) {
			log.error(LogManager.getHeader(context, "MetricsItemHomeProcessor", e.getMessage()), e);
		}
	}

	private Double[] getPageViewsAndDownloads(Context context, Item item) {
		Double[] values = new Double[2];
		int[] rankingLevels;
		List<String> metricTypes;

		String levels = "1,5,10,20,50";
		String[] split = levels.split(",");
		rankingLevels = new int[split.length];
		for (int idx = 0; idx < split.length; idx++) {
			rankingLevels[idx] = Integer.parseInt(split[idx].trim());
		}

		String metricTypesConf = "scopus,wos,view,download";
		String[] splitTypes = metricTypesConf.split(",");
		metricTypes = new ArrayList<String>();
		for (int idx = 0; idx < splitTypes.length; idx++) {
			metricTypes.add(splitTypes[idx].trim());
		}

		SearchService searchService = new DSpace().getServiceManager().getServiceByName(SearchService.class.getName(),
				SearchService.class);
		SolrQuery solrQuery = new SolrQuery();
		solrQuery.setQuery("search.uniqueid:" + Constants.ITEM + "-" + item.getID());
		solrQuery.setRows(1);
		String prefixField = ConstantMetrics.PREFIX_FIELD;
		for (String t : metricTypes) {
			solrQuery.addField(prefixField + t);
			solrQuery.addField(prefixField + t + "_last1");
			solrQuery.addField(prefixField + t + "_last2");
			solrQuery.addField(prefixField + t + "_ranking");
			solrQuery.addField(prefixField + t + "_remark");
			solrQuery.addField(prefixField + t + "_time");
		}
		try {
			QueryResponse resp = searchService.search(solrQuery);
			SolrDocument doc = resp.getResults().get(0);
			values[0] = (Double) doc.getFieldValue("crismetrics_view");
			values[1] = (Double) doc.getFieldValue("crismetrics_download");

		} catch (SearchServiceException e) {
			log.error(LogManager.getHeader(context, "MetricsItemHomeProcessor", e.getMessage()), e);
		}
		return values;
	}

	private Map<String, ItemMetricsDTO> getMapFromList(List<ItemMetricsDTO> metricsList) {
		Map<String, ItemMetricsDTO> result = new HashMap<String, ItemMetricsDTO>();
		for (ItemMetricsDTO dto : metricsList) {
			result.put(dto.type, dto);
		}
		return result;
	}

    public List<Integer> getRankingLevels()
    {
        return rankingLevels;
    }

    public void setRankingLevels(List<Integer> rankingLevels)
    {
        this.rankingLevels = rankingLevels;
    }

    public List<String> getMetricTypes()
    {
        return metricTypes;
    }

    public void setMetricTypes(List<String> metricTypes)
    {
        this.metricTypes = metricTypes;
    }

    public Class<ACO> getClazz()
    {
        return clazz;
    }

    public void setClazz(Class<ACO> clazz)
    {
        this.clazz = clazz;
    }

    public SearchService getSearchService()
    {
        return searchService;
    }

    public void setSearchService(SearchService searchService)
    {
        this.searchService = searchService;
    }

    public void setConfigurator(MetricsProcessorConfigurator configurator)
    {
        this.configurator = configurator;
    }
}