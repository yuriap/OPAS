CREATE OR REPLACE
PACKAGE ASHA_CUBE_API AS

  gMODNAME            constant varchar2(32) := 'ASH_ANALYZER';

  gREPORT_SQL_MEMORY  constant varchar2(32) := 'REPORT_SQL_MEMORY';
  gREPORT_SQL_AWR     constant varchar2(32) := 'REPORT_SQL_AWR';

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
END ASHA_CUBE_API;
/
