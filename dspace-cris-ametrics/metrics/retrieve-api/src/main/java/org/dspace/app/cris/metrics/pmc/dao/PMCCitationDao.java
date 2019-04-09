/**
 * The contents of this file are subject to the license and copyright
 * detailed in the LICENSE and NOTICE files at the root of the source
 * tree and available online at
 *
 * https://github.com/CILEA/dspace-cris/wiki/License
 */
package org.dspace.app.cris.metrics.pmc.dao;

import org.dspace.app.cris.metrics.pmc.model.PMCCitation;

import it.cilea.osd.common.dao.GenericDao;

public interface PMCCitationDao extends GenericDao<PMCCitation, Integer>
{

    PMCCitation uniqueCitationByItemID(Integer itemID);

}
