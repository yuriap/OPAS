CREATE OR REPLACE
PACKAGE DB_GROWTH_PROJ_API AS

  --project cleanup modes
  c_ALL         constant number :=1;
  c_SOURCEDATA  constant number :=2;
  c_PARSEDDATA  constant number :=3;

  --project
  procedure create_project(p_proj_name    db_growth_projects.proj_name%type,
                           p_owner        db_growth_projects.owner%type,
                           p_keep_forever db_growth_projects.keep_forever%type default 'N',
                           p_is_public    db_growth_projects.is_public%type default 'Y',
                           p_proj_id  out db_growth_projects.proj_id%type);

  procedure edit_project  (p_proj_id      db_growth_projects.proj_id%type,
                           p_proj_name    db_growth_projects.proj_name%type,
                           p_priority     db_growth_projects.priority%type);

  procedure set_project_security
                        (p_proj_id        db_growth_projects.proj_id%type,
                         p_owner          db_growth_projects.owner%type,
                         p_keep_forever   db_growth_projects.keep_forever%type,
                         p_is_public      db_growth_projects.is_public%type);

  procedure drop_project(p_proj_id db_growth_projects.proj_id%type);

  procedure archive_project(p_proj_id db_growth_projects.proj_id%type);   --remove source and parsed data

  -----------------------------------------------------------------
  procedure cleanup_projects;
  -----------------------------------------------------------------
  function  getproject(p_proj_id db_growth_projects.proj_id%type, p_for_update boolean default false) return db_growth_projects%rowtype;

  procedure set_note(p_proj_id      db_growth_projects.proj_id%type,
                     p_proj_note    db_growth_projects.proj_note%type);

--  function  get_proj_dblink (p_proj_id db_growth_projects.proj_id%type) return db_growth_srcdblink2projects.src_dblink%type;
--  procedure set_proj_dblink (p_proj_id db_growth_projects.proj_id%type, p_dblink db_growth_srcdblink2projects.src_dblink%type);

END DB_GROWTH_PROJ_API;
/
