CREATE OR REPLACE
PACKAGE TRC_PROCESSFILE
ACCESSIBLE BY (package TRC_FILE_API)
AS

  procedure parse_file(p_trc_file_id trc_files.trc_file_id%type);

END TRC_PROCESSFILE;
/
