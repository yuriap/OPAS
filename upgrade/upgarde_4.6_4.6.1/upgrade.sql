set echo on

spool upgrade.log

@../../install/install_global_config

conn &localscheme./&localscheme.@&localdb.

-------------------------------------------------------------------------------------------------------------
--ASH Analyzer
-------------------------------------------------------------------------------------------------------------

define MODNM=ASH_ANALYZER
define MODVER="3.4.1"

set define off

@../../modules/ash_analyzer/source/ASHA_CUBE_PKG_SPEC.SQL
@../../modules/ash_analyzer/source/ASHA_CUBE_PKG_BODY.SQL
@../../modules/ash_analyzer/source/ASHA_PROJ_API_SPEC.SQL
@../../modules/ash_analyzer/source/ASHA_PROJ_API_BODY.SQL

set define on

exec COREMOD.register(p_modname => '&MODNM.', p_modver => '&MODVER.', p_installed => sysdate);

commit;

-------------------------------------------------------------------------------------------------------------
--AWR Warehouse
-------------------------------------------------------------------------------------------------------------

define MODNM=AWR_WAREHOUSE
define MODVER="4.3.1"

set define off

drop procedure AWRWH_CALC_ASH_CUBE;
@../../modules/awr_warehouse/source/AWRWH_CALC_ASH_CUBE_FNC.SQL
@../../modules/awr_warehouse/source/AWRWH_FILE_API_SPEC.SQL
@../../modules/awr_warehouse/source/AWRWH_FILE_API_BODY.SQL
@../../modules/awr_warehouse/source/AWRWH_PROJ_API_SPEC.SQL
@../../modules/awr_warehouse/source/AWRWH_PROJ_API_BODY.SQL

set define on

exec COREMOD.register(p_modname => '&MODNM.', p_modver => '&MODVER.', p_installed => sysdate);

commit;

-------------------------------------------------------------------------------------------------------------
--Extended SQL Trace
-------------------------------------------------------------------------------------------------------------

define MODNM=SQL_TRACE
define MODVER="2.2.1"

set define off

@../../modules/sql_trace/source/TRC_PROJ_API_SPEC.SQL
@../../modules/sql_trace/source/TRC_PROJ_API_BODY.SQL

set define on

exec COREMOD.register(p_modname => '&MODNM.', p_modver => '&MODVER.', p_installed => sysdate);

commit;

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