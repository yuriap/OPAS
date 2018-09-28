create or replace package TRC_PROJ_API as

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
                           p_proj_name    trc_projects.proj_name%type);

  procedure set_project_security
                        (p_proj_id        trc_projects.proj_id%type,
                         p_owner          trc_projects.owner%type,
                         p_keep_forever   trc_projects.keep_forever%type,
                         p_is_public      trc_projects.is_public%type);

  procedure set_project_crdt(p_proj_id trc_projects.proj_id%type,
                             p_created   trc_projects.created%type);

  procedure drop_project(p_proj_id trc_projects.proj_id%type);
  procedure load_project(p_proj_id trc_projects.proj_id%type);
  procedure parse_project(p_proj_id trc_projects.proj_id%type);
  procedure report_cr(p_proj_id trc_projects.proj_id%type);
  procedure report_vw(p_proj_id trc_projects.PROJ_ID%type);

  procedure lock_project(p_proj_id trc_projects.proj_id%type);
  procedure unlock_project(p_proj_id trc_projects.proj_id%type);

  procedure compress_project(p_proj_id trc_projects.proj_id%type);  --remove source data
  procedure archive_project(p_proj_id trc_projects.proj_id%type);   --remove source and parsed data
  procedure close_project(p_proj_id trc_projects.proj_id%type);


  -----------------------------------------------------------------
  procedure cleanup_projects;
  -----------------------------------------------------------------
  function  getproject(p_proj_id trc_projects.proj_id%type, p_for_update boolean default false) return trc_projects%rowtype;

  procedure set_note(p_proj_id      trc_projects.proj_id%type,
                     p_proj_note    trc_projects.proj_note%type);

end TRC_PROJ_API;
/
--------------------------------------------------------
show errors
--------------------------------------------------------

