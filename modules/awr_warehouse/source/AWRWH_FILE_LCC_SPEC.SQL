CREATE OR REPLACE
package AWRWH_FILE_LCC as

  -- Dump file actions
  c_dmpfile_create         constant varchar2(20) :='CREATE';
  c_dmpfile_loadfile       constant varchar2(20) :='LOAD FILE';           -- load dump data
  c_dmpfile_editfile       constant varchar2(20) :='EDIT FILE';           -- edit dump metadata
  c_dmpfile_putinqueue     constant varchar2(20) :='PUT IN QUEUE';        -- put in processing queue
  c_dmpfile_startprocess   constant varchar2(20) :='START PROCESSING';    -- start processing
  c_dmpfile_finishprocess  constant varchar2(20) :='FINISH PROCESSING';   -- finish processing
  c_dmpfile_failprocess    constant varchar2(20) :='FAIL PROCESSING';     -- fail processing
  c_dmpfile_awrload        constant varchar2(20) :='AWR LOAD';            -- load from AWR
  c_dmpfile_awrunload      constant varchar2(20) :='AWR UNLOAD';          -- unload from AWR
  c_dmpfile_compress       constant varchar2(20) :='COMPRESS';
  c_dmpfile_archive        constant varchar2(20) :='ARCHIVE';
  c_dmpfile_dropfile       constant varchar2(20) :='DROP FILE';

  --Dump file states
  c_dmpfilestate_new               constant awrwh_dumps.status%type := 'NEW';                -- just created
  c_dmpfilestate_dmploaded         constant awrwh_dumps.status%type := 'DUMP LOADED';        -- file loaded
  c_dmpfilestate_inqueue           constant awrwh_dumps.status%type := 'IN QUEUE';           -- processing queue
  c_dmpfilestate_processing        constant awrwh_dumps.status%type := 'PROCESSING';         -- being processed (load, unload, etc)
  c_dmpfilestate_failed            constant awrwh_dumps.status%type := 'FAILED';             -- failed
  c_dmpfilestate_awrloaded         constant awrwh_dumps.status%type := 'LOADED INTO AWR';    -- file parsed
  c_dmpfilestate_compressed        constant awrwh_dumps.status%type := 'COMPRESSED';         -- source data removed, parsed is available
  c_dmpfilestate_archived          constant awrwh_dumps.status%type := 'ARCHIVED';           -- source and parsed data removed
  c_dmpfilestate_dropped           constant awrwh_dumps.status%type := 'DROPPED';

  --Dump file life-cycle set state
  procedure dmpfile_exec_action(p_awrwh_dumps awrwh_dumps%rowtype, p_action varchar2, p_process_action varchar2 default null);
  procedure dmpfile_exec_action(p_dump_id awrwh_dumps.dump_id%type, p_action varchar2, p_process_action varchar2 default null);

  --Dump file action availability
  function dmpfile_check_action(p_dump_id awrwh_dumps.dump_id%type, p_action varchar2) return boolean;
  function dmpfile_check_action_vc(p_dump_id awrwh_dumps.dump_id%type, p_action varchar2) return varchar2;
  function dmpfile_check_action(p_awrwh_dumps awrwh_dumps%rowtype, p_action varchar2) return boolean;

end AWRWH_FILE_LCC;
/
