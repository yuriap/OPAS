set echo on

spool upgrade.log

@../../install/install_global_config

conn &localscheme./&localscheme.@&localdb.

-------------------------------------------------------------------------------------------------------------
-- OPAS Core
-------------------------------------------------------------------------------------------------------------

define MODNM=OPASCORE
define MODVER="1.3.2"

set define off


@../../modules/core/source/COREMOD_REPORT_UTILS_SPEC.SQL
@../../modules/core/source/COREMOD_REPORT_UTILS_BODY.SQL

set define on

set define ~


declare
  l_script clob;
begin
  l_script := 
q'^
@../../modules/core/scripts/__prn_tbl_html.sql
^';
  delete from opas_scripts where script_id='PROC_PRNHTMLTBL';
  insert into opas_scripts (script_id,modname,script_content) values ('PROC_PRNHTMLTBL','~MODNM.',l_script);  
  COREMOD_REPORT_UTILS.prepare_saved_sql_script (  P_SCRIPT_NAME => 'PROC_PRNHTMLTBL');
end;
/

set define &

exec COREMOD.register(p_modname => 'OPASAPP', p_modver => '&OPASVER.', p_installed => sysdate);
exec COREMOD.register(p_modname => '&MODNM.', p_modver => '&MODVER.', p_installed => sysdate);

commit;

-------------------------------------------------------------------------------------------------------------
--ASH Analyzer
-------------------------------------------------------------------------------------------------------------

define MODNM=ASH_ANALYZER
define MODVER="3.4.3"

alter table asha_cube_srcdblink2projects add default_dblink  varchar2(1);

set define off


@../../modules/ash_analyzer/source/ASHA_CUBE_API_SPEC.SQL
@../../modules/ash_analyzer/source/ASHA_CUBE_API_BODY.SQL
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
define MODVER="4.3.3"

alter table awrwh_srcdblink2projects add default_dblink  varchar2(1);

set define off


@../../modules/awr_warehouse/source/AWRWH_PROJ_API_SPEC.SQL.SQL
@../../modules/awr_warehouse/source/AWRWH_PROJ_API_BODY.SQL.SQL

set define on

set define off
set serveroutput on


declare
  l_script clob := 
q'^
@../../modules/awr_warehouse/scripts/_getcomph.sql
^';
begin
  delete from opas_scripts where script_id='PROC_GETCOMP';
  insert into opas_scripts (script_id,modname,script_content) values ('PROC_GETCOMP','AWR_WAREHOUSE',l_script||l_script1||l_script2);  
  COREMOD_REPORT_UTILS.prepare_saved_sql_script (  P_SCRIPT_NAME => 'PROC_GETCOMP');
  dbms_output.put_line('#1: '||dbms_lob.getlength(l_script)||' bytes; #2: '||dbms_lob.getlength(l_script1)||' bytes; #3: '||dbms_lob.getlength(l_script2)||' bytes;');
end;
/ 

 
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