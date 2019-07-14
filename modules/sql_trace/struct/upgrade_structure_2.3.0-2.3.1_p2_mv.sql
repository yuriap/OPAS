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