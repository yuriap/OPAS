create or replace package TRC_FILE_LCC as

  -- Trace file actions
  c_trcfile_create        constant varchar2(20) :='CREATE';
  c_trcfile_edit          constant varchar2(20) :='EDIT';
  c_trcfile_drop          constant varchar2(20) :='DROP';
  c_trcfile_load          constant varchar2(20) :='LOAD';  -- load source data
  c_trcfile_startparse    constant varchar2(20) :='START PARSE';  -- start parse source data
  c_trcfile_finishparse   constant varchar2(20) :='FINISH PARSE';  -- finish parse source data
  c_trcfile_failparse     constant varchar2(20) :='FAIL PARSE';  -- fail parse source data
  c_trcfile_reparse       constant varchar2(20) :='REPARSE';
  c_trcfile_report_vw     constant varchar2(20) :='VIEW REPORT';  -- view reports
  c_trcfile_compress      constant varchar2(20) :='COMPRESS';
  c_trcfile_archive       constant varchar2(20) :='ARCHIVE';
  --c_trcfile_cleanup_dep   constant varchar2(20) :=11; --cleanup dependent components
  --c_trcfile_cleaunp_drop  constant varchar2(20) :=12; --parent cleanup drop


  --Trace file states
  c_trcfilestate_new         constant trc_projects.status%type := 'NEW';        --just created
  c_trcfilestate_loaded      constant trc_projects.status%type := 'LOADED';     --file loaded
  c_trcfilestate_parsing     constant trc_projects.status%type := 'PARSING';    --being parsed
  c_trcfilestate_parsed      constant trc_projects.status%type := 'PARSED';     --file parsed
  c_trcfilestate_compressed  constant trc_projects.status%type := 'COMPRESSED'; --source data removed, parsed is available
  c_trcfilestate_archived    constant trc_projects.status%type := 'ARCHIVED';   --source and parsed data removed

  --Trace file life-cycle set state
  procedure trcfile_exec_action(p_trc_file trc_files%rowtype, p_action varchar2);
  procedure trcfile_exec_action(p_trc_file_id trc_files.trc_file_id%type, p_action varchar2);

  --Trace file action availability
  function trcfile_check_action(p_trc_file_id trc_files.trc_file_id%type, p_action varchar2) return boolean;
  function trcfile_check_action_vc(p_trc_file_id trc_files.trc_file_id%type, p_action varchar2) return varchar2;
  function trcfile_check_action(p_trc_file trc_files%rowtype, p_action varchar2) return boolean;

end TRC_FILE_LCC;
/
--------------------------------------------------------
show errors
--------------------------------------------------------

