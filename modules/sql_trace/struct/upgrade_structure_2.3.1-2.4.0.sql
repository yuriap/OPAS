alter table trc_wait add call_id NUMBER REFERENCES trc_call ( call_id ) on delete cascade;
create index idx_trc_wait_call on trc_wait(call_id);

alter table trc_stat add call_id NUMBER REFERENCES trc_call ( call_id ) on delete cascade;
create index idx_trc_stat_call on trc_stat(call_id);

CREATE INDEX IDX_TRC_CALL_BINDING ON TRC_CALL (TRC_FILE_ID,trc_slot,row_num,call_id);

drop materialized view trc_mv_files_retentions;
create materialized view trc_mv_files_retentions 
build immediate
refresh start with sysdate next sysdate + 1/24/10
as
select
PROJ_ID,
sum(case when created >= sysdate - COREMOD_API.getconf('HISTORYAFTER',COREMOD_API.getMODNAME) then 1 else 0 end) recent,
sum(case when created < sysdate - COREMOD_API.getconf('HISTORYAFTER',COREMOD_API.getMODNAME) then 1 else 0 end) historic,
sum(case when source_retention is not null and source_retention<>0 and status in ('LOADED','PARSED')
               and (created+nvl(source_retention,COREMOD_API.getconf('SOURCERETENTION',TRC_FILE_API.getMODNAME)/24)) < 
                   (sysdate + COREMOD_API.getconf('SHOWEXPBEFORE',COREMOD_API.getMODNAME)) then 1 else 0 end) expiring
from trc_files
group by PROJ_ID;

create index idx_trc_mv_files_ret_proj on trc_mv_files_retentions(proj_id);
