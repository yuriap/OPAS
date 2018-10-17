CREATE OR REPLACE
package TRC_PROJ_LCC as

  -- Project actions
  c_project_create        constant VARCHAR2(20) :='CREATE';
  c_project_edit          constant VARCHAR2(20) :='EDIT';
  c_project_drop          constant VARCHAR2(20) :='DROP';
  c_project_rocontent     constant VARCHAR2(20) :='R/O CONTENT';  -- Read-only project content
  c_project_rwcontent     constant VARCHAR2(20) :='R/W CONTENT';  -- Read-write project content
  c_project_lock          constant VARCHAR2(20) :='LOCK';
  c_project_unlock        constant VARCHAR2(20) :='UNLOCK';
  c_project_compress      constant VARCHAR2(20) :='COMPRESS';
  c_project_archive       constant VARCHAR2(20) :='ARCHIVE';

  --Project states
  c_projstate_new         constant trc_projects.status%type := 'NEW';        --just created                                                    fa-window-new
  c_projstate_active      constant trc_projects.status%type := 'ACTIVE';     --actively used                                                   fa-window-check
  c_projstate_locked      constant trc_projects.status%type := 'LOCKED';     --read only, no activity, excluded from purging, can be unlocked  fa-window-lock
  c_projstate_compressed  constant trc_projects.status%type := 'COMPRESSED'; --source data removed, parsed is available                        fa-window-search
  c_projstate_archived    constant trc_projects.status%type := 'ARCHIVED';   --source and parsed data removed                                  fa-window-ban

  --Project life-cycle set state
  procedure project_exec_action(p_proj trc_projects%rowtype, p_action VARCHAR2);
  procedure project_exec_action(p_proj_id trc_projects.proj_id%type, p_action VARCHAR2);

  --Project action availability
  function project_check_action(p_proj_id trc_projects.proj_id%type, p_action VARCHAR2) return boolean;
  function project_check_action(p_proj trc_projects%rowtype, p_action VARCHAR2) return boolean;

end TRC_PROJ_LCC;
/
