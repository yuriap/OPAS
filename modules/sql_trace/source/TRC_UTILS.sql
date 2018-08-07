create or replace PACKAGE TRC_UTILS AS

  --Files statuses
  fsNew         constant varchar2(10) := 'NEW';
  fsBeingParsed constant varchar2(10) := 'PARSING';
  fsParsed      constant varchar2(10) := 'PARSED';

  procedure create_project(p_proj_name   trc_projects.proj_name%type,
                           p_owner       trc_projects.owner%type,
                           p_description trc_projects.description%type,
                           p_trcproj_id  out trc_projects.trcproj_id%type);
  procedure edit_project(p_proj_name   trc_projects.proj_name%type,
                         p_description trc_projects.description%type,
                         p_trcproj_id  trc_projects.trcproj_id%type);
  procedure drop_project(p_trcproj_id  trc_projects.trcproj_id%type);

  procedure set_project_visibility (p_trcproj_id  trc_projects.trcproj_id%type, p_is_public boolean);
  procedure set_project_retention  (p_trcproj_id  trc_projects.trcproj_id%type, p_retention trc_projects.retention%type);
  procedure set_project_owner      (p_trcproj_id  trc_projects.trcproj_id%type, p_owner     trc_projects.owner%type);

  procedure register_trace_file(p_trcproj_id TRC_FILE.trcproj_id%type,
                                p_owner TRC_FILE.owner%type,
                                p_filename TRC_FILE.filename%type,
                                p_db_source TRC_FILE_SOURCE.file_db_source%type,
                                p_file_content TRC_FILE_SOURCE.file_content%type,
                                p_trc_file_id out TRC_FILE.trc_file_id%type);

  procedure store_file(p_trc_file_id TRC_FILE.trc_file_id%type, p_file blob default null);

  procedure delete_file(p_trc_file_id TRC_FILE.trc_file_id%type, p_keep_file boolean default false, p_keep_parsed boolean default false);

  procedure set_note(p_trcproj_id  trc_projects.trcproj_id%type,
                     p_trc_file_id TRC_FILE.trc_file_id%type,
                     p_note clob);

  procedure purge_trc_projects;

  procedure get_file(p_trc_file_id TRC_FILE.trc_file_id%type,p_trc_file out TRC_FILE%rowtype,p_trc_file_source out TRC_FILE_SOURCE%rowtype, p_lock boolean default false);
  procedure get_file(p_trc_file_id TRC_FILE.trc_file_id%type,p_trc_file out TRC_FILE%rowtype, p_lock boolean default false);

END TRC_UTILS;
/

--------------------------------------------------------
show errors
--------------------------------------------------------

