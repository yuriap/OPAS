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


create materialized view trc_mv_files_retentions 
build immediate
refresh start with sysdate next sysdate + 1/24/10
as
select
PROJ_ID,
sum(case when created >= sysdate - COREMOD_API.getconf('HISTORYAFTER',COREMOD_API.getMODNAME) then 1 else 0 end) recent,
sum(case when created < sysdate - COREMOD_API.getconf('HISTORYAFTER',COREMOD_API.getMODNAME) then 1 else 0 end) historic,
sum(case when source_retention is not null and source_retention<>0
               and (created+nvl(source_retention,COREMOD_API.getconf('SOURCERETENTION',TRC_FILE_API.getMODNAME)/24)) < 
                   (sysdate + COREMOD_API.getconf('SHOWEXPBEFORE',COREMOD_API.getMODNAME)) then 1 else 0 end) expiring
from trc_files
group by PROJ_ID;

create index idx_trc_mv_files_ret_proj on trc_mv_files_retentions(proj_id);

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