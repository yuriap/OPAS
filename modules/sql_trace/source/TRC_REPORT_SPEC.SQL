CREATE OR REPLACE
package trc_report
ACCESSIBLE BY (package TRC_FILE_API)
as

  procedure getreport(p_trc_file_id trc_files.trc_file_id%type);

end;
/
