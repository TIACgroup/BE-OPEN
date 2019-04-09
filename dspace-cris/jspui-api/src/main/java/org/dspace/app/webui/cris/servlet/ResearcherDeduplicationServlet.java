package org.dspace.app.webui.cris.servlet;

import org.dspace.app.cris.model.ResearcherPage;
import org.dspace.app.cris.model.dto.ResearcherPageDTO;
import org.dspace.app.cris.rpdeduplication.service.ResearcherMergeService;
import org.dspace.app.cris.rpdeduplication.service.impl.ResearcherMergeServiceImpl;
import org.dspace.app.webui.discovery.DiscoverUtility;
import org.dspace.app.webui.servlet.DSpaceServlet;
import org.dspace.app.webui.util.JSPManager;
import org.dspace.content.DSpaceObject;
import org.dspace.core.Context;
import org.dspace.discovery.DiscoverQuery;
import org.dspace.discovery.DiscoverResult;
import org.dspace.discovery.SearchServiceException;
import org.dspace.discovery.SearchUtils;
import org.dspace.discovery.configuration.DiscoveryConfiguration;
import org.dspace.utils.DSpace;

import javax.servlet.ServletException;
import javax.servlet.http.HttpServletRequest;
import javax.servlet.http.HttpServletResponse;
import java.io.IOException;
import java.util.ArrayList;
import java.util.List;

public class ResearcherDeduplicationServlet extends DSpaceServlet {

    @Override
    protected void doDSGet(Context context, HttpServletRequest request, HttpServletResponse response) throws ServletException, IOException {

        String query = request.getParameter("query");

        if (query != null && !query.isEmpty()) {
            List<ResearcherPageDTO> resultList = doSimpleSearch(context, request);

            if (resultList != null && !resultList.isEmpty()) {
                request.setAttribute("resultList", resultList);
            }
        }

        JSPManager.showJSP(request, response,
                "/rp-deduplication/researcher-deduplication.jsp");
    }

    @Override
    protected void doDSPost(Context context, HttpServletRequest request, HttpServletResponse response) throws ServletException, IOException {
        String original = request.getParameter("original");
        String duplikati = request.getParameter("duplikati");

        String[] duplikatiNiz = duplikati.split(",");

        DSpace dspace = new DSpace();
        ResearcherMergeService researcherMergeService = dspace.getServiceManager().getServiceByName("researcherMergeService", ResearcherMergeServiceImpl.class);

        Boolean success = researcherMergeService.merge(original, duplikatiNiz);

        request.setAttribute("success", success);

        JSPManager.showJSP(request, response,
                "/rp-deduplication/researcher-deduplication.jsp");
    }

    private List<ResearcherPageDTO> doSimpleSearch(Context context, HttpServletRequest request) {
        List<ResearcherPageDTO> resultList = null;

        String configurationName = "researcherprofiles";

        DiscoveryConfiguration discoveryConfiguration = SearchUtils.getDiscoveryConfigurationByName(configurationName);

        DiscoverQuery queryArgs = DiscoverUtility.getDiscoverQuery(context, request, null, configurationName, true);

        queryArgs.setSpellCheck(discoveryConfiguration.isSpellCheckEnabled());

        // Perform the search
        DiscoverResult qResults = null;
        try {
            qResults = SearchUtils.getSearchService().search(context, null, queryArgs);

            if (qResults.getDspaceObjects() != null && !qResults.getDspaceObjects().isEmpty()) {
                resultList = new ArrayList<>();

                for (DSpaceObject dso : qResults.getDspaceObjects()) {
                    ResearcherPage rp = (ResearcherPage) dso;
                    ResearcherPageDTO rpDTO = new ResearcherPageDTO();

                    rpDTO.setSourceID(rp.getCrisID());
                    rpDTO.setFullName(rp.getName());

                    resultList.add(rpDTO);
                }

                request.setAttribute("resultList", resultList);
            }

        } catch (SearchServiceException e) {
            request.setAttribute("search.error", true);
            request.setAttribute("search.error.message", e.getMessage());
        }

        return resultList;
    }
}
