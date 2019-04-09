package org.dspace.app.cris.rpdeduplication.service;

public interface ResearcherMergeService {

    Boolean merge(String crisID, String[] mergeIDs);

}
