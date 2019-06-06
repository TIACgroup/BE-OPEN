<%--

    The contents of this file are subject to the license and copyright
    detailed in the LICENSE and NOTICE files at the root of the source
    tree and available online at

    http://www.dspace.org/license/

--%>
<%--
  - Show the user the Creative Commons license which they may grant or reject
  -
  - Attributes to pass in:
  -    cclicense.exists   - boolean to indicate CC license already exists
  --%>

<%@ page contentType="text/html;charset=UTF-8" %>

<%@ taglib uri="http://java.sun.com/jsp/jstl/fmt"
    prefix="fmt" %>

<%@ page import="org.dspace.core.Context" %>
<%@ page import="org.dspace.app.webui.servlet.SubmissionController" %>
<%@ page import="org.dspace.submit.AbstractProcessingStep" %>
<%@ page import="org.dspace.app.util.SubmissionInfo" %>
<%@ page import="org.dspace.app.webui.util.UIUtil" %>
<%@ page import="org.dspace.license.CreativeCommons" %>
<%@ page import="org.dspace.core.ConfigurationManager" %>
<%@ page import="org.dspace.license.CCLicense"%>
<%@ page import="java.util.Collection"%>

<%@ taglib uri="http://www.dspace.org/dspace-tags.tld" prefix="dspace" %>

<%
    request.setAttribute("LanguageSwitch", "hide");

    // Obtain DSpace context
    Context context = UIUtil.obtainContext(request);    

	//get submission information object
    SubmissionInfo subInfo = SubmissionController.getSubmissionInfo(context, request);

    Boolean lExists = (Boolean)request.getAttribute("cclicense.exists");
    boolean licenseExists = (lExists == null ? false : lExists.booleanValue());

    Collection<CCLicense> cclicenses = (Collection<CCLicense>)request.getAttribute("cclicense.licenses");
    
    String licenseURL = "";
    if(licenseExists)
        licenseURL = CreativeCommons.getLicenseURL(subInfo.getSubmissionItem().getItem());
%>

