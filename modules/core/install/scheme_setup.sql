create bigfile tablespace &tblspc_name. datafile size 100m autoextend on next 100m maxsize 1000m;

create user &localscheme. identified by &localscheme.
default tablespace &tblspc_name.
temporary tablespace temp;
alter user &localscheme. quota unlimited on &tblspc_name.;

grant connect, resource to &localscheme.;
grant select_catalog_role to &localscheme.;
grant select any table to &localscheme.;
grant execute on dbms_lock to &localscheme.;
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