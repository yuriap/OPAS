CREATE OR REPLACE
package body TRC_PROJ_LCC as

  function project_check_action(p_proj trc_projects%rowtype, p_action VARCHAR2) return boolean
  is
    l_status trc_projects.status%type:=p_proj.status;
  begin
    return
      case
        when p_action = c_project_create    and l_status in (c_projstate_new)                                                                then true
        when p_action = c_project_edit      and l_status in (c_projstate_new,c_projstate_active,c_projstate_compressed,c_projstate_archived) then true
        when p_action = c_project_drop      and l_status in (c_projstate_new,c_projstate_compressed,c_projstate_archived)                    then true
        when p_action = c_project_rocontent and l_status in (c_projstate_new,c_projstate_active,c_projstate_locked,c_projstate_compressed,c_projstate_archived) then true
        when p_action = c_project_rwcontent and l_status in (c_projstate_new,c_projstate_active)                                             then true
        when p_action = c_project_lock      and l_status in (c_projstate_active)                                                             then true
        when p_action = c_project_unlock    and l_status in (c_projstate_locked)                                                             then true
        when p_action = c_project_compress  and l_status in (c_projstate_active)                                                             then true
        when p_action = c_project_archive   and l_status in (c_projstate_active,c_projstate_compressed)                                      then true
      else
        false
      end;
  end;

  function project_check_action(p_proj_id trc_projects.proj_id%type, p_action VARCHAR2) return boolean
  is
    l_curproj trc_projects%rowtype;
  begin
    l_curproj:=TRC_PROJ_API.getproject(p_proj_id,false);
    return project_check_action(l_curproj,p_action);
  end;

  procedure project_set_status(p_proj_id trc_projects.proj_id%type, p_status trc_projects.status%type)
  is
  begin
    UPDATE trc_projects set status = p_status where proj_id = p_proj_id;
  end;

  procedure project_exec_action(p_proj trc_projects%rowtype, p_action VARCHAR2)
  is
  begin
    if project_check_action(p_proj,p_action) then
    case
      when p_action = c_project_create     then project_set_status(p_proj.proj_id,c_projstate_new);
      when p_action = c_project_edit       then null;
      when p_action = c_project_drop       then null;
      when p_action = c_project_rocontent  then null;
      when p_action = c_project_rwcontent  then case when p_proj.status = c_projstate_new then project_set_status(p_proj.proj_id,c_projstate_active); else null; end case;
      when p_action = c_project_lock       then project_set_status(p_proj.proj_id,c_projstate_locked);
      when p_action = c_project_unlock     then project_set_status(p_proj.proj_id,c_projstate_active);
      when p_action = c_project_compress   then project_set_status(p_proj.proj_id,c_projstate_compressed);
      when p_action = c_project_archive    then project_set_status(p_proj.proj_id,c_projstate_archived);
      else
        raise_application_error(-20000,'Unimplemented project action: '||p_action);
      end case;
    else
      raise_application_error(-20000,'Action '||p_action||' is not allowed for the project '||p_proj.proj_id||' with status '||p_proj.status);
    end if;
  end;

  procedure project_exec_action(p_proj_id trc_projects.proj_id%type, p_action VARCHAR2)
  is
    l_curproj trc_projects%rowtype;
  begin
    l_curproj:=TRC_PROJ_API.getproject(p_proj_id,false);
    project_exec_action(l_curproj,p_action);
  end;

end TRC_PROJ_LCC;
/
