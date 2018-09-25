create or replace package TRC_FILE_LCC as

  -- Trace file actions
  c_trcfile_create        constant number :=1;
  c_trcfile_edit          constant number :=2;
  c_trcfile_drop          constant number :=3;
  c_trcfile_load          constant number :=4;  -- load source data
  c_trcfile_startparse    constant number :=5;  -- start parse source data
  c_trcfile_finishparse   constant number :=6;  -- finish parse source data
  c_trcfile_failparse     constant number :=6;  -- fail parse source data
  c_trcfile_reparse       constant number :=7; 
  c_trcfile_report_vw     constant number :=8;  -- view reports
  c_trcfile_compress      constant number :=9;
  c_trcfile_archive       constant number :=10;
  c_trcfile_cleanup_dep   constant number :=11; --cleanup dependent components
  c_trcfile_cleaunp_drop  constant number :=12; --parent cleanup drop
  

  --Trace file states
  c_trcfilestate_new         constant opas_projects.status%type := 'NEW';        --just created
  c_trcfilestate_loaded      constant opas_projects.status%type := 'LOADED';     --file loaded
  c_trcfilestate_parsing     constant opas_projects.status%type := 'PARSING';    --being parsed
  c_trcfilestate_parsed      constant opas_projects.status%type := 'PARSED';     --file parsed
  c_trcfilestate_compressed  constant opas_projects.status%type := 'COMPRESSED'; --source data removed, parsed is available
  c_trcfilestate_archived    constant opas_projects.status%type := 'ARCHIVED';   --source and parsed data removed

  --Trace file life-cycle set state
  procedure trcfile_exec_action(p_trc_file TRC_FILE%rowtype, p_action number);

  --Trace file action availability
  function trcfile_check_action(p_trc_file_id TRC_FILE.trc_file_id%type, p_action number) return boolean;
  function trcfile_check_action(p_trc_file TRC_FILE%rowtype, p_action number) return boolean;

end TRC_FILE_LCC;
/
--------------------------------------------------------
show errors
--------------------------------------------------------


create or replace package body TRC_FILE_LCC as

  function trcfile_check_action(p_trc_file TRC_FILE%rowtype, p_action number) return boolean
  is
    l_status TRC_FILE.status%type:=p_trc_file.status;
  begin
    return
      case
        when p_action = c_trcfile_create      and l_status in (c_trcfilestate_new)                                                                                                 then true
        when p_action = c_trcfile_edit        and l_status in (c_trcfilestate_new,c_trcfilestate_parsed,c_trcfilestate_compressed,c_trcfilestate_archived) then true
        when p_action = c_trcfile_drop        and l_status in (c_trcfilestate_new,c_trcfilestate_parsed,c_trcfilestate_compressed,c_trcfilestate_archived) then true
        when p_action = c_trcfile_load        and l_status in (c_trcfilestate_new)                                                                                                 then true
        when p_action = c_trcfile_startparse  and l_status in (c_trcfilestate_loaded)                                                                                              then true
		when p_action = c_trcfile_finishparse and l_status in (c_trcfilestate_parsing)                                                                                             then true
		when p_action = c_trcfile_failparse   and l_status in (c_trcfilestate_loaded,c_trcfilestate_parsing)                                                                       then true
		when p_action = c_trcfile_reparse     and l_status in (c_trcfilestate_parsed)                                          then true
        when p_action = c_trcfile_report_vw   and l_status in (c_trcfilestate_parsed,c_trcfilestate_compressed,c_trcfilestate_archived)                                          then true
        when p_action = c_trcfile_compress    and l_status in (c_trcfilestate_loaded,c_trcfilestate_parsed,                                                then true
        when p_action = c_trcfile_archive     and l_status in (c_trcfilestate_loaded,c_trcfilestate_parsed,c_trcfilestate_compressed)                      then true
		when p_action = c_trcfile_cleanup_dep  and l_status in (c_trcfilestate_new,c_trcfilestate_loaded,c_trcfilestate_parsed,c_trcfilestate_compressed,c_trcfilestate_archived) then true
		when p_action = c_trcfile_cleaunp_drop and l_status in (c_trcfilestate_new,c_trcfilestate_loaded,c_trcfilestate_parsed,c_trcfilestate_compressed,c_trcfilestate_archived) then true
      else
        false
      end;
  end;

  function trcfile_check_action(p_trc_file_id TRC_FILE.trc_file_id%type, p_action number) return boolean
  is
    l_trc_file TRC_FILE%rowtype;
  begin
    l_trc_file:=TRC_UTILS.get_file(p_trc_file_id,false);
    return trcfile_check_action(l_trc_file.trc_file_id,p_action);
  end;

  procedure trcfile_set_status(p_trc_file_id TRC_FILE.trc_file_id%type, p_status TRC_FILE.status%type)
  is
  begin
    UPDATE TRC_FILE set status = p_status where trc_file_id = p_trc_file_id;
  end;
  
  procedure trcfile_set_status_a(p_trc_file_id TRC_FILE.trc_file_id%type, p_status TRC_FILE.status%type)
  is
    pragma autonomous_transaction;
  begin
    trcfile_set_status(p_trc_file_id,p_status);
	commit;
  end;
  
  procedure trcfile_exec_action(p_trc_file TRC_FILE%rowtype, p_action number)
  is
  begin
    if trcfile_check_action(p_trc_file,p_action) then
    case
      when p_action = c_trcfile_create      then trcfile_set_status(p_trc_file.trc_file_id,c_trcfilestate_new);
      when p_action = c_trcfile_edit        then null;
      when p_action = c_trcfile_drop        then null;
      when p_action = c_trcfile_load        then trcfile_set_status(p_trc_file.trc_file_id,c_trcfilestate_loaded);
      when p_action = c_trcfile_startparse  then trcfile_set_status_a(p_trc_file.trc_file_id,c_trcfilestate_parsing);
	  when p_action = c_trcfile_finishparse then trcfile_set_status(p_trc_file.trc_file_id,c_trcfilestate_parsed);
	  when p_action = c_trcfile_failparse   then trcfile_set_status_a(p_trc_file.trc_file_id,c_trcfilestate_loaded);
      when p_action = c_trcfile_reparse     then trcfile_set_status(p_trc_file.trc_file_id,c_trcfilestate_loaded);
      when p_action = c_trcfile_report_vw   then null;
      when p_action = c_trcfile_compress    then project_set_status(p_trc_file.trc_file_id,c_trcfilestate_compressed);
      when p_action = c_trcfile_archive     then project_set_status(p_trc_file.trc_file_id,c_trcfilestate_archived);
	  when p_action = c_trcfile_cleanup_dep  then null;
	  when p_action = c_trcfile_cleaunp_drop then null;
      else
        raise_application_error(-20000,'Unimplemented project action: '||p_action);
      end case; 
    else
      raise_application_error(-20000,'Action '||p_action||' is not allowed for the trace file '||p_trc_file.trc_file_id||' with status '||p_trc_file.status);
    end if;
  end;

end TRC_FILE_LCC;
/
--------------------------------------------------------
show errors
--------------------------------------------------------