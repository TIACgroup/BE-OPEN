/**
 * The contents of this file are subject to the license and copyright
 * detailed in the LICENSE and NOTICE files at the root of the source
 * tree and available online at
 *
 * http://www.dspace.org/license/
 */
package org.dspace.authority.orcid;

import java.util.ArrayList;
import java.util.Collection;
import java.util.Date;
import java.util.HashMap;
import java.util.HashSet;
import java.util.List;
import java.util.Map;
import java.util.UUID;

import javax.xml.bind.JAXBElement;

import org.apache.commons.lang.StringUtils;
import org.apache.log4j.Logger;
import org.apache.solr.common.SolrDocument;
import org.apache.solr.common.SolrInputDocument;
import org.dspace.authority.AuthorityValue;
import org.dspace.authority.AuthorityValueGenerator;
import org.dspace.authority.PersonAuthorityValue;
import org.dspace.authority.orcid.jaxb.address.AddressCtype;
import org.dspace.authority.orcid.jaxb.address.Addresses;
import org.dspace.authority.orcid.jaxb.common.ExternalId;
import org.dspace.authority.orcid.jaxb.keyword.Keyword;
import org.dspace.authority.orcid.jaxb.keyword.KeywordCtype;
import org.dspace.authority.orcid.jaxb.othername.OtherNameCtype;
import org.dspace.authority.orcid.jaxb.person.externalidentifier.ExternalIdentifier;
import org.dspace.authority.orcid.jaxb.personaldetails.NameCtype;
import org.dspace.authority.orcid.jaxb.personaldetails.PersonalDetails;
import org.dspace.authority.orcid.jaxb.researcherurl.ResearcherUrl;
import org.dspace.authority.orcid.jaxb.researcherurl.ResearcherUrlCtype;
import org.orcid.ns.record.Record;

/**
 *
 * @author Antoine Snyers (antoine at atmire.com)
 * @author Kevin Van de Velde (kevin at atmire dot com)
 * @author Ben Bosman (ben at atmire dot com)
 * @author Mark Diggory (markd at atmire dot com)
 */
public class OrcidAuthorityValue extends PersonAuthorityValue {

	/**
	 * log4j logger
	 */
	private static Logger log = Logger.getLogger(OrcidAuthorityValue.class);

	private String orcid_id;
	private Map<String, List<String>> otherMetadata = new HashMap<String, List<String>>();
	private boolean update; // used in setValues(Bio bio)

	/**
	 * Creates an instance of OrcidAuthorityValue with only uninitialized
	 * fields. This is meant to be filled in with values from an existing
	 * record. To create a brand new OrcidAuthorityValue, use create()
	 */
	public OrcidAuthorityValue() {
	}

	public OrcidAuthorityValue(SolrDocument document) {
		super(document);
	}

	public String getOrcid_id() {
		return orcid_id;
	}

	public void setOrcid_id(String orcid_id) {
		this.orcid_id = orcid_id;
	}

	public Map<String, List<String>> getOtherMetadata() {
		return otherMetadata;
	}

	public void addOtherMetadata(String label, String data) {
		List<String> strings = otherMetadata.get(label);
		if (strings == null) {
			strings = new ArrayList<String>();
		}
		strings.add(data);
		otherMetadata.put(label, strings);
	}

	@Override
	public SolrInputDocument getSolrInputDocument() {
		SolrInputDocument doc = super.getSolrInputDocument();
		if (StringUtils.isNotBlank(getOrcid_id())) {
			doc.addField("orcid_id", getOrcid_id());
		}

		for (String t : otherMetadata.keySet()) {
			List<String> data = otherMetadata.get(t);
			for (String data_entry : data) {
				doc.addField("label_" + t, data_entry);
			}
		}
		return doc;
	}

	@Override
	public void setValues(SolrDocument document) {
		super.setValues(document);
		this.orcid_id = String.valueOf(document.getFieldValue("orcid_id"));

		otherMetadata = new HashMap<String, List<String>>();
		for (String fieldName : document.getFieldNames()) {
			String labelPrefix = "label_";
			if (fieldName.startsWith(labelPrefix)) {
				String label = fieldName.substring(labelPrefix.length());
				List<String> list = new ArrayList<String>();
				Collection<Object> fieldValues = document.getFieldValues(fieldName);
				for (Object o : fieldValues) {
					list.add(String.valueOf(o));
				}
				otherMetadata.put(label, list);
			}
		}
	}

	public static OrcidAuthorityValue create() {
		OrcidAuthorityValue orcidAuthorityValue = new OrcidAuthorityValue();
		orcidAuthorityValue.setId(UUID.randomUUID().toString());
		orcidAuthorityValue.updateLastModifiedDate();
		orcidAuthorityValue.setCreationDate(new Date());
		return orcidAuthorityValue;
	}

	/**
	 * Create an authority based on a given orcid bio
	 */
	public static OrcidAuthorityValue create(Record bio) {
		OrcidAuthorityValue authority = OrcidAuthorityValue.create();

		authority.setValues(bio);

		return authority;
	}

