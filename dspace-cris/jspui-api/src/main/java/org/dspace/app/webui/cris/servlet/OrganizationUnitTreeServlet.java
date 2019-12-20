package org.dspace.app.webui.cris.servlet;

import org.apache.log4j.Logger;
import org.dspace.app.cris.util.OrganizationUnitTreeMaker;
import org.dspace.app.webui.servlet.DSpaceServlet;
import org.dspace.authorize.AuthorizeException;
import org.dspace.core.Context;

import javax.servlet.ServletException;
import javax.servlet.http.HttpServletRequest;
import javax.servlet.http.HttpServletResponse;
import java.io.IOException;
import java.io.PrintWriter;
import java.sql.SQLException;

public class OrganizationUnitTreeServlet extends DSpaceServlet
{

    private Logger log = Logger.getLogger(OrganizationUnitTreeServlet.class);
    private OrganizationUnitTreeMaker treeMaker = OrganizationUnitTreeMaker.getInstance();

    @Override
    protected void doDSGet(Context context, HttpServletRequest request,
                           HttpServletResponse response) throws ServletException, IOException,
            SQLException, AuthorizeException
    {
        response.setHeader("Content-Type", "text/html; charset=UTF-8");
        
        try(PrintWriter pw = response.getWriter()) {
           pw.write(treeMaker.getTreeAsHTML());
           pw.flush();
        }
    }

}
