package org.dspace.app.webui.cris.servlet;

import java.io.IOException;
import java.sql.SQLException;
import java.text.SimpleDateFormat;
import java.util.ArrayList;
import java.util.Arrays;
import java.util.Collections;
import java.util.Date;
import java.util.Enumeration;
import java.util.HashMap;
import java.util.HashSet;
import java.util.Iterator;
import java.util.LinkedList;
import java.util.List;
import java.util.Map;
import java.util.Set;
import java.util.StringTokenizer;

import javax.mail.MessagingException;
import javax.servlet.ServletException;
import javax.servlet.http.HttpServletRequest;
import javax.servlet.http.HttpServletResponse;

import org.apache.commons.lang3.StringUtils;
import org.apache.log4j.Logger;
import org.apache.lucene.search.spell.JaroWinklerDistance;
import org.dspace.app.cris.integration.BindItemToRP;
import org.dspace.app.cris.model.ResearcherPage;
import org.dspace.app.cris.service.ApplicationService;
import org.dspace.app.cris.util.Researcher;
import org.dspace.app.cris.util.ResearcherPageUtils;
import org.dspace.app.webui.servlet.DSpaceServlet;
import org.dspace.app.webui.util.JSPManager;
import org.dspace.app.webui.util.UIUtil;
import org.dspace.authorize.AuthorizeException;
import org.dspace.content.DSpaceObject;
import org.dspace.content.Item;
import org.dspace.content.MetadataField;
import org.dspace.content.MetadataSchema;
import org.dspace.content.Metadatum;
import org.dspace.content.authority.Choice;
import org.dspace.content.authority.ChoiceAuthorityManager;
import org.dspace.content.authority.Choices;
import org.dspace.core.ConfigurationManager;
import org.dspace.core.Context;
import org.dspace.core.I18nUtil;
import org.dspace.core.LogManager;
import org.dspace.core.Utils;
import org.dspace.discovery.SearchServiceException;
import org.dspace.discovery.SearchUtils;
import org.dspace.discovery.configuration.DiscoveryViewAndHighlightConfiguration;
import org.dspace.eperson.EPerson;
import org.dspace.eperson.Group;
import org.dspace.handle.HandleManager;
import org.dspace.utils.DSpace;

import it.cilea.osd.common.constants.Constants;

public class AuthorityClaimServlet extends DSpaceServlet
{

    private static final String[] METADATA_MESSAGE = new String[] { "local",
            "message", "claim" };

    private static final String PUBLICATION_CLAIMED_UNCERTAIN = "publication-claimed-uncertain";

    private static final String PUBLICATION_REQUEST_FOR_CLAIM = "publication-claimed-requested";

    private static final String PUBLICATION_CLAIMED_USER = "publication-claimed-user";

    private static final SimpleDateFormat sdf = new SimpleDateFormat(
            "yyyy-MM-dd'T'HH:mm:ss.SSSZ");

    private Logger log = Logger.getLogger(AuthorityClaimServlet.class);

    private DSpace dspace = new DSpace();
    
    private ApplicationService applicationService = dspace.getServiceManager()
            .getServiceByName("applicationService",
                    ApplicationService.class);
    
    @Override
    protected void doDSGet(Context context, HttpServletRequest request,
            HttpServletResponse response) throws ServletException, IOException,
            SQLException, AuthorizeException
    {

        String handle = request.getParameter("handle");
        String crisID = (String) request
                .getAttribute("requesterMapPublication");

        // find list of match
        DiscoveryViewAndHighlightConfiguration discoveryViewAndHighlightConfigurationByName = SearchUtils
                .getDiscoveryViewAndHighlightConfigurationByName("global");

        request.setAttribute("viewMetadata",
                discoveryViewAndHighlightConfigurationByName
                        .getViewConfiguration());
        request.setAttribute("selectorViewMetadata",
                discoveryViewAndHighlightConfigurationByName.getSelector());

        if (StringUtils.isBlank(crisID))
        {
            crisID = context.getCrisID();
        }
        List<Item> publications = (List<Item>) request
                .getAttribute("publicationList");
        if (publications != null)
        {
            showListClaim(context, request, response, crisID, publications);
        }
        else
        {
            Map<String, List<String[]>> result = new HashMap<String, List<String[]>>();
            Map<String, Boolean> haveSimilar = new HashMap<String, Boolean>();
            showAuthorityClaim(context, request, response, handle, crisID,
                    result, haveSimilar);
        }

    }