	public boolean setValues(Record profile) {

        if (profile.getOrcidIdentifier() != null)
        {
            if (updateValue(profile.getOrcidIdentifier().getUriPath(),
                    getOrcid_id()))
            {
                setOrcid_id(profile.getOrcidIdentifier().getUriPath());
            }
        }

		if (profile.getPerson() != null) {

			NameCtype name = profile.getPerson().getName();

			if (updateValue(name.getFamilyName().getValue(), getLastName())) {
				setLastName(name.getFamilyName().getValue());
			}

			if (updateValue(name.getGivenNames().getValue(), getFirstName())) {
				setFirstName(name.getGivenNames().getValue());
			}

			if (name.getCreditName() != null) {
				if (StringUtils.isNotBlank(name.getCreditName().getValue())) {
					if (!getNameVariants().contains(name.getCreditName())) {
						addNameVariant(name.getCreditName().getValue());
						update = true;
					}
				}
			}
			
			
			if (profile.getPerson().getOtherNames() != null) {
				for (OtherNameCtype otherName : profile.getPerson().getOtherNames().getOtherName()) {
					if (!getNameVariants().contains(otherName.getContent())) {
						addNameVariant(otherName.getContent());
						update = true;
					}
				}
			}

			Addresses addresses = profile.getPerson().getAddresses();
            if (addresses != null) {
                for(AddressCtype address : addresses.getAddress()) {
                    if (address.getCountry() != null) {
						if (updateOtherMetadata("country",
								address.getCountry())) {
							addOtherMetadata("country",
									address.getCountry());
						}
					}
				}
			}
			if (profile.getPerson().getKeywords() != null) {
				for (KeywordCtype keyword : profile.getPerson().getKeywords().getKeyword()) {
					if (updateOtherMetadata("keyword", keyword.getContent())) {
						addOtherMetadata("keyword", keyword.getContent());
					}
				}
			}

			if (profile.getPerson().getExternalIdentifiers() != null) {
				for (ExternalId externalIdentifier : profile.getPerson().getExternalIdentifiers()
						.getExternalIdentifier()) {
					if (updateOtherMetadata("external_identifier",
							externalIdentifier.getExternalIdValue())) {
						addOtherMetadata("external_identifier",
								externalIdentifier.getExternalIdValue());
					}
				}
			}

			if (profile.getPerson().getResearcherUrls() != null) {
				for (ResearcherUrlCtype researcherUrl : profile.getPerson().getResearcherUrls().getResearcherUrl()) {
					if (updateOtherMetadata("researcher_url", researcherUrl.getUrlName())) {
						addOtherMetadata("researcher_url", researcherUrl.getUrlName());
					}
				}
			}

			if (profile.getPerson().getBiography() != null) {
				if (updateOtherMetadata("biography", profile.getPerson().getBiography().getContent())) {
					addOtherMetadata("biography", profile.getPerson().getBiography().getContent());
				}
			}

		}

		setValue(getName());

		if (update) {
			update();
		}
		boolean result = update;
		update = false;
		return result;
	}

	private boolean updateOtherMetadata(String label, String data) {
		List<String> strings = getOtherMetadata().get(label);
		boolean update;
		if (strings == null) {
			update = StringUtils.isNotBlank(data);
		} else {
			update = !strings.contains(data);
		}
		if (update) {
			this.update = true;
		}
		return update;
	}

	private boolean updateValue(String incoming, String resident) {
		boolean update = StringUtils.isNotBlank(incoming) && !incoming.equals(resident);
		if (update) {
			this.update = true;
		}
		return update;
	}

	@Override
	public Map<String, String> choiceSelectMap() {

		Map<String, String> map = super.choiceSelectMap();

		map.put("orcid", getOrcid_id());

		return map;
	}

	public String getAuthorityType() {
		return "orcid";
	}

	@Override
	public String generateString() {
		String generateString = AuthorityValueGenerator.GENERATE + getAuthorityType() + AuthorityValueGenerator.SPLIT;
		if (StringUtils.isNotBlank(getOrcid_id())) {
			generateString += getOrcid_id();
		}
		return generateString;
	}

	@Override
	public AuthorityValue newInstance(String info) {
		AuthorityValue authorityValue = null;
		if (StringUtils.isNotBlank(info)) {
			OrcidService orcid = OrcidService.getOrcid();
			authorityValue = orcid.queryAuthorityID(info);
		} else {
			authorityValue = OrcidAuthorityValue.create();
		}
		return authorityValue;
	}

	@Override
	public boolean equals(Object o) {
		if (this == o) {
			return true;
		}
		if (o == null || getClass() != o.getClass()) {
			return false;
		}

		OrcidAuthorityValue that = (OrcidAuthorityValue) o;

		if (orcid_id != null ? !orcid_id.equals(that.orcid_id) : that.orcid_id != null) {
			return false;
		}

		return true;
	}

	@Override
	public int hashCode() {
		return orcid_id != null ? orcid_id.hashCode() : 0;
	}

	public boolean hasTheSameInformationAs(Object o) {
		if (this == o) {
			return true;
		}
		if (o == null || getClass() != o.getClass()) {
			return false;
		}
		if (!super.hasTheSameInformationAs(o)) {
			return false;
		}

		OrcidAuthorityValue that = (OrcidAuthorityValue) o;

		if (orcid_id != null ? !orcid_id.equals(that.orcid_id) : that.orcid_id != null) {
			return false;
		}

		for (String key : otherMetadata.keySet()) {
			if (otherMetadata.get(key) != null) {
				List<String> metadata = otherMetadata.get(key);
				List<String> otherMetadata = that.otherMetadata.get(key);
				if (otherMetadata == null) {
					return false;
				} else {
					HashSet<String> metadataSet = new HashSet<String>(metadata);
					HashSet<String> otherMetadataSet = new HashSet<String>(otherMetadata);
					if (!metadataSet.equals(otherMetadataSet)) {
						return false;
					}
				}
			} else {
				if (that.otherMetadata.get(key) != null) {
					return false;
				}
			}
		}

		return true;
	}
}
