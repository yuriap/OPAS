CREATE OR REPLACE
PACKAGE BODY DB_GROWTH_PROJ_API AS

  function getproject(p_proj_id db_growth_projects.proj_id%type, p_for_update boolean default false) return db_growth_projects%rowtype
  is
    l_curproj db_growth_projects%rowtype;
  begin
    if nvl(p_for_update,false) then
      select * into l_curproj from db_growth_projects where proj_id=p_proj_id for update nowait;
    else
      select * into l_curproj from db_growth_projects where proj_id=p_proj_id;
    end if;
    return l_curproj;
  end;
/*
  function  get_proj_dblink (p_proj_id       db_growth_projects.proj_id%type) return db_growth_srcdblink2projects.src_dblink%type
  is
    l_dblink db_growth_srcdblink2projects.src_dblink%type;
  begin
    select src_dblink into l_dblink from db_growth_srcdblink2projects where proj_id=p_proj_id;
    return l_dblink;
    exception when others then return null;
  end;
*/

  procedure create_project(p_proj_name    db_growth_projects.proj_name%type,
                           p_owner        db_growth_projects.owner%type,
                           p_keep_forever db_growth_projects.keep_forever%type default 'N',
                           p_is_public    db_growth_projects.is_public%type default 'Y',
                           p_proj_id  out db_growth_projects.proj_id%type)as
    l_curproj db_growth_projects%rowtype;
  begin
    INSERT INTO db_growth_projects (   proj_name,   owner, proj_note,   keep_forever,   is_public )
                      VALUES ( p_proj_name, p_owner, null,      p_keep_forever, p_is_public )
    returning proj_id, status into l_curproj.proj_id, l_curproj.status;

    p_proj_id:=l_curproj.proj_id;

    DB_GROWTH_PROJ_LCC.project_exec_action(l_curproj,DB_GROWTH_PROJ_LCC.c_project_create);
  end create_project;

  procedure edit_project  (p_proj_id      db_growth_projects.proj_id%type,
                           p_proj_name    db_growth_projects.proj_name%type,
                           p_priority     db_growth_projects.priority%type) as
    l_curproj db_growth_projects%rowtype;
  begin
    l_curproj:=getproject(p_proj_id, true);
    DB_GROWTH_PROJ_LCC.project_exec_action(l_curproj,DB_GROWTH_PROJ_LCC.c_project_edit);

    UPDATE db_growth_projects
       SET
           proj_name = p_proj_name,
           priority  = p_priority
     WHERE proj_id = p_proj_id;

  end edit_project;

  procedure set_project_security
                        (p_proj_id     db_growth_projects.proj_id%type,
                         p_owner       db_growth_projects.owner%type,
                         p_keep_forever db_growth_projects.keep_forever%type,
                         p_is_public   db_growth_projects.is_public%type) as
    l_curproj db_growth_projects%rowtype;
  begin
    l_curproj:=getproject(p_proj_id, true);
    DB_GROWTH_PROJ_LCC.project_exec_action(l_curproj,DB_GROWTH_PROJ_LCC.c_project_edit);

    UPDATE db_growth_projects
       SET
           owner = p_owner,
           keep_forever = p_keep_forever,
           is_public = case when p_owner = 'PUBLIC' then 'Y' else p_is_public end
     WHERE proj_id = p_proj_id;

  end set_project_security;

  procedure cleanup_project(p_proj_id db_growth_projects.proj_id%type) as
    l_curproj db_growth_projects%rowtype;
    l_errmsg  varchar2(1000);
    l_cmd     varchar2(1000);
	l_done    number := 0;
  begin
    l_curproj:=getproject(p_proj_id, true);

    DB_GROWTH_API.cleanup_config(p_proj_id);
  end cleanup_project;

  procedure drop_project_i(p_proj_id db_growth_projects.proj_id%type) as
    l_curproj db_growth_projects%rowtype;
  begin
    l_curproj:=getproject(p_proj_id, true);
    DB_GROWTH_PROJ_LCC.project_exec_action(l_curproj,DB_GROWTH_PROJ_LCC.c_project_drop);

    cleanup_project(p_proj_id=>p_proj_id);

    delete from db_growth_projects where proj_id=p_proj_id;
  end drop_project_i;


  procedure drop_project(p_proj_id db_growth_projects.proj_id%type)
  is
  begin
    drop_project_i(p_proj_id=>p_proj_id);
  end;

  procedure cleanup_projects is
  begin

    for p in (select proj_id,proj_name, systimestamp - created duration, nvl(keep_forever,'N') keep_forever, status from db_growth_projects) loop
	  if p.keep_forever='N' and p.duration > TO_DSINTERVAL(nvl(COREMOD_API.getconf('PROJECTRETENTION',DB_GROWTH_API.gMODNAME),8)||' 00:00:00')
         and p.status in (DB_GROWTH_PROJ_LCC.c_projstate_new,DB_GROWTH_PROJ_LCC.c_projstate_preparing,DB_GROWTH_PROJ_LCC.c_projstate_suspended)
      then
        begin
          drop_project_i(p_proj_id=>p.proj_id);
          coremod_log.log('DB Growth Project removed: '||p.proj_id||' : '||p.proj_name);
        exception
          when others then
            coremod_log.log('Removing DB Growth project '||p.proj_id||' error: '||sqlerrm);
            coremod_log.log(DBMS_UTILITY.FORMAT_ERROR_STACK);
            coremod_log.log(DBMS_UTILITY.FORMAT_ERROR_BACKTRACE);
        end;
      /*else
        begin
          cleanup_project(p_proj_id=>p.proj_id);
          coremod_log.log('DB Growth Project cleaned: '||p.proj_id||' : '||p.proj_name);
        exception
          when others then
            coremod_log.log('Cleanup DB Growth project '||p.proj_id||' components error: '||sqlerrm);
            coremod_log.log(DBMS_UTILITY.FORMAT_ERROR_STACK);
            coremod_log.log(DBMS_UTILITY.FORMAT_ERROR_BACKTRACE);
        end;*/
	  end if;
	end loop;
    commit;
  end;

  procedure archive_project(p_proj_id db_growth_projects.proj_id%type) as
    l_curproj db_growth_projects%rowtype;
  begin
    l_curproj:=getproject(p_proj_id, true);
	cleanup_project(p_proj_id=>p_proj_id);
    DB_GROWTH_PROJ_LCC.project_exec_action(l_curproj,DB_GROWTH_PROJ_LCC.c_project_archive);
  end;

  procedure set_note(p_proj_id      db_growth_projects.proj_id%type,
                     p_proj_note    db_growth_projects.proj_note%type)
  is
    l_curproj db_growth_projects%rowtype;
  begin
    l_curproj:=getproject(p_proj_id, true);
    DB_GROWTH_PROJ_LCC.project_exec_action(l_curproj,DB_GROWTH_PROJ_LCC.c_project_edit);
    update db_growth_projects set proj_note = p_proj_note where proj_id = p_proj_id;
  end;

END DB_GROWTH_PROJ_API;
/
