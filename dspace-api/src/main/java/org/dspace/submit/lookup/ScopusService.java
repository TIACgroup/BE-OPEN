/**
 * The contents of this file are subject to the license and copyright
 * detailed in the LICENSE and NOTICE files at the root of the source
 * tree and available online at
 *
 * http://www.dspace.org/license/
 */
package org.dspace.submit.lookup;

import java.io.File;
import java.io.FileInputStream;
import java.io.IOException;
import java.io.InputStream;
import java.net.URLEncoder;
import java.nio.charset.StandardCharsets;
import java.util.ArrayList;
import java.util.Collections;
import java.util.List;

import javax.xml.parsers.DocumentBuilder;
import javax.xml.parsers.DocumentBuilderFactory;
import javax.xml.parsers.ParserConfigurationException;

import gr.ekt.bte.core.Value;
import org.apache.commons.httpclient.HostConfiguration;
import org.apache.commons.httpclient.HttpClient;
import org.apache.commons.httpclient.methods.GetMethod;
import org.apache.commons.lang.StringUtils;
import org.apache.http.HttpException;
import org.apache.http.HttpStatus;
import org.apache.http.params.CoreConnectionPNames;
import org.apache.log4j.Logger;
import org.dspace.app.util.XMLUtils;
import org.dspace.core.ConfigurationManager;
import org.w3c.dom.Document;
import org.w3c.dom.Element;

import gr.ekt.bte.core.Record;

/**
 * @author Andrea Bollini
 * @author Kostas Stamatis
 * @author Luigi Andrea Pascarelli
 * @author Panagiotis Koutsourakis
 */
public class ScopusService
{

    private static final String ENDPOINT_SEARCH_SCOPUS = "http://api.elsevier.com/content/search/scopus";
    //private static final String ENDPOINT_SEARCH_SCOPUS = "http://localhost:9999/content/search/scopus";

    private static final Logger log = Logger.getLogger(ScopusService.class);

    private int timeout = 1000;

    int itemPerPage = 25;

    public List<Record> search(String title, String author, int year)
            throws HttpException, IOException
    {
        StringBuffer query = new StringBuffer();
        if (StringUtils.isNotBlank(title))
        {
        	query.append("title(").append(title).append("");
        }
        if (StringUtils.isNotBlank(author))
        {
            // [FAU]
            if (query.length() > 0)
                query.append(" AND ");
            query.append("AUTH(").append(author).append(")");
        }
        if (year != -1)
        {
            // [DP]
            if (query.length() > 0)
                query.append(" AND ");
            query.append("PUBYEAR IS ").append(year);
        }
        return search(query.toString());
    }

