CREATE OR REPLACE
package AWRWH_FILE_LCC as

  -- Dump file actions
  c_dmpfile_create         constant varchar2(20) :='CREATE';
  c_dmpfile_loadfile       constant varchar2(20) :='LOAD FILE';        -- load dump data
  c_dmpfile_inawrloadqueue constant varchar2(20) :='IN AWR LOAD QUEUE';   -- put in parse source data queue
  c_dmpfile_startawrload   constant varchar2(20) :='START AWR LOAD';      -- start parse source data
  c_dmpfile_finishawrload  constant varchar2(20) :='FINISH AWR LOAD';     -- finish parse source data
  c_dmpfile_failawrload    constant varchar2(20) :='FAIL AWR LOAD';       -- fail parse source data
  c_dmpfile_awrunload      constant varchar2(20) :='AWR UNLOAD';          -- unload from AWR
  c_dmpfile_compress       constant varchar2(20) :='COMPRESS';
  c_dmpfile_archive        constant varchar2(20) :='ARCHIVE';
  c_dmpfile_dropfile       constant varchar2(20) :='DROP FILE';

  --Dump file states
  c_dmpfilestate_new            constant awrwh_dumps.status%type := 'NEW';        --just created
  c_dmpfilestate_dmploaded      constant awrwh_dumps.status%type := 'DUMP LOADED';  --file loaded
  c_dmpfilestate_awrloadqueue   constant awrwh_dumps.status%type := 'IN AWR LOAD QUEUE';
  c_dmpfilestate_awrloading     constant awrwh_dumps.status%type := 'LOADING INTO AWR';    --being parsed
  c_dmpfilestate_awrloaded      constant awrwh_dumps.status%type := 'LOADED INTO AWR';  --file parsed
  c_dmpfilestate_compressed     constant awrwh_dumps.status%type := 'COMPRESSED'; --source data removed, parsed is available
  c_dmpfilestate_archived       constant awrwh_dumps.status%type := 'ARCHIVED';   --source and parsed data removed

  --Dump file life-cycle set state
  procedure dmpfile_exec_action(p_awrwh_dumps awrwh_dumps%rowtype, p_action varchar2);
  procedure dmpfile_exec_action(p_dump_id awrwh_dumps.dump_id%type, p_action varchar2);

  --Dump file action availability
  function dmpfile_check_action(p_dump_id awrwh_dumps.dump_id%type, p_action varchar2) return boolean;
  function dmpfile_check_action_vc(p_dump_id awrwh_dumps.dump_id%type, p_action varchar2) return varchar2;
  function dmpfile_check_action(p_awrwh_dumps awrwh_dumps%rowtype, p_action varchar2) return boolean;

end AWRWH_FILE_LCC;
/
