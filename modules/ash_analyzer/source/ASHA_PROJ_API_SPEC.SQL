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
                           p_proj_name    asha_cube_projects.proj_name%type);

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

end ASHA_PROJ_API;
/
