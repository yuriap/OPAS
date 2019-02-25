CREATE OR REPLACE
PACKAGE COREMOD_REPORT_UTILS AS

  type t_output_lines is table of varchar2(32767) index by pls_integer;

  gReportMimeType          constant varchar2(32) := 'TEXT/HTML';

  gDTFMT                   constant varchar2(32) := 'YYYYMMDDHH24MISS';
  gShortDTFMT              constant varchar2(32) := 'YYYYMMDDHH24MI';

  --custom reports
  gSQL_MEMORY_REPORT       constant varchar2(32) := 'CUST_SQL_MEM_REPORT';
  --gparDBLINK, gparSQLID, gparOWNER
  gSQL_AWR_REPORT          constant varchar2(32) := 'CUST_SQL_AWR_REPORT';
  --gparDBLINK, gparSQLID, gparOWNER,gparREP_LIMIT

  --standard AWR reports
  qAWRRPT                  constant varchar2(32) := 'AWR_REPORT';
  --gparDBID, gparMIN_SNAP, gparMAX_SNAP, gparINSTANCE_NUM, gparDBLINK
  qSQAWRRPT                constant varchar2(32) := 'AWR_SQL_REPORT';
  --gparSQLID, gparDBID, gparMIN_SNAP, gparMAX_SNAP, gparINSTANCE_NUM, gparDBLINK
  qAWRDIFF                 constant varchar2(32) := 'AWR_DIFF';
  --gparDBID, gparMIN_SNAP, gparMAX_SNAP, gparINSTANCE_NUM, gparDBID2, gparMIN_SNAP2, gparMAX_SNAP2, gparINSTANCE_NUM2, gparDBLINK
  qASHRPT                  constant varchar2(32) := 'ASH_REPORT';
  --gparDBID, gparBTIME, gparETIME, gparINSTANCE_NUM, gparDBLINK

  --params
  gparDBLINK               constant varchar2(32) := 'PAR_DBLINK';
  gparSQLID                constant varchar2(32) := 'PAR_SQLID';
  gparOWNER                constant varchar2(32) := 'PAR_OWNER';
  gparREP_LIMIT            constant varchar2(32) := 'PAR_REPORT_LIMIT';

  gparDBID                 constant varchar2(32) := 'PAR_DBID';
  gparMIN_SNAP             constant varchar2(32) := 'PAR_MIN_SNAP';
  gparMAX_SNAP             constant varchar2(32) := 'PAR_MAX_SNAP';
  gparINSTANCE_NUM         constant varchar2(32) := 'PAR_INSTANCE_NUM';

  gparDBID2                constant varchar2(32) := 'PAR_DBID2';
  gparMIN_SNAP2            constant varchar2(32) := 'PAR_MIN_SNAP2';
  gparMAX_SNAP2            constant varchar2(32) := 'PAR_MAX_SNAP2';
  gparINSTANCE_NUM2        constant varchar2(32) := 'PAR_INSTANCE_NUM2';

  gparBTIME                constant varchar2(32) := 'PAR_BTIME';
  gparETIME                constant varchar2(32) := 'PAR_ETIME';

  procedure init_report(p_modname opas_reports.modname%type, p_report_id out opas_reports.report_id%type, p_parent_report opas_reports.report_id%type default null);
  procedure set_report_type(p_report_id opas_reports.report_id%type, p_report_type varchar2);
  function  get_report_type(p_report_id opas_reports.report_id%type) return varchar2;

  procedure set_report_param(p_report_id opas_reports.report_id%type, p_name opas_reports_pars.par_name%type, p_num_par number);
  procedure set_report_param(p_report_id opas_reports.report_id%type, p_name opas_reports_pars.par_name%type, p_varchar_par varchar2);
  procedure set_report_param(p_report_id opas_reports.report_id%type, p_name opas_reports_pars.par_name%type, p_date_par date);

  function get_reppar_n(p_report_id opas_reports.report_id%type, p_name opas_reports_pars.par_name%type, p_validate boolean default true) return number result_cache;
  function get_reppar_c(p_report_id opas_reports.report_id%type, p_name opas_reports_pars.par_name%type, p_validate boolean default true) return varchar2 result_cache;
  function get_reppar_d(p_report_id opas_reports.report_id%type, p_name opas_reports_pars.par_name%type, p_validate boolean default true) return date result_cache;

  procedure queue_report(p_report_id opas_reports.report_id%type);
  procedure set_report_task(p_report_id opas_reports.report_id%type, p_tq_id opas_task_queue.tq_id%type);
  procedure set_report_content(p_report_id opas_reports.report_id%type, p_content opas_reports.report_content%type, p_displ_params opas_reports.report_params_displ%type);
  --for task
  procedure execute_report(p_report_id opas_reports.report_id%type);

  procedure drop_report(p_report_id opas_reports.report_id%type);

  function get_inst_list(p_list varchar2, p_col_nm varchar2) return varchar2;
  function get_inst_list(p_list AWRRPT_INSTANCE_LIST_TYPE, p_col_nm varchar2) return varchar2;
  function get_inst_list(p_list varchar2) return AWRRPT_INSTANCE_LIST_TYPE;
  --===========================================================================

  --script preparation
  procedure prepare_saved_sql_script(p_script_name opas_scripts.script_id%type);
  procedure prepare_script(p_script in out clob,
                           p_sqlid varchar2,
                           p_dbid varchar2 default null,
                           p_inst_id varchar2 default null,
                           p_start_snap number default null,
                           p_end_snap number default null);

  procedure execute_plsql(p_sql varchar2, p_output out clob, p_is_output boolean default true);
  procedure execute_plsql_remotelly(p_sql varchar2, p_dblink varchar2, p_output out clob, p_is_output boolean default true);
  procedure execute_plsql_remotelly(p_sql varchar2, p_dblink varchar2, p_output out t_output_lines);
  procedure get_clob_remotelly(p_sql varchar2, p_dblink varchar2, p_output out clob);

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

  -- query cache
  procedure CLEANUP_CACHE;
  function get_sql_qry_txt(p_srcdb varchar2, p_sql_id varchar2) return clob;
  procedure pin_sql_in_cache(p_sql_id varchar2, p_days number default 180);
  function get_sql_search_query(p_srcdb varchar2, p_sql_search_str varchar2, p_use_cache varchar2 default 'N', p_result_limit number default 0) return varchar2;
  function get_sql_search_query(p_srcdb varchar2, p_sql_search_expr varchar2, p_use_cache varchar2 default 'N', p_result_limit number default 0) return varchar2;

end;
/
