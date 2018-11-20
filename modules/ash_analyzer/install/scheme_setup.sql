-- ASH Analyzer schema setup

grant select on V_$METRICGROUP to &localscheme.;
grant select on v_$metricname to &localscheme.;
grant select on dba_hist_sqltext to &localscheme.;