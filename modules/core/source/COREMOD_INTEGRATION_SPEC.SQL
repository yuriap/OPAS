CREATE OR REPLACE
PACKAGE COREMOD_INTEGRATION AS

  procedure register_integration(p_int_key           opas_integration_tmpl.int_key%type,
                                 p_owner_modname     opas_integration_tmpl.owner_modname%type,
                                 p_src_modname       opas_integration_tmpl.src_modname%type,
                                 p_trg_modname       opas_integration_tmpl.trg_modname%type,
                                 p_src_url_tmpl      opas_integration_tmpl.src_url_tmpl%type,
                                 p_trg_url_tmpl      opas_integration_tmpl.trg_url_tmpl%type,
                                 p_src_desc_tmpl     opas_integration_tmpl.src_desc_tmpl%type,
                                 p_trg_desc_tmpl     opas_integration_tmpl.trg_desc_tmpl%type,
                                 p_src_desc_dyn_tmpl opas_integration_tmpl.src_desc_dyn_tmpl%type,
                                 p_trg_desc_dyn_tmpl opas_integration_tmpl.trg_desc_dyn_tmpl%type);

  procedure create_integration(p_int_key             opas_integration.int_key%type,
                               p_src_entity_id       opas_integration.src_entity_id%type,
                               p_src_prnt_entity_id  opas_integration.src_prnt_entity_id%type,
                               p_trg_entity_id       opas_integration.trg_entity_id%type,
                               p_trg_prnt_entity_id  opas_integration.trg_prnt_entity_id%type);

  procedure clone_integration (p_int_key             opas_integration.int_key%type,
                               p_modname             opas_integration_tmpl.owner_modname%type,
                               p_trg_entity_id       opas_integration.trg_entity_id%type,
                               p_trg_prnt_entity_id  opas_integration.trg_prnt_entity_id%type,
                               p_new_trg_entity_id   opas_integration.trg_entity_id%type);

  procedure print_url_list(p_int_key             opas_integration_tmpl.int_key%type,
                           p_type                varchar2, --SOURCE, TARGET
                           p_modname             opas_integration_tmpl.owner_modname%type,
                           p_prnt_entity_id      opas_integration.src_prnt_entity_id%type,
                           p_entity_id           opas_integration.src_entity_id%type default null);
  function does_integration_exist(
                           p_int_key             opas_integration_tmpl.int_key%type,
                           p_type                varchar2, --SOURCE, TARGET
                           p_modname             opas_integration_tmpl.owner_modname%type,
                           p_prnt_entity_id      opas_integration.src_prnt_entity_id%type,
                           p_entity_id           opas_integration.src_entity_id%type default null) return boolean;
  function does_integration_exist(
                           p_int_key             opas_integration_tmpl.int_key%type,
                           p_modname             opas_integration_tmpl.owner_modname%type,
                           p_prnt_entity_id      opas_integration.src_prnt_entity_id%type,
                           p_entity_id           opas_integration.src_entity_id%type default null) return boolean;
  procedure remove_integration(
                           p_int_key             opas_integration_tmpl.int_key%type,
                           p_modname             opas_integration_tmpl.owner_modname%type,
                           p_prnt_entity_id      opas_integration.src_prnt_entity_id%type,
                           p_entity_id           opas_integration.src_entity_id%type default null);
  --
  function get_src_url(p_int_id opas_integration.int_id%type) return varchar2;
  function get_trg_url(p_int_id opas_integration.int_id%type) return varchar2;
END COREMOD_INTEGRATION;
/
