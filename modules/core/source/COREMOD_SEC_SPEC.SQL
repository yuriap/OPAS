package COREMOD_SEC as

  type t_mod_list    is table of OPAS_GROUPS2APEXUSR.modname%type;
  type t_grp_id_list is table of opas_groups.group_id%type;

  function is_mod_installed(p_modname opas_modules.MODNAME%type) return boolean RESULT_CACHE;

  function is_role_assigned(p_modname OPAS_GROUPS2APEXUSR.modname%type, p_group_name opas_groups.group_name%type) return boolean;
  function is_role_assigned_n(p_modname OPAS_GROUPS2APEXUSR.modname%type, p_group_name opas_groups.group_name%type) return number;

  procedure save_role_assignment(p_modname_lst t_mod_list, p_group_id_lst t_grp_id_list, p_apex_user OPAS_GROUPS2APEXUSR.apex_user%type);

  --common UI rights
  --Projects
  --function proj_is_role_assigned(p_proj_type opas_project_types.proj_type%type, p_group_name opas_groups.group_name%type) return boolean;

end COREMOD_SEC;
/
