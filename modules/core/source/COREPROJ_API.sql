create or replace package COREPROJ_API as

  -- cleanup project modes
  c_SOURCEDATA   constant varchar2(10) := 'SOURCEDATA';
  c_PARSEDDATA   constant varchar2(10) := 'PARSEDDATA';

   --project
  procedure create_project(p_modname     opas_projects.modname%type,
                           p_proj_name   opas_projects.proj_name%type,
                           p_proj_type   opas_projects.proj_type%type,
                           p_owner       opas_projects.owner%type,
                           p_description opas_projects.description%type,
                           p_retention   opas_projects.retention%type default 'DEFAULT',
                           p_is_public   opas_projects.is_public%type default 'Y',
                           p_proj_id out opas_projects.proj_id%type);
  procedure edit_project(p_proj_id     opas_projects.proj_id%type,
                         p_proj_name   opas_projects.proj_name%type,
                         p_description opas_projects.description%type);
  procedure set_project_security
                        (p_proj_id     opas_projects.proj_id%type,
                         p_owner       opas_projects.owner%type,                        
                         p_retention   opas_projects.retention%type,
                         p_is_public   opas_projects.is_public%type);                         
  procedure set_project_crdt(p_proj_id opas_projects.proj_id%type,
                             p_created   opas_projects.created%type);
  procedure drop_project(p_proj_id opas_projects.PROJ_ID%type);
  procedure load_project(p_proj_id opas_projects.PROJ_ID%type);
  procedure parse_project(p_proj_id opas_projects.PROJ_ID%type);
  procedure report_cr(p_proj_id opas_projects.PROJ_ID%type);
  procedure report_vw(p_proj_id opas_projects.PROJ_ID%type);
  
  procedure lock_project(p_proj_id opas_projects.PROJ_ID%type);
  procedure unlock_project(p_proj_id opas_projects.PROJ_ID%type);

  procedure compress_project(p_proj_id opas_projects.proj_id%type);  --remove source data
  procedure archive_project(p_proj_id opas_projects.PROJ_ID%type);   --remove source and parsed data
  procedure close_project(p_proj_id opas_projects.PROJ_ID%type);     --eligible for cleaning up whatever keep policy
  
       
  -----------------------------------------------------------------
  procedure cleanup_project(p_proj_id opas_projects.proj_id%type, p_mode varchar2, p_is_purge boolean default false);
  procedure cleanup_projects;
  procedure cleanup_project_source_data(p_proj_id     opas_projects.proj_id%type,
                                        p_is_purge    varchar2 default 'N');
  procedure cleanup_project_parsed_data(p_proj_id     opas_projects.proj_id%type,
                                        p_is_purge    varchar2 default 'N');
  -----------------------------------------------------------------
  function getproject(p_proj_id opas_projects.PROJ_ID%type, p_for_update boolean default false) return opas_projects%rowtype;
  
  procedure set_note(p_note_id      in out opas_notes.note_id%type,
                     p_proj_id      opas_notes.proj_id%type,
                     p_is_proj_note opas_notes.is_proj_note%type,
                     p_note         opas_notes.note%type);

end COREPROJ_API;
/
--------------------------------------------------------
show errors
--------------------------------------------------------

