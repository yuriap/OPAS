CREATE OR REPLACE
PACKAGE COREMOD_REPORT_UTILS AS

  type t_output_lines is table of varchar2(32767) index by pls_integer;

  --custom reports
  gSQL_MEMORY_REPORT       constant varchar2(32) := 'SQL_MEMORY_REPORT';
  --gparDBLINK, gparSQLID, gparOWNER
  gSQL_AWR_REPORT          constant varchar2(32) := 'SQL_AWR_REPORT';
  --gparDBLINK, gparSQLID, gparOWNER,gparREP_LIMIT

  --params
  gparDBLINK                  constant varchar2(32) := 'PAR_DBLINK';
  gparSQLID                   constant varchar2(32) := 'PAR_SQLID';
  gparOWNER                   constant varchar2(32) := 'PAR_OWNER';
  gparREP_LIMIT               constant varchar2(32) := 'PAR_REPORT_LIMIT';

  procedure init_report(p_modname opas_reports.modname%type, p_report_id out opas_reports.report_id%type, p_parent_report opas_reports.report_id%type default null);
  procedure set_report_type(p_report_id opas_reports.report_id%type, p_report_type varchar2);

  procedure set_report_param(p_report_id opas_reports.report_id%type, p_name opas_reports_pars.par_name%type, p_num_par number);
  procedure set_report_param(p_report_id opas_reports.report_id%type, p_name opas_reports_pars.par_name%type, p_varchar_par varchar2);
  procedure set_report_param(p_report_id opas_reports.report_id%type, p_name opas_reports_pars.par_name%type, p_date_par date);

  procedure queue_report(p_report_id opas_reports.report_id%type);
  --for task
  procedure execute_report(p_report_id opas_reports.report_id%type);

  procedure drop_report(p_report_id opas_reports.report_id%type);
  --===========================================================================

  --script preparation
  procedure prepare_saved_sql_script(p_script_name opas_scripts.script_id%type);
  procedure prepare_script(p_script in out clob,
                           p_sqlid varchar2,
                           p_dbid varchar2 default null,
                           p_inst_id varchar2 default null,
                           p_start_snap number default null,
                           p_end_snap number default null);

  procedure execute_plsql_remotelly(p_sql varchar2, p_dblink varchar2, p_output out clob, p_is_output boolean default true);
  procedure execute_plsql_remotelly(p_sql varchar2, p_dblink varchar2, p_output out t_output_lines);
  procedure print_table_html_remotelly(p_query in varchar2,
                                       p_width number,
                                       p_summary varchar2,
                                       p_search varchar2 default null,
                                       p_replacement varchar2 default null,
                                       p_style1 varchar2 default 'awrc1',
                                       p_style2  varchar2 default 'awrnc1',
                                       p_header number default 0,
                                       p_break_col varchar2 default null,
                                       p_dblink varchar2,
                                       p_output out t_output_lines);
  procedure print_table_html(p_query in varchar2,
                             p_width number,
                             p_summary varchar2,
                             p_search varchar2 default null,
                             p_replacement varchar2 default null,
                             p_style1 varchar2 default 'awrc1',
                             p_style2  varchar2 default 'awrnc1',
                             p_header number default 0,
                             p_break_col varchar2 default null,
                             p_output in out t_output_lines);

  procedure print_table_html_new
                            (p_query in varchar2,
                             p_width number,
                             p_summary varchar2,
                             p_style_tab varchar2,
                             p_style_head varchar2, --head
                             p_style_r1 varchar2,   --odd rows
                             p_style_r2  varchar2, --even rows
                             p_style_finrow  varchar2, --final row
                             p_search varchar2 default null,
                             p_replacement varchar2 default null,
                             p_header number default 0,
                             p_break_col varchar2 default null,
                             p_output in out t_output_lines);

  procedure print_text_as_table(p_text clob, p_t_header varchar2, p_width number, p_search varchar2 default null, p_replacement varchar2 default null, p_comparison boolean default false, p_output out t_output_lines);

  procedure print_text_as_table_new(p_text clob,
                                    p_t_header varchar2,
                                    p_width number,
                                    p_search varchar2 default null,
                                    p_replacement varchar2 default null,
                                    p_comparison boolean default false,
                                    p_style_tab varchar2,
                                    p_style_head varchar2, --head
                                    p_style_r1 varchar2,   --odd rows
                                    p_style_r2  varchar2, --even rows
                                    p_output in out t_output_lines);

  procedure save_report_for_download(p_file opas_files.file_id%type);

  --long ops for reports
  procedure set_report_timing(p_timing boolean);
  procedure init_lo_report(p_op_name varchar2, p_target_desc varchar2, p_units varchar2, p_totalwork number);
  procedure start_lo_section(p_module_name varchar2, p_action_name varchar2);
  function  end_lo_section(p_is_finished boolean default false) return varchar2;
end;
/
