CREATE OR REPLACE
PACKAGE DB_GROWTH_API AS

  gMODNAME                constant varchar2(32) := 'DB_GROWTH';

  function  getMODNAME return varchar2;

  procedure set_parameters (p_proj_id     db_growth_parameters.proj_id%type,
                            p_src_dblink  db_growth_parameters.src_dblink%type,
                            p_scheme_list db_growth_parameters.scheme_list%type,
                            p_schedule    db_growth_parameters.schedule%type,
                            p_start_date  db_growth_parameters.start_date%type);

  procedure set_alerts (p_proj_id     db_growth_parameters.proj_id%type,
                        p_delta_alert db_growth_parameters.delta_alert%type,
                        p_size_alert  db_growth_parameters.size_alert%type);

  procedure suspend_config(p_proj_id db_growth_projects.proj_id%type);
  procedure activate_config(p_proj_id db_growth_projects.proj_id%type);
  procedure validate_config(p_proj_id db_growth_projects.proj_id%type);
  procedure cleanup_config(p_proj_id db_growth_projects.proj_id%type);

  procedure refresh_matviews;

  --for job
  procedure gather_data(p_proj_id db_growth_projects.proj_id%type);

END DB_GROWTH_API;
/