create or replace package body TRC_PROJ_API as

  function getproject(p_proj_id trc_projects.proj_id%type, p_for_update boolean default false) return trc_projects%rowtype
  is
    l_curproj trc_projects%rowtype;
  begin
    if nvl(p_for_update,false) then
      select * into l_curproj from trc_projects where proj_id=p_proj_id for update nowait;
    else
      select * into l_curproj from trc_projects where proj_id=p_proj_id;
    end if;
    return l_curproj;
  end;

  procedure create_project(p_proj_name    trc_projects.proj_name%type,
                           p_owner        trc_projects.owner%type,
                           p_keep_forever trc_projects.keep_forever%type default 'N',
                           p_is_public    trc_projects.is_public%type default 'Y',
                           p_proj_id  out trc_projects.proj_id%type)as
    l_curproj trc_projects%rowtype;
  begin
    INSERT INTO trc_projects (   proj_name,   owner, proj_note,   keep_forever,   is_public )
                      VALUES ( p_proj_name, p_owner, null,      p_keep_forever, p_is_public )
    returning proj_id, status into l_curproj.proj_id, l_curproj.status;

    p_proj_id:=l_curproj.proj_id;

    TRC_PROJ_LCC.project_exec_action(l_curproj,TRC_PROJ_LCC.c_project_create);
  end create_project;

  procedure edit_project  (p_proj_id      trc_projects.proj_id%type,
                           p_proj_name    trc_projects.proj_name%type) as
    l_curproj trc_projects%rowtype;
  begin
    l_curproj:=getproject(p_proj_id, true);
    TRC_PROJ_LCC.project_exec_action(l_curproj,TRC_PROJ_LCC.c_project_edit);

    UPDATE trc_projects
       SET
           proj_name = p_proj_name
     WHERE proj_id = p_proj_id;

  end edit_project;

  procedure set_project_security
                        (p_proj_id     trc_projects.proj_id%type,
                         p_owner       trc_projects.owner%type,
                         p_keep_forever trc_projects.keep_forever%type,
                         p_is_public   trc_projects.is_public%type) as
    l_curproj trc_projects%rowtype;
  begin
    l_curproj:=getproject(p_proj_id, true);
    TRC_PROJ_LCC.project_exec_action(l_curproj,TRC_PROJ_LCC.c_project_edit);

    UPDATE trc_projects
       SET
           owner = p_owner,
           keep_forever = p_keep_forever,
           is_public = case when p_owner = 'PUBLIC' then 'Y' else p_is_public end
     WHERE proj_id = p_proj_id;

  end set_project_security;

  procedure set_project_crdt(p_proj_id trc_projects.proj_id%type,
                             p_created   trc_projects.created%type) as
    l_curproj trc_projects%rowtype;
  begin
    l_curproj:=getproject(p_proj_id, true);
    UPDATE trc_projects
       SET
           created =p_created
     WHERE proj_id =p_proj_id;
  end set_project_crdt;



  procedure cleanup_project(p_proj_id trc_projects.proj_id%type, p_mode number, p_use_retention boolean) as
    l_curproj trc_projects%rowtype;
    l_errmsg  varchar2(1000);
    l_cmd     varchar2(1000);
	l_done    number := 0;
  begin
    l_curproj:=getproject(p_proj_id, true);
    TRC_FILE_API.cleanup_files(p_proj_id,p_mode,p_use_retention);
  end cleanup_project;

  procedure drop_project_i(p_proj_id trc_projects.proj_id%type, p_is_purge boolean default false) as
    l_curproj trc_projects%rowtype;
  begin
    l_curproj:=getproject(p_proj_id, true);

	if not p_is_purge then
      TRC_PROJ_LCC.project_exec_action(l_curproj,TRC_PROJ_LCC.c_project_drop);
	end if;

    cleanup_project(p_proj_id=>p_proj_id, p_mode => c_ALL, p_use_retention => false);

    delete from trc_projects where proj_id=p_proj_id;
  end drop_project_i;


  procedure drop_project(p_proj_id trc_projects.proj_id%type)
  is
  begin
    drop_project_i(p_proj_id=>p_proj_id, p_is_purge => false);
  end;

  procedure cleanup_projects is
    l_curproj trc_projects%rowtype; --getproject
  begin

    for p in (select proj_id, systimestamp - created duration, nvl(keep_forever,'N') keep_forever from trc_projects) loop
	  if p.keep_forever='N' and p.duration > TO_DSINTERVAL(nvl(COREMOD_API.getconf('PROJECTRETENTION',TRC_FILE_API.gMODNAME),8)||' 00:00:00') then
        begin
          drop_project_i(p_proj_id=>p.proj_id, p_is_purge => true);
        exception
          when others then
            coremod_log.log('Cleanup project '||p.proj_id||' error: '||sqlerrm);
            coremod_log.log(DBMS_UTILITY.FORMAT_ERROR_STACK);
            coremod_log.log(DBMS_UTILITY.FORMAT_ERROR_BACKTRACE);
        end;
      else
        begin
          cleanup_project(p_proj_id=>p.proj_id, p_mode => c_ALL, p_use_retention => true);
        exception
          when others then
            coremod_log.log('Cleanup project '||p.proj_id||' components error: '||sqlerrm);
            coremod_log.log(DBMS_UTILITY.FORMAT_ERROR_STACK);
            coremod_log.log(DBMS_UTILITY.FORMAT_ERROR_BACKTRACE);
        end;
	  end if;
	end loop;
    commit;
  end;

  procedure load_project(p_proj_id trc_projects.proj_id%type)is
    l_curproj trc_projects%rowtype;
  begin
    l_curproj:=getproject(p_proj_id, false);
    TRC_PROJ_LCC.project_exec_action(l_curproj,TRC_PROJ_LCC.c_project_load);
  end;

  procedure parse_project(p_proj_id trc_projects.proj_id%type)is
    l_curproj trc_projects%rowtype;
  begin
    l_curproj:=getproject(p_proj_id, false);
    TRC_PROJ_LCC.project_exec_action(l_curproj,TRC_PROJ_LCC.c_project_parse);
  end;

  procedure report_cr(p_proj_id trc_projects.proj_id%type)is
    l_curproj trc_projects%rowtype;
  begin
    l_curproj:=getproject(p_proj_id, false);
    TRC_PROJ_LCC.project_exec_action(l_curproj,TRC_PROJ_LCC.c_project_report_cr);
  end;

  procedure report_vw(p_proj_id trc_projects.proj_id%type)is
    l_curproj trc_projects%rowtype;
  begin
    l_curproj:=getproject(p_proj_id, false);
    TRC_PROJ_LCC.project_exec_action(l_curproj,TRC_PROJ_LCC.c_project_report_vw);
  end;

  procedure lock_project(p_proj_id trc_projects.proj_id%type)is
    l_curproj trc_projects%rowtype;
  begin
    l_curproj:=getproject(p_proj_id, true);
    TRC_PROJ_LCC.project_exec_action(l_curproj,TRC_PROJ_LCC.c_project_lock);
  end;

  procedure unlock_project(p_proj_id trc_projects.proj_id%type)is
    l_curproj trc_projects%rowtype;
  begin
    l_curproj:=getproject(p_proj_id, true);
    TRC_PROJ_LCC.project_exec_action(l_curproj,TRC_PROJ_LCC.c_project_unlock);
  end;

  procedure close_project(p_proj_id trc_projects.proj_id%type)is
    l_curproj trc_projects%rowtype;
  begin
    l_curproj:=getproject(p_proj_id, true);
    TRC_PROJ_LCC.project_exec_action(l_curproj,TRC_PROJ_LCC.c_project_close);
  end;

  procedure compress_project(p_proj_id trc_projects.proj_id%type) as
    l_curproj trc_projects%rowtype;
  begin
    l_curproj:=getproject(p_proj_id, true);
    TRC_PROJ_LCC.project_exec_action(l_curproj,TRC_PROJ_LCC.c_project_compress);
	cleanup_project(p_proj_id=>p_proj_id, p_mode => c_SOURCEDATA, p_use_retention => false);
  end;

  procedure archive_project(p_proj_id trc_projects.proj_id%type) as
    l_curproj trc_projects%rowtype;
  begin
    l_curproj:=getproject(p_proj_id, true);
    TRC_PROJ_LCC.project_exec_action(l_curproj,TRC_PROJ_LCC.c_project_archive);
	cleanup_project(p_proj_id=>p_proj_id, p_mode => c_SOURCEDATA, p_use_retention => false);
	cleanup_project(p_proj_id=>p_proj_id, p_mode => c_PARSEDDATA, p_use_retention => false);
  end;

  procedure set_note(p_proj_id      trc_projects.proj_id%type,
                     p_proj_note    trc_projects.proj_note%type)
  is
    l_curproj trc_projects%rowtype;
  begin
    l_curproj:=getproject(p_proj_id, true);
    TRC_PROJ_LCC.project_exec_action(l_curproj,TRC_PROJ_LCC.c_project_edit);
    update trc_projects set proj_note = p_proj_note where proj_id = p_proj_id;
  end;

end TRC_PROJ_API;
/
--------------------------------------------------------
show errors
--------------------------------------------------------