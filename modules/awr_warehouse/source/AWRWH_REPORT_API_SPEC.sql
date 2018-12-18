CREATE OR REPLACE
PACKAGE AWRWH_REPORT_API AS

  procedure create_report_awrrpt(p_proj_id      awrwh_reports.proj_id%type,
                                 p_dbid         number,
                                 p_min_snap     number,
                                 p_max_snap     number,
                                 p_instance_num number default 1);

  procedure create_report_awrrpt(p_proj_id      awrwh_reports.proj_id%type,
                                 p_dump_id      awrwh_dumps.dump_id%type);

  procedure edit_report_properties(p_report_id          awrwh_reports.report_id%type,
                                   p_report_retention   awrwh_reports.report_retention%type,
                                   p_report_note        awrwh_reports.report_note%type);
  procedure delete_report(p_proj_id            awrwh_reports.proj_id%type,
                          p_report_id          awrwh_reports.report_id%type);
END AWRWH_REPORT_API;
/
