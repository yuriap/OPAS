create or replace PACKAGE TRC_FILE_API AS

  procedure register_trace_file(p_proj_id TRC_FILE.proj_id%type,
                                p_owner TRC_FILE.owner%type,
                                p_filename TRC_FILE.filename%type,
                                p_db_source TRC_FILE.file_db_source%type,
                                p_file_content TRC_FILE.file_content%type,
                                p_trc_file_id out TRC_FILE.trc_file_id%type);

  procedure store_file(p_trc_file_id TRC_FILE.trc_file_id%type, p_file blob default null);

  procedure compress_file(p_trc_file_id TRC_FILE.trc_file_id%type);
  procedure archive_file(p_trc_file_id TRC_FILE.trc_file_id%type);
  procedure drop_file(p_trc_file_id TRC_FILE.trc_file_id%type);

  procedure cleanup_files(p_proj_id opas_projects.proj_id%type, p_is_drop boolean);
  
  procedure set_note(p_trc_file_id  TRC_FILE.trc_file_id%type,
                     p_note         opas_notes.note%type);

END TRC_FILE_API;
/

--------------------------------------------------------
show errors
--------------------------------------------------------

create or replace PACKAGE BODY TRC_FILE_API AS

  function get_file(p_trc_file_id TRC_FILE.trc_file_id%type, p_lock boolean default false) return TRC_FILE%rowtype
  is
    exResourceBusy exception;
    pragma exception_init(exResourceBusy,-54);
	l_trc_file TRC_FILE%rowtype;
  begin
    if p_lock then
      select * into l_trc_file from TRC_FILE where trc_file_id = p_trc_file_id for update nowait;
    else
      select * into l_trc_file from TRC_FILE where trc_file_id = p_trc_file_id;
    end if;
	
	return l_trc_file;
  exception
    when no_data_found then raise_application_error(-20000, 'File ID:'||p_trc_file_id||' not found');
    when exResourceBusy then raise_application_error(-20000, 'File ID:'||p_trc_file_id||' is being processed now.');
  end;

  procedure store_file(p_trc_file_id TRC_FILE.trc_file_id%type, p_file blob default null)
  is
    l_trc_file TRC_FILE%rowtype;

    l_file opas_files.file_id%type;
    l_file_content clob;

    crsr sys_refcursor;
    l_line varchar2(4000);

    l_doff number := 1;
    l_soff number := 1;
    l_cont integer := DBMS_LOB.DEFAULT_LANG_CTX;
    l_warn integer;
  begin
    l_trc_file:=get_file(p_trc_file_id,true);
    if l_trc_file.filename is not null then
      l_file := COREFILE_API.create_file(P_MODNAME => 'SQL_TRACE',
                                         P_FILE_TYPE => 'Extended SQL Trace',
                                         P_FILE_NAME => l_trc_file.filename,
                                         P_MIMETYPE => 'TXT',
                                         P_OWNER => l_trc_file.OWNER);
      COREFILE_API.get_locator(l_file,l_file_content);
      if p_file is null then
        if l_trc_file.file_db_source = '$LOCAL$' then
          for i in ( select payload from V$DIAG_TRACE_FILE_CONTENTS where trace_filename=l_trc_file.filename  order by line_number) loop
            l_file_content:=l_file_content||i.payload;
          end loop;
        elsif l_trc_file.file_db_source != '$LOCAL$' then
          open crsr for 'select payload from V$DIAG_TRACE_FILE_CONTENTS@'||l_trc_file.file_db_source||' where trace_filename=:p1 order by line_number' using l_trc_file.filename;
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
      UPDATE trc_file
         SET file_content = l_file
       WHERE trc_file_id = p_trc_file_id;
      
	  TRC_FILE_LCC.trcfile_exec_action(l_trc_file,TRC_FILE_LCC.c_trcfile_load);	   
    end if;
  end;

  procedure register_trace_file(p_proj_id TRC_FILE.proj_id%type,
                                p_owner TRC_FILE.owner%type,
                                p_filename TRC_FILE.filename%type,
                                p_db_source TRC_FILE.file_db_source%type,
                                p_file_content TRC_FILE.file_content%type,
                                p_trc_file_id out TRC_FILE.trc_file_id%type)
  is
    l_db_source TRC_FILE.file_db_source%type;
  begin
    if nvl(p_db_source,'$LOCAL$') = '$LOCAL$' then
      l_db_source := p_db_source;
    else
      select DB_LINK_NAME into l_db_source from v$opas_db_links where ORA_DB_LINK=p_db_source;
    end if;
    
    INSERT INTO trc_file (proj_id, filename, owner, created, status, file_db_source, file_content) VALUES (p_proj_id,p_filename, nvl(p_owner,COREMOD_API.gDefaultOwner), default, fsNew, l_db_source, p_file_content) returning trc_file_id into p_trc_file_id;
	TRC_FILE_LCC.trcfile_exec_action(p_trc_file_id,TRC_FILE_LCC.c_trcfile_create);
  end;

