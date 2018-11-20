CREATE OR REPLACE
PACKAGE ASHA_CUBE_API AS

  gMODNAME       constant varchar2(32) := 'ASH_ANALYZER';

  function  getMODNAME return varchar2;

  procedure CLEANUP_CUBE;
  procedure refresh_dictionaries;

  procedure add_dic_metrics(p_metric_id number);

  function get_sql_qry_txt(p_srcdb varchar2, p_sql_id varchar2) return clob;

END ASHA_CUBE_API;
/
