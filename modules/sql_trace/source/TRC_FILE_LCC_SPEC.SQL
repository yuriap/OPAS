CREATE OR REPLACE
package TRC_FILE_LCC as

  -- Trace file actions
  c_trcfile_create        constant varchar2(20) :='CREATE';
  c_trcfile_edit          constant varchar2(20) :='EDIT';
  c_trcfile_drop          constant varchar2(20) :='DROP';
  c_trcfile_load          constant varchar2(20) :='LOAD';  -- load source data
  c_trcfile_inparsequeue  constant varchar2(20) :='IN PARSE QUEUE';  -- put in parse source data queue
  c_trcfile_startparse    constant varchar2(20) :='START PARSE';  -- start parse source data
  c_trcfile_finishparse   constant varchar2(20) :='FINISH PARSE';  -- finish parse source data
  c_trcfile_failparse     constant varchar2(20) :='FAIL PARSE';  -- fail parse source data
  c_trcfile_report_vw     constant varchar2(20) :='VIEW REPORT';  -- view reports
  c_trcfile_compress      constant varchar2(20) :='COMPRESS';
  c_trcfile_archive       constant varchar2(20) :='ARCHIVE';
  c_trcfile_discover      constant varchar2(20) :='DISCOVER';
  c_trcfile_reparse       constant varchar2(20) :='REPARSE';


  --Trace file states
  c_trcfilestate_new         constant trc_files.status%type := 'NEW';        --just created
  c_trcfilestate_loaded      constant trc_files.status%type := 'LOADED';     --file loaded
  c_trcfilestate_parsequeue  constant trc_files.status%type := 'PARSEQUEUE';
  c_trcfilestate_parsing     constant trc_files.status%type := 'PARSING';    --being parsed
  c_trcfilestate_parsed      constant trc_files.status%type := 'PARSED';     --file parsed
  c_trcfilestate_compressed  constant trc_files.status%type := 'COMPRESSED'; --source data removed, parsed is available
  c_trcfilestate_archived    constant trc_files.status%type := 'ARCHIVED';   --source and parsed data removed

  --Trace file life-cycle set state
  procedure trcfile_exec_action(p_trc_file trc_files%rowtype, p_action varchar2);
  procedure trcfile_exec_action(p_trc_file_id trc_files.trc_file_id%type, p_action varchar2);

  --Trace file action availability
  function trcfile_check_action(p_trc_file_id trc_files.trc_file_id%type, p_action varchar2) return boolean;
  function trcfile_check_action_vc(p_trc_file_id trc_files.trc_file_id%type, p_action varchar2) return varchar2;
  function trcfile_check_action(p_trc_file trc_files%rowtype, p_action varchar2) return boolean;

end TRC_FILE_LCC;
/