	public List<Record> search(String query) throws IOException, HttpException {

		String proxyHost = ConfigurationManager.getProperty("http.proxy.host");
		String proxyPort = ConfigurationManager.getProperty("http.proxy.port");
		String apiKey = ConfigurationManager.getProperty("submission.lookup.scopus.apikey");

		boolean readFromDirectory = ConfigurationManager.getBooleanProperty("submission.lookup.scopus.readfromdirectory");
		String directoryPath = ConfigurationManager.getProperty("submission.lookup.scopus.directory");
		String eid = null;
		if (query.contains("EID")) {
			eid =  StringUtils.substringBetween(query, "(", ")");
		}

		List<Record> results = new ArrayList<>();
		
		HttpClient client = new HttpClient();
		client.getParams().setIntParameter(CoreConnectionPNames.CONNECTION_TIMEOUT, timeout);
		if (StringUtils.isNotBlank(proxyHost) && StringUtils.isNotBlank(proxyPort)) {
			HostConfiguration hostCfg = client.getHostConfiguration();
			hostCfg.setProxy(proxyHost, Integer.parseInt(proxyPort));
			client.setHostConfiguration(hostCfg);
		}
		
		DocumentBuilderFactory factory = DocumentBuilderFactory.newInstance();
		factory.setValidating(false);
		factory.setIgnoringComments(true);
		factory.setIgnoringElementContentWhitespace(true);
		
		DocumentBuilder builder = null;
		try {
			builder = factory.newDocumentBuilder();
		} catch (ParserConfigurationException e) {
			throw new RuntimeException(e);
		}
		
		int start = 0;
		boolean inProgress = true;
		while (inProgress) {
			GetMethod method = null;
			if (!readFromDirectory) { // open session
				try {
					method = new GetMethod(String.format("%s?httpAccept=application/xml&apiKey=%s&view=STANDARD&start=%s&count=%s&query=%s",
							ENDPOINT_SEARCH_SCOPUS, apiKey, start, itemPerPage, URLEncoder.encode(query, StandardCharsets.UTF_8.displayName())));

					// Execute the method.
					int statusCode = client.executeMethod(method);

					if (statusCode != HttpStatus.SC_OK) {
						throw new RuntimeException("WS call failed: " + statusCode);
					}
				} catch (Exception e) {
					log.error(e.getMessage(), e);
					if (method != null) {
						method.releaseConnection();
					}
					break;
				}
			}

			if (readFromDirectory) {
				File dir = new File(directoryPath);
				File[] scopusResponses = dir.listFiles();
				for (File response : scopusResponses) {
					try (InputStream responseBodyAsStream = new FileInputStream(response)) {

						Document inDoc = builder.parse(responseBodyAsStream);

						Element xmlRoot = inDoc.getDocumentElement();

						List<Element> pubArticles = XMLUtils.getElementList(xmlRoot, "entry");

						for (Element xmlArticle : pubArticles) {
							try {
								if (eid != null) {
									String recordEid = XMLUtils.getElementValue(xmlArticle, "eid");
									if (eid.equals(recordEid)) {
										Record record = ScopusUtils.convertScopusDomToRecord(xmlArticle);
										return Collections.singletonList(record);
									}
								} else {
									results.add(ScopusUtils.convertScopusDomToRecord(xmlArticle));
								}
							} catch (Exception e) {
								throw new RuntimeException("EID is not valid or not exist: " + e.getMessage(), e);
							}
						}
					} catch (Exception e) {
						log.error(e.getMessage(), e);
						break;
					}
				}
				inProgress = false;

			} else {
				try (InputStream responseBodyAsStream = method.getResponseBodyAsStream()) {

					Document inDoc = builder.parse(responseBodyAsStream);

					Element xmlRoot = inDoc.getDocumentElement();

					List<Element> pubArticles = XMLUtils.getElementList(xmlRoot, "entry");

					for (Element xmlArticle : pubArticles) {
						try {
							results.add(ScopusUtils.convertScopusDomToRecord(xmlArticle));
						} catch (Exception e) {
							throw new RuntimeException("EID is not valid or not exist: " + e.getMessage(), e);
						}
					}

					boolean lastPageReached = true;
					for (Element page : XMLUtils.getElementList(xmlRoot, "link")) {
						String refPage = page.getAttribute("ref");
						if (StringUtils.equalsIgnoreCase(refPage, "next")) {
							lastPageReached = false;
							break;
						}
					}
					if (lastPageReached) {
						break;
					} else {
						start += itemPerPage;
					}

				} catch (Exception e) {
					log.error(e.getMessage(), e);
					if (method != null) {
						method.releaseConnection();
					}
					break;
				}
			}
		}
		return results;
	}
    
    public List<Record> search(String doi, String eid) throws HttpException,
            IOException
    {
        StringBuffer query = new StringBuffer();
        if (StringUtils.isNotBlank(doi))
        {
            query.append("DOI(").append(doi).append(")");
            
        }
        if (StringUtils.isNotBlank(eid))
        {
            // [FAU]
            if (query.length() > 0)
                query.append(" OR ");
            query.append("EID(").append(eid).append(")");
        }
        return search(query.toString());
    }
    
}