/*
  procedure delete_file(p_trc_file_id TRC_FILE.trc_file_id%type, p_keep_file boolean default false, p_keep_parsed boolean default false)
  is
    l_trc_file         TRC_FILE%rowtype;
  begin
    if p_keep_file and p_keep_parsed then
      raise_application_error(-20000,'Invalid input for delete_file.');
    end if;

    get_file(p_trc_file_id,l_trc_file,true);

    if not p_keep_file and l_trc_file.file_content is not null then
      update trc_file set file_content=null where trc_file_id=p_trc_file_id;
      COREFILE_API.delete_file(l_trc_file.file_content);
    end if;

    --delete file anyway
    if (l_trc_file.status=fsNew and not p_keep_file) or
       (not p_keep_parsed and not p_keep_file) or
       (not p_keep_parsed and l_trc_file.file_content is null)
    then
      delete from trc_file where trc_file_id=p_trc_file_id;
    end if;

    if not p_keep_parsed then
      update trc_file set status=fsNew where trc_file_id=p_trc_file_id;
      delete from opas_notes where note_id=l_trc_file.note_id;
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
  begin null;

    for p in (select * from trc_projects where retention = 'DEFAULT' and systimestamp - created > TO_DSINTERVAL(COREMOD_API.getconf('PROJECTRETENTION','SQL_TRACE')||' 00:00:00'))
    loop
      drop_project_i(p.TRCPROJ_ID);
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
*/

  procedure cleanup_files(p_proj_id opas_projects.proj_id%type, p_is_drop boolean)
  is
  begin
    for i in (select * from trc_file where proj_id=p_proj_id)
	loop
	  if p_is_drop then
	    remove_source_data_i(i.trc_file_id);
		remove_parsed_data_i(i.trc_file_id);
		remove_report_i(i.trc_file_id);
	  else
	    if i.source_keep_forever='N' then
		  remove_source_data_i(i.trc_file_id);
		end if;
	  end if;
	end loop; 	
  end;

  procedure remove_source_data_i(p_trc_file_id TRC_FILE.trc_file_id%type)
  is
    l_trc_file         TRC_FILE%rowtype;
  begin
    l_trc_file:=get_file(p_trc_file_id,true);
    update trc_file set file_content=null where trc_file_id=p_trc_file_id;
    COREFILE_API.delete_file(l_trc_file.file_content);  
  end;  
  
  procedure remove_parsed_data_i(p_trc_file_id TRC_FILE.trc_file_id%type)
  is
  begin
    delete from trc_stat where trc_file_id=p_trc_file_id;
    delete from trc_wait where trc_file_id=p_trc_file_id;
    delete from trc_binds where trc_file_id=p_trc_file_id;
    delete from trc_call where trc_file_id=p_trc_file_id;
    delete from trc_statement where trc_file_id=p_trc_file_id;
    delete from trc_client_identity where trc_file_id=p_trc_file_id;
    delete from trc_trans where trc_file_id=p_trc_file_id;
    delete from trc_session where trc_file_id=p_trc_file_id;  
  end;  
  
  procedure remove_report_i(p_trc_file_id TRC_FILE.trc_file_id%type)
  is
    l_trc_file         TRC_FILE%rowtype;
  begin
    l_trc_file:=get_file(p_trc_file_id,true);
    update trc_file set report_content=null where trc_file_id=p_trc_file_id;
    COREFILE_API.delete_file(l_trc_file.report_content);  
  end;					

  procedure compress_file(p_trc_file_id TRC_FILE.trc_file_id%type)
  is
  begin
    TRC_FILE_LCC.trcfile_exec_action(p_trc_file_id,TRC_FILE_LCC.c_trcfile_compress);
    remove_source_data_i(p_trc_file_id);
  end;
  
  procedure archive_file(p_trc_file_id TRC_FILE.trc_file_id%type)
  is
  begin
    TRC_FILE_LCC.trcfile_exec_action(p_trc_file_id,TRC_FILE_LCC.c_trcfile_archive);
    remove_source_data_i(p_trc_file_id);
	remove_parsed_data_i(p_trc_file_id);
  end;
  
  procedure drop_file(p_trc_file_id TRC_FILE.trc_file_id%type)
  is
    l_trc_file         TRC_FILE%rowtype;
  begin
    l_trc_file:=get_file(p_trc_file_id,true);
    TRC_FILE_LCC.trcfile_exec_action(l_trc_file,TRC_FILE_LCC.c_trcfile_drop);
	if l_trc_file.note_id is not null then
	   COREPROJ_API.drop_note(l_trc_file.note_id);
	end if;
    remove_source_data_i(p_trc_file_id);
	remove_parsed_data_i(p_trc_file_id);
	remove_reports_i    (p_trc_file_id);
	delete from TRC_FILE where trc_file_id = p_trc_file_id;
  end;
  
  procedure set_note(p_trc_file_id  TRC_FILE.trc_file_id%type,
                     p_note         opas_notes.note%type)
  is
    l_trc_file         TRC_FILE%rowtype;
    l_note_id          TRC_FILE.note_id%type;
  begin
    l_trc_file:=get_file(p_trc_file_id,true);
	
	TRC_FILE_LCC.trcfile_exec_action(l_trc_file,TRC_FILE_LCC.c_trcfile_edit);
    
	l_note_id:=l_trc_file.NOTE_ID;
    COREPROJ_API.set_note (  
        P_NOTE_ID => l_note_id,
        P_PROJ_ID => l_trc_file.proj_id,
        P_IS_PROJ_NOTE => 'N',
        P_NOTE => P_NOTE) ;  
    if l_trc_file.NOTE_ID is null then
      update TRC_FILE set note_id=l_note_id where trc_file_id=p_trc_file_id;
    end if;
  end;
END TRC_FILE_API;
/

--------------------------------------------------------
show errors
--------------------------------------------------------