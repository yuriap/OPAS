CREATE OR REPLACE FORCE VIEW V$TRC_FILES AS 
select x.*,
case
  when source_retention = 0 
    then 'Will be kept forever'
  when status in ('COMPRESSED','ARCHIVED')
    then 'N/A'
  when source_retention is null
    then replace('Will be kept till <%p1>','<%p1>',to_char(created + TO_DSINTERVAL(COREMOD_API.getconf('SOURCERETENTION',TRC_FILE_API.getMODNAME)||' 00:00:00'),'YYYY-MON-DD HH24:MI' ))
  else
    replace('Will be kept till <%p1>','<%p1>',to_char(created + source_retention,'YYYY-MON-DD HH24:MI' ))
end source_retention_dt,
case
  when parsed_retention = 0 
    then 'Will be kept forever'
  when status in ('ARCHIVED')
    then 'N/A'	
  when parsed_retention is null
    then decode(parsed,null,null,replace('Will be kept till <%p1>','<%p1>',to_char(parsed + TO_DSINTERVAL(COREMOD_API.getconf('PARSEDRETENTION',TRC_FILE_API.getMODNAME)||' 00:00:00'),'YYYY-MON-DD HH24:MI' )))
  else
    decode(parsed,null,null,replace('Will be kept till <%p1>','<%p1>',to_char(parsed + parsed_retention,'YYYY-MON-DD HH24:MI' )))
end parsed_retention_dt
from trc_files x;

CREATE OR REPLACE FORCE VIEW V$TRC_PROJECTS AS 
select x.*,
case
  when keep_forever = 'Y' 
    then 'Will be kept forever.'
  else
    replace('Will be kept till <%p1>','<%p1>',to_char(created + TO_DSINTERVAL(COREMOD_API.getconf('PROJECTRETENTION',TRC_FILE_API.getMODNAME)||' 00:00:00'),'YYYY-MON-DD HH24:MI' ))||'.'
end retention,
case when keep_forever = 'N' and created + COREMOD_API.getconf('PROJECTRETENTION',TRC_FILE_API.getMODNAME) < (sysdate + COREMOD_API.getconf('SHOWEXPBEFORE',COREMOD_API.getMODNAME)) then 'Project is expiring.' else null end
|| (select case when expiring>0 then ' '||expiring||' file(s) is(are) expiring.' else null end from trc_mv_files_retentions i where i.PROJ_ID=x.PROJ_ID) proj_warnings
from trc_projects x
where owner=decode(owner,'PUBLIC',owner,decode(is_public,'Y',owner,nvl(V('APP_USER'),'~^')));  