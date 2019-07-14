create materialized view asha_mv_cube_retentions 
build immediate
refresh start with sysdate next sysdate + 1/24/10
as
select
sess_proj_id proj_id,
sum(case when sess_created >= sysdate - COREMOD_API.getconf('HISTORYAFTER',COREMOD_API.getMODNAME) then 1 else 0 end) recent,
sum(case when sess_created < sysdate - COREMOD_API.getconf('HISTORYAFTER',COREMOD_API.getMODNAME) then 1 else 0 end) historic,
sum(case when sess_retention_days is not null and sess_retention_days<>0
               and (sess_created+nvl(sess_retention_days,COREMOD_API.getconf('CUBERETENTION',ASHA_CUBE_API.getMODNAME)/24)) < 
                   (sysdate + COREMOD_API.getconf('SHOWEXPBEFORE',COREMOD_API.getMODNAME)) then 1 else 0 end) expiring
from ASHA_CUBE_SESS
group by sess_proj_id;
-------------------------

create materialized view asha_mv_reports_retentions 
build immediate
refresh start with sysdate next sysdate + 1/24/10
as
select
proj_id,
sum(case when arep.created >= sysdate - COREMOD_API.getconf('HISTORYAFTER',COREMOD_API.getMODNAME) then 1 else 0 end) recent,
sum(case when arep.created < sysdate - COREMOD_API.getconf('HISTORYAFTER',COREMOD_API.getMODNAME) then 1 else 0 end) historic,
sum(case when report_retention is not null and report_retention<>0
       and (arep.created+nvl(report_retention,COREMOD_API.getconf('REPORTRETENTION',ASHA_CUBE_API.getMODNAME)/24)) < (sysdate + COREMOD_API.getconf('SHOWEXPBEFORE',COREMOD_API.getMODNAME)) then 1 else 0 end) expiring
from asha_cube_reports arep
group by proj_id;

create index idx_asha_mv_cube_ret_proj on asha_mv_cube_retentions(proj_id);
create index idx_asha_mv_rep_ret_proj on asha_mv_reports_retentions(proj_id);