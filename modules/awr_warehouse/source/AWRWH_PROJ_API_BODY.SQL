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

    set_proj_dblinks (p_proj_id       => l_curproj.proj_id,
                      p_db_links_list => '$LOCAL$');

    AWRWH_PROJ_LCC.project_exec_action(l_curproj,AWRWH_PROJ_LCC.c_project_create);
  end create_project;

  procedure edit_project  (p_proj_id      awrwh_projects.proj_id%type,
                           p_proj_name    awrwh_projects.proj_name%type,
                           p_priority     awrwh_projects.priority%type) as
    l_curproj awrwh_projects%rowtype;
  begin
    l_curproj:=getproject(p_proj_id, true);
    AWRWH_PROJ_LCC.project_exec_action(l_curproj,AWRWH_PROJ_LCC.c_project_edit);

    UPDATE awrwh_projects
       SET
           proj_name = p_proj_name,
           priority  = p_priority
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
    if p_use_retention and p_mode in (c_ALL, c_SOURCEDATA, c_PARSEDDATA) then

      for i in (select dump_id, loaded,parsed, source_retention, parsed_retention,status from awrwh_dumps where proj_id=p_proj_id) loop
        if p_mode in (c_ALL, c_SOURCEDATA) then
          if nvl(i.source_retention,-1) <> 0 and (i.loaded+nvl(i.source_retention,COREMOD_API.getconf('DUMPETENTION',AWRWH_API.gMODNAME)))<sysdate then
            AWRWH_FILE_LCC.dmpfile_exec_action(i.dump_id,AWRWH_FILE_LCC.c_dmpfile_putinqueue);
            commit;
            AWRWH_FILE_API.exec_file_action(i.dump_id,AWRWH_FILE_LCC.c_dmpfile_compress,i.status);
            commit;
            coremod_log.log('Dump file removed: '||i.dump_id);
          end if;
        end if;

        if p_mode in (c_ALL, c_PARSEDDATA) then
          if nvl(i.parsed_retention,-1) <> 0 and (i.parsed+nvl(i.parsed_retention,COREMOD_API.getconf('AWRPARSEDRETENTION',AWRWH_API.gMODNAME)))<sysdate then
            AWRWH_FILE_LCC.dmpfile_exec_action(i.dump_id,AWRWH_FILE_LCC.c_dmpfile_putinqueue);
            commit;
            AWRWH_FILE_API.exec_file_action(i.dump_id,AWRWH_FILE_LCC.c_dmpfile_awrunload,i.status);
            commit;
            coremod_log.log('AWR data removed: '||i.dump_id);
          end if;
        end if;

      end loop;

      if p_mode in (c_ALL, c_REPORTS) then
        for i in (select report_id,created,report_retention from awrwh_reports where proj_id=p_proj_id) loop
          if nvl(i.report_retention,-1) <> 0 and (i.created+nvl(i.report_retention,COREMOD_API.getconf('REPORTRETENTION',AWRWH_API.gMODNAME)))<sysdate then
            AWRWH_REPORT_API.delete_report(p_proj_id,i.report_id);
            commit;
            coremod_log.log('Report removed: '||i.report_id);
          end if;
        end loop;
      end if;

    elsif not p_use_retention then

      for i in (select dump_id, loaded,parsed, source_retention, parsed_retention,status from awrwh_dumps where proj_id=p_proj_id) loop
        if p_mode in (c_ALL, c_SOURCEDATA) then
          AWRWH_FILE_LCC.dmpfile_exec_action(i.dump_id,AWRWH_FILE_LCC.c_dmpfile_putinqueue);
          commit;
          AWRWH_FILE_API.exec_file_action(i.dump_id,AWRWH_FILE_LCC.c_dmpfile_compress,i.status);
          commit;
          coremod_log.log('Dump file removed: '||i.dump_id);
        end if;

        if p_mode in (c_ALL, c_PARSEDDATA) then
          AWRWH_FILE_LCC.dmpfile_exec_action(i.dump_id,AWRWH_FILE_LCC.c_dmpfile_putinqueue);
          commit;
          AWRWH_FILE_API.exec_file_action(i.dump_id,AWRWH_FILE_LCC.c_dmpfile_archive,i.status);
          commit;
          coremod_log.log('AWR data removed: '||i.dump_id);
        end if;
      end loop;
      if p_mode in (c_ALL, c_REPORTS) then
        for i in (select report_id,created,report_retention from awrwh_reports where proj_id=p_proj_id) loop
          AWRWH_REPORT_API.delete_report(p_proj_id,i.report_id);
          commit;
          coremod_log.log('Report removed: '||i.report_id);
        end loop;
      end if;
    end if;

  end cleanup_project;


  procedure drop_project_i(p_proj_id awrwh_projects.proj_id%type, p_is_purge boolean default false) as
    l_curproj awrwh_projects%rowtype;
  begin
    l_curproj:=getproject(p_proj_id, true);

	if not p_is_purge then
      AWRWH_PROJ_LCC.project_exec_action(l_curproj,AWRWH_PROJ_LCC.c_project_drop);
	end if;

    cleanup_project(p_proj_id=>p_proj_id, p_mode => c_ALL, p_use_retention => false);

    COREMOD_INTEGRATION.remove_integration
    (  p_int_key => AWRWH_API.gintAWRWH2ASH_DUMP2CUBE,
       p_modname => AWRWH_API.gMODNAME,
       P_PRNT_ENTITY_ID => p_proj_id,
       P_ENTITY_ID => null) ;

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

    for p in (select proj_id, proj_name, systimestamp - created duration, nvl(keep_forever,'N') keep_forever from awrwh_projects) loop
	  if p.keep_forever='N' and p.duration > TO_DSINTERVAL(nvl(COREMOD_API.getconf('PROJECTRETENTION',AWRWH_API.gMODNAME),8)||' 00:00:00') then
        begin
          drop_project_i(p_proj_id=>p.proj_id, p_is_purge => true);
          coremod_log.log('AWRWH Project removed: '||p.proj_id||' : '||p.proj_name);
        exception
          when others then
            coremod_log.log('Removing AWRWH project '||p.proj_id||' error: '||sqlerrm);
            coremod_log.log(DBMS_UTILITY.FORMAT_ERROR_STACK);
            coremod_log.log(DBMS_UTILITY.FORMAT_ERROR_BACKTRACE);
        end;
      else
        begin
          cleanup_project(p_proj_id=>p.proj_id, p_mode => c_ALL, p_use_retention => true);
		  coremod_log.log('AWRWH Project cleaned: '||p.proj_id||' : '||p.proj_name);
        exception
          when others then
            coremod_log.log('Cleanup AWRWH project '||p.proj_id||' components error: '||sqlerrm);
            coremod_log.log(DBMS_UTILITY.FORMAT_ERROR_STACK);
            coremod_log.log(DBMS_UTILITY.FORMAT_ERROR_BACKTRACE);
        end;
	  end if;
	end loop;
    commit;

    begin
      COREMOD_EXPIMP.cleanup_expimp_sess(AWRWH_API.gMODNAME, COREMOD_API.getconf(P_KEY => 'EXPIMPSESS',P_MODULE => AWRWH_API.gMODNAME));
      coremod_log.log('AWRWH Exp/Imp sessions cleaned');
    exception
      when others then
        coremod_log.log('AWRWH Exp/Imp sessions components error: '||sqlerrm);
        coremod_log.log(DBMS_UTILITY.FORMAT_ERROR_STACK);
        coremod_log.log(DBMS_UTILITY.FORMAT_ERROR_BACKTRACE);
    end;
    commit;

    AWRWH_REPORT_API.gather_recursive_reports();
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

  procedure set_proj_def_dblink (p_proj_id       awrwh_projects.proj_id%type,
                                  p_db_link       awrwh_srcdblink2projects.src_dblink%type)
  is
  begin
    update awrwh_srcdblink2projects set default_dblink = decode(src_dblink,p_db_link,'Y',null) where proj_id = p_proj_id;
  end;

  function  get_proj_def_dblink (p_proj_id       awrwh_projects.proj_id%type) return awrwh_srcdblink2projects.src_dblink%type
  is
    l_default_dblink awrwh_srcdblink2projects.src_dblink%type;
  begin
    select src_dblink into l_default_dblink from awrwh_srcdblink2projects where default_dblink='Y' and proj_id=p_proj_id;
    return l_default_dblink;
    exception when others then return null;
  end;

  procedure set_proj_dblinks (p_proj_id       awrwh_projects.proj_id%type,
                              p_db_links_list varchar2)
  is
    l_tbl DBMS_UTILITY.LNAME_ARRAY;
    l_n   number;
    l_default_dblink awrwh_srcdblink2projects.src_dblink%type;
  begin
    DBMS_UTILITY.COMMA_TO_TABLE (
      list   => replace(replace(p_db_links_list,':',','),'$LOCAL$','LOCAL$$'),
      tablen => l_n,
      tab    => l_tbl);

    l_default_dblink := get_proj_def_dblink(p_proj_id);
    delete from awrwh_srcdblink2projects where proj_id=p_proj_id;

    for i in 1..l_n loop
      --coremod_log.log(i||':'||l_tbl(i));
      insert into awrwh_srcdblink2projects (proj_id,src_dblink,default_dblink) values(p_proj_id,replace(l_tbl(i),'LOCAL$$','$LOCAL$'),decode(l_tbl(i),l_default_dblink,'Y',null));
    end loop;
  end;

  -- move data between projects
  procedure move_dump(p_dump_id          awrwh_dumps.dump_id%type,
                      p_new_proj_id      awrwh_projects.proj_id%type)
  is
    l_dmp_file awrwh_dumps%rowtype;
  begin
    l_dmp_file:=AWRWH_FILE_API.get_file(p_dump_id,true);
    if l_dmp_file.status not in (AWRWH_FILE_LCC.c_dmpfilestate_new,
                                 AWRWH_FILE_LCC.c_dmpfilestate_dmploaded,
                                 AWRWH_FILE_LCC.c_dmpfilestate_awrloaded,
                                 AWRWH_FILE_LCC.c_dmpfilestate_compressed,
                                 AWRWH_FILE_LCC.c_dmpfilestate_archived)
    then raise_application_error(-20000,'Inapropriate status for file: '||l_dmp_file.status); end if;
    update awrwh_dumps set proj_id=p_new_proj_id where dump_id=p_dump_id;
    for i in (select report_id from awrwh_reports where nvl(dump_id,-1) = p_dump_id or nvl(dump_id_2,-1)=p_dump_id) loop
      move_report(i.report_id,p_new_proj_id);
    end loop;
  end;

  procedure move_report(p_report_id      awrwh_reports.report_id%type,
                        p_new_proj_id    awrwh_projects.proj_id%type)
  is
    l_repo    awrwh_reports%rowtype;
    l_dmp_file awrwh_dumps%rowtype;
  begin
    select * into l_repo from awrwh_reports where report_id=p_report_id for update;

    if l_repo.dump_id is not null then
      l_dmp_file:=AWRWH_FILE_API.get_file(l_repo.dump_id,false);
      if l_dmp_file.proj_id <> p_new_proj_id then raise_application_error(-20000,'Report project must match dump project (dump:report): '||l_dmp_file.proj_id ||':'|| p_new_proj_id); end if;
    end if;

    if l_repo.dump_id_2 is not null then
      l_dmp_file:=AWRWH_FILE_API.get_file(l_repo.dump_id_2,false);
      if l_dmp_file.proj_id <> p_new_proj_id then raise_application_error(-20000,'Report project must match dump project (dump:report): '||l_dmp_file.proj_id ||':'|| p_new_proj_id); end if;
    end if;

    update awrwh_reports set proj_id=p_new_proj_id where report_id=p_report_id;
  end;

end AWRWH_PROJ_API;
/
