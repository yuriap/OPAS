CREATE OR REPLACE
package body COREMOD_SEC as

  function is_mod_installed(p_modname opas_modules.MODNAME%type) return boolean RESULT_CACHE
  is
    l_cnt number;
  begin
    select count(1) into l_cnt from opas_modules where MODNAME=p_modname;
    return l_cnt>0;
  end;

  function is_role_assigned(p_modname OPAS_GROUPS2APEXUSR.modname%type, p_group_name opas_groups.group_name%type) return boolean
  is
    l_ual number;
    l_gal number;
  begin
    select min(group_id) into l_ual
      from OPAS_GROUPS2APEXUSR g2u
     where g2u.apex_user = V('APP_USER')
       and g2u.modname=p_modname;

    select group_id into l_gal from opas_groups where group_name=p_group_name;
    --user access level less or eqial to group access level
    return l_gal>=l_ual;
  end;

  function is_role_assigned_n(p_modname OPAS_GROUPS2APEXUSR.modname%type, p_group_name opas_groups.group_name%type) return number
  is
  begin
    return case when is_role_assigned(p_modname,p_group_name) then 1 else 0 end;
  end;

  procedure save_role_assignment(p_modname_lst t_mod_list, p_group_id_lst t_grp_id_list, p_apex_user OPAS_GROUPS2APEXUSR.apex_user%type)
  is
    l_handle varchar2(512);
  begin
    if p_modname_lst.count<>p_group_id_lst.count then
      raise_application_error(-20000,'Invalid lists of modules and groups specified.');
    end if;

    if p_modname_lst.count>0 then
      l_handle:=COREMOD_API.lock_resource('SETUSERPERM'||p_apex_user);

      for i in 1..p_modname_lst.count loop
        delete from OPAS_GROUPS2APEXUSR
         where apex_user=p_apex_user
           and modname=p_modname_lst(i);

        insert into OPAS_GROUPS2APEXUSR (group_id, modname, apex_user) values (p_group_id_lst(i),p_modname_lst(i), p_apex_user);
      end loop;
      COREMOD_API.release_resource(l_handle);
    end if;
  end;

/*
  function proj_is_role_assigned(p_proj_type opas_project_types.proj_type%type, p_group_name opas_groups.group_name%type) return boolean
  is
    l_modname opas_project_types.modname%type;
  begin
    if p_proj_type is null then
      return false;
    end if;
    select modname into l_modname from opas_project_types where proj_type = p_proj_type;
    return is_role_assigned(l_modname,p_group_name);
  exception
    when no_data_found then
      return false;
  end;
*/
end COREMOD_SEC;
/
