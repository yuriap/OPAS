create or replace package COREPROJ_LCC as

  -- Project actions
  c_project_create        constant number :=1;
  c_project_edit          constant number :=2;
  c_project_drop          constant number :=3;
  c_project_load          constant number :=4;  -- load source data
  c_project_parse         constant number :=5;  -- parse source data
  c_project_report_cr     constant number :=6;  -- create reports
  c_project_report_vw     constant number :=7;  -- view reports
  c_project_lock          constant number :=8;
  c_project_unlock        constant number :=9;
  c_project_close         constant number :=10;
  c_project_compress      constant number :=11;
  c_project_archive       constant number :=12;

  --Project states
  c_projstate_new         constant opas_projects.status%type := 'NEW';        --just created                                                    fa-window-new
  c_projstate_active      constant opas_projects.status%type := 'ACTIVE';     --actively used                                                   fa-window-check
  c_projstate_locked      constant opas_projects.status%type := 'LOCKED';     --read only, no activity, excluded from purging, can be unlocked  fa-window-lock
  c_projstate_compressed  constant opas_projects.status%type := 'COMPRESSED'; --source data removed, parsed is available                        fa-window-search
  c_projstate_archived    constant opas_projects.status%type := 'ARCHIVED';   --source and parsed data removed                                  fa-window-ban
  c_projstate_closed      constant opas_projects.status%type := 'CLOSED';     --read only, no activity                                          fa-window-x

  --Project life-cycle set state
  procedure project_exec_action(p_proj opas_projects%rowtype, p_action number);

  --Project action availability
  function project_check_action(p_proj_id opas_projects.proj_id%type, p_action number) return boolean;
  function project_check_action(p_proj opas_projects%rowtype, p_action number) return boolean;

end COREPROJ_LCC;
/
--------------------------------------------------------
show errors
--------------------------------------------------------

create or replace package body COREPROJ_LCC as

  function project_check_action(p_proj opas_projects%rowtype, p_action number) return boolean
  is
    l_status opas_projects.status%type:=p_proj.status;
  begin
    return
      case
        when p_action = c_project_create    and l_status in (c_projstate_new)                                                                then true
        when p_action = c_project_edit      and l_status in (c_projstate_new,c_projstate_active,c_projstate_compressed,c_projstate_archived) then true
        when p_action = c_project_drop      and l_status in (c_projstate_new,c_projstate_compressed,c_projstate_archived,c_projstate_closed) then true
        when p_action = c_project_load      and l_status in (c_projstate_new,c_projstate_active)                                             then true
		when p_action = c_project_parse     and l_status in (c_projstate_active)                                                             then true
		when p_action = c_project_report_cr and l_status in (c_projstate_new,c_projstate_active,c_projstate_compressed)                      then true
		when p_action = c_project_report_vw and l_status in (c_projstate_new,c_projstate_active,c_projstate_compressed,c_projstate_archived) then true
        when p_action = c_project_lock      and l_status in (c_projstate_active)                                                             then true
        when p_action = c_project_unlock    and l_status in (c_projstate_locked)                                                             then true
		when p_action = c_project_close     and l_status in (c_projstate_active,c_projstate_compressed,c_projstate_archived)                 then true
		when p_action = c_project_compress  and l_status in (c_projstate_active)                                                             then true
		when p_action = c_project_archive   and l_status in (c_projstate_active,c_projstate_compressed)                                      then true
      else
        false
      end;
  end;

  function project_check_action(p_proj_id opas_projects.proj_id%type, p_action number) return boolean
  is
    l_curproj opas_projects%rowtype;
  begin
    l_curproj:=COREPROJ_API.getproject(p_proj_id,false);
    return project_check_action(l_curproj,p_action);
  end;

  procedure project_set_status(p_proj_id opas_projects.proj_id%type, p_status opas_projects.status%type)
  is
  begin
    UPDATE opas_projects set status = p_status where proj_id = p_proj_id;
  end;

  procedure project_exec_action(p_proj opas_projects%rowtype, p_action number)
  is
  begin
    if project_check_action(p_proj,p_action) then
    case
      when p_action = c_project_create     then project_set_status(p_proj.proj_id,c_projstate_new);
      when p_action = c_project_edit       then case when p_proj.status = c_projstate_new then project_set_status(p_proj.proj_id,c_projstate_active); else null; end case;
      when p_action = c_project_drop       then project_set_status(p_proj.proj_id,c_projstate_closed);
      when p_action = c_project_load       then case when p_proj.status = c_projstate_new then project_set_status(p_proj.proj_id,c_projstate_active); else null; end case;
      when p_action = c_project_parse      then null;
      when p_action = c_project_report_cr  then null;
	  when p_action = c_project_report_vw  then null;
      when p_action = c_project_lock       then project_set_status(p_proj.proj_id,c_projstate_locked);
      when p_action = c_project_unlock     then project_set_status(p_proj.proj_id,c_projstate_active);
      when p_action = c_project_close      then project_set_status(p_proj.proj_id,c_projstate_closed);
      when p_action = c_project_compress   then project_set_status(p_proj.proj_id,c_projstate_compressed);
      when p_action = c_project_archive    then project_set_status(p_proj.proj_id,c_projstate_archived);
      else
        raise_application_error(-20000,'Unimplemented project action: '||p_action);
      end case;
	else
	  raise_application_error(-20000,'Action '||p_action||' is not allowed for the project '||p_proj.proj_id||' with status '||p_proj.status);
    end if;
  end;

end COREPROJ_LCC;
/
--------------------------------------------------------
show errors
--------------------------------------------------------