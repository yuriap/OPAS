set define ~

declare
  l_script clob;
begin
  l_script := 
q'[
@../../modules/core/scripts/__ash_summ.sql
]';
  delete from opas_scripts where script_id='PROC_AWRASHSUMM';
  insert into opas_scripts (script_id,modname,script_content) values ('PROC_AWRASHSUMM','~MODNM.',l_script);
  COREMOD_REPORT_UTILS.prepare_saved_sql_script (  P_SCRIPT_NAME => 'PROC_AWRASHSUMM');
end;
/

set define &