create or replace PACKAGE BODY TRC_UTILS AS

  procedure get_file(p_trc_file_id TRC_FILE.trc_file_id%type,p_trc_file out TRC_FILE%rowtype,p_trc_file_source out TRC_FILE_SOURCE%rowtype, p_lock boolean default false)
  is
    exResourceBusy exception;
    pragma exception_init(exResourceBusy,-54);
  begin
    if p_lock then
      select * into p_trc_file from TRC_FILE where trc_file_id = p_trc_file_id for update nowait;
      select * into p_trc_file_source from TRC_FILE_SOURCE where trc_file_id = p_trc_file_id for update nowait;
    else
      select * into p_trc_file from TRC_FILE where trc_file_id = p_trc_file_id;
      select * into p_trc_file_source from TRC_FILE_SOURCE where trc_file_id = p_trc_file_id;
    end if;
  exception
    when no_data_found then raise_application_error(-20000, 'File ID:'||p_trc_file_id||' not found');
    when exResourceBusy then raise_application_error(-20000, 'File ID:'||p_trc_file_id||' is being processed now.');
  end;

  procedure get_file(p_trc_file_id TRC_FILE.trc_file_id%type,p_trc_file out TRC_FILE%rowtype, p_lock boolean default false)
  is
    l_trc_file_source  TRC_FILE_SOURCE%rowtype;  
  begin
    get_file(p_trc_file_id,p_trc_file,l_trc_file_source,p_lock);
  end;
  
  procedure store_file(p_trc_file_id TRC_FILE.trc_file_id%type, p_file blob default null)
  is
    l_trc_file TRC_FILE%rowtype;
    l_trc_file_source TRC_FILE_SOURCE%rowtype;

    l_file opas_files.file_id%type;
    l_file_content clob;

    crsr sys_refcursor;
    l_line varchar2(4000);

    l_doff number := 1;
    l_soff number := 1;
    l_cont integer := DBMS_LOB.DEFAULT_LANG_CTX;
    l_warn integer;
  begin
    get_file(p_trc_file_id,l_trc_file,l_trc_file_source,true);
    if l_trc_file.filename is not null then
      l_file := COREFILE_API.create_file(P_MODNAME => 'SQL_TRACE',
                                         P_FILE_TYPE => 'Extended SQL Trace',
                                         P_FILE_NAME => l_trc_file.filename,
                                         P_MIMETYPE => 'TXT',
                                         P_OWNER => l_trc_file.OWNER);
      COREFILE_API.get_locator(l_file,l_file_content);
      if p_file is null then
        if l_trc_file_source.file_db_source = '$LOCAL$' then
          for i in ( select payload from V$DIAG_TRACE_FILE_CONTENTS where trace_filename=l_trc_file.filename  order by line_number) loop
            l_file_content:=l_file_content||i.payload;
          end loop;
        elsif l_trc_file_source.file_db_source != '$LOCAL$' then
          open crsr for 'select payload from V$DIAG_TRACE_FILE_CONTENTS@'||l_trc_file_source.file_db_source||' where trace_filename=:p1 order by line_number' using l_trc_file.filename;
          loop
            fetch crsr into l_line;
            exit when crsr%notfound;
            l_file_content:=l_file_content||l_line;
          end loop;
        end if;
      else
        DBMS_LOB.CONVERTTOCLOB(
          dest_lob       => l_file_content,
          src_blob       => p_file,
          amount         => DBMS_LOB.LOBMAXSIZE,
          dest_offset    => l_doff,
          src_offset     => l_soff,
          blob_csid      => DBMS_LOB.DEFAULT_CSID,
          lang_context   => l_cont,
          warning        => l_warn);
      end if;
      COREFILE_API.store_content(l_file,l_file_content);
      UPDATE trc_file_source
         SET file_content = l_file
       WHERE trc_file_id = p_trc_file_id
         AND trcproj_id = l_trc_file.trcproj_id;
    end if;
  end;

  procedure create_project(p_proj_name   trc_projects.proj_name%type,
                           p_owner       trc_projects.owner%type,
                           p_description trc_projects.description%type,
                           p_trcproj_id  out trc_projects.trcproj_id%type)
  is
  begin
    INSERT INTO trc_projects (owner,created,status,description,retention,proj_name,is_public)
                      VALUES (p_owner, default, default, p_description, default,p_proj_name,default) returning trcproj_id into p_trcproj_id;
  end;

  procedure set_project_retention  (p_trcproj_id  trc_projects.trcproj_id%type, p_retention trc_projects.retention%type)
  is
    l_cnt number;
  begin
    if p_retention is null then raise_application_error(-20000,'Retention must be specified'); end if;
    select count(1) into l_cnt from trc_dic_retention where ret_code = p_retention;
    if l_cnt = 0 then raise_application_error(-20000,'Invalid retention specified'); end if;

    update trc_projects set
      retention=p_retention
    where trcproj_id = p_trcproj_id;
  end;

  procedure set_project_visibility (p_trcproj_id  trc_projects.trcproj_id%type, p_is_public boolean)
  is
    l_is_public trc_projects.is_public%type;
  begin
    l_is_public:=case when p_is_public then 'Y' else 'N' end;
    update trc_projects set
      is_public=l_is_public
    where trcproj_id = p_trcproj_id and owner<>'PUBLIC';
  end;

  procedure set_project_owner      (p_trcproj_id  trc_projects.trcproj_id%type, p_owner     trc_projects.owner%type)
  is
  begin
    update trc_projects set
      owner=p_owner
    where trcproj_id = p_trcproj_id;
  end;
  procedure edit_project(p_proj_name   trc_projects.proj_name%type,
                         p_description trc_projects.description%type,
                         p_trcproj_id  trc_projects.trcproj_id%type)
  is
  begin
    update trc_projects set
      proj_name=p_proj_name,
      description=p_description
    where trcproj_id = p_trcproj_id;
  end;

  procedure drop_project(p_trcproj_id  trc_projects.trcproj_id%type)
  is
    l_proj trc_projects%rowtype;
  begin
    select * into l_proj from trc_projects where trcproj_id=p_trcproj_id;
    if l_proj.owner = 'PUBLIC' or l_proj.owner = V('APP_USER') then
      for i in (select file_content, trc_file_id from trc_file_source where trcproj_id=p_trcproj_id) loop
        update trc_file_source set file_content=null where trc_file_id=i.trc_file_id;
        COREFILE_API.delete_file(i.file_content);
      end loop;
      delete from trc_projects where trcproj_id = p_trcproj_id;
    else
      raise_application_error(-20000,'A user '||V('APP_USER')||'can not delete this project owned by '||l_proj.owner);
    end if;
  end;

  procedure register_trace_file(p_trcproj_id TRC_FILE.trcproj_id%type,
                                p_owner TRC_FILE.owner%type,
                                p_filename TRC_FILE.filename%type,
                                p_db_source TRC_FILE_SOURCE.file_db_source%type,
                                p_file_content TRC_FILE_SOURCE.file_content%type,
                                p_trc_file_id out TRC_FILE.trc_file_id%type)
  is
    l_db_source TRC_FILE_SOURCE.file_db_source%type;
  begin
    INSERT INTO trc_file (trcproj_id, filename, owner, created, status) VALUES (p_trcproj_id,p_filename, nvl(p_owner,COREMOD_API.gDefaultOwner), default, fsNew) returning trc_file_id into p_trc_file_id;
    if nvl(p_db_source,'$LOCAL$') = '$LOCAL$' then
      l_db_source := p_db_source;
    else
      select DB_LINK_NAME into l_db_source from v$opas_db_links where ORA_DB_LINK=p_db_source;
    end if;
    INSERT INTO trc_file_source (trcproj_id, trc_file_id, file_db_source, file_content ) VALUES (p_trcproj_id, p_trc_file_id, l_db_source, p_file_content);
  end;

  procedure delete_file(p_trc_file_id TRC_FILE.trc_file_id%type, p_keep_file boolean default false, p_keep_parsed boolean default false)
  is
