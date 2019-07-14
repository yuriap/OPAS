drop materialized view awrwh_mv_reports_retentions ;
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
from awrwh_reports arep
group by proj_id;