-------------------------------------------------------------------------------------------------------------
--Extended SQL Trace
-------------------------------------------------------------------------------------------------------------

define MODNM=SQL_TRACE
@../../modules/sql_trace/install/version.sql

set define off

@../../modules/sql_trace/source/TRC_EXPIMP_SPEC.SQL
@../../modules/sql_trace/source/TRC_EXPIMP_BODY.SQL
@../../modules/sql_trace/source/TRC_REPORT_BODY.SQL

set define on

exec COREMOD.register(p_modname => '&MODNM.', p_modver => '&MODVER.', p_installed => sysdate);

commit;

begin
  TRC_EXPIMP.init();
end;
/

