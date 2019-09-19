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

@../../modules/core/data/upgrade_data_1.3.16_1.3.17.sql
@../../modules/core/data/expimp_compat.sql
commit;

rem @../../modules/core/struct/upgrade_struct_1.3.14_1.3.15.sql

set define off
@../../modules/core/source/create_stored.sql
set define on


exec COREMOD.register(p_modname => '&MODNM.', p_modver => '&MODVER.', p_installed => sysdate);
commit;

rem begin
rem    COREMOD_EXPIMP.init();
rem end;
rem /

-------------------------------------------------------------------------------------------------------------
--Extended SQL Trace
-------------------------------------------------------------------------------------------------------------

rem define MODNM=SQL_TRACE
rem @../../modules/sql_trace/install/version.sql
rem @../../modules/sql_trace/struct/upgrade_structure_2.4.4-2.4.5.sql 
rem @../../modules/sql_trace/data/expimp_compat.sql
rem @../../modules/sql_trace/data/upgrade_data_2.4.2-2.4.3.sql

rem commit;

rem set define off
rem @../../modules/sql_trace/source/create_stored.sql
rem set define on

rem exec COREMOD.register(p_modname => '&MODNM.', p_modver => '&MODVER.', p_installed => sysdate);
rem commit;

rem begin
rem   TRC_EXPIMP.init();
rem end;
rem /

-------------------------------------------------------------------------------------------------------------
--AWR Warehouse
-------------------------------------------------------------------------------------------------------------

define MODNM=AWR_WAREHOUSE
rem @../../modules/awr_warehouse/struct/upgrade_struct_4.4.3_4.4.4.sql
rem @../../modules/awr_warehouse/install/version.sql
rem @../../modules/awr_warehouse/data/expimp_compat.sql
rem commit;

rem set define off
rem @../../modules/awr_warehouse/source/create_stored.sql
rem set define on

rem exec COREMOD.register(p_modname => '&MODNM.', p_modver => '&MODVER.', p_installed => sysdate);
rem commit;

rem begin
rem    AWRWH_EXPIMP.init();
rem end;
rem /

-------------------------------------------------------------------------------------------------------------
--ASH Analyzer
-------------------------------------------------------------------------------------------------------------

define MODNM=ASH_ANALYZER

rem @../../modules/ash_analyzer/struct/upgrade_struct_3.4.16_3.4.17.sql 

@../../modules/ash_analyzer/install/version.sql
@../../modules/ash_analyzer/data/expimp_compat.sql

rem @../../modules/ash_analyzer/data/load_tmpls.sql
rem @../../modules/ash_analyzer/data/upgrade_data_3.4.16_3.4.17.sql 

commit;

set define off
@../../modules/ash_analyzer/source/create_stored.sql
set define on

exec COREMOD.register(p_modname => '&MODNM.', p_modver => '&MODVER.', p_installed => sysdate);
commit;

rem begin
rem    ASHA_EXPIMP.init();
rem end;
rem /

-------------------------------------------------------------------------------------------------------------
--DB Growth Tracker
-------------------------------------------------------------------------------------------------------------

define MODNM=DB_GROWTH
rem @../../modules/db_growth/struct/upgrade_struct_1.0.2_1.0.3.sql

rem @../../modules/db_growth/install/version.sql
rem @../../modules/db_growth/data/expimp_compat.sql

rem commit;

rem set define off
rem @../../modules/db_growth/source/create_stored.sql
rem set define on

rem exec COREMOD.register(p_modname => '&MODNM.', p_modver => '&MODVER.', p_installed => sysdate);
rem commit;

rem begin
rem   DB_GROWTH_EXPIMP.init();
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