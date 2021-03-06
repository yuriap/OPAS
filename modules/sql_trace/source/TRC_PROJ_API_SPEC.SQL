CREATE OR REPLACE
package TRC_PROJ_API as

  --project cleanup modes
  c_ALL         constant number :=1;
  c_SOURCEDATA  constant number :=2;
  c_PARSEDDATA  constant number :=3;

  --project
  procedure create_project(p_proj_name    trc_projects.proj_name%type,
                           p_owner        trc_projects.owner%type,
                           p_keep_forever trc_projects.keep_forever%type default 'N',
                           p_is_public    trc_projects.is_public%type default 'Y',
                           p_proj_id  out trc_projects.proj_id%type);

  procedure edit_project  (p_proj_id      trc_projects.proj_id%type,
                           p_proj_name    trc_projects.proj_name%type,
                           p_priority     trc_projects.priority%type);

  procedure set_project_security
                        (p_proj_id        trc_projects.proj_id%type,
                         p_owner          trc_projects.owner%type,
                         p_keep_forever   trc_projects.keep_forever%type,
                         p_is_public      trc_projects.is_public%type);

  procedure set_project_crdt(p_proj_id trc_projects.proj_id%type,
                             p_created   trc_projects.created%type);

  procedure drop_project(p_proj_id trc_projects.proj_id%type);

  procedure lock_project(p_proj_id trc_projects.proj_id%type);
  procedure unlock_project(p_proj_id trc_projects.proj_id%type);

  procedure compress_project(p_proj_id trc_projects.proj_id%type);  --remove source data
  procedure archive_project(p_proj_id trc_projects.proj_id%type);   --remove source and parsed data

  -----------------------------------------------------------------
  procedure cleanup_projects;
  -----------------------------------------------------------------
  function  getproject(p_proj_id trc_projects.proj_id%type, p_for_update boolean default false) return trc_projects%rowtype;

  procedure set_note(p_proj_id      trc_projects.proj_id%type,
                     p_proj_note    trc_projects.proj_note%type);

  -- move data between projects
  procedure move_trace(p_trc_file_id      trc_files.trc_file_id%type,
                       p_new_proj_id      trc_projects.proj_id%type);


end TRC_PROJ_API;
/
