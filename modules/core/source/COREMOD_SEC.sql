create or replace package COREMOD_SEC as
  
  type t_mod_list    is table of opas_groups.modname%type;
  type t_grp_id_list is table of opas_groups.group_id%type;

  function is_mod_installed(p_modname opas_modules.MODNAME%type) return boolean RESULT_CACHE;

  function is_role_assigned(p_modname opas_groups.modname%type, p_group_name opas_groups.group_name%type) return boolean;
  function is_role_assigned_n(p_modname opas_groups.modname%type, p_group_name opas_groups.group_name%type) return number;
  
  procedure save_role_assignment(p_modname_lst t_mod_list, p_group_id_lst t_grp_id_list, p_apex_user OPAS_GROUPS2APEXUSR.apex_user%type);

end COREMOD_SEC;
/
--------------------------------------------------------
show errors
--------------------------------------------------------
create or replace package body COREMOD_SEC as

  function is_mod_installed(p_modname opas_modules.MODNAME%type) return boolean RESULT_CACHE
  is
    l_cnt number;
  begin
    select count(1) into l_cnt from opas_modules where MODNAME=p_modname;
    return l_cnt>0;
  end;

  function is_role_assigned(p_modname opas_groups.modname%type, p_group_name opas_groups.group_name%type) return boolean
  is
    l_ual number;
    l_gal number;
  begin
    select min(access_level) into l_ual
      from OPAS_GROUPS2APEXUSR g2u, OPAS_GROUPS g
     where apex_user = V('APP_USER')
       and g2u.group_id=g.group_id
       and g.modname=p_modname;

    select access_level into l_gal from opas_groups where group_name=p_group_name and modname=p_modname;
    --user access level less or eqial to group access level
    return l_gal>=l_ual;
  end;

  function is_role_assigned_n(p_modname opas_groups.modname%type, p_group_name opas_groups.group_name%type) return number
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
           and group_id in (select group_id from OPAS_GROUPS where modname=p_modname_lst(i));
       
        insert into OPAS_GROUPS2APEXUSR (group_id, apex_user) values ((select group_id from OPAS_GROUPS where modname=p_modname_lst(i) and group_id=p_group_id_lst(i)), p_apex_user);
      end loop;
      COREMOD_API.release_resource(l_handle);
    end if;
  end;

end COREMOD_SEC;
/
--------------------------------------------------------
show errors
--------------------------------------------------------