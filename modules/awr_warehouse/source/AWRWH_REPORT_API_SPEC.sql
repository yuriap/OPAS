CREATE OR REPLACE
PACKAGE AWRWH_REPORT_API AS

  procedure create_report_awrrpt(p_proj_id      awrwh_reports.proj_id%type,
                                 p_dbid         number,
                                 p_min_snap     number,
                                 p_max_snap     number,
                                 p_instance_num number,
                                 p_dump_id      awrwh_dumps.dump_id%type default null,
                                 p_dblink       varchar2 default null);

  procedure create_report_awrrpt(p_proj_id      awrwh_reports.proj_id%type,
                                 p_dump_id      awrwh_dumps.dump_id%type);
--=============================================================================================================================================
  procedure create_report_sqawrrpt(p_proj_id      awrwh_reports.proj_id%type,
                                   p_sql_id       varchar2,
                                   p_dbid         number,
                                   p_min_snap     number,
                                   p_max_snap     number,
                                   p_instance_num number,
                                   p_dump_id      awrwh_dumps.dump_id%type default null,
                                   p_dblink       varchar2 default null);

  procedure create_report_sqawrrpt(p_proj_id      awrwh_reports.proj_id%type,
                                   p_sql_id       varchar2,
                                   p_dump_id      awrwh_dumps.dump_id%type);
--=============================================================================================================================================
  procedure create_report_diffrpt(p_proj_id       awrwh_reports.proj_id%type,
                                  p_dbid1         number,
                                  p_min_snap1     number,
                                  p_max_snap1     number,
                                  p_instance_num1 number,
                                  p_dbid2         number,
                                  p_min_snap2     number,
                                  p_max_snap2     number,
                                  p_instance_num2 number,
                                  p_dump_id1      awrwh_dumps.dump_id%type default null,
                                  p_dump_id2      awrwh_dumps.dump_id%type default null,
                                  p_dblink        varchar2 default null);

  procedure create_report_diffrpt(p_proj_id      awrwh_reports.proj_id%type,
                                  p_dump_id1      awrwh_dumps.dump_id%type,
                                  p_dump_id2      awrwh_dumps.dump_id%type);
--=============================================================================================================================================
  procedure create_report_ashrpt(p_proj_id      awrwh_reports.proj_id%type,
                                 p_dbid         number,
                                 p_bdate        date,
                                 p_edate        date,
                                 p_instance_num number,
                                 p_dump_id      awrwh_dumps.dump_id%type default null,
                                 p_dblink       varchar2 default null);

  procedure create_report_ashrpt(p_proj_id      awrwh_reports.proj_id%type,
                                 p_dump_id      awrwh_dumps.dump_id%type);
--=============================================================================================================================================
  procedure queue_report_awrcomp(p_proj_id      awrwh_reports.proj_id%type,
                                 p_dump_id1     awrwh_dumps.dump_id%type,
                                 p_dump_id2     awrwh_dumps.dump_id%type,
                                 p_sort         varchar2,
                                 p_sort_limit   number,
                                 p_filter       varchar2);
  procedure report_awrcomp (p_report_id      awrwh_reports.report_id%type);
--==============================================================================================
  procedure edit_report_properties(p_report_id          awrwh_reports.report_id%type,
                                   p_report_retention   awrwh_reports.report_retention%type,
                                   p_report_note        awrwh_reports.report_note%type);
  procedure delete_report(p_proj_id            awrwh_reports.proj_id%type,
                          p_report_id          awrwh_reports.report_id%type);
END AWRWH_REPORT_API;
/
