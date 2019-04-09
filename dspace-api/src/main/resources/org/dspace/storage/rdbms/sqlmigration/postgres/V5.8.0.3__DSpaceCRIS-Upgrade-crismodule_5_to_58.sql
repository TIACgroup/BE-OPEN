--
-- The contents of this file are subject to the license and copyright
-- detailed in the LICENSE and NOTICE files at the root of the source
-- tree and available online at
--
-- http://www.dspace.org/license/
--

do $$
begin
	
	ALTER TABLE CRIS_ORCID_HISTORY ADD COLUMN orcid varchar(255);
	ALTER TABLE CRIS_ORCID_HISTORY DROP COLUMN entityid;
	
	DELETE FROM CRIS_ORCID_HISTORY;
exception when others then
 	
	DELETE FROM CRIS_ORCID_HISTORY;
 	
    raise notice 'The transaction is in an uncommittable state. '
                     'Transaction was rolled back';
 
    raise notice 'Yo this is good! --> % %', SQLERRM, SQLSTATE;
end;
$$ language 'plpgsql';
