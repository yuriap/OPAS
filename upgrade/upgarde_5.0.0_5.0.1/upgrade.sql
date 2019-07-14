set echo on

spool upgrade.log

@../../install/install_global_config

-------------------------------------------------------------------------------------------------------------
-- OPAS Core
-------------------------------------------------------------------------------------------------------------

define MODNM=OPASCORE
@../../modules/core/install/version.sql
@../../modules/core/install/install_config

conn sys/&localsys.@&localdb. as sysdba

grant create materialized view to &localscheme.;

conn &localscheme./&localscheme.@&localdb.

@../../modules/core/data/upgrade_data_1.3.7_1.3.8.sql
@../../modules/core/data/expimp_compat.sql
commit;

set define off
@../../modules/core/source/create_stored.sql
set define on

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
@../../modules/sql_trace/struct/upgrade_structure_2.3.0-2.3.1.sql 
@../../modules/sql_trace/data/expimp_compat.sql
commit;

set define off
@../../modules/sql_trace/source/create_stored.sql
set define on

@../../modules/sql_trace/struct/upgrade_structure_2.3.0-2.3.1_p2.sql
@../../modules/sql_trace/struct/upgrade_structure_2.3.0-2.3.1_p2_mv.sql

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
@../../modules/awr_warehouse/struct/upgrade_struct_4.4.0_4.4.1.sql
@../../modules/awr_warehouse/data/expimp_compat.sql
commit;

set define off
@../../modules/awr_warehouse/source/create_stored.sql
set define on

@../../modules/awr_warehouse/struct/upgrade_struct_4.4.0_4.4.1_mv.sql

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
@../../modules/ash_analyzer/install/version.sql
@../../modules/ash_analyzer/struct/upgrade_struct_3.4.9_3.4.10.sql 
@../../modules/ash_analyzer/data/expimp_compat.sql
commit;

set define off
@../../modules/ash_analyzer/source/create_stored.sql
set define on

@../../modules/ash_analyzer/struct/upgrade_struct_3.4.9_3.4.10_mv.sql

exec COREMOD.register(p_modname => '&MODNM.', p_modver => '&MODVER.', p_installed => sysdate);
commit;

begin
  ASHA_EXPIMP.init();
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