    private void showListClaim(Context context, HttpServletRequest request,
            HttpServletResponse response, String crisID,
            List<Item> publications)
            throws SQLException, ServletException, IOException
    {
        Map<String, Map<String, List<String[]>>> mapResult = new HashMap<String, Map<String, List<String[]>>>();
        Map<String, Map<String, Boolean>> haveSimilarResult = new HashMap<String, Map<String, Boolean>>();
        Map<String, DSpaceObject> mapItem = new HashMap<String, DSpaceObject>();
        ResearcherPage rp = applicationService.getEntityByCrisId(crisID, ResearcherPage.class);
        for (Item ii : publications)
        {
            Map<String, List<String[]>> result = new HashMap<String, List<String[]>>();
            Map<String, Boolean> haveSimilar = new HashMap<String, Boolean>();
            String handle = ii.getHandle();
            internalDoResult(context, handle, crisID, result, haveSimilar, rp);
            mapResult.put(handle, result);
            mapItem.put(handle, HandleManager.resolveToObject(context, handle));
            haveSimilarResult.put(handle, haveSimilar);
        }

        log.info(LogManager.getHeader(context, "show_authority_claim_list",
                null));
        request.setAttribute("items", mapItem);
        request.setAttribute("result", mapResult);
        request.setAttribute("haveSimilar", haveSimilarResult);
        request.setAttribute("crisID", crisID);

        JSPManager.showJSP(request, response,
                "/tools/authority-claim-list.jsp");

    }

    private void showAuthorityClaim(Context context, HttpServletRequest request,
            HttpServletResponse response, String handle, String crisID,
            Map<String, List<String[]>> result,
            Map<String, Boolean> haveSimilar)
            throws SQLException, ServletException, IOException
    {

        ResearcherPage rp = applicationService.getEntityByCrisId(crisID, ResearcherPage.class);
        
        internalDoResult(context, handle, crisID, result, haveSimilar, rp);

        request.setAttribute("item",
                HandleManager.resolveToObject(context, handle));
        request.setAttribute("result", result);
        request.setAttribute("handle", handle);
        request.setAttribute("haveSimilar", haveSimilar);
        request.setAttribute("crisID", crisID);

        log.info(LogManager.getHeader(context, "show_authority_claim",
                "#keys: " + result.size()));

        JSPManager.showJSP(request, response, "/tools/authority-claim.jsp");
    }

