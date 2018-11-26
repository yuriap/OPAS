CREATE OR REPLACE
PACKAGE ASHA_CUBE_API AS

  gMODNAME       constant varchar2(32) := 'ASH_ANALYZER';

  function  getMODNAME return varchar2;

  procedure CLEANUP_CUBE;
  procedure refresh_dictionaries;

  procedure add_dic_metrics(p_metric_id number);

  function get_sql_qry_txt(p_srcdb varchar2, p_sql_id varchar2) return clob;

  procedure edit_session(p_sess_id             asha_cube_sess.sess_id%type,
                         p_sess_retention_days asha_cube_sess.sess_retention_days%type,
                         p_sess_description    asha_cube_sess.sess_description%type);

END ASHA_CUBE_API;
/
