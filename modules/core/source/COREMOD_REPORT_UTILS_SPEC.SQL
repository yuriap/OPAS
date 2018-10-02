PACKAGE COREMOD_REPORT_UTILS AS

  type t_output_lines is table of varchar2(32767) index by pls_integer;

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
