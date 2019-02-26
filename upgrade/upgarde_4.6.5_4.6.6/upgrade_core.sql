-------------------------------------------------------------------------------------------------------------
-- OPAS Core
-------------------------------------------------------------------------------------------------------------

define MODNM=OPASCORE
@../../modules/core/install/version.sql
@../../modules/core/install/install_config

conn &localscheme./&localscheme.@&localdb.

set define off

@../../modules/core/source/COREMOD_EXPIMP_SPEC.SQL
@../../modules/core/source/COREMOD_EXPIMP_BODY.SQL

set define on

set define ~

/*
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
*/
set define &

exec COREMOD.register(p_modname => '&MODNM.', p_modver => '&MODVER.', p_installed => sysdate);

commit;

begin
  COREMOD_EXPIMP.init();
end;
/
