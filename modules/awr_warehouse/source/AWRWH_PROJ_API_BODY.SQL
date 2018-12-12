CREATE OR REPLACE
package body AWRWH_PROJ_API as

  function getproject(p_proj_id awrwh_projects.proj_id%type, p_for_update boolean default false) return awrwh_projects%rowtype
  is
    l_curproj awrwh_projects%rowtype;
  begin
    if nvl(p_for_update,false) then
      select * into l_curproj from awrwh_projects where proj_id=p_proj_id for update nowait;
    else
      select * into l_curproj from awrwh_projects where proj_id=p_proj_id;
    end if;
    return l_curproj;
  end;

  procedure create_project(p_proj_name    awrwh_projects.proj_name%type,
                           p_owner        awrwh_projects.owner%type,
                           p_keep_forever awrwh_projects.keep_forever%type default 'N',
                           p_is_public    awrwh_projects.is_public%type default 'Y',
                           p_proj_id  out awrwh_projects.proj_id%type)as
    l_curproj awrwh_projects%rowtype;
  begin
    INSERT INTO awrwh_projects (   proj_name,   owner, proj_note,   keep_forever,   is_public )
                        VALUES ( p_proj_name, p_owner, null,      p_keep_forever, p_is_public )
    returning proj_id, status into l_curproj.proj_id, l_curproj.status;

    p_proj_id:=l_curproj.proj_id;

    AWRWH_PROJ_LCC.project_exec_action(l_curproj,AWRWH_PROJ_LCC.c_project_create);
  end create_project;

  procedure edit_project  (p_proj_id      awrwh_projects.proj_id%type,
                           p_proj_name    awrwh_projects.proj_name%type) as
    l_curproj awrwh_projects%rowtype;
  begin
    l_curproj:=getproject(p_proj_id, true);
    AWRWH_PROJ_LCC.project_exec_action(l_curproj,AWRWH_PROJ_LCC.c_project_edit);

    UPDATE awrwh_projects
       SET
           proj_name = p_proj_name
     WHERE proj_id = p_proj_id;

  end edit_project;

  procedure set_project_security
                        (p_proj_id     awrwh_projects.proj_id%type,
                         p_owner       awrwh_projects.owner%type,
                         p_keep_forever awrwh_projects.keep_forever%type,
                         p_is_public   awrwh_projects.is_public%type) as
    l_curproj awrwh_projects%rowtype;
  begin
    l_curproj:=getproject(p_proj_id, true);
    AWRWH_PROJ_LCC.project_exec_action(l_curproj,AWRWH_PROJ_LCC.c_project_edit);

    UPDATE awrwh_projects
       SET
           owner = p_owner,
           keep_forever = p_keep_forever,
           is_public = case when p_owner = 'PUBLIC' then 'Y' else p_is_public end
     WHERE proj_id = p_proj_id;

  end set_project_security;

  procedure set_project_crdt(p_proj_id awrwh_projects.proj_id%type,
                             p_created   awrwh_projects.created%type) as
    l_curproj awrwh_projects%rowtype;
  begin
    l_curproj:=getproject(p_proj_id, true);
    UPDATE awrwh_projects
       SET
           created =p_created
     WHERE proj_id =p_proj_id;
  end set_project_crdt;



  procedure cleanup_project(p_proj_id awrwh_projects.proj_id%type, p_mode number, p_use_retention boolean) as
    l_curproj awrwh_projects%rowtype;
    l_errmsg  varchar2(1000);
    l_cmd     varchar2(1000);
	l_done    number := 0;
  begin
    l_curproj:=getproject(p_proj_id, true);
    AWRWH_FILE_API.cleanup_files(p_proj_id,p_mode,p_use_retention);
  end cleanup_project;

  procedure drop_project_i(p_proj_id awrwh_projects.proj_id%type, p_is_purge boolean default false) as
    l_curproj awrwh_projects%rowtype;
  begin
    l_curproj:=getproject(p_proj_id, true);

	if not p_is_purge then
      AWRWH_PROJ_LCC.project_exec_action(l_curproj,AWRWH_PROJ_LCC.c_project_drop);
	end if;

    cleanup_project(p_proj_id=>p_proj_id, p_mode => c_ALL, p_use_retention => false);

    delete from awrwh_projects where proj_id=p_proj_id;
  end drop_project_i;


  procedure drop_project(p_proj_id awrwh_projects.proj_id%type)
  is
  begin
    drop_project_i(p_proj_id=>p_proj_id, p_is_purge => false);
  end;

  procedure cleanup_projects is
    l_curproj awrwh_projects%rowtype; --getproject
  begin

    for p in (select proj_id, systimestamp - created duration, nvl(keep_forever,'N') keep_forever from awrwh_projects) loop
	  if p.keep_forever='N' and p.duration > TO_DSINTERVAL(nvl(COREMOD_API.getconf('PROJECTRETENTION',AWRWH_API.gMODNAME),8)||' 00:00:00') then
        begin
          drop_project_i(p_proj_id=>p.proj_id, p_is_purge => true);
		   --coremod_log.log('Project removed: '||p.proj_id||' : '||p.proj_name);
        exception
          when others then
            coremod_log.log('Removing project '||p.proj_id||' error: '||sqlerrm);
            coremod_log.log(DBMS_UTILITY.FORMAT_ERROR_STACK);
            coremod_log.log(DBMS_UTILITY.FORMAT_ERROR_BACKTRACE);
        end;
      else
        begin
          cleanup_project(p_proj_id=>p.proj_id, p_mode => c_ALL, p_use_retention => true);
		  --coremod_log.log('Project cleaned: '||p.proj_id||' : '||p.proj_name);
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

  procedure lock_project(p_proj_id awrwh_projects.proj_id%type)is
    l_curproj awrwh_projects%rowtype;
  begin
    l_curproj:=getproject(p_proj_id, true);
    AWRWH_PROJ_LCC.project_exec_action(l_curproj,AWRWH_PROJ_LCC.c_project_lock);
  end;

  procedure unlock_project(p_proj_id awrwh_projects.proj_id%type)is
    l_curproj awrwh_projects%rowtype;
  begin
    l_curproj:=getproject(p_proj_id, true);
    AWRWH_PROJ_LCC.project_exec_action(l_curproj,AWRWH_PROJ_LCC.c_project_unlock);
  end;

  procedure compress_project(p_proj_id awrwh_projects.proj_id%type) as
    l_curproj awrwh_projects%rowtype;
  begin
    l_curproj:=getproject(p_proj_id, true);
    AWRWH_PROJ_LCC.project_exec_action(l_curproj,AWRWH_PROJ_LCC.c_project_compress);
	cleanup_project(p_proj_id=>p_proj_id, p_mode => c_SOURCEDATA, p_use_retention => false);
  end;

  procedure archive_project(p_proj_id awrwh_projects.proj_id%type) as
    l_curproj awrwh_projects%rowtype;
  begin
    l_curproj:=getproject(p_proj_id, true);
    AWRWH_PROJ_LCC.project_exec_action(l_curproj,AWRWH_PROJ_LCC.c_project_archive);
	cleanup_project(p_proj_id=>p_proj_id, p_mode => c_SOURCEDATA, p_use_retention => false);
	cleanup_project(p_proj_id=>p_proj_id, p_mode => c_PARSEDDATA, p_use_retention => false);
  end;

  procedure set_note(p_proj_id      awrwh_projects.proj_id%type,
                     p_proj_note    awrwh_projects.proj_note%type)
  is
    l_curproj awrwh_projects%rowtype;
  begin
    l_curproj:=getproject(p_proj_id, true);
    AWRWH_PROJ_LCC.project_exec_action(l_curproj,AWRWH_PROJ_LCC.c_project_edit);
    update awrwh_projects set proj_note = p_proj_note where proj_id = p_proj_id;
  end;

end AWRWH_PROJ_API;
/
