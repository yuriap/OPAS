create bigfile tablespace &tblspc_name. datafile size 100m autoextend on next 100m maxsize 1000m;

create user &localscheme. identified by &localscheme.
default tablespace &tblspc_name.
temporary tablespace temp;
alter user &localscheme. quota unlimited on &tblspc_name.;

grant connect, resource to &localscheme.;
grant select_catalog_role to &localscheme.;
grant select any table to &localscheme.;
grant execute on dbms_lock to &localscheme.;
grant execute on dbms_workload_repository to &localscheme.;
grant create view to &localscheme.;
grant create synonym to &localscheme.;
grant create job to &localscheme.;
grant execute on dbms_xplan to &localscheme.;
grant create database link to &localscheme.;
grant alter session to &localscheme.;

--APEX 18.1 uploading files
grant update on apex_180100.WWV_FLOW_TEMP_FILES to &localscheme.;
grant select on v_$session to &localscheme.;
grant select on gv_$session to &localscheme.;
grant select on v_$parameter to &localscheme.;
grant select on dba_hist_sqltext to &localscheme.;

begin
DBMS_SCHEDULER.CREATE_JOB_CLASS (
   job_class_name            => 'OPASLIGHTJOBS',
   logging_level             => DBMS_SCHEDULER.LOGGING_FAILED_RUNS,
   log_history               => 1,
   comments                  => 'Low logging level for coordinator jobs');
end;
/

grant execute on OPASLIGHTJOBS to &localscheme.;

set serveroutput on
begin
  for i in (select * from dba_tab_privs where grantee='SELECT_CATALOG_ROLE')
  loop
  begin
    execute immediate 'grant '||i.privilege||' on '||i.table_name||' to &localscheme.';
  exception
    when others then null; -- dbms_output.put_line(i.table_name||':'||i.privilege||': '||sqlerrm);
  end;
  end loop;
end;
/
