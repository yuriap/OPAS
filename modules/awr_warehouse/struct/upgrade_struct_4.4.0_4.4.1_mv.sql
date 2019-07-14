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