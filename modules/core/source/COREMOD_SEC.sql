create or replace package COREMOD_SEC as

  function is_mod_installed(p_modname opas_modules.MODNAME%type) return boolean RESULT_CACHE;
  
  function is_role_assigned(p_modname opas_groups.modname%type, p_group_name opas_groups.group_name%type) return boolean RESULT_CACHE;

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

  function is_role_assigned(p_modname opas_groups.modname%type, p_group_name opas_groups.group_name%type) return boolean RESULT_CACHE
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
    return l_ual<=l_ual;
  end;
  
end COREMOD_SEC;
/
--------------------------------------------------------
show errors
--------------------------------------------------------