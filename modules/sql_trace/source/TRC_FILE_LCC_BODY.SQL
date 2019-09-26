CREATE OR REPLACE
package body TRC_FILE_LCC as

  function trcfile_check_action(p_trc_file trc_files%rowtype, p_action varchar2) return boolean
  is
    l_status trc_files.status%type:=p_trc_file.status;
    l_res    boolean;
  begin
    l_res :=
      case
        when p_action = c_trcfile_create      and l_status in (c_trcfilestate_new)
                                               and TRC_PROJ_LCC.project_check_action(p_trc_file.proj_id,TRC_PROJ_LCC.c_project_rwcontent) then true
        when p_action = c_trcfile_edit        and l_status in (c_trcfilestate_new,c_trcfilestate_loaded,c_trcfilestate_parsed,c_trcfilestate_compressed,c_trcfilestate_archived)
                                               and TRC_PROJ_LCC.project_check_action(p_trc_file.proj_id,TRC_PROJ_LCC.c_project_rwcontent) then true
        when p_action = c_trcfile_drop        and l_status in (c_trcfilestate_new,c_trcfilestate_loaded,c_trcfilestate_parsed,c_trcfilestate_compressed,c_trcfilestate_archived)
                                               and TRC_PROJ_LCC.project_check_action(p_trc_file.proj_id,TRC_PROJ_LCC.c_project_rwcontent) then true
        when p_action = c_trcfile_load        and l_status in (c_trcfilestate_new)
                                               and TRC_PROJ_LCC.project_check_action(p_trc_file.proj_id,TRC_PROJ_LCC.c_project_rwcontent) then true
        when p_action = c_trcfile_inparsequeue  and l_status in (c_trcfilestate_loaded)
                                               and TRC_PROJ_LCC.project_check_action(p_trc_file.proj_id,TRC_PROJ_LCC.c_project_rwcontent) then true
        when p_action = c_trcfile_startparse  and l_status in (c_trcfilestate_parsequeue)
                                               and TRC_PROJ_LCC.project_check_action(p_trc_file.proj_id,TRC_PROJ_LCC.c_project_rwcontent) then true
		when p_action = c_trcfile_finishparse and l_status in (c_trcfilestate_parsing)
                                               and TRC_PROJ_LCC.project_check_action(p_trc_file.proj_id,TRC_PROJ_LCC.c_project_rwcontent) then true
		when p_action = c_trcfile_failparse   and l_status in (c_trcfilestate_loaded,c_trcfilestate_parsing)
                                               and TRC_PROJ_LCC.project_check_action(p_trc_file.proj_id,TRC_PROJ_LCC.c_project_rwcontent) then true
		when p_action = c_trcfile_reparse     and l_status in (c_trcfilestate_parsed)
                                               and TRC_PROJ_LCC.project_check_action(p_trc_file.proj_id,TRC_PROJ_LCC.c_project_rwcontent) then true
        when p_action = c_trcfile_report_vw   and (l_status in (c_trcfilestate_parsed,c_trcfilestate_compressed,c_trcfilestate_archived) or (l_status in (c_trcfilestate_loaded) and p_trc_file.report_content is not null))
                                               and TRC_PROJ_LCC.project_check_action(p_trc_file.proj_id,TRC_PROJ_LCC.c_project_rocontent) then true
        when p_action = c_trcfile_compress    and l_status in (/*c_trcfilestate_loaded,*/c_trcfilestate_parsed)
                                               and TRC_PROJ_LCC.project_check_action(p_trc_file.proj_id,TRC_PROJ_LCC.c_project_rwcontent) then true
        when p_action = c_trcfile_archive     and l_status in (/*c_trcfilestate_loaded,*/c_trcfilestate_parsed,c_trcfilestate_compressed,c_trcfilestate_archived)
                                               and (TRC_PROJ_LCC.project_check_action(p_trc_file.proj_id,TRC_PROJ_LCC.c_project_archive)
                                                    or
                                                    TRC_PROJ_LCC.project_check_action(p_trc_file.proj_id,TRC_PROJ_LCC.c_project_drop)
                                                    or
                                                    TRC_PROJ_LCC.project_check_action(p_trc_file.proj_id,TRC_PROJ_LCC.c_project_rwcontent)) then true
        when p_action = c_trcfile_discover    and (l_status in (c_trcfilestate_parsed,c_trcfilestate_compressed))
                                               and TRC_PROJ_LCC.project_check_action(p_trc_file.proj_id,TRC_PROJ_LCC.c_project_rocontent) then true

      else
        false
      end;
    coremod_log.log('TRC_FILE_LCC.trcfile_check_action: '||p_trc_file.trc_file_id||';'||p_action||';'||p_trc_file.status||';'||case l_res when true then 'TRUE' else 'FALSE' end,'DEBUG');
    return l_res;
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
      when p_action = c_trcfile_create       then trcfile_set_status  (p_trc_file.trc_file_id,c_trcfilestate_new);        TRC_PROJ_LCC.project_exec_action(p_trc_file.proj_id,TRC_PROJ_LCC.c_project_rwcontent);
      when p_action = c_trcfile_edit         then                                                                         TRC_PROJ_LCC.project_exec_action(p_trc_file.proj_id,TRC_PROJ_LCC.c_project_rwcontent);
      when p_action = c_trcfile_drop         then                                                                         TRC_PROJ_LCC.project_exec_action(p_trc_file.proj_id,TRC_PROJ_LCC.c_project_rwcontent);
      when p_action = c_trcfile_load         then trcfile_set_status  (p_trc_file.trc_file_id,c_trcfilestate_loaded);     TRC_PROJ_LCC.project_exec_action(p_trc_file.proj_id,TRC_PROJ_LCC.c_project_rwcontent);
      when p_action = c_trcfile_inparsequeue then trcfile_set_status  (p_trc_file.trc_file_id,c_trcfilestate_parsequeue); TRC_PROJ_LCC.project_exec_action(p_trc_file.proj_id,TRC_PROJ_LCC.c_project_rwcontent);
      when p_action = c_trcfile_startparse   then trcfile_set_status_a(p_trc_file.trc_file_id,c_trcfilestate_parsing);    TRC_PROJ_LCC.project_exec_action(p_trc_file.proj_id,TRC_PROJ_LCC.c_project_rwcontent);
	  when p_action = c_trcfile_finishparse  then trcfile_set_status  (p_trc_file.trc_file_id,c_trcfilestate_parsed);     TRC_PROJ_LCC.project_exec_action(p_trc_file.proj_id,TRC_PROJ_LCC.c_project_rwcontent);
	  when p_action = c_trcfile_failparse    then trcfile_set_status_a(p_trc_file.trc_file_id,c_trcfilestate_loaded);     TRC_PROJ_LCC.project_exec_action(p_trc_file.proj_id,TRC_PROJ_LCC.c_project_rwcontent);
      when p_action = c_trcfile_reparse      then trcfile_set_status  (p_trc_file.trc_file_id,c_trcfilestate_loaded);     TRC_PROJ_LCC.project_exec_action(p_trc_file.proj_id,TRC_PROJ_LCC.c_project_rwcontent);
      when p_action = c_trcfile_report_vw    then                                                                         TRC_PROJ_LCC.project_exec_action(p_trc_file.proj_id,TRC_PROJ_LCC.c_project_rocontent);
      when p_action = c_trcfile_discover     then                                                                         TRC_PROJ_LCC.project_exec_action(p_trc_file.proj_id,TRC_PROJ_LCC.c_project_rocontent);
      when p_action = c_trcfile_compress     then trcfile_set_status  (p_trc_file.trc_file_id,c_trcfilestate_compressed); --TRC_PROJ_LCC.project_exec_action(p_trc_file.proj_id,TRC_PROJ_LCC.c_project_rwcontent);
      when p_action = c_trcfile_archive      then trcfile_set_status  (p_trc_file.trc_file_id,c_trcfilestate_archived);   --TRC_PROJ_LCC.project_exec_action(p_trc_file.proj_id,TRC_PROJ_LCC.c_project_rwcontent);
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
