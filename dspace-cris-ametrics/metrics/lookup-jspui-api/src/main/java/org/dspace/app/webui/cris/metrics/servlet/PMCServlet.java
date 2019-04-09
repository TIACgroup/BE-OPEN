/**
 * The contents of this file are subject to the license and copyright
 * detailed in the LICENSE and NOTICE files at the root of the source
 * tree and available online at
 *
 * https://github.com/CILEA/dspace-cris/wiki/License
 */
package org.dspace.app.webui.cris.metrics.servlet;


import java.io.IOException;
import java.sql.SQLException;

import javax.servlet.ServletException;
import javax.servlet.http.HttpServletRequest;
import javax.servlet.http.HttpServletResponse;

import org.dspace.app.cris.metrics.common.services.MetricsPersistenceService;
import org.dspace.app.cris.metrics.pmc.model.PMCCitation;
import org.dspace.app.webui.servlet.DSpaceServlet;
import org.dspace.app.webui.util.JSPManager;
import org.dspace.app.webui.util.UIUtil;
import org.dspace.authorize.AuthorizeException;
import org.dspace.core.Context;
import org.dspace.kernel.ServiceManager;
import org.dspace.utils.DSpace;

public class PMCServlet extends DSpaceServlet
{
    DSpace dspace = new DSpace();

    ServiceManager serviceManager = dspace.getServiceManager();

    MetricsPersistenceService pservice = serviceManager.getServiceByName(
    		MetricsPersistenceService.class.getName(), MetricsPersistenceService.class);

    @Override
    protected void doDSGet(Context context, HttpServletRequest request,
            HttpServletResponse response) throws ServletException, IOException,
            SQLException, AuthorizeException
    {
        Integer itemID = UIUtil.getIntParameter(request, "item_id");
        Integer pmid = UIUtil.getIntParameter(request, "pmid");
        if (itemID != -1)
        {
            PMCCitation citation = pservice.getPMCCitationByItemID(itemID);
            request.setAttribute("pmccitation", citation);
            JSPManager.showJSP(request, response,
                    "/ametrics/pubmed/pmc-citation.jsp");
        }
        else if (pmid != -1)
        {
            PMCCitation citation = pservice.get(PMCCitation.class, pmid);
            request.setAttribute("pmccitation", citation);
            JSPManager.showJSP(request, response,
                    "/ametrics/pubmed/pmc-citation-details.jsp");
        }
        return;
    }
}