    private void internalDoResult(Context context, String handle, String crisID,
            Map<String, List<String[]>> result,
            Map<String, Boolean> haveSimilar, ResearcherPage rp) throws SQLException
    {
        
        JaroWinklerDistance jaroWinklerDistance = new JaroWinklerDistance();
        double checksimilarity = 0.9;
        
        if (StringUtils.isNotBlank(handle))
        {

            Item item = (Item) (HandleManager.resolveToObject(context, handle));

            List<MetadataField> metadataFields = BindItemToRP
                    .metadataFieldWithAuthorityRP(context);
            for (MetadataField metadataField : metadataFields)
            {

                MetadataSchema find = MetadataSchema.find(context,
                        metadataField.getSchemaID());
                String field = Utils.standardize(find.getName(),
                        metadataField.getElement(),
                        metadataField.getQualifier(), "_");
                String standardizeField = Utils.standardize(find.getName(),
                        metadataField.getElement(),
                        metadataField.getQualifier(), ".");
                Metadatum[] metadatum = item
                        .getMetadataByMetadataString(standardizeField);

                haveSimilar.put(field, false);

                for (Metadatum meta : metadatum)
                {
                    String similar = null;
                    Choices choices = null;
                    try
                    {
                        choices = ResearcherPageUtils.doGetMatches(
                                Researcher.FILTER_MYDSPACE_MATCHES, meta.value);
                    }
                    catch (SearchServiceException e)
                    {
                        log.error(e.getMessage());
                    }

                    if (choices != null)
                    {
                        if (choices.total > 0)
                        {
                            choice : for (Choice choice : choices.values)
                            {
                                for(String allname : rp.getAllNames()) {
                                    if (crisID.equals(choice.authority) || allname.equals(choice.value) || jaroWinklerDistance.getDistance(allname,choice.value)>checksimilarity)
                                    {
                                        similar = meta.value;
                                        haveSimilar.put(field, true);
                                        break choice;
                                    }
                                }
                            }
                        }
                    }

                    List<String[]> options = null;
                    if (result.containsKey(field))
                    {
                        options = result.get(field);
                    }
                    else
                    {
                        options = new ArrayList<String[]>();
                    }

                    String[] innerOptions = new String[] { meta.value,
                            meta.authority, "" + meta.confidence, meta.language,
                            similar };
                    options.add(innerOptions);
                    result.put(field, options);
                }

            }

        }
    }

    protected void doDSPost(Context context, HttpServletRequest request,
            HttpServletResponse response) throws ServletException, IOException,
            SQLException, AuthorizeException
    {
        context.turnOffAuthorisationSystem();

        final Date now = new Date();
        final String submitButton = UIUtil.getSubmitButton(request,
                "submit_cancel");

        String handle = request.getParameter("handle");
        String crisID = context.getCrisID();

        // retrieve Group users to send notification; Default is Administrator
        // Group
        String notifyGroupSelfClaim = ConfigurationManager.getProperty("cris",
                "notify-publication.claim.group.name");
        if (StringUtils.isBlank(notifyGroupSelfClaim))
        {
            notifyGroupSelfClaim = "Administrator";
        }

        // check if currentUser is member of the self claim group
        boolean selfClaim = false;
        String nameGroupSelfClaim = ConfigurationManager.getProperty("cris",
                "publication.claim.group.name");
        if (StringUtils.isNotBlank(nameGroupSelfClaim))
        {
            Group selfClaimGroup = Group.findByName(context,
                    nameGroupSelfClaim);
            if (selfClaimGroup != null)
            {
                if (Group.isMember(context, selfClaimGroup.getID()))
                {
                    selfClaim = true;
                }
            }
        }

        if (!"submit_cancel".equals(submitButton))
        {
            Context subcontext = null;
            try
            {
                subcontext = new Context();
                subcontext.turnOffAuthorisationSystem();
                subcontext.setDispatcher("onlyindex");
                subcontext.setCurrentUser(context.getCurrentUser());
                subcontext.setCurrentLocale(context.getCurrentLocale());
                int[] selectedIds = UIUtil.getIntParameters(request,
                        "selectedId");

                String message = null;
                int failures = 0;
                int successes = 0;
                int discarded = 0;
                for (int selectedId : selectedIds)
                {
                    try
                    {
                        String selectedHandle = request
                                .getParameter("handle_" + selectedId);
                        workNow(subcontext, request, now, selectedHandle,
                                crisID, notifyGroupSelfClaim, selfClaim,
                                selectedId, submitButton);
                        if ("submit_approve".equalsIgnoreCase(submitButton))
                        {
                            successes++;
                        } else {
                            discarded++;
                        }
                    }
                    catch (Exception ex)
                    {
                        failures++;
                        log.error(ex.getMessage(), ex);
                    }
                }

                if (failures > 0)
                {
                    if ("submit_approve".equalsIgnoreCase(submitButton))
                    {
                        message = I18nUtil.getMessage(
                                "jsp.dspace.authority-listclaim.failure.success",
                                new Object[] { successes, failures },
                                context.getCurrentLocale(), false);
                    } else {
                        message = I18nUtil.getMessage(
                                "jsp.dspace.authority-listclaim.failure.reject",
                                new Object[] { discarded, failures },
                                context.getCurrentLocale(), false);
                    }
                }
                else
                {
                    if (successes > 0)
                    {
                        message = I18nUtil.getMessage(
                                "jsp.dspace.authority-listclaim.success",
                                new Object[] { successes },
                                context.getCurrentLocale(), false);
                    }
                    else
                    {
                        message = I18nUtil.getMessage(
                                "jsp.dspace.authority-listclaim.reject",
                                new Object[] { selectedIds.length },
                                context.getCurrentLocale(), false);
                    }
                }
                if (StringUtils.isNotBlank(message))
                {
                    request.getSession().setAttribute(Constants.MESSAGES_KEY,
                            Arrays.asList(message));
                }
                subcontext.complete();
            }
            catch (Exception ex)
            {
                log.error(ex.getMessage(), ex);
            }
            finally
            {
                if (subcontext != null && subcontext.isValid())
                {
                    subcontext.abort();
                }
            }
        }

        if (StringUtils.isBlank(handle))
        {
            response.sendRedirect(
                    request.getContextPath() + "/cris/rp/" + crisID);
        }
        else
        {
            response.sendRedirect(
                    request.getContextPath() + "/handle/" + handle);
        }

        context.restoreAuthSystemState();
    }

