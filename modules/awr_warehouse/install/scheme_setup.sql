-- ASH Analyzer schema setup

grant select on V_$METRICGROUP to &localscheme.;
grant select on dba_users to &localscheme.;
grant execute on dbms_swrf_internal to &localscheme.;
grant execute on dbms_workload_repository to &localscheme.;
grant select on DBA_HIST_SNAPSHOT to &localscheme.;