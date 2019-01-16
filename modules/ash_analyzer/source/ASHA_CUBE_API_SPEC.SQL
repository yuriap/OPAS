CREATE OR REPLACE
PACKAGE ASHA_CUBE_API AS

  gMODNAME                constant varchar2(32) := 'ASH_ANALYZER';

  function  getMODNAME return varchar2;

  procedure refresh_dictionaries;

  procedure add_dic_metrics(p_metric_id number);

  procedure edit_session(p_sess_id             asha_cube_sess.sess_id%type,
                         p_sess_retention_days asha_cube_sess.sess_retention_days%type,
                         p_sess_description    asha_cube_sess.sess_description%type);

  procedure create_report(p_report_type      varchar2,
                          p_proj_id          asha_cube_reports.proj_id%type,
                          p_sess_id          asha_cube_reports.sess_id%type,
                          p_sql_id           varchar2,
                          p_dblink           varchar2,
                          p_limit            number default 0);

  procedure edit_report_properties(p_report_id          asha_cube_reports.report_id%type,
                                   p_report_retention   asha_cube_reports.report_retention%type,
                                   p_report_note        asha_cube_reports.report_note%type);

  procedure delete_report(p_proj_id          asha_cube_reports.proj_id%type,
                          p_report_id          asha_cube_reports.report_id%type);

--=============================================================================================================================================
  procedure create_report_awrrpt(p_proj_id      asha_cube_reports.proj_id%type,
                                 p_dbid         number,
                                 p_min_snap     number,
                                 p_max_snap     number,
                                 p_instance_num varchar2,
                                 p_dblink       varchar2 default null,
                                 p_sess_id      asha_cube_reports.sess_id%type default null);
--=============================================================================================================================================
  procedure create_report_sqawrrpt(p_proj_id      asha_cube_reports.proj_id%type,
                                   p_sql_id       varchar2,
                                   p_dbid         number,
                                   p_min_snap     number,
                                   p_max_snap     number,
                                   p_instance_num number,
                                   p_dblink       varchar2 default null,
                                   p_sess_id      asha_cube_reports.sess_id%type default null);
--=============================================================================================================================================
  procedure create_report_diffrpt(p_proj_id       asha_cube_reports.proj_id%type,
                                  p_dbid1         number,
                                  p_min_snap1     number,
                                  p_max_snap1     number,
                                  p_instance_num1 varchar2,
                                  p_dbid2         number,
                                  p_min_snap2     number,
                                  p_max_snap2     number,
                                  p_instance_num2 varchar2,
                                  p_dblink        varchar2 default null,
                                  p_sess_id       asha_cube_reports.sess_id%type default null);
--=============================================================================================================================================
  procedure create_report_ashrpt(p_proj_id      asha_cube_reports.proj_id%type,
                                 p_dbid         number,
                                 p_bdate        date,
                                 p_edate        date,
                                 p_instance_num varchar2,
                                 p_dblink       varchar2 default null,
                                 p_sess_id      asha_cube_reports.sess_id%type default null);
--=============================================================================================================================================
  procedure create_awrsql_report(p_proj_id          asha_cube_reports.proj_id%type,
                                 p_sess_id          asha_cube_reports.sess_id%type default null,
                                 p_sql_id           varchar2,
                                 p_dblink           varchar2,
                                 p_limit            number,
                                 p_dbid             number,
                                 p_min_snap         number,
                                 p_max_snap         number);

END ASHA_CUBE_API;
/