    private void workNow(Context context, HttpServletRequest request,
            final Date now, String handle, String crisID,
            String notifyGroupSelfClaim, boolean selfClaim, int selectedId,
            String submitMode) throws SQLException, AuthorizeException
    {

        String templateEmail = null;
        String templateEmailParam0 = null;
        String templateEmailParam1 = null;
        String templateEmailParam2 = null;
        String templateEmailParam3 = null;

        ChoiceAuthorityManager cam = ChoiceAuthorityManager.getManager();

        List<String> choices = new ArrayList<String>();

        Enumeration e = request.getParameterNames();

        // find user choice
        while (e.hasMoreElements())
        {
            String parameterName = (String) e.nextElement();

            // userchoice_<identifier>_schema_element_qualifier ->
            // userchoice_16_dc_contributor_author
            if (parameterName.startsWith("userchoice_" + selectedId))
            {
                // <sequencenumber>_<identifier>_schema_element_qualifier ->
                // 00_16_dc_contributor_author
                choices.add(request.getParameter(parameterName));
            }
        }

        // for each publication try to accept/reject
        for (String choice : choices)
        {
            String[] arrayChoices = null;
            if (StringUtils.isNotBlank(choice))
            {
                arrayChoices = choice.split("_", 2);
            }

            // the choice sequence by the end user -> 00
            String sequenceChoice = arrayChoices[0];
            // the field with the identifier as prefix ->
            // 16_dc_contributor_author
            String fieldChoice = arrayChoices[1];

            // try to retrieve the text note ->
            // requestNote_16_dc_contributor_author
            String note = request.getParameter("requestNote_" + fieldChoice);

            Set<Integer> itemRejectedIDs = new HashSet<Integer>();
            if (StringUtils.isNotBlank(fieldChoice))
            {
                Item item = (Item) HandleManager.resolveToObject(context,
                        handle);
                String[] metadata = fieldChoice.split("_");
                // skip item id ---> e.g. 01_dc_contributor_author
                item.clearMetadata(metadata[1], metadata[2],
                        metadata.length > 3 ? metadata[3] : null, Item.ANY);

                // process update
                Enumeration unsortedParamNames = request.getParameterNames();

                // Put them in a list
                List<String> sortedParamNames = new LinkedList<String>();

                while (unsortedParamNames.hasMoreElements())
                {
                    sortedParamNames
                            .add((String) unsortedParamNames.nextElement());
                }

                // Sort the list
                Collections.sort(sortedParamNames);

                for (String p : sortedParamNames)
                {
                    // e.g. value_3_dc_contributor_author_00
                    if (p.startsWith("value_" + selectedId))
                    {
                        /*
                         * It's a metadata value - it will be of the form
                         * value_element_1 OR value_element_qualifier_2 (the
                         * number being the sequence number) We use a
                         * StringTokenizer to extract these values
                         */
                        StringTokenizer st = new StringTokenizer(p, "_");

                        st.nextToken(); // Skip "value"
                        st.nextToken(); // Skip "id"

                        String schema = st.nextToken();

                        String element = st.nextToken();

                        String qualifier = null;

                        if (st.countTokens() == 2)
                        {
                            qualifier = st.nextToken();
                        }

                        String[] checkTokenized = Utils.tokenize(fieldChoice
                                .substring(fieldChoice.indexOf("_") + 1));
                        if (schema.equals(checkTokenized[0]))
                        {
                            if (element.equals(checkTokenized[1]))
                            {
                                if (qualifier != null
                                        && checkTokenized.length == 3)
                                {
                                    if (qualifier.equals(checkTokenized[2]))
                                    {
                                        String sequenceNumber = st.nextToken();

                                        // Get a string with "element" for
                                        // unqualified or
                                        // "element_qualifier"
                                        String key = MetadataField.formKey(
                                                schema, element, qualifier);

                                        // Get the language
                                        String language = request.getParameter(
                                                "language_" + fieldChoice + "_"
                                                        + sequenceNumber);

                                        // trim language and set empty
                                        // string language =
                                        // null
                                        if (language != null)
                                        {
                                            language = language.trim();
                                            if (language.equals(""))
                                            {
                                                language = null;
                                            }
                                        }

                                        // Get the authority key if any
                                        String authority = request.getParameter(
                                                "choice_" + fieldChoice
                                                        + "_authority_"
                                                        + sequenceNumber);

                                        // Get the authority confidence
                                        // value, passed as
                                        // symbolic name
                                        String sconfidence = request
                                                .getParameter("choice_"
                                                        + fieldChoice
                                                        + "_confidence_"
                                                        + sequenceNumber);
                                        int confidence = (StringUtils
                                                .isBlank(sconfidence))
                                                        ? Choices.CF_NOVALUE
                                                        : Integer.parseInt(
                                                                sconfidence);

                                        // Get the value
                                        String value = request.getParameter(p)
                                                .trim();

                                        if (StringUtils.isBlank(authority))
                                        {
                                            if (sequenceNumber
                                                    .equals(sequenceChoice))
                                            {
                                                authority = crisID;
                                                if (selfClaim)
                                                {
                                                    confidence = Choices.CF_ACCEPTED;
                                                }
                                                else
                                                {
                                                    confidence = Choices.CF_UNCERTAIN;
                                                    templateEmail = PUBLICATION_CLAIMED_UNCERTAIN;
                                                    templateEmailParam0 = key;
                                                    templateEmailParam1 = value;
                                                    templateEmailParam2 = authority;
                                                    templateEmailParam3 = ""
                                                            + confidence;
                                                }
                                            }
                                            else
                                            {
                                                authority = null;
                                            }
                                        }
                                        else
                                        {
                                            if (authority.equals(crisID)
                                                    && selfClaim)
                                            {
                                                confidence = Choices.CF_ACCEPTED;
                                            }
                                            else if (sequenceNumber
                                                    .equals(sequenceChoice))
                                            {
                                                templateEmail = PUBLICATION_REQUEST_FOR_CLAIM;
                                                templateEmailParam0 = key;
                                                templateEmailParam1 = value;
                                                templateEmailParam2 = authority;
                                                templateEmailParam3 = ""
                                                        + confidence;
                                            }
                                        }

                                        if ("submit_reject"
                                                .equalsIgnoreCase(submitMode))
                                        {
                                            if (StringUtils
                                                    .isNotBlank(authority)
                                                    && crisID.equals(authority))
                                            {
                                                item.addMetadata(schema,
                                                        element, qualifier,
                                                        language, value, null,
                                                        Choices.CF_REJECTED);
                                                itemRejectedIDs
                                                        .add(item.getID());
                                            }
                                            else
                                            {
                                                item.addMetadata(schema,
                                                        element, qualifier,
                                                        language, value,
                                                        authority, confidence);
                                            }
                                        }
                                        else
                                        {
                                            item.addMetadata(schema, element,
                                                    qualifier, language, value,
                                                    authority, confidence);
                                        }

                                    }
                                }

                            }

                        }
                    }
                }

                if (StringUtils.isNotBlank(templateEmail))
                {
                    item.addMetadata(METADATA_MESSAGE[0], METADATA_MESSAGE[1],
                            METADATA_MESSAGE[2], Item.ANY,
                            sdf.format(now) + "|||" + crisID + "|||"
                                    + submitMode + "|||" + templateEmail + "|||"
                                    + fieldChoice.substring(
                                            fieldChoice.indexOf("_") + 1)
                                    + "|||" + note);
                }

                item.update();
                context.commit();
                if (itemRejectedIDs.size() > 0)
                {
                    // notify reject
                    int[] ids = new int[itemRejectedIDs.size()];
                    Iterator<Integer> iter = itemRejectedIDs.iterator();
                    int i = 0;
                    while (iter.hasNext())
                    {
                        ids[i] = (Integer) iter.next();
                        i++;
                    }

                    String[] splitted = fieldChoice.split("_");
                    // skip item id ---> e.g. 01_dc_contributor_author
                    String schema = splitted[1];
                    String element = splitted[2];
                    String qualifier = (splitted.length == 4) ? splitted[3]
                            : null;
                    cam.notifyReject(ids, schema, element, qualifier, crisID);
                }
            }

            if (StringUtils.isNotBlank(templateEmail))
            {
                sendEmail(context, templateEmail, notifyGroupSelfClaim, null,
                        templateEmailParam0, templateEmailParam1,
                        templateEmailParam2, templateEmailParam3, note, handle,
                        crisID);
            }

            sendEmail(context, PUBLICATION_CLAIMED_USER, null,
                    context.getCurrentUser().getEmail(), templateEmailParam0,
                    templateEmailParam1, templateEmailParam2,
                    templateEmailParam3, note, handle, crisID);

        }

    }

