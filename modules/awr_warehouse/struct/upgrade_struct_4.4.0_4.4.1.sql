create materialized view awrwh_mv_dumps_retentions 
build immediate
refresh start with sysdate next sysdate + 1/24/10
as
select
proj_id,
sum(case when loaded >= sysdate - COREMOD_API.getconf('HISTORYAFTER',COREMOD_API.getMODNAME) then 1 else 0 end) recent,
sum(case when loaded < sysdate - COREMOD_API.getconf('HISTORYAFTER',COREMOD_API.getMODNAME) then 1 else 0 end) historic,
sum(case when source_retention is not null and source_retention<>0
         and (loaded+nvl(source_retention,COREMOD_API.getconf('DUMPETENTION',AWRWH_API.getMODNAME))) < 
             (sysdate + COREMOD_API.getconf('SHOWEXPBEFORE',COREMOD_API.getMODNAME)) then 1 else 0 end) expiring
from awrwh_dumps
group by proj_id;
------------------------------
create materialized view awrwh_mv_reports_retentions 
build immediate
refresh start with sysdate next sysdate + 1/24/10
as
select
proj_id,
sum(case when arep.created >= sysdate - COREMOD_API.getconf('HISTORYAFTER',COREMOD_API.getMODNAME) then 1 else 0 end) recent,
sum(case when arep.created < sysdate - COREMOD_API.getconf('HISTORYAFTER',COREMOD_API.getMODNAME) then 1 else 0 end) historic,
sum(case when report_retention is not null and report_retention<>0
       and (arep.created+nvl(report_retention,COREMOD_API.getconf('REPORTRETENTION',AWRWH_API.getMODNAME)/24)) < 
             (sysdate + COREMOD_API.getconf('SHOWEXPBEFORE',COREMOD_API.getMODNAME)) then 1 else 0 end) expiring
from asha_cube_reports arep
group by proj_id;

create index idx_awrwh_mv_dumps_ret_proj on awrwh_mv_dumps_retentions(proj_id);
create index idx_awrwh_mv_rep_ret_proj on awrwh_mv_reports_retentions(proj_id);

CREATE OR REPLACE FORCE VIEW V$AWRWH_PROJECTS AS 
select x.*,
case
  when keep_forever = 'Y' 
    then 'Will be kept forever.'
  else
    replace('Will be kept till <%p1>','<%p1>',to_char(created + TO_DSINTERVAL(COREMOD_API.getconf('PROJECTRETENTION',AWRWH_API.getMODNAME)||' 00:00:00'),'YYYY-MON-DD HH24:MI' ))||'.'
end retention,
case when keep_forever = 'N' and created + COREMOD_API.getconf('PROJECTRETENTION',AWRWH_API.getMODNAME) < (sysdate + COREMOD_API.getconf('SHOWEXPBEFORE',COREMOD_API.getMODNAME)) then 'Project is expiring.' else null end
|| (select case when expiring>0 then ' '||expiring||' dump(s) is(are) expiring.' else null end from AWRWH_MV_DUMPS_RETENTIONS i where i.PROJ_ID=x.PROJ_ID) 
|| (select case when expiring>0 then ' '||expiring||' report(s) is(are) expiring.' else null end from AWRWH_MV_REPORTS_RETENTIONS i where i.PROJ_ID=x.PROJ_ID) proj_warnings
from awrwh_projects x
where owner=decode(owner,'PUBLIC',owner,decode(is_public,'Y',owner,nvl(V('APP_USER'),'~^')));