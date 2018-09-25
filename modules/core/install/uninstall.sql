--Core uninstallation script

conn sys/&localsys.@&localdb. as sysdba

set serveroutput on
begin
  for i in (select sid, serial#, inst_id from gv$session where username=upper('&localscheme.')) loop
    dbms_output.put_line('About to kill a session: '||i.sid||','||i.serial#||',@'||i.inst_id);
    execute immediate q'[alter system kill session ']'||i.sid||','||i.serial#||',@'||i.inst_id||q'[']';
  end loop;
end;
/
set serveroutput off

drop user &localscheme. cascade;
rem drop tablespace &tblspc_name. including contents and datafiles;

begin
  DBMS_SCHEDULER.DROP_JOB_CLASS (job_class_name  => 'OPASLIGHTJOBS');
end;
/

disc