    private void sendEmail(Context context, String templateEmail,
            String groupName, String emailUser, String field, String value,
            String authority, String confidence, String note, String handle,
            String crisId)
    {

        org.dspace.core.Email email;
        try
        {
            email = org.dspace.core.Email.getEmail(I18nUtil.getEmailFilename(
                    context.getCurrentLocale(), templateEmail));

            if (StringUtils.isBlank(authority))
            {
                authority = context.getCrisID();
            }
            try
            {
                if (StringUtils.isNotBlank(emailUser))
                {
                    email.addRecipient(emailUser);
                }
                else
                {
                    Group group = Group.findByName(context, groupName);
                    if (group != null && !group.isEmpty())
                    {
                        for (EPerson eperson : group.getMembers())
                        {
                            email.addRecipient(eperson.getEmail());
                        }
                    }
                    else
                    {
                        log.warn(
                                "No get eperson from group (check notify-publication.claim.group.name configuration)");
                        return;
                    }
                }
                email.addArgument(field);
                email.addArgument(value);
                email.addArgument(authority);
                email.addArgument(confidence);
                email.addArgument(ConfigurationManager.getProperty("dspace.url")
                        + "/cris/rp/" + crisId);
                email.addArgument(ConfigurationManager.getProperty("dspace.url")
                        + "/handle/" + handle);
                email.addArgument(crisId);
                email.addArgument(note);
                email.send();
            }
            catch (SQLException | MessagingException e)
            {
                log.error(e.getMessage(), e);
            }
        }
        catch (

        IOException e)
        {
            log.error(e.getMessage(), e);
        }

    }
}
