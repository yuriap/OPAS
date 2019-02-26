CREATE OR REPLACE
package ASHA_PROJ_API as

  --project cleanup modes
  c_ALL         constant number :=1;
  c_SOURCEDATA  constant number :=2;
  c_PARSEDDATA  constant number :=3;

  --project
  procedure create_project(p_proj_name    asha_cube_projects.proj_name%type,
                           p_owner        asha_cube_projects.owner%type,
                           p_keep_forever asha_cube_projects.keep_forever%type default 'N',
                           p_is_public    asha_cube_projects.is_public%type default 'Y',
                           p_proj_id  out asha_cube_projects.proj_id%type);

  procedure edit_project  (p_proj_id      asha_cube_projects.proj_id%type,
                           p_proj_name    asha_cube_projects.proj_name%type,
                           p_priority     asha_cube_projects.priority%type);

  procedure set_project_security
                        (p_proj_id        asha_cube_projects.proj_id%type,
                         p_owner          asha_cube_projects.owner%type,
                         p_keep_forever   asha_cube_projects.keep_forever%type,
                         p_is_public      asha_cube_projects.is_public%type);

  procedure set_project_crdt(p_proj_id asha_cube_projects.proj_id%type,
                             p_created   asha_cube_projects.created%type);

  procedure drop_project(p_proj_id asha_cube_projects.proj_id%type);

  procedure lock_project(p_proj_id asha_cube_projects.proj_id%type);
  procedure unlock_project(p_proj_id asha_cube_projects.proj_id%type);

  procedure compress_project(p_proj_id asha_cube_projects.proj_id%type);  --remove source data
  procedure archive_project(p_proj_id asha_cube_projects.proj_id%type);   --remove source and parsed data

  -----------------------------------------------------------------
  procedure cleanup_projects;
  -----------------------------------------------------------------
  function  getproject(p_proj_id asha_cube_projects.proj_id%type, p_for_update boolean default false) return asha_cube_projects%rowtype;

  procedure set_note(p_proj_id      asha_cube_projects.proj_id%type,
                     p_proj_note    asha_cube_projects.proj_note%type);

  procedure set_proj_dblinks (p_proj_id       asha_cube_projects.proj_id%type,
                              p_db_links_list varchar2);

  procedure set_proj_def_dblink (p_proj_id       asha_cube_projects.proj_id%type,
                                  p_db_link       asha_cube_srcdblink2projects.src_dblink%type);
  function  get_proj_def_dblink (p_proj_id       asha_cube_projects.proj_id%type) return asha_cube_srcdblink2projects.src_dblink%type;

  -- move data between projects
  procedure move_cube(p_sess_id          asha_cube_sess.sess_id%type,
                      p_new_proj_id      asha_cube_projects.proj_id%type);

  procedure move_report(p_report_id      asha_cube_reports.report_id%type,
                        p_new_proj_id    asha_cube_projects.proj_id%type);

end ASHA_PROJ_API;
/