create or replace package body TRC_FILE_LCC as

  function trcfile_check_action(p_trc_file trc_files%rowtype, p_action varchar2) return boolean
  is
    l_status trc_files.status%type:=p_trc_file.status;
  begin
    return
      case
        when p_action = c_trcfile_create      and l_status in (c_trcfilestate_new)
                                               and TRC_PROJ_LCC.project_check_action(p_trc_file.proj_id,TRC_PROJ_LCC.c_project_rwcontent) then true
        when p_action = c_trcfile_edit        and l_status in (c_trcfilestate_new,c_trcfilestate_loaded,c_trcfilestate_parsed,c_trcfilestate_compressed,c_trcfilestate_archived)
                                               and TRC_PROJ_LCC.project_check_action(p_trc_file.proj_id,TRC_PROJ_LCC.c_project_rwcontent) then true
        when p_action = c_trcfile_drop        and l_status in (c_trcfilestate_new,c_trcfilestate_loaded,c_trcfilestate_parsed,c_trcfilestate_compressed,c_trcfilestate_archived)
                                               and TRC_PROJ_LCC.project_check_action(p_trc_file.proj_id,TRC_PROJ_LCC.c_project_rwcontent) then true
        when p_action = c_trcfile_load        and l_status in (c_trcfilestate_new)
                                               and TRC_PROJ_LCC.project_check_action(p_trc_file.proj_id,TRC_PROJ_LCC.c_project_rwcontent) then true
        when p_action = c_trcfile_startparse  and l_status in (c_trcfilestate_loaded)
                                               and TRC_PROJ_LCC.project_check_action(p_trc_file.proj_id,TRC_PROJ_LCC.c_project_rwcontent) then true
		when p_action = c_trcfile_finishparse and l_status in (c_trcfilestate_parsing)
                                               and TRC_PROJ_LCC.project_check_action(p_trc_file.proj_id,TRC_PROJ_LCC.c_project_rwcontent) then true
		when p_action = c_trcfile_failparse   and l_status in (c_trcfilestate_loaded,c_trcfilestate_parsing)
                                               and TRC_PROJ_LCC.project_check_action(p_trc_file.proj_id,TRC_PROJ_LCC.c_project_rwcontent) then true
		when p_action = c_trcfile_reparse     and l_status in (c_trcfilestate_parsed)
                                               and TRC_PROJ_LCC.project_check_action(p_trc_file.proj_id,TRC_PROJ_LCC.c_project_rwcontent) then true
        when p_action = c_trcfile_report_vw   and l_status in (c_trcfilestate_parsed,c_trcfilestate_compressed,c_trcfilestate_archived) and p_trc_file.report_content is not null
                                               and TRC_PROJ_LCC.project_check_action(p_trc_file.proj_id,TRC_PROJ_LCC.c_project_rocontent) then true
        when p_action = c_trcfile_compress    and l_status in (c_trcfilestate_loaded,c_trcfilestate_parsed)
                                               and TRC_PROJ_LCC.project_check_action(p_trc_file.proj_id,TRC_PROJ_LCC.c_project_rwcontent) then true
        when p_action = c_trcfile_archive     and l_status in (c_trcfilestate_loaded,c_trcfilestate_parsed,c_trcfilestate_compressed)
                                               and TRC_PROJ_LCC.project_check_action(p_trc_file.proj_id,TRC_PROJ_LCC.c_project_rwcontent) then true
      else
        false
      end;
  end;

  function trcfile_check_action(p_trc_file_id trc_files.trc_file_id%type, p_action varchar2) return boolean
  is
    l_trc_file trc_files%rowtype;
  begin
    l_trc_file:=TRC_FILE_API.get_file(p_trc_file_id,false);
    return trcfile_check_action(l_trc_file,p_action);
  end;

  function trcfile_check_action_vc(p_trc_file_id trc_files.trc_file_id%type, p_action varchar2) return varchar2
  is 
  begin
    return case when trcfile_check_action(p_trc_file_id,p_action) then 'Y' else 'N' end;
  end;
  
  procedure trcfile_set_status(p_trc_file_id trc_files.trc_file_id%type, p_status trc_files.status%type)
  is
  begin
    UPDATE trc_files set
	  status = p_status,
	  parsed = case p_status
	             when c_trcfilestate_parsed then systimestamp
				 when c_trcfilestate_loaded then null
				 else parsed end
	where trc_file_id = p_trc_file_id;
  end;

  procedure trcfile_set_status_a(p_trc_file_id trc_files.trc_file_id%type, p_status trc_files.status%type)
  is
    pragma autonomous_transaction;
  begin
    trcfile_set_status(p_trc_file_id,p_status);
	commit;
  end;

  procedure trcfile_exec_action(p_trc_file trc_files%rowtype, p_action varchar2)
  is
  begin
    if trcfile_check_action(p_trc_file,p_action) then
    case
      when p_action = c_trcfile_create      then trcfile_set_status(p_trc_file.trc_file_id,c_trcfilestate_new);       TRC_PROJ_LCC.project_exec_action(p_trc_file.proj_id,TRC_PROJ_LCC.c_project_rwcontent);
      when p_action = c_trcfile_edit        then                                                                      TRC_PROJ_LCC.project_exec_action(p_trc_file.proj_id,TRC_PROJ_LCC.c_project_rwcontent);
      when p_action = c_trcfile_drop        then                                                                      TRC_PROJ_LCC.project_exec_action(p_trc_file.proj_id,TRC_PROJ_LCC.c_project_rwcontent);
      when p_action = c_trcfile_load        then trcfile_set_status(p_trc_file.trc_file_id,c_trcfilestate_loaded);    TRC_PROJ_LCC.project_exec_action(p_trc_file.proj_id,TRC_PROJ_LCC.c_project_rwcontent);
      when p_action = c_trcfile_startparse  then trcfile_set_status_a(p_trc_file.trc_file_id,c_trcfilestate_parsing); TRC_PROJ_LCC.project_exec_action(p_trc_file.proj_id,TRC_PROJ_LCC.c_project_rwcontent);
	  when p_action = c_trcfile_finishparse then trcfile_set_status(p_trc_file.trc_file_id,c_trcfilestate_parsed);    TRC_PROJ_LCC.project_exec_action(p_trc_file.proj_id,TRC_PROJ_LCC.c_project_rwcontent);
	  when p_action = c_trcfile_failparse   then trcfile_set_status_a(p_trc_file.trc_file_id,c_trcfilestate_loaded);  TRC_PROJ_LCC.project_exec_action(p_trc_file.proj_id,TRC_PROJ_LCC.c_project_rwcontent);
      when p_action = c_trcfile_reparse     then trcfile_set_status(p_trc_file.trc_file_id,c_trcfilestate_parsing);   TRC_PROJ_LCC.project_exec_action(p_trc_file.proj_id,TRC_PROJ_LCC.c_project_rwcontent);
      when p_action = c_trcfile_report_vw   then                                                                      TRC_PROJ_LCC.project_exec_action(p_trc_file.proj_id,TRC_PROJ_LCC.c_project_rocontent);
      when p_action = c_trcfile_compress    then trcfile_set_status(p_trc_file.trc_file_id,c_trcfilestate_compressed);TRC_PROJ_LCC.project_exec_action(p_trc_file.proj_id,TRC_PROJ_LCC.c_project_rwcontent);
      when p_action = c_trcfile_archive     then trcfile_set_status(p_trc_file.trc_file_id,c_trcfilestate_archived);  TRC_PROJ_LCC.project_exec_action(p_trc_file.proj_id,TRC_PROJ_LCC.c_project_rwcontent);
	  --when p_action = c_trcfile_cleanup_dep  then null;
	  --when p_action = c_trcfile_cleaunp_drop then null;
      else
        raise_application_error(-20000,'Unimplemented project action: '||p_action);
      end case;
    else
      raise_application_error(-20000,'Action '||p_action||' is not allowed for the trace file '||p_trc_file.trc_file_id||' ('||p_trc_file.filename||') with status '||p_trc_file.status);
    end if;
  end;

  procedure trcfile_exec_action(p_trc_file_id trc_files.trc_file_id%type, p_action varchar2)
  is
    l_trc_file trc_files%rowtype;
  begin
    l_trc_file:=TRC_FILE_API.get_file(p_trc_file_id,false);
    trcfile_exec_action(l_trc_file,p_action);
  end;

end TRC_FILE_LCC;
/
--------------------------------------------------------
show errors
--------------------------------------------------------