<dspace:layout style="submission"
			   locbar="off"
               navbar="off"
               titlekey="jsp.submit.creative-commons.title"
               nocache="true">

    <form name="foo" id="license_form" action="<%= request.getContextPath() %>/submit" method="post" onkeydown="return disableEnterKey(event);">

        <jsp:include page="/submit/progressbar.jsp"/>

        <%-- <h1>Submit: Use a Creative Commons License</h1> --%>
		<h1><fmt:message key="jsp.submit.creative-commons.heading"/></h1>

		<p class="help-block"><fmt:message key="jsp.submit.creative-commons.info1"/></p>

	<div class="row">
        <table class="table">
            <thead>
              <tr>
                <th scope="col"></th>
                <th scope="col"><fmt:message key="jsp.creative-commons.heading.title"/></th>
                <th scope="col"><fmt:message key="jsp.creative-commons.heading.description"/></th>
                <th scope="col"><fmt:message key="jsp.creative-commons.heading.selection"/></th>
              </tr>
            </thead>
            <tbody>
              <tr>
                <td><img src="image/creative-commons-zero.png" alt=""></td>
                <td><a href="https://creativecommons.org/publicdomain/zero/1.0/" target="_blank"><fmt:message key="jsp.creative-commons.license.zero"/></a></td>
                <td><fmt:message key="jsp.creative-commons.description.zero"/></td>
                <td><input type="radio" name="license-radio" value="zero"></td>
              </tr>
              <tr>
                <td><img src="image/creative-commons-by.png" alt=""></td>
                <td><a href="https://creativecommons.org/licenses/by/3.0/rs/deed.sr_LATN" target="_blank"><fmt:message key="jsp.creative-commons.license.by"/></a></td>
                <td><fmt:message key="jsp.creative-commons.description.by"/></td>
                <td><input type="radio" name="license-radio" value="by"></td>
              </tr>
              <tr>
                <td><img src="image/creative-commons-by-sa.png" alt=""></td>
                <td><a href="https://creativecommons.org/licenses/by-sa/3.0/rs/deed.sr_LATN" target="_blank"><fmt:message key="jsp.creative-commons.license.by-sa"/></a></td>
                <td><fmt:message key="jsp.creative-commons.description.by-sa"/></td>
                <td><input type="radio" name="license-radio" value="by-sa"></td>
              </tr>
              <tr>
                <td><img src="image/creative-commons-by-nd.png" alt=""></td>
                <td><a href="https://creativecommons.org/licenses/by-nd/3.0/rs/deed.sr_LATN" target="_blank"><fmt:message key="jsp.creative-commons.license.by-nd"/></a></td>
                <td><fmt:message key="jsp.creative-commons.description.by-nd"/></td>
                <td><input type="radio" name="license-radio" value="by-nd"></td>
              </tr>
              <tr>
                <td><img src="image/creative-commons-by-nc.png" alt=""></td>
                <td><a href="https://creativecommons.org/licenses/by-nc/3.0/rs/deed.sr_LATN" target="_blank"><fmt:message key="jsp.creative-commons.license.by-nc"/></a></td>
                <td><fmt:message key="jsp.creative-commons.description.by-nc"/></td>
                <td><input type="radio" name="license-radio" value="by-nc"></td>
              </tr>
              <tr>
                <td><img src="image/creative-commons-by-nc-sa.png" alt=""></td>
                <td><a href="https://creativecommons.org/licenses/by-nc-sa/3.0/rs/deed.sr_LATN" target="_blank"><fmt:message key="jsp.creative-commons.license.by-nc-sa"/></a></td>
                <td><fmt:message key="jsp.creative-commons.description.by-nc-sa"/></td>
                <td><input type="radio" name="license-radio" value="by-nc-sa"></td>
              </tr>
              <tr>
                <td><img src="image/creative-commons-by-nc-nd.png" alt=""></td>
                <td><a href="https://creativecommons.org/licenses/by-nc-nd/3.0/rs/deed.sr_LATN" target="_blank"><fmt:message key="jsp.creative-commons.license.by-nc-nd"/></a></td>
                <td><fmt:message key="jsp.creative-commons.description.by-nc-nd"/></td>
                <td ><input type="radio" name="license-radio" value="by-nc-nd"></td>
              </tr>
            </tbody>
          </table>

          <div class="pull-right">
              <label class="form-check-label" for="license-radio"><fmt:message key="jsp.creative-commons.license.none"/></label>
            <input class="form-check-input" type="radio" name="license-radio" value="none" checked>
          </div>
	</div>
	<% if(licenseExists) { %>
	<div class="row" id="current_creativecommons">
		<label class="col-md-2"><fmt:message key="jsp.submit.creative-commons.license.current"/></label>
		<span class="col-md-8">
			<a href="<%=licenseURL %>"><%=licenseURL %></a>
		</span>
	</div>
	<% } %>
        <%--
	<div style="display:none;" id="creativecommons_response">
	</div>
        --%>
	<br/>
        
        <%-- Hidden inputs used for custom CC license step --%>
        <input type="hidden" name="licenseclass_chooser" id="licenseclass_chooser"/>
        <input type="hidden" name="commercial_chooser" id="commercial_chooser"/>
        <input type="hidden" name="derivatives_chooser" id="derivatives_chooser"/>
        
		<%-- Hidden fields needed for SubmissionController servlet to know which step is next--%>
    <%= SubmissionController.getSubmissionParameters(context, request) %>

	<input type="hidden" name="cc_license_url" value="<%=licenseURL %>" />
    <input type="submit" id="submit_grant" name="submit_grant" value="submit_grant" style="display: none;" />
	<%
		int numButton = 2 + (!SubmissionController.isFirstStep(request, subInfo)?1:0) + (licenseExists?1:0);

	%>
    <div class="row col-md-<%= 2*numButton %> pull-right btn-group">
                <%  //if not first step, show "Previous" button
					if(!SubmissionController.isFirstStep(request, subInfo))
					{ %>
			<input class="btn btn-default col-md-<%= 12 / numButton %>" type="submit" name="<%=AbstractProcessingStep.PREVIOUS_BUTTON%>" value="<fmt:message key="jsp.submit.general.previous"/>" />
                <%  } %>

            <input class="btn btn-default col-md-<%= 12 / numButton %>" type="submit" name="<%=AbstractProcessingStep.CANCEL_BUTTON%>" value="<fmt:message key="jsp.submit.general.cancel-or-save.button"/>"/>
			<input class="btn btn-primary col-md-<%= 12 / numButton %>" type="submit" name="<%=AbstractProcessingStep.NEXT_BUTTON%>" value="<fmt:message key="jsp.submit.general.next"/>" />
    </div>

    <input type="hidden" name="pageCallerID" value="<%= request.getAttribute("pageCallerID")%>"/>
    </form>
    <script type="text/javascript">

jQuery('input[type=radio][name=license-radio]').change(function() {
  switch(this.value) {
    case 'zero':
        jQuery('#licenseclass_chooser').val('publicdomain');
        jQuery('#commercial_chooser').val('');
        jQuery('#derivatives_chooser').val('');
        break;
    case 'by':
        jQuery('#licenseclass_chooser').val('standard');
        jQuery('#commercial_chooser').val('y');
        jQuery('#derivatives_chooser').val('y');
        break;
    case 'by-sa':
        jQuery('#licenseclass_chooser').val('standard');
        jQuery('#commercial_chooser').val('y');
        jQuery('#derivatives_chooser').val('sa');
        break;
    case 'by-nd':
        jQuery('#licenseclass_chooser').val('standard');
        jQuery('#commercial_chooser').val('y');
        jQuery('#derivatives_chooser').val('n');
        break;
    case 'by-nc':
        jQuery('#licenseclass_chooser').val('standard');
        jQuery('#commercial_chooser').val('n');
        jQuery('#derivatives_chooser').val('y');
        break;
    case 'by-nc-sa':
        jQuery('#licenseclass_chooser').val('standard');
        jQuery('#commercial_chooser').val('n');
        jQuery('#derivatives_chooser').val('sa');
        break;
    case 'by-nc-nd':
        jQuery('#licenseclass_chooser').val('standard');
        jQuery('#commercial_chooser').val('n');
        jQuery('#derivatives_chooser').val('n');
        break;
    case 'none':
        jQuery('#licenseclass_chooser').val('webui.Submission.submit.CCLicenseStep.no_license');
        jQuery('#commercial_chooser').val('');
        jQuery('#derivatives_chooser').val('');
        break;
  }
});


</script>
</dspace:layout>