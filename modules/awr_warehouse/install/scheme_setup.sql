-- AWR WareHouse schema setup

create or replace directory &dirname. as '&dirpath.';
grant read, write on directory &dirname. to &localscheme.;

grant select on V_$METRICGROUP to &localscheme.;
grant select on dba_users to &localscheme.;
grant execute on dbms_swrf_internal to &localscheme.;
grant execute on dbms_workload_repository to &localscheme.;
grant select on DBA_HIST_SNAPSHOT to &localscheme.;

grant create user to &localscheme.;
grant drop user to &localscheme.;
grant alter user to &localscheme.;

grant select on dba_hist_sqlstat to &localscheme.;
grant select on dba_hist_database_instance to &localscheme.;
grant select on dba_hist_snapshot to &localscheme.;
grant select on dba_hist_active_sess_history to &localscheme.;
grant select on dba_procedures to &localscheme.;
grant select on DBA_HIST_SQL_PLAN to &localscheme.;
grant select on DBA_HIST_SQL_BIND_METADATA to &localscheme.;
grant select on DBA_HIST_SQLBIND to &localscheme.;
grant select on V_$DATABASE to &localscheme.;
grant select on AWR_ROOT_SQL_PLAN to &localscheme.;
grant select on AWR_ROOT_SQLTEXT to &localscheme.;
grant select on dba_users to &localscheme.;
grant select on dba_hist_sysmetric_history to &localscheme.;
grant select on v_$active_session_history to &localscheme.;
grant select on dba_hist_reports to &localscheme.;
grant select on gv_$active_session_history to &localscheme.;
grant select on V_$METRICGROUP to &localscheme.;
grant select on DBA_HIST_METRIC_NAME to &localscheme.;
grant select on V_$METRICNAME to &localscheme.;
grant select on dba_objects to &localscheme.;
grant select on dba_data_files to &localscheme.;

grant select on AWR_PDB_SQL_PLAN to &localscheme.;
grant select on AWR_PDB_SQLTEXT to &localscheme.;