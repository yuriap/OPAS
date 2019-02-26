-------------------------------------------------------------------------------------------------------------
--Extended SQL Trace
-------------------------------------------------------------------------------------------------------------

define MODNM=SQL_TRACE
@../../modules/sql_trace/install/version.sql

alter table trc_projects add priority            number default 10;
CREATE OR REPLACE FORCE VIEW V$TRC_PROJECTS AS 
select x.*,
case
  when keep_forever = 'Y' 
    then 'Will be kept forever'
  else
    replace('Will be kept till <%p1>','<%p1>',to_char(created + TO_DSINTERVAL(COREMOD_API.getconf('PROJECTRETENTION',TRC_FILE_API.getMODNAME)||' 00:00:00'),'YYYY-MON-DD HH24:MI' ))
end retention
from trc_projects x
where owner=decode(owner,'PUBLIC',owner,decode(is_public,'Y',owner,nvl(V('APP_USER'),'~^')));

set define off

@../../modules/sql_trace/source/TRC_PROJ_API_SPEC.SQL
@../../modules/sql_trace/source/TRC_PROJ_API_BODY.SQL

set define on

exec COREMOD.register(p_modname => '&MODNM.', p_modver => '&MODVER.', p_installed => sysdate);

commit;

begin
  TRC_EXPIMP.init();
end;
/

