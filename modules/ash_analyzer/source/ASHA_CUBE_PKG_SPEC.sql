CREATE OR REPLACE
PACKAGE ASHA_CUBE_PKG AS

  procedure load_cube         (p_sess_id in out number,
                               p_source varchar2,
                               p_dblink varchar2,
                               p_agg varchar2,
                               p_inst_id varchar2,
                               p_start_dt date,
                               p_end_dt date,
                               p_filter varchar2,
                               p_dump_id number default null,
                               p_metric_id number default null,
                               p_metricgroup_id number default null,
                               p_aggr_func varchar2 default null,
                               p_block_analyze boolean default false,
                               p_unknown_analyze boolean default false,
                               p_monitor boolean default false);

  procedure load_cube_mon     (p_sess_id number,
                               p_source varchar2,
                               p_dblink varchar2,
                               p_agg varchar2,
                               p_inst_id varchar2,
                               p_start_dt date,
                               p_end_dt date,
                               p_filter varchar2,
                               p_dump_id number default null,
                               p_metric_id number default null,
                               p_metricgroup_id number default null,
                               p_aggr_func varchar2 default null,
                               p_block_analyze boolean default false,
                               p_unknown_analyze boolean default false,
                               p_monitor boolean default false);

  procedure load_dic(p_db_link varchar2, p_src_tab varchar2);

END ASHA_CUBE_PKG;
/
