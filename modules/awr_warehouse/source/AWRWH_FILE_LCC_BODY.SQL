CREATE OR REPLACE
package body AWRWH_FILE_LCC as

  function dmpfile_check_action(p_awrwh_dumps awrwh_dumps%rowtype, p_action varchar2) return boolean
  is
    l_status awrwh_dumps.status%type:=p_awrwh_dumps.status;
	l_does_proj_allow_rw boolean;
  begin
    l_does_proj_allow_rw := AWRWH_PROJ_LCC.project_check_action(p_awrwh_dumps.proj_id,AWRWH_PROJ_LCC.c_project_rwcontent);
    return
      case
        when p_action = c_dmpfile_create          and l_status in (c_dmpfilestate_new)
                                                      and l_does_proj_allow_rw then true
        when p_action = c_dmpfile_loadfile        and l_status in (c_dmpfilestate_new)
                                                      and l_does_proj_allow_rw then true
        when p_action = c_dmpfile_inawrloadqueue  and l_status in (c_dmpfilestate_dmploaded)
                                                      and l_does_proj_allow_rw then true
        when p_action = c_dmpfile_startawrload    and l_status in (c_dmpfilestate_awrloadqueue)
                                                      and l_does_proj_allow_rw then true
		when p_action = c_dmpfile_finishawrload   and l_status in (c_dmpfilestate_awrloading)
                                                      and l_does_proj_allow_rw then true
		when p_action = c_dmpfile_failawrload     and l_status in (c_dmpfilestate_awrloading)
                                                      and l_does_proj_allow_rw then true
		when p_action = c_dmpfile_awrunload       and l_status in (c_dmpfilestate_awrloaded)
                                                      and l_does_proj_allow_rw then true
        when p_action = c_dmpfile_compress        and l_status in (c_dmpfilestate_dmploaded,c_dmpfilestate_awrloaded)
                                                      and l_does_proj_allow_rw then true
        when p_action = c_dmpfile_archive         and l_status in (c_dmpfilestate_dmploaded,c_dmpfilestate_awrloaded,c_dmpfilestate_compressed)
                                                      and l_does_proj_allow_rw then true
        when p_action = c_dmpfile_dropfile        and l_status in (c_dmpfilestate_new,c_dmpfilestate_dmploaded,c_dmpfilestate_awrloaded,c_dmpfilestate_compressed,c_dmpfilestate_archived)
                                                       and l_does_proj_allow_rw then true
      else
        false
      end;
  end;

  function dmpfile_check_action(p_dump_id awrwh_dumps.dump_id%type, p_action varchar2) return boolean
  is
    l_dmp_file awrwh_dumps%rowtype;
  begin
    l_dmp_file:=AWRWH_FILE_API.get_file(p_dump_id,false);
    return dmpfile_check_action(l_dmp_file,p_action);
  end;

  function dmpfile_check_action_vc(p_dump_id awrwh_dumps.dump_id%type, p_action varchar2) return varchar2
  is
  begin
    return case when dmpfile_check_action(p_dump_id,p_action) then 'Y' else 'N' end;
  end;

  procedure dmpfile_set_status(p_dump_id awrwh_dumps.dump_id%type, p_status awrwh_dumps.status%type)
  is
  begin
  null;
  /*
    UPDATE awrwh_dumps set
	  status = p_status,
	  parsed = case p_status
	             when c_dmpfilestate_parsed then systimestamp
				 else parsed end
	where dump_id = p_dump_id;
    */
  end;

  procedure dmpfile_set_status_a(p_dump_id awrwh_dumps.dump_id%type, p_status awrwh_dumps.status%type)
  is
    pragma autonomous_transaction;
  begin
    dmpfile_set_status(p_dump_id,p_status);
	commit;
  end;

  procedure dmpfile_exec_action(p_awrwh_dumps awrwh_dumps%rowtype, p_action varchar2)
  is
  begin
    if dmpfile_check_action(p_awrwh_dumps,p_action) then
    case
      when p_action = c_dmpfile_create         then dmpfile_set_status  (p_awrwh_dumps.dump_id,c_dmpfilestate_new);          AWRWH_PROJ_LCC.project_exec_action(p_awrwh_dumps.proj_id,AWRWH_PROJ_LCC.c_project_rwcontent);
      when p_action = c_dmpfile_loadfile       then dmpfile_set_status  (p_awrwh_dumps.dump_id,c_dmpfilestate_dmploaded);    AWRWH_PROJ_LCC.project_exec_action(p_awrwh_dumps.proj_id,AWRWH_PROJ_LCC.c_project_rwcontent);
      when p_action = c_dmpfile_inawrloadqueue then dmpfile_set_status  (p_awrwh_dumps.dump_id,c_dmpfilestate_awrloadqueue); AWRWH_PROJ_LCC.project_exec_action(p_awrwh_dumps.proj_id,AWRWH_PROJ_LCC.c_project_rwcontent);
      when p_action = c_dmpfile_startawrload   then dmpfile_set_status_a(p_awrwh_dumps.dump_id,c_dmpfilestate_awrloading);   AWRWH_PROJ_LCC.project_exec_action(p_awrwh_dumps.proj_id,AWRWH_PROJ_LCC.c_project_rwcontent);
	  when p_action = c_dmpfile_finishawrload  then dmpfile_set_status  (p_awrwh_dumps.dump_id,c_dmpfile_finishawrload);     AWRWH_PROJ_LCC.project_exec_action(p_awrwh_dumps.proj_id,AWRWH_PROJ_LCC.c_project_rwcontent);
	  when p_action = c_dmpfile_failawrload    then dmpfile_set_status_a(p_awrwh_dumps.dump_id,c_dmpfilestate_dmploaded);    AWRWH_PROJ_LCC.project_exec_action(p_awrwh_dumps.proj_id,AWRWH_PROJ_LCC.c_project_rwcontent);
      when p_action = c_dmpfile_awrunload      then dmpfile_set_status  (p_awrwh_dumps.dump_id,c_dmpfilestate_dmploaded);    AWRWH_PROJ_LCC.project_exec_action(p_awrwh_dumps.proj_id,AWRWH_PROJ_LCC.c_project_rwcontent);
      when p_action = c_dmpfile_compress       then dmpfile_set_status  (p_awrwh_dumps.dump_id,c_dmpfilestate_compressed);   AWRWH_PROJ_LCC.project_exec_action(p_awrwh_dumps.proj_id,AWRWH_PROJ_LCC.c_project_rwcontent);
      when p_action = c_dmpfile_archive        then dmpfile_set_status  (p_awrwh_dumps.dump_id,c_dmpfilestate_archived);     AWRWH_PROJ_LCC.project_exec_action(p_awrwh_dumps.proj_id,AWRWH_PROJ_LCC.c_project_rwcontent);
      when p_action = c_dmpfile_dropfile       then                                                                          AWRWH_PROJ_LCC.project_exec_action(p_awrwh_dumps.proj_id,AWRWH_PROJ_LCC.c_project_rwcontent);
      else
        raise_application_error(-20000,'Unimplemented project action: '||p_action);
      end case;
    else
      raise_application_error(-20000,'Action '||p_action||' is not allowed for the trace file '||p_awrwh_dumps.dump_id||' ('||p_awrwh_dumps.filename||') with status '||p_awrwh_dumps.status);
    end if;
  end;

  procedure dmpfile_exec_action(p_dump_id awrwh_dumps.dump_id%type, p_action varchar2)
  is
    l_dmp_file awrwh_dumps%rowtype;
  begin
    l_dmp_file:=AWRWH_FILE_API.get_file(p_dump_id,false);
    dmpfile_exec_action(l_dmp_file,p_action);
  end;

end AWRWH_FILE_LCC;
/
