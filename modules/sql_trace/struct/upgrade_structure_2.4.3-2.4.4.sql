alter table trc_session ROW STORE COMPRESS ADVANCED;
alter table trc_client_identity ROW STORE COMPRESS ADVANCED;
alter table trc_statement ROW STORE COMPRESS ADVANCED;
alter table trc_trans ROW STORE COMPRESS ADVANCED;
alter table trc_call ROW STORE COMPRESS ADVANCED;
alter table trc_call_self ROW STORE COMPRESS ADVANCED;
alter table trc_binds ROW STORE COMPRESS ADVANCED;
alter table trc_wait ROW STORE COMPRESS ADVANCED;
alter table trc_stat ROW STORE COMPRESS ADVANCED;
alter table trc_obj_dic ROW STORE COMPRESS ADVANCED;

alter table trc_session move;
alter table trc_client_identity move;
alter table trc_statement move;
alter table trc_trans move;
alter table trc_call move;
alter table trc_call_self move;
alter table trc_binds move;
alter table trc_wait move;
alter table trc_stat move;
alter table trc_obj_dic move;


CREATE OR REPLACE FORCE VIEW V$TRC_PROJECTS AS 
select x.*,
case
  when keep_forever = 'Y' 
    then 'Will be kept forever'
  else
    replace('Will be kept till <%p1>','<%p1>',to_char(created + TO_DSINTERVAL(COREMOD_API.getconf('PROJECTRETENTION',TRC_FILE_API.getMODNAME)||' 00:00:00'),'YYYY-MON-DD HH24:MI' ))
end retention,
case when keep_forever = 'N' and created + COREMOD_API.getconf('PROJECTRETENTION',TRC_FILE_API.getMODNAME) < (sysdate + COREMOD_API.getconf('SHOWEXPBEFORE',COREMOD_API.getMODNAME)) then 'Project is expiring.' else null end
|| (select case when expiring>0 then ' '||expiring||' file(s) is(are) expiring.' else null end from trc_mv_files_retentions i where i.PROJ_ID=x.PROJ_ID) proj_warnings
from trc_projects x
where owner=decode(owner,'PUBLIC',owner,decode(is_public,'Y',owner,nvl(V('APP_USER'),'~^')));  