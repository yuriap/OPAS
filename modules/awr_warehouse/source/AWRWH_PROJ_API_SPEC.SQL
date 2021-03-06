CREATE OR REPLACE
package AWRWH_PROJ_API as

  --project cleanup modes
  c_ALL         constant number :=1;
  c_SOURCEDATA  constant number :=2;
  c_PARSEDDATA  constant number :=3;
  c_REPORTS     constant number :=4;

  --project
  procedure create_project(p_proj_name    awrwh_projects.proj_name%type,
                           p_owner        awrwh_projects.owner%type,
                           p_keep_forever awrwh_projects.keep_forever%type default 'N',
                           p_is_public    awrwh_projects.is_public%type default 'Y',
                           p_proj_id  out awrwh_projects.proj_id%type);

  procedure edit_project  (p_proj_id      awrwh_projects.proj_id%type,
                           p_proj_name    awrwh_projects.proj_name%type,
                           p_priority     awrwh_projects.priority%type);

  procedure set_project_security
                        (p_proj_id        awrwh_projects.proj_id%type,
                         p_owner          awrwh_projects.owner%type,
                         p_keep_forever   awrwh_projects.keep_forever%type,
                         p_is_public      awrwh_projects.is_public%type);

  procedure set_project_crdt(p_proj_id awrwh_projects.proj_id%type,
                             p_created   awrwh_projects.created%type);

  procedure drop_project(p_proj_id awrwh_projects.proj_id%type);

  procedure lock_project(p_proj_id awrwh_projects.proj_id%type);
  procedure unlock_project(p_proj_id awrwh_projects.proj_id%type);

  procedure compress_project(p_proj_id awrwh_projects.proj_id%type);  --remove source data
  procedure archive_project(p_proj_id awrwh_projects.proj_id%type);   --remove source and parsed data

  -----------------------------------------------------------------
  procedure cleanup_projects;
  -----------------------------------------------------------------
  function  getproject(p_proj_id awrwh_projects.proj_id%type, p_for_update boolean default false) return awrwh_projects%rowtype;

  procedure set_note(p_proj_id      awrwh_projects.proj_id%type,
                     p_proj_note    awrwh_projects.proj_note%type);
  procedure set_proj_dblinks (p_proj_id       awrwh_projects.proj_id%type,
                              p_db_links_list varchar2);
  procedure set_proj_def_dblink (p_proj_id       awrwh_projects.proj_id%type,
                                  p_db_link       awrwh_srcdblink2projects.src_dblink%type);
  function  get_proj_def_dblink (p_proj_id       awrwh_projects.proj_id%type) return awrwh_srcdblink2projects.src_dblink%type;

  -- move data between projects
  procedure move_dump(p_dump_id          awrwh_dumps.dump_id%type,
                      p_new_proj_id      awrwh_projects.proj_id%type);

  procedure move_report(p_report_id      awrwh_reports.report_id%type,
                        p_new_proj_id    awrwh_projects.proj_id%type);

end AWRWH_PROJ_API;
/
