CREATE OR REPLACE
package coremod_reports
as

  function getreport_sql_memory_stats(p_sql_id varchar2, p_dblink varchar2) return coremod_report_utils.t_output_lines;
  function queue_report_sql_memory_stats(p_modname varchar2, p_owner varchar2, p_sql_id varchar2, p_dblink varchar2) return opas_reports.report_id%type;
  procedure queue_report_sql_memory_stats_recursive(p_report_id opas_reports.report_id%type);

  function getreport_sql_awr_stats(p_sql_id varchar2,
                                   p_dblink varchar2,
                                   p_report_limit number,
                                   p_dbid number,
                                   p_min_snap number,
                                   p_max_snap number,
                                   p_filename out varchar2,
                                   p_displ_params out varchar2) return coremod_report_utils.t_output_lines;

  function queue_report_sql_awr_stats(p_modname varchar2,
                                      p_owner varchar2,
                                      p_sql_id varchar2,
                                      p_dblink varchar2,
                                      p_report_limit number,
                                      p_dbid number default null,
                                      p_min_snap number default null,
                                      p_max_snap number default null) return opas_reports.report_id%type;
  procedure queue_report_sql_awr_stats_recursive(p_report_id opas_reports.report_id%type);

  function getreport_awrrpt(p_dbid number, p_min_snap number, p_max_snap number, p_instance_num varchar2, p_filename out varchar2, p_displ_params out varchar2) return coremod_report_utils.t_output_lines;
  function getreport_awrrpt(p_dbid number, p_min_snap number, p_max_snap number, p_instance_num varchar2, p_dblink varchar2, p_filename out varchar2, p_displ_params out varchar2) return clob;
  function queue_report_awrrpt(p_modname varchar2, p_owner varchar2, p_dbid number, p_min_snap number, p_max_snap number, p_instance_num varchar2, p_dblink varchar2) return opas_reports.report_id%type;

  function getreport_sqawrrpt(p_sql_id varchar2, p_dbid number, p_min_snap number, p_max_snap number, p_instance_num number, p_filename out varchar2, p_displ_params out varchar2) return coremod_report_utils.t_output_lines;
  function getreport_sqawrrpt(p_sql_id varchar2, p_dbid number, p_min_snap number, p_max_snap number, p_instance_num number, p_dblink varchar2, p_filename out varchar2, p_displ_params out varchar2) return clob;
  function queue_report_sqawrrpt(p_modname varchar2, p_owner varchar2, p_sql_id varchar2, p_dbid number, p_min_snap number, p_max_snap number, p_instance_num number, p_dblink varchar2) return opas_reports.report_id%type;

  function getreport_diffrpt(p_dbid1 number, p_min_snap1 number, p_max_snap1 number, p_instance_num1 varchar2,
                             p_dbid2 number, p_min_snap2 number, p_max_snap2 number, p_instance_num2 varchar2, p_filename out varchar2, p_displ_params out varchar2) return coremod_report_utils.t_output_lines;
  function getreport_diffrpt(p_dbid1 number, p_min_snap1 number, p_max_snap1 number, p_instance_num1 varchar2,
                             p_dbid2 number, p_min_snap2 number, p_max_snap2 number, p_instance_num2 varchar2, p_dblink varchar2, p_filename out varchar2, p_displ_params out varchar2) return clob;
  function queue_report_diffrpt(p_modname varchar2, p_owner varchar2,
                                p_dbid1 number, p_min_snap1 number, p_max_snap1 number, p_instance_num1 varchar2,
                                p_dbid2 number, p_min_snap2 number, p_max_snap2 number, p_instance_num2 varchar2, p_dblink varchar2) return opas_reports.report_id%type;

  function getreport_ashrpt(p_dbid number, p_btime date, p_etime date, p_instance_num varchar2, p_filename out varchar2, p_displ_params out varchar2) return coremod_report_utils.t_output_lines;
  function getreport_ashrpt(p_dbid number, p_btime date, p_etime date, p_instance_num varchar2, p_dblink varchar2, p_filename out varchar2, p_displ_params out varchar2) return clob;
  function queue_report_ashrpt(p_modname varchar2, p_owner varchar2, p_dbid number, p_btime date, p_etime date, p_instance_num varchar2, p_dblink varchar2) return opas_reports.report_id%type;

end;
/