create or replace package body COREPROJ_API as

  function getproject(p_proj_id opas_projects.PROJ_ID%type, p_for_update boolean default false) return opas_projects%rowtype
  is
    l_curproj opas_projects%rowtype;
  begin
    if nvl(p_for_update,false) then
      select * into l_curproj from opas_projects where proj_id=p_proj_id for update nowait;
    else
      select * into l_curproj from opas_projects where proj_id=p_proj_id;
    end if;
    return l_curproj;
  end;


  procedure create_project(p_modname     opas_projects.modname%type,
                           p_proj_name   opas_projects.proj_name%type,
                           p_proj_type   opas_projects.proj_type%type,
                           p_owner       opas_projects.owner%type,
                           p_description opas_projects.description%type,
                           p_retention   opas_projects.retention%type default 'DEFAULT',
                           p_is_public   opas_projects.is_public%type default 'Y',
                           p_proj_id out opas_projects.proj_id%type) as
    l_curproj opas_projects%rowtype;
  begin
    INSERT INTO opas_projects ( modname, proj_name, proj_type, owner, description, retention, is_public )
                       VALUES ( p_modname, p_proj_name, p_proj_type, p_owner, p_description, p_retention, p_is_public)
    returning proj_id, status into l_curproj.proj_id, l_curproj.status;
    p_proj_id:=l_curproj.proj_id;

    COREPROJ_LCC.project_exec_action(l_curproj,COREPROJ_LCC.c_project_create);
  end create_project;

  procedure edit_project(p_proj_id     opas_projects.proj_id%type,
                         p_proj_name   opas_projects.proj_name%type,
                         p_description opas_projects.description%type) as
    l_curproj opas_projects%rowtype;
  begin
    l_curproj:=getproject(p_proj_id, true);
    COREPROJ_LCC.project_exec_action(l_curproj,COREPROJ_LCC.c_project_edit);

    UPDATE opas_projects
       SET
           proj_name = p_proj_name,
           description = p_description
     WHERE proj_id = p_proj_id;

  end edit_project;

  procedure set_project_security
                        (p_proj_id     opas_projects.proj_id%type,
                         p_owner       opas_projects.owner%type,
                         p_retention   opas_projects.retention%type,
                         p_is_public   opas_projects.is_public%type) as
    l_curproj opas_projects%rowtype;
  begin
    l_curproj:=getproject(p_proj_id, true);
    COREPROJ_LCC.project_exec_action(l_curproj,COREPROJ_LCC.c_project_edit);

    UPDATE opas_projects
       SET
           owner = p_owner,
           retention = p_retention,
           is_public = case when p_owner = 'PUBLIC' then 'Y' else p_is_public end
     WHERE proj_id = p_proj_id;

  end set_project_security;

  procedure set_project_crdt(p_proj_id opas_projects.proj_id%type,
                             p_created   opas_projects.created%type) as
    l_curproj opas_projects%rowtype;
  begin
    l_curproj:=getproject(p_proj_id, true);
    UPDATE opas_projects
       SET
           created =p_created
     WHERE proj_id =p_proj_id;
  end set_project_crdt;

  procedure cleanup_project(p_proj_id opas_projects.proj_id%type, p_mode varchar2, p_is_purge boolean default false) as
    l_curproj opas_projects%rowtype;
    l_errmsg  varchar2(1000);
    l_cmd     varchar2(1000);
  begin
    l_curproj:=getproject(p_proj_id, true);

    for i in (select * from opas_project_cleanup where cleanup_mode = upper(p_mode) and  modname=l_curproj.modname order by ordr) loop
      begin
        l_cmd:='begin '||i.cleanup_prc||'('||p_proj_id||case when p_is_purge then q'[,'Y']' else null end||'); end;';
        execute immediate l_cmd using p_proj_id;
      exception
        when others then
          l_errmsg := 'The cleanup procedure "'||i.cleanup_prc||'" of module "'||l_curproj.modname||'" for mode "'||p_mode||'" failed for proj_id='||p_proj_id||', see log for details.';
          coremod_log.log(l_errmsg);
          coremod_log.log(l_cmd);
          coremod_log.log(sqlerrm);
          raise_application_error(-20000,l_errmsg);
      end;
    end loop;
  end cleanup_project;

  procedure cleanup_project_source_data(p_proj_id     opas_projects.proj_id%type,
                                        p_is_purge    varchar2 default 'N')
  is
  begin
    coremod_log.log('Default cleanup_project_source_data procedure executed');
  end;

  procedure cleanup_project_parsed_data(p_proj_id     opas_projects.proj_id%type,
                                        p_is_purge    varchar2 default 'N')
  is
  begin
    coremod_log.log('Default cleanup_project_parsed_data procedure executed');
  end;


  procedure drop_project(p_proj_id opas_projects.proj_id%type) as
    l_curproj opas_projects%rowtype;
  begin
    l_curproj:=getproject(p_proj_id, true);

    COREPROJ_LCC.project_exec_action(l_curproj,COREPROJ_LCC.c_project_drop);

    cleanup_project(p_proj_id,c_SOURCEDATA);
    cleanup_project(p_proj_id,c_PARSEDDATA);

    delete from opas_projects where proj_id=p_proj_id;
  end drop_project;

  procedure load_project(p_proj_id opas_projects.PROJ_ID%type)is
    l_curproj opas_projects%rowtype;
  begin
    l_curproj:=getproject(p_proj_id, false);
    COREPROJ_LCC.project_exec_action(l_curproj,COREPROJ_LCC.c_project_load);
  end;

  procedure parse_project(p_proj_id opas_projects.PROJ_ID%type)is
    l_curproj opas_projects%rowtype;
  begin
    l_curproj:=getproject(p_proj_id, false);
    COREPROJ_LCC.project_exec_action(l_curproj,COREPROJ_LCC.c_project_parse);
  end;

  procedure report_cr(p_proj_id opas_projects.PROJ_ID%type)is
    l_curproj opas_projects%rowtype;
  begin
    l_curproj:=getproject(p_proj_id, false);
    COREPROJ_LCC.project_exec_action(l_curproj,COREPROJ_LCC.c_project_report_cr);
  end;

  procedure report_vw(p_proj_id opas_projects.PROJ_ID%type)is
    l_curproj opas_projects%rowtype;
  begin
    l_curproj:=getproject(p_proj_id, false);
    COREPROJ_LCC.project_exec_action(l_curproj,COREPROJ_LCC.c_project_report_vw);
  end;

  procedure lock_project(p_proj_id opas_projects.PROJ_ID%type)is
    l_curproj opas_projects%rowtype;
  begin
    l_curproj:=getproject(p_proj_id, true);
    COREPROJ_LCC.project_exec_action(l_curproj,COREPROJ_LCC.c_project_lock);
  end;

  procedure unlock_project(p_proj_id opas_projects.PROJ_ID%type)is
    l_curproj opas_projects%rowtype;
  begin
    l_curproj:=getproject(p_proj_id, true);
    COREPROJ_LCC.project_exec_action(l_curproj,COREPROJ_LCC.c_project_unlock);
  end;

  procedure close_project(p_proj_id opas_projects.PROJ_ID%type)is
    l_curproj opas_projects%rowtype;
  begin
    l_curproj:=getproject(p_proj_id, true);
    COREPROJ_LCC.project_exec_action(l_curproj,COREPROJ_LCC.c_project_close);
  end;

  procedure compress_project(p_proj_id opas_projects.proj_id%type) as
    l_curproj opas_projects%rowtype;
  begin
    l_curproj:=getproject(p_proj_id, true);
    COREPROJ_LCC.project_exec_action(l_curproj,COREPROJ_LCC.c_project_compress);
    cleanup_project(p_proj_id,c_SOURCEDATA);
  end;

  procedure archive_project(p_proj_id opas_projects.proj_id%type) as
    l_curproj opas_projects%rowtype;
  begin
    l_curproj:=getproject(p_proj_id, true);
    COREPROJ_LCC.project_exec_action(l_curproj,COREPROJ_LCC.c_project_archive);
    cleanup_project(p_proj_id,c_SOURCEDATA);
    cleanup_project(p_proj_id,c_PARSEDDATA);
  end;

  procedure cleanup_projects is
    l_curproj opas_projects%rowtype; --getproject
  begin
    for p in (select * from opas_projects where retention = 'DEFAULT' and systimestamp - created > TO_DSINTERVAL(COREMOD_API.getconf('PROJECTRETENTION',modname)||' 00:00:00'))
    loop
      begin
        drop_project(p.proj_id);
      exception
        when others then
          coremod_log.log('Cleanup project error (DEFAULT policy): '||sqlerrm);
          coremod_log.log(DBMS_UTILITY.FORMAT_ERROR_STACK);
          coremod_log.log(DBMS_UTILITY.FORMAT_ERROR_BACKTRACE);
      end;
    end loop;
    for p in (select * from opas_projects where retention = 'KEEPSOURCEDATAONLY')
    loop
      begin
        cleanup_project(p_proj_id=>p.proj_id, p_mode=>c_PARSEDDATA, p_is_purge=>true);
      exception
        when others then
          coremod_log.log('Cleanup project error (KEEPSOURCEDATAONLY policy): '||sqlerrm);
          coremod_log.log(DBMS_UTILITY.FORMAT_ERROR_STACK);
          coremod_log.log(DBMS_UTILITY.FORMAT_ERROR_BACKTRACE);
      end;
    end loop;
    for p in (select * from opas_projects where retention = 'KEEPPARSEDDATAONLY')
    loop
      begin
        cleanup_project(p_proj_id=>p.proj_id, p_mode=>c_SOURCEDATA, p_is_purge=>true);
      exception
        when others then
          coremod_log.log('Cleanup project error (KEEPPARSEDDATAONLY policy): '||sqlerrm);
          coremod_log.log(DBMS_UTILITY.FORMAT_ERROR_STACK);
          coremod_log.log(DBMS_UTILITY.FORMAT_ERROR_BACKTRACE);
      end;
    end loop;
    commit;
  end;

  procedure set_note(p_note_id      in out opas_notes.note_id%type,
                     p_proj_id      opas_notes.proj_id%type,
                     p_is_proj_note opas_notes.is_proj_note%type,
                     p_note         opas_notes.note%type)
  is
    l_curproj opas_projects%rowtype;
  begin
    --project note
    if p_proj_id is not null and p_is_proj_note = 'Y' then
      l_curproj:=getproject(p_proj_id, true);
      COREPROJ_LCC.project_exec_action(l_curproj,COREPROJ_LCC.c_project_edit);

      if p_note_id is null then
        begin
          select note_id into p_note_id from opas_notes where proj_id = p_proj_id and is_proj_note = 'Y';
        exception
          when no_data_found then
            insert into opas_notes (proj_id,is_proj_note,note) values (p_proj_id,p_is_proj_note,empty_clob()) returning note_id into p_note_id;
        end;
      end if;
      update opas_notes set note = p_note where note_id = p_note_id;
    end if;
    
    if p_is_proj_note = 'N' then
      if p_note_id is null then
        insert into opas_notes (proj_id,is_proj_note,note) values (p_proj_id,p_is_proj_note,empty_clob()) returning note_id into p_note_id;
      end if;
      update opas_notes set note = p_note where note_id = p_note_id;
    end if;
  end;

end COREPROJ_API;
/
--------------------------------------------------------
show errors
--------------------------------------------------------