--    l_file_id trc_file_source.file_content%type;
--    l_file_status TRC_FILE.status%type;
    
    l_trc_file         TRC_FILE%rowtype;
    l_trc_file_source  TRC_FILE_SOURCE%rowtype;    
  begin
    if p_keep_file and p_keep_parsed then
      raise_application_error(-20000,'Invalid input for delete_file.');
    end if;

    get_file(p_trc_file_id,l_trc_file,l_trc_file_source,true);
--    begin
--      select file_content into l_file_id from trc_file_source where trc_file_id=p_trc_file_id;
--    exception
--      when no_data_found then l_file_id:= null;
--    end;
--    select status into l_file_status from trc_file where trc_file_id=p_trc_file_id;

    if not p_keep_file and l_trc_file_source.file_content is not null then
      update trc_file_source set file_content=null where trc_file_id=p_trc_file_id;
      COREFILE_API.delete_file(l_trc_file_source.file_content);
    end if;

    --delete file anyway
    if (l_trc_file.status=fsNew and not p_keep_file) or
       (not p_keep_parsed and not p_keep_file) or
       (not p_keep_parsed and l_trc_file_source.file_content is null)
    then
      delete trc_file_source where trc_file_id=p_trc_file_id;
      delete from trc_file where trc_file_id=p_trc_file_id;
    end if;

    if not p_keep_parsed then
      update trc_file set status=fsNew where trc_file_id=p_trc_file_id;
      delete from trc_stat where trc_file_id=p_trc_file_id;
      delete from trc_wait where trc_file_id=p_trc_file_id;
      delete from trc_binds where trc_file_id=p_trc_file_id;
      delete from trc_call where trc_file_id=p_trc_file_id;
      delete from trc_statement where trc_file_id=p_trc_file_id;
      delete from trc_client_identity where trc_file_id=p_trc_file_id;
      delete from trc_trans where trc_file_id=p_trc_file_id;
      delete from trc_session where trc_file_id=p_trc_file_id;
    end if;
  end;

  procedure purge_trc_projects is
    l_trc_file TRC_FILE%rowtype;
    l_trc_file_source TRC_FILE_SOURCE%rowtype;
  begin
    for p in (select * from trc_projects where retention = 'DEFAULT' and systimestamp - created > TO_DSINTERVAL(COREMOD_API.getconf('TRACEPROJRETENTION')||' 00:00:00'))
    loop
      drop_project(p.TRCPROJ_ID);
    end loop;
    for p in (select * from trc_projects where retention = 'KEEPFILESONLY')
    loop
      for i in (select trc_file_id from trc_file x where x.TRCPROJ_ID=p.TRCPROJ_ID and systimestamp - created > TO_DSINTERVAL(COREMOD_API.getconf('TRACEFILERETENTION')||' 00:00:00')) loop
        delete_file(i.trc_file_id, p_keep_file => true);
      end loop;
    end loop;
    for p in (select * from trc_projects where retention = 'KEEPPARSEDONLY')
    loop
      for i in (select trc_file_id from trc_file x where x.TRCPROJ_ID=p.TRCPROJ_ID and systimestamp - created > TO_DSINTERVAL(COREMOD_API.getconf('TRACEFILERETENTION')||' 00:00:00')) loop
        delete_file(i.trc_file_id, p_keep_parsed => true);
      end loop;
    end loop;
    for p in (select * from trc_projects where retention = 'CLEANUPOLD')
    loop
      for i in (select trc_file_id from trc_file x where x.TRCPROJ_ID=p.TRCPROJ_ID and systimestamp - created > TO_DSINTERVAL(COREMOD_API.getconf('TRACEFILERETENTION')||' 00:00:00')) loop
        delete_file(i.trc_file_id);
      end loop;
    end loop;
    commit;
  end;

  procedure set_note(p_trcproj_id  trc_projects.trcproj_id%type,
                     p_trc_file_id TRC_FILE.trc_file_id%type,
                     p_note clob)
  is
  begin
    if p_trc_file_id is null then --project note
      merge into trc_notes t using (select p_trcproj_id trcproj_id, p_note note from dual)s
      on (t.trcproj_id=s.trcproj_id and t.trc_file_id is null)
      when matched then update set t.note = s.note
      when not matched then insert (t.trcproj_id,t.trc_file_id,t.note) values (s.trcproj_id,null,s.note);
    elsif p_trcproj_id is not null and p_trc_file_id is not null then
      merge into trc_notes t using (select p_trcproj_id trcproj_id, p_trc_file_id trc_file_id, p_note note from dual)s
      on (t.trcproj_id=s.trcproj_id and t.trc_file_id=s.trc_file_id)
      when matched then update set t.note = s.note
      when not matched then insert (t.trcproj_id,t.trc_file_id,t.note) values (s.trcproj_id,s.trc_file_id,s.note);
    else
      raise_application_error(-20000,'Invalid input for set_note.');
    end if;
  end;

END TRC_UTILS;
/

--------------------------------------------------------
show errors
--------------------------------------------------------