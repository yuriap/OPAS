CREATE OR REPLACE
package body AWRWH_FILE_LCC as

  function dmpfile_check_action(p_awrwh_dumps awrwh_dumps%rowtype, p_action varchar2) return boolean
  is
    l_status awrwh_dumps.status%type:=p_awrwh_dumps.status;
    l_does_proj_allow_rw boolean;
  begin
    l_does_proj_allow_rw := AWRWH_PROJ_LCC.project_check_action(p_awrwh_dumps.proj_id,AWRWH_PROJ_LCC.c_project_rwcontent);
    return l_does_proj_allow_rw and
      case
        when p_action = c_dmpfile_create                                                                                                         then true
        when p_action = c_dmpfile_loadfile        and l_status in (c_dmpfilestate_new)                                                           then true
        when p_action = c_dmpfile_editfile        and l_status in (c_dmpfilestate_new, c_dmpfilestate_dmploaded, c_dmpfilestate_awrloaded)       then true
        when p_action = c_dmpfile_putinqueue      and l_status in (c_dmpfilestate_new, c_dmpfilestate_dmploaded, c_dmpfilestate_awrloaded, c_dmpfilestate_compressed, c_dmpfilestate_archived) then true
        when p_action = c_dmpfile_startprocess    and l_status in (c_dmpfilestate_inqueue)                                                       then true
        when p_action = c_dmpfile_finishprocess   and l_status in (c_dmpfilestate_processing)                                                    then true
        when p_action = c_dmpfile_failprocess     and l_status in (c_dmpfilestate_processing)                                                    then true
        when p_action = c_dmpfile_awrload         and l_status in (c_dmpfilestate_dmploaded)                                                     then true
        when p_action = c_dmpfile_awrunload       and l_status in (c_dmpfilestate_awrloaded)                                                     then true
        when p_action = c_dmpfile_compress        and l_status in (c_dmpfilestate_dmploaded, c_dmpfilestate_awrloaded)                           then true
        when p_action = c_dmpfile_archive         and l_status in (c_dmpfilestate_dmploaded, c_dmpfilestate_awrloaded,c_dmpfilestate_compressed) then true
        when p_action = c_dmpfile_dropfile        and l_status in (c_dmpfilestate_new, c_dmpfilestate_dmploaded, c_dmpfilestate_awrloaded, c_dmpfilestate_compressed, c_dmpfilestate_archived) then true
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
    UPDATE awrwh_dumps set
      status = p_status
    where dump_id = p_dump_id;
  end;

  procedure dmpfile_set_status_a(p_dump_id awrwh_dumps.dump_id%type, p_status awrwh_dumps.status%type)
  is
    pragma autonomous_transaction;
  begin
    dmpfile_set_status(p_dump_id,p_status);
    commit;
  end;

  procedure dmpfile_exec_action(p_awrwh_dumps awrwh_dumps%rowtype, p_action varchar2, p_process_action varchar2 default null, p_start_state varchar2 default null)
  is
  begin

    if dmpfile_check_action(p_awrwh_dumps,p_action) then
    case
      when p_action = c_dmpfile_create         then dmpfile_set_status  (p_awrwh_dumps.dump_id,c_dmpfilestate_new);
      when p_action = c_dmpfile_loadfile       then dmpfile_set_status  (p_awrwh_dumps.dump_id,c_dmpfilestate_dmploaded);
      when p_action = c_dmpfile_editfile       then null;
      when p_action = c_dmpfile_putinqueue     then dmpfile_set_status  (p_awrwh_dumps.dump_id,c_dmpfilestate_inqueue);
      when p_action = c_dmpfile_startprocess   then case
                                                      when p_process_action = c_dmpfile_dropfile then  dmpfile_set_status_a(p_awrwh_dumps.dump_id,c_dmpfilestate_dropped);
                                                      else dmpfile_set_status_a(p_awrwh_dumps.dump_id,c_dmpfilestate_processing);
                                                    end case;
      when p_action = c_dmpfile_finishprocess  then case
                                                      when p_process_action = c_dmpfile_awrload   then dmpfile_set_status  (p_awrwh_dumps.dump_id,c_dmpfilestate_awrloaded);
                                                      when p_process_action = c_dmpfile_awrunload then dmpfile_set_status  (p_awrwh_dumps.dump_id,c_dmpfilestate_dmploaded);
                                                      when p_process_action = c_dmpfile_compress  then dmpfile_set_status  (p_awrwh_dumps.dump_id,c_dmpfilestate_compressed);
                                                      when p_process_action = c_dmpfile_archive   then dmpfile_set_status  (p_awrwh_dumps.dump_id,c_dmpfilestate_archived);
                                                      when p_process_action = c_dmpfile_dropfile  then dmpfile_set_status  (p_awrwh_dumps.dump_id,c_dmpfilestate_dropped);
                                                    else
                                                      raise_application_error(-20000,'Unimplemented dump file action: '||p_action||':'||nvl(p_process_action,'N/A'));
                                                    end case;
      when p_action = c_dmpfile_failprocess    then
      case
                                                      when p_process_action = c_dmpfile_awrload   then dmpfile_set_status_a  (p_awrwh_dumps.dump_id,p_start_state);
                                                      when p_process_action = c_dmpfile_awrunload then dmpfile_set_status_a  (p_awrwh_dumps.dump_id,p_start_state);
                                                      when p_process_action = c_dmpfile_compress  then dmpfile_set_status_a  (p_awrwh_dumps.dump_id,p_start_state);
                                                      when p_process_action = c_dmpfile_archive   then dmpfile_set_status_a  (p_awrwh_dumps.dump_id,p_start_state);
                                                      when p_process_action = c_dmpfile_dropfile  then dmpfile_set_status_a  (p_awrwh_dumps.dump_id,p_start_state);
                                                    else
                                                      raise_application_error(-20000,'Unimplemented dump file action: '||p_action||':'||nvl(p_process_action,'N/A'));
                                                    end case;
      else
        raise_application_error(-20000,'Unimplemented project action: '||p_action||':'||nvl(p_process_action,'N/A'));
      end case;
      AWRWH_PROJ_LCC.project_exec_action(p_awrwh_dumps.proj_id,AWRWH_PROJ_LCC.c_project_rwcontent);
    else
      raise_application_error(-20000,'Action '||p_action||' is not allowed for the dump file '||p_awrwh_dumps.dump_id||' ('||p_awrwh_dumps.filename||') with status '||p_awrwh_dumps.status);
    end if;
  end;

  procedure dmpfile_exec_action(p_dump_id awrwh_dumps.dump_id%type, p_action varchar2, p_process_action varchar2 default null, p_start_state varchar2 default null)
  is
    l_dmp_file awrwh_dumps%rowtype;
  begin
    l_dmp_file:=AWRWH_FILE_API.get_file(p_dump_id,false);
    dmpfile_exec_action(l_dmp_file,p_action,p_process_action,p_start_state);
  end;

end AWRWH_FILE_LCC;
/
