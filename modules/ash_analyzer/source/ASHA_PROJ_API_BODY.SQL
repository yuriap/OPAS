CREATE OR REPLACE
package body ASHA_PROJ_API as

  function getproject(p_proj_id asha_cube_projects.proj_id%type, p_for_update boolean default false) return asha_cube_projects%rowtype
  is
    l_curproj asha_cube_projects%rowtype;
  begin
    if nvl(p_for_update,false) then
      select * into l_curproj from asha_cube_projects where proj_id=p_proj_id for update nowait;
    else
      select * into l_curproj from asha_cube_projects where proj_id=p_proj_id;
    end if;
    return l_curproj;
  end;

  procedure create_project(p_proj_name    asha_cube_projects.proj_name%type,
                           p_owner        asha_cube_projects.owner%type,
                           p_keep_forever asha_cube_projects.keep_forever%type default 'N',
                           p_is_public    asha_cube_projects.is_public%type default 'Y',
                           p_proj_id  out asha_cube_projects.proj_id%type)as
    l_curproj asha_cube_projects%rowtype;
  begin
    INSERT INTO asha_cube_projects (   proj_name,   owner, proj_note,   keep_forever,   is_public )
                      VALUES ( p_proj_name, p_owner, null,      p_keep_forever, p_is_public )
    returning proj_id, status into l_curproj.proj_id, l_curproj.status;

    p_proj_id:=l_curproj.proj_id;

    ASHA_PROJ_LCC.project_exec_action(l_curproj,ASHA_PROJ_LCC.c_project_create);
  end create_project;

  procedure edit_project  (p_proj_id      asha_cube_projects.proj_id%type,
                           p_proj_name    asha_cube_projects.proj_name%type) as
    l_curproj asha_cube_projects%rowtype;
  begin
    l_curproj:=getproject(p_proj_id, true);
    ASHA_PROJ_LCC.project_exec_action(l_curproj,ASHA_PROJ_LCC.c_project_edit);

    UPDATE asha_cube_projects
       SET
           proj_name = p_proj_name
     WHERE proj_id = p_proj_id;

  end edit_project;

  procedure set_project_security
                        (p_proj_id     asha_cube_projects.proj_id%type,
                         p_owner       asha_cube_projects.owner%type,
                         p_keep_forever asha_cube_projects.keep_forever%type,
                         p_is_public   asha_cube_projects.is_public%type) as
    l_curproj asha_cube_projects%rowtype;
  begin
    l_curproj:=getproject(p_proj_id, true);
    ASHA_PROJ_LCC.project_exec_action(l_curproj,ASHA_PROJ_LCC.c_project_edit);

    UPDATE asha_cube_projects
       SET
           owner = p_owner,
           keep_forever = p_keep_forever,
           is_public = case when p_owner = 'PUBLIC' then 'Y' else p_is_public end
     WHERE proj_id = p_proj_id;

  end set_project_security;

  procedure set_project_crdt(p_proj_id asha_cube_projects.proj_id%type,
                             p_created   asha_cube_projects.created%type) as
    l_curproj asha_cube_projects%rowtype;
  begin
    l_curproj:=getproject(p_proj_id, true);
    UPDATE asha_cube_projects
       SET
           created =p_created
     WHERE proj_id =p_proj_id;
  end set_project_crdt;



  procedure cleanup_project(p_proj_id asha_cube_projects.proj_id%type, p_mode number, p_use_retention boolean) as
    l_done    number := 0;
  begin

    --delete expired sessions
    if p_mode in (c_ALL, c_SOURCEDATA) and p_use_retention then
      l_done:=0;
      for i in (select sess_id from asha_cube_sess
       where sess_proj_id=p_proj_id
         and (sess_created+nvl(sess_retention_days,COREMOD_API.getconf('CUBERETENTION',ASHA_CUBE_API.gMODNAME)/24))<sysdate
         and nvl(sess_retention_days,COREMOD_API.getconf('CUBERETENTION',ASHA_CUBE_API.gMODNAME))>0
         and parent_id is null)
      loop
        delete from asha_cube_sess where sess_id=i.sess_id;
        COREMOD_INTEGRATION.remove_integration
        (  p_int_key => 'AWRWH2ASH_DUMP2CUBE',
           p_modname => 'ASH_ANALYZER',
           P_PRNT_ENTITY_ID => p_proj_id,
           P_ENTITY_ID => i.sess_id) ;
        l_done:=l_done+1;
      end loop;

      coremod_log.log('ASHA Sessions: '||l_done||' removed');

      for i in (select * from asha_cube_reports
                 where proj_id = p_proj_id
                   and (created+nvl(report_retention,COREMOD_API.getconf('REPORTRETENTION',ASHA_CUBE_API.gMODNAME)/24))<sysdate
                   and nvl(report_retention,COREMOD_API.getconf('REPORTRETENTION',ASHA_CUBE_API.gMODNAME))>0)
      loop
        --coremod_report_utils.drop_report(i.report_id);
        --delete from asha_cube_reports where proj_id=i.proj_id and report_id=i.report_id;
        ASHA_CUBE_API.delete_report(p_proj_id, i.report_id);
        l_done:=l_done+1;
      end loop;
      coremod_log.log('ASHA Reports: '||l_done||' removed');

    elsif not p_use_retention then

      for i in (select * from asha_cube_reports where proj_id = p_proj_id)
      loop
        --coremod_report_utils.drop_report(i.report_id);
        ASHA_CUBE_API.delete_report(p_proj_id, i.report_id);
      end loop;
      --delete from asha_cube_reports where proj_id=p_proj_id;
      delete from asha_cube_sess where sess_proj_id=p_proj_id;

    end if;

  end cleanup_project;

  procedure drop_project_i(p_proj_id asha_cube_projects.proj_id%type, p_is_purge boolean default false) as
    l_curproj asha_cube_projects%rowtype;
  begin
    l_curproj:=getproject(p_proj_id, true);

	if not p_is_purge then
      ASHA_PROJ_LCC.project_exec_action(l_curproj,ASHA_PROJ_LCC.c_project_drop);
	end if;

    cleanup_project(p_proj_id=>p_proj_id, p_mode => c_ALL, p_use_retention => false);

    COREMOD_INTEGRATION.remove_integration
    (  p_int_key => 'AWRWH2ASH_DUMP2CUBE',
       p_modname => 'ASH_ANALYZER',
       P_PRNT_ENTITY_ID => p_proj_id,
       P_ENTITY_ID => null) ;

    delete from asha_cube_projects where proj_id=p_proj_id;
  end drop_project_i;


  procedure drop_project(p_proj_id asha_cube_projects.proj_id%type)
  is
  begin
    drop_project_i(p_proj_id=>p_proj_id, p_is_purge => false);
  end;

  procedure cleanup_projects is
    l_curproj asha_cube_projects%rowtype; --getproject
  begin

    for p in (select proj_id,proj_name, systimestamp - created duration, nvl(keep_forever,'N') keep_forever from asha_cube_projects) loop
      if p.keep_forever='N' and p.duration > TO_DSINTERVAL(nvl(COREMOD_API.getconf('PROJECTRETENTION',ASHA_CUBE_API.gMODNAME),8)||' 00:00:00') then
        begin
          drop_project_i(p_proj_id=>p.proj_id, p_is_purge => true);
          coremod_log.log('ASHA Project removed: '||p.proj_id||' : '||p.proj_name);
        exception
          when others then
            coremod_log.log('Removing ASHA project '||p.proj_id||' error: '||sqlerrm);
            coremod_log.log(DBMS_UTILITY.FORMAT_ERROR_STACK);
            coremod_log.log(DBMS_UTILITY.FORMAT_ERROR_BACKTRACE);
        end;
      else
        begin
          cleanup_project(p_proj_id=>p.proj_id, p_mode => c_ALL, p_use_retention => true);
          coremod_log.log('ASHA Project cleaned: '||p.proj_id||' : '||p.proj_name);
        exception
          when others then
            coremod_log.log('Cleanup ASNA project '||p.proj_id||' components error: '||sqlerrm);
            coremod_log.log(DBMS_UTILITY.FORMAT_ERROR_STACK);
            coremod_log.log(DBMS_UTILITY.FORMAT_ERROR_BACKTRACE);
        end;
      end if;
    end loop;
    commit;
  end;

  procedure lock_project(p_proj_id asha_cube_projects.proj_id%type)is
    l_curproj asha_cube_projects%rowtype;
  begin
    l_curproj:=getproject(p_proj_id, true);
    ASHA_PROJ_LCC.project_exec_action(l_curproj,ASHA_PROJ_LCC.c_project_lock);
  end;

  procedure unlock_project(p_proj_id asha_cube_projects.proj_id%type)is
    l_curproj asha_cube_projects%rowtype;
  begin
    l_curproj:=getproject(p_proj_id, true);
    ASHA_PROJ_LCC.project_exec_action(l_curproj,ASHA_PROJ_LCC.c_project_unlock);
  end;

  procedure compress_project(p_proj_id asha_cube_projects.proj_id%type) as
    l_curproj asha_cube_projects%rowtype;
  begin
    l_curproj:=getproject(p_proj_id, true);
    ASHA_PROJ_LCC.project_exec_action(l_curproj,ASHA_PROJ_LCC.c_project_compress);
    cleanup_project(p_proj_id=>p_proj_id, p_mode => c_SOURCEDATA, p_use_retention => false);
  end;

  procedure archive_project(p_proj_id asha_cube_projects.proj_id%type) as
    l_curproj asha_cube_projects%rowtype;
  begin
    l_curproj:=getproject(p_proj_id, true);
    ASHA_PROJ_LCC.project_exec_action(l_curproj,ASHA_PROJ_LCC.c_project_archive);
    cleanup_project(p_proj_id=>p_proj_id, p_mode => c_SOURCEDATA, p_use_retention => false);
    cleanup_project(p_proj_id=>p_proj_id, p_mode => c_PARSEDDATA, p_use_retention => false);
  end;

  procedure set_note(p_proj_id      asha_cube_projects.proj_id%type,
                     p_proj_note    asha_cube_projects.proj_note%type)
  is
    l_curproj asha_cube_projects%rowtype;
  begin
    l_curproj:=getproject(p_proj_id, true);
    ASHA_PROJ_LCC.project_exec_action(l_curproj,ASHA_PROJ_LCC.c_project_edit);
    update asha_cube_projects set proj_note = p_proj_note where proj_id = p_proj_id;
  end;

  procedure set_proj_dblinks (p_proj_id       asha_cube_projects.proj_id%type,
                              p_db_links_list varchar2)
  is
    l_tbl DBMS_UTILITY.LNAME_ARRAY;
    l_n   number;
  begin
    DBMS_UTILITY.COMMA_TO_TABLE (
      list   => replace(replace(p_db_links_list,':',','),'$LOCAL$','LOCAL$$'),
      tablen => l_n,
      tab    => l_tbl);

    delete from asha_cube_srcdblink2projects where proj_id=p_proj_id;
    for i in 1..l_n loop
      --coremod_log.log(i||':'||l_tbl(i));
      insert into asha_cube_srcdblink2projects (proj_id,src_dblink) values(p_proj_id,replace(l_tbl(i),'LOCAL$$','$LOCAL$'));
    end loop;
  end;

  -- move data between projects
  procedure move_cube(p_sess_id          asha_cube_sess.sess_id%type,
                      p_new_proj_id      asha_cube_projects.proj_id%type)
  is
    l_sess     asha_cube_sess%rowtype;
  begin
    select * into l_sess from asha_cube_sess where sess_id=p_sess_id;

    if l_sess.sess_status not in (ASHA_CUBE_PKG.stREADY) then raise_application_error(-20000,'Inapropriate status for cube: '||l_sess.sess_status); end if;
    update asha_cube_sess set sess_proj_id=p_new_proj_id where sess_id=p_sess_id;
    for i in (select report_id from asha_cube_reports where nvl(sess_id,-1) = p_sess_id) loop
      move_report(i.report_id,p_new_proj_id);
    end loop;
  end;

  procedure move_report(p_report_id      asha_cube_reports.report_id%type,
                        p_new_proj_id    asha_cube_projects.proj_id%type)
  is
    l_repo     asha_cube_reports%rowtype;
    l_sess     asha_cube_sess%rowtype;
  begin
    select * into l_repo from asha_cube_reports where report_id=p_report_id for update;

    if l_repo.sess_id is not null then
      select * into l_sess from asha_cube_sess where sess_id=l_repo.sess_id;
      if l_sess.sess_proj_id <> p_new_proj_id then raise_application_error(-20000,'Report project must match cube project (cube:report): '||l_sess.sess_proj_id ||':'|| p_new_proj_id); end if;
    end if;

    update asha_cube_reports set proj_id=p_new_proj_id where report_id=p_report_id;
  end;

end ASHA_PROJ_API;
/
