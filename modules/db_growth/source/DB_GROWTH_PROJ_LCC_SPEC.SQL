CREATE OR REPLACE
PACKAGE DB_GROWTH_PROJ_LCC AS

  -- Project actions
  c_project_create        constant VARCHAR2(20) :='CREATE';
  c_project_activate      constant VARCHAR2(20) :='ACTIVATE';
  c_project_validate      constant VARCHAR2(20) :='VALIDATE';
  c_project_edit          constant VARCHAR2(20) :='EDIT';
  c_project_chng_conf     constant VARCHAR2(20) :='CHANGE_CONFIG';
  c_project_drop          constant VARCHAR2(20) :='DROP';
  c_project_rocontent     constant VARCHAR2(20) :='R/O CONTENT';  -- Read-only project content
  c_project_rwcontent     constant VARCHAR2(20) :='R/W CONTENT';  -- Read-write project content
  c_project_suspend       constant VARCHAR2(20) :='SUSPEND';
  c_project_archive       constant VARCHAR2(20) :='ARCHIVE';

  --Project states
  c_projstate_new         constant db_growth_projects.status%type := 'NEW';        --just created                                                    fa-window-new
  c_projstate_preparing   constant db_growth_projects.status%type := 'PREPARING';  --in preparation, being edited                                    fa-window-new
  c_projstate_active      constant db_growth_projects.status%type := 'ACTIVE';     --data is being gathered                                          fa-window-check
  c_projstate_suspended   constant db_growth_projects.status%type := 'SUSPENDED';  --gathering is suspended due to user action or errors             fa-window-lock
  c_projstate_archived    constant db_growth_projects.status%type := 'ARCHIVED';   --no more activity                                                fa-window-ban

  --Project life-cycle set state
  procedure project_exec_action(p_proj db_growth_projects%rowtype, p_action VARCHAR2);
  procedure project_exec_action(p_proj_id db_growth_projects.proj_id%type, p_action VARCHAR2);

  --Project action availability
  function project_check_action(p_proj_id db_growth_projects.proj_id%type, p_action VARCHAR2) return boolean;
  function project_check_action(p_proj db_growth_projects%rowtype, p_action VARCHAR2) return boolean;

END DB_GROWTH_PROJ_LCC;
/
