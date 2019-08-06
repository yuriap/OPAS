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

conn &localscheme./&localscheme.@&localdb.

rem @../../modules/core/data/upgrade_data_1.3.11_1.3.12.sql
@../../modules/core/data/expimp_compat.sql
commit;

@../../modules/core/struct/upgrade_struct_1.3.11_1.3.12.sql

rem set define off
rem @../../modules/core/source/create_stored.sql
rem set define on


exec COREMOD.register(p_modname => '&MODNM.', p_modver => '&MODVER.', p_installed => sysdate);
commit;

begin
   COREMOD_EXPIMP.init();
end;
/

-------------------------------------------------------------------------------------------------------------
--Extended SQL Trace
-------------------------------------------------------------------------------------------------------------

define MODNM=SQL_TRACE
@../../modules/sql_trace/install/version.sql
@../../modules/sql_trace/struct/upgrade_structure_2.4.3-2.4.4.sql 
@../../modules/sql_trace/data/expimp_compat.sql
rem @../../modules/sql_trace/data/upgrade_data_2.4.2-2.4.3.sql

commit;

rem set define off
rem @../../modules/sql_trace/source/create_stored.sql
rem set define on

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
@../../modules/awr_warehouse/struct/upgrade_struct_4.4.3_4.4.4.sql
@../../modules/awr_warehouse/install/version.sql
@../../modules/awr_warehouse/data/expimp_compat.sql
commit;

rem set define off
rem @../../modules/awr_warehouse/source/create_stored.sql
rem set define on

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
@../../modules/ash_analyzer/struct/upgrade_struct_3.4.14_3.4.15.sql 

@../../modules/ash_analyzer/install/version.sql
@../../modules/ash_analyzer/data/expimp_compat.sql
rem @../../modules/ash_analyzer/data/load_tmpls.sql

commit;

rem set define off
rem @../../modules/ash_analyzer/source/create_stored.sql
rem set define on

exec COREMOD.register(p_modname => '&MODNM.', p_modver => '&MODVER.', p_installed => sysdate);
commit;

begin
  ASHA_EXPIMP.init();
end;
/

-------------------------------------------------------------------------------------------------------------
--DB Growth Tracker
-------------------------------------------------------------------------------------------------------------

define MODNM=DB_GROWTH
@../../modules/db_growth/install/version.sql

--Scheme setup script
conn sys/&localsys.@&localdb. as sysdba

@../../modules/db_growth/install/scheme_setup.sql

conn &localscheme./&localscheme.@&localdb.

@../../modules/db_growth/struct/create_struct.sql

@../../modules/db_growth/source/create_stored.sql


exec COREMOD.register(p_modname => '&MODNM.', p_moddescr => 'DB Growth Tracker module', p_modver => '&MODVER.', p_installed => sysdate);

@../../modules/db_growth/data/load.sql

begin
  coremod_cleanup.register_cleanup_tasks (  P_TASKNAME => 'CLEANUP_DB_GROWTH',
                                            P_MODNAME => '&MODNM.',
                                            p_task_body => 'begin DB_GROWTH_PROJ_API.cleanup_projects; end;');
end;
/


begin
  COREMOD_TASKS.create_task (  p_taskname  => 'DB_GROWTH_EXP_PROJ',
                               p_modname   => '&MODNM.',
                               p_is_public => 'Y', 
                               p_task_body => 'begin DB_GROWTH_EXPIMP.export_proj (p_proj_ids => coremod_tasks.t_ids(<B1>), p_exp_sess_id => <B2>) ; end;');
end;
/

begin
  COREMOD_TASKS.create_task (  p_taskname  => 'DB_GROWTH_IMP_PROCESSING',
                               p_modname   => '&MODNM.',
                               p_is_public => 'Y', 
                               p_task_body => 'begin DB_GROWTH_EXPIMP.import_processing (p_exp_sess_id => <B1>, p_proj_id => <B2>) ; end;');
end;
/

commit;

begin
  DB_GROWTH_EXPIMP.init();
end;
/

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