CREATE OR REPLACE
package coremod_reports
as

  function getreport_sql_memory_stats(p_sql_id varchar2, p_dblink varchar2) return coremod_report_utils.t_output_lines;
  function queue_report_sql_memory_stats(p_modname varchar2, p_owner varchar2, p_sql_id varchar2, p_dblink varchar2) return opas_reports.report_id%type;

  function getreport_sql_awr_stats(p_sql_id varchar2, p_dblink varchar2, p_report_limit number) return coremod_report_utils.t_output_lines;
  function queue_report_sql_awr_stats(p_modname varchar2, p_owner varchar2, p_sql_id varchar2, p_dblink varchar2, p_report_limit number) return opas_reports.report_id%type;


end;
/
