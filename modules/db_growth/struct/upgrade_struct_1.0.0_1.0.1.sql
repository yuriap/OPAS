alter table db_growth_parameters add minimum_seg_sz number default 1e6;
drop materialized view DB_GROWTH_SIZES preserve table;

CREATE OR REPLACE FORCE VIEW V$DB_GROWTH_PROJECTS AS 
select
  proj_id,
  proj_name,
  owner,
  created,
  status,
  proj_note,
  keep_forever,
  is_public,
  priority,
  retention,
  sizes,
  case when trim(proj_warnings) is null then null else 'Warning! '||proj_warnings end proj_warnings
from (
select x.*,
case
  when keep_forever = 'Y' 
    then 'Will be kept forever'
  else
    replace('Will be kept till <%p1>','<%p1>',to_char(created + TO_DSINTERVAL(COREMOD_API.getconf('PROJECTRETENTION',DB_GROWTH_API.getMODNAME)||' 00:00:00'),'YYYY-MON-DD HH24:MI' ))
end retention,
'Schema size: '||case when pars.tot_size is not null then case when pars.tot_size>=0 then dbms_xplan.format_size(pars.tot_size) else '-'||dbms_xplan.format_size(abs(pars.tot_size)) end else 'N/A' end || 
'; Delta: ' ||   case when pars.delta is not null then case when pars.delta>=0 then dbms_xplan.format_size(pars.delta) else '-'||dbms_xplan.format_size(abs(pars.delta)) end else 'N/A' end sizes,
case when keep_forever = 'N' and created + COREMOD_API.getconf('PROJECTRETENTION',DB_GROWTH_API.getMODNAME) < (sysdate + COREMOD_API.getconf('SHOWEXPBEFORE',COREMOD_API.getMODNAME)) then ' Project is expiring.' else null end ||
case when tot_size > nvl(size_alert,1e50) then ' DB Size Alert!' else null end ||
case when delta/greatest(1,nvl(round(trunc(pars.last_updated,'mi') - (select trunc(max(gs.last_updated),'mi') from DB_GROWTH_SIZES gs where gs.proj_id=x.proj_id and trunc(gs.last_updated,'mi')<trunc(pars.last_updated,'mi'))),1)) > nvl(delta_alert,1e50) then ' DB Delta Alert!' else null end
  proj_warnings
from db_growth_projects x, db_growth_parameters pars
where x.proj_id=pars.proj_id(+)
  and owner=decode(owner,'PUBLIC',owner,decode(is_public,'Y',owner,nvl(V('APP_USER'),'~^'))));
