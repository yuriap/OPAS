CREATE OR REPLACE
package body TRC_PROJ_API as

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
  begin

    for p in (select proj_id,proj_name, systimestamp - created duration, nvl(keep_forever,'N') keep_forever from trc_projects) loop
	  if p.keep_forever='N' and p.duration > TO_DSINTERVAL(nvl(COREMOD_API.getconf('PROJECTRETENTION',TRC_FILE_API.gMODNAME),8)||' 00:00:00') then
        begin
          drop_project_i(p_proj_id=>p.proj_id, p_is_purge => true);
          coremod_log.log('TRC Project removed: '||p.proj_id||' : '||p.proj_name);
        exception
          when others then
            coremod_log.log('Removing TRC project '||p.proj_id||' error: '||sqlerrm);
            coremod_log.log(DBMS_UTILITY.FORMAT_ERROR_STACK);
            coremod_log.log(DBMS_UTILITY.FORMAT_ERROR_BACKTRACE);
        end;
      else
        begin
          cleanup_project(p_proj_id=>p.proj_id, p_mode => c_ALL, p_use_retention => true);
          coremod_log.log('TRC Project cleaned: '||p.proj_id||' : '||p.proj_name);
        exception
          when others then
            coremod_log.log('Cleanup TRC project '||p.proj_id||' components error: '||sqlerrm);
            coremod_log.log(DBMS_UTILITY.FORMAT_ERROR_STACK);
            coremod_log.log(DBMS_UTILITY.FORMAT_ERROR_BACKTRACE);
        end;
	  end if;
	end loop;
    commit;
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

  procedure move_trace(p_trc_file_id      trc_files.trc_file_id%type,
                       p_new_proj_id      trc_projects.proj_id%type)
  is
    l_trc_file         trc_files%rowtype;
  begin
    coremod_log.log('TRC_PROJ_API.move_trace: '||p_trc_file_id||':'||p_new_proj_id,'DEBUG');
    l_trc_file:=TRC_FILE_API.get_file(p_trc_file_id,true);
    if l_trc_file.status not in (TRC_FILE_LCC.c_trcfilestate_new,
                                 TRC_FILE_LCC.c_trcfilestate_loaded,
                                 TRC_FILE_LCC.c_trcfilestate_parsed,
                                 TRC_FILE_LCC.c_trcfilestate_compressed,
                                 TRC_FILE_LCC.c_trcfilestate_archived)
    then raise_application_error(-20000,'Inapropriate status for trace file: '||l_trc_file.status); end if;
    update trc_files set proj_id=p_new_proj_id where trc_file_id = p_trc_file_id;
  end;

end TRC_PROJ_API;
/
