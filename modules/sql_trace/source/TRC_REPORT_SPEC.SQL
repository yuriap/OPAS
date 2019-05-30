CREATE OR REPLACE
package trc_report
as
  procedure getreport(p_trc_file_id trc_files.trc_file_id%type);
  procedure getstatssect(p_trc_file_id trc_files.trc_file_id%type, p_call_id trc_call.call_id%type,p_report out coremod_report_utils.t_output_lines);
end;
/
