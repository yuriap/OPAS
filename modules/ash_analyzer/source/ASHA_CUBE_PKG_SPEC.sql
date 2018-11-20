CREATE OR REPLACE
PACKAGE ASHA_CUBE_PKG AS

  c_datetime_fmt         constant varchar2(100) := 'YYYY/MM/DD HH24:MI:SS';
  c_source               constant varchar2(100) := 'SOURCE';
  c_dblink               constant varchar2(100) := 'DBLINK';
  c_cubeagg              constant varchar2(100) := 'CUBEAGG';
  c_inst_id              constant varchar2(100) := 'INST_ID';
  c_start_dt             constant varchar2(100) := 'START_DT';
  c_end_dt               constant varchar2(100) := 'END_DT';
  c_filter               constant varchar2(100) := 'FILTER';
  c_dump_id              constant varchar2(100) := 'DUMP_ID';
  c_metric_id            constant varchar2(100) := 'METRIC_ID';
  c_metricgroup_id       constant varchar2(100) := 'METRICGROUP_ID';
  c_metricagg            constant varchar2(100) := 'METRICAGG';
  c_block_analyze        constant varchar2(100) := 'BLOCKANALYZE';
  c_unknown_analyze      constant varchar2(100) := 'UNKNOWNANALYZE';
  c_monitor              constant varchar2(100) := 'MONITOR';
  c_top_sess             constant varchar2(100) := 'TOP_SESS';

  c_date_interval        constant varchar2(100) := 'DATE_INTERVAL';

  procedure load_cube         (p_sess_id asha_cube_sess.sess_id%type);
  procedure load_cube_mon     (p_sess_id asha_cube_sess.sess_id%type);

  procedure init_session(p_proj_id          asha_cube_sess.sess_proj_id%type,
                         p_retention        asha_cube_sess.sess_retention_days%type,
                         p_sess_id   in out asha_cube_sess.sess_id%type);

  procedure load_par_tmpl(p_tmpl_id          asha_cube_sess_tmpl.tmpl_id%type,
                          p_sess_id          asha_cube_sess.sess_id%type);

  procedure add_parameter(p_sess_id         asha_cube_sess.sess_id%type,
                          p_param_name      asha_cube_sess_pars.sess_par_nm%type,
                          p_value           asha_cube_sess_pars.sess_par_val%type);
  function get_parameter (p_param_name      asha_cube_sess_pars.sess_par_nm%type) return asha_cube_sess_pars.sess_par_val%type;

END ASHA_CUBE_PKG;
/
