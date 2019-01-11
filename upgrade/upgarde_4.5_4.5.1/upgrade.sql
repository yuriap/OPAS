set echo on

spool upgrade.log

@../../install/install_global_config

conn &localscheme./&localscheme.@&localdb.

-- OPAS Core

define MODNM=OPASCORE
define MODVER="1.2.1"

set define off

@../../modules/core/source/COREMOD_SPEC.SQL
@../../modules/core/source/COREMOD_BODY.SQL
@../../modules/core/source/COREMOD_REPORT_UTILS_SPEC.SQL
@../../modules/core/source/COREMOD_REPORT_UTILS_BODY.SQL
@../../modules/core/source/COREMOD_REPORTS_BODY.SQL

set define on

INSERT INTO opas_config (modname,cgroup,ckey,cvalue,descr) VALUES ('&MODNM.','REPORT','LONGSECTROWS', 10000,'Custom reports long sections length in rows');
INSERT INTO opas_config (modname,cgroup,ckey,cvalue,descr) VALUES ('&MODNM.','REPORT','NARROWSECT',   700, 'Custom reports narrow section width, pixels');
INSERT INTO opas_config (modname,cgroup,ckey,cvalue,descr) VALUES ('&MODNM.','REPORT','MIDDLESECT',   1000, 'Custom reports middle section width, pixels');
INSERT INTO opas_config (modname,cgroup,ckey,cvalue,descr) VALUES ('&MODNM.','REPORT','WIDESECT',     1500, 'Custom reports wide section width, pixels');
INSERT INTO opas_config (modname,cgroup,ckey,cvalue,descr) VALUES ('&MODNM.','REPORT','SUPERWIDESECT',1800, 'Custom reports super wide section width, pixels');

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

--AWR Warehouse

define MODNM=AWR_WAREHOUSE
define MODVER="4.2.1"

set define off

@../../modules/awr_warehouse/source/AWRWH_FILE_LCC_BODY.SQL
@../../modules/awr_warehouse/source/AWRWH_PROJ_API_BODY.SQL

set define on

exec COREMOD.register(p_modname => '&MODNM.', p_modver => '&MODVER.', p_installed => sysdate);



set pages 999
set lines 200

select * from user_errors order by 1,2,3,4,5;

begin
  dbms_utility.compile_schema(user);
end;
/

select * from user_errors order by 1,2,3,4,5;

set pages 999
set lines 200
column MODNAME format a32 word_wrapped
column MODDESCR format a100 word_wrapped
select t.modname, t.modver, to_char(t.installed,'YYYY/MON/DD HH24:MI:SS') installed, t.moddescr from opas_modules t order by t.installed;
disc

spool off