set echo on

spool upgrade.log

@../../install/install_global_config

-------------------------------------------------------------------------------------------------------------
-- OPAS Core
-------------------------------------------------------------------------------------------------------------

define MODNM=OPASCORE
@../../modules/core/install/version.sql
@../../modules/core/install/install_config

rem conn sys/&localsys.@&localdb. as sysdba
rem grant create materialized view to &localscheme.;

conn &localscheme./&localscheme.@&localdb.

rem @../../modules/core/data/upgrade_data_1.3.7_1.3.8.sql
rem @../../modules/core/data/expimp_compat.sql
rem commit;

rem set define off
rem @../../modules/core/source/create_stored.sql
rem set define on

rem exec COREMOD.register(p_modname => '&MODNM.', p_modver => '&MODVER.', p_installed => sysdate);
rem commit;

rem begin
rem   COREMOD_EXPIMP.init();
rem end;
rem /

-------------------------------------------------------------------------------------------------------------
--Extended SQL Trace
-------------------------------------------------------------------------------------------------------------

define MODNM=SQL_TRACE
@../../modules/sql_trace/install/version.sql
@../../modules/sql_trace/struct/upgrade_structure_2.3.1-2.4.0.sql 
@../../modules/sql_trace/data/expimp_compat.sql

UPDATE OPAS_TASK SET TASK_BODY = 'begin TRC_EXPIMP.export_trc (p_trc_ids => coremod_tasks.t_ids(<B1>), p_exp_sess_id => <B2>) ; end;' WHERE taskname = 'TRC_EXP_TRACE' AND modname = 'SQL_TRACE'

commit;

set define off
@../../modules/sql_trace/source/create_stored.sql
set define on

exec COREMOD.register(p_modname => '&MODNM.', p_modver => '&MODVER.', p_installed => sysdate);
commit;

begin
  TRC_EXPIMP.init();
end;
/

-------------------------------------------------------------------------------------------------------------
--AWR Warehouse
-------------------------------------------------------------------------------------------------------------

define MODNM=AWR_WAREHOUSE
@../../modules/awr_warehouse/install/version.sql
@../../modules/awr_warehouse/struct/upgrade_struct_4.4.1_4.4.2.sql
@../../modules/awr_warehouse/data/expimp_compat.sql
commit;

set define off
@../../modules/awr_warehouse/source/create_stored.sql
set define on

exec COREMOD.register(p_modname => '&MODNM.', p_modver => '&MODVER.', p_installed => sysdate);
commit;

begin
  AWRWH_EXPIMP.init();
end;
/

-------------------------------------------------------------------------------------------------------------
--ASH Analyzer
-------------------------------------------------------------------------------------------------------------

define MODNM=ASH_ANALYZER
rem @../../modules/ash_analyzer/install/version.sql
rem @../../modules/ash_analyzer/struct/upgrade_struct_3.4.9_3.4.10.sql 
rem @../../modules/ash_analyzer/data/expimp_compat.sql
rem commit;

rem set define off
rem @../../modules/ash_analyzer/source/create_stored.sql
rem set define on

rem exec COREMOD.register(p_modname => '&MODNM.', p_modver => '&MODVER.', p_installed => sysdate);
rem commit;

rem begin
rem   ASHA_EXPIMP.init();
rem end;
rem /
-------------------------------------------------------------------------------------------------------------
-------------------------------------------------------------------------------------------------------------
-------------------------------------------------------------------------------------------------------------

set pages 999
set lines 200

select * from user_errors order by 1,2,3,4,5;

begin
  dbms_utility.compile_schema(user);
end;
/

select * from user_errors order by 1,2,3,4,5;


exec COREMOD.register(p_modname => 'OPASAPP', p_modver => '&OPASVER.', p_installed => sysdate);
commit;

set pages 999
set lines 200
column MODNAME format a32 word_wrapped
column MODDESCR format a100 word_wrapped
select t.modname, t.modver, to_char(t.installed,'YYYY/MON/DD HH24:MI:SS') installed, t.moddescr from opas_modules t order by t.installed;
disc

spool off