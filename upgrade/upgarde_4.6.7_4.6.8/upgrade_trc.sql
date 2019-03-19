-------------------------------------------------------------------------------------------------------------
--Extended SQL Trace
-------------------------------------------------------------------------------------------------------------

define MODNM=SQL_TRACE
@../../modules/sql_trace/install/version.sql

set define off

rem @../../modules/sql_trace/source/TRC_PROJ_API_SPEC.SQL

set define on

exec COREMOD.register(p_modname => '&MODNM.', p_modver => '&MODVER.', p_installed => sysdate);

commit;

begin
  TRC_EXPIMP.init();
end;
/

