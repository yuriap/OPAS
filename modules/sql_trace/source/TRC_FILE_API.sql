create or replace PACKAGE TRC_FILE_API AS

  gMODNAME       constant varchar2(32) := 'SQL_TRACE';

  function getMODNAME return varchar2;


  procedure register_trace_file(p_proj_id         trc_files.proj_id%type,
                                p_owner           trc_files.owner%type,
                                p_filename        trc_files.filename%type,
                                p_file_source     trc_files.file_source%type,
                                p_store_file      boolean,
                                p_trc_file_id out trc_files.trc_file_id%type);

  procedure store_file(p_trc_file_id trc_files.trc_file_id%type, p_file blob default null);

  procedure compress_file(p_trc_file_id trc_files.trc_file_id%type);
  procedure archive_file(p_trc_file_id trc_files.trc_file_id%type);
  procedure drop_file(p_trc_file_id trc_files.trc_file_id%type);
  procedure cleanup_for_reparse(p_trc_file_id trc_files.trc_file_id%type);

  procedure cleanup_files(p_proj_id trc_projects.proj_id%type, p_mode number, p_use_retention boolean);

  procedure set_note(p_trc_file_id  trc_files.trc_file_id%type,
                     p_note         trc_files.file_note%type);

  function get_file(p_trc_file_id trc_files.trc_file_id%type, p_lock boolean default false) return trc_files%rowtype;

  procedure set_file_security
                        (p_trc_file_id         trc_files.trc_file_id%type,
                         p_owner               trc_files.owner%type default null,
                         p_source_keep_forever trc_files.source_keep_forever%type,
                         p_parsed_keep_forever trc_files.parsed_keep_forever%type);

  procedure delete_file (P_TRC_FILE_ID trc_files.trc_file_id%type,
                         P_KEEP_SOURCE boolean,
                         P_KEEP_PARSED boolean,
                         P_KEEP_REPORT boolean);
                         
END TRC_FILE_API;
/

--------------------------------------------------------
show errors
--------------------------------------------------------

create or replace PACKAGE BODY TRC_FILE_API AS

  function getMODNAME return varchar2 is begin return gMODNAME; end;

  function get_file(p_trc_file_id trc_files.trc_file_id%type, p_lock boolean default false) return trc_files%rowtype
  is
    exResourceBusy exception;
    pragma exception_init(exResourceBusy,-54);
	l_trc_file trc_files%rowtype;
  begin
    if p_lock then
      select * into l_trc_file from trc_files where trc_file_id = p_trc_file_id for update nowait;
    else
      select * into l_trc_file from trc_files where trc_file_id = p_trc_file_id;
    end if;

	return l_trc_file;
  exception
    when no_data_found then raise_application_error(-20000, 'File ID:'||p_trc_file_id||' not found');
    when exResourceBusy then raise_application_error(-20000, 'File ID:'||p_trc_file_id||' is being processed now.');
  end;

  procedure store_file(p_trc_file_id trc_files.trc_file_id%type, p_file blob default null)
  is
    l_trc_file trc_files%rowtype;

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

      l_file := COREFILE_API.create_file(P_MODNAME => gMODNAME,
                                         P_FILE_TYPE => 'Extended SQL Trace',
                                         P_FILE_NAME => l_trc_file.filename,
                                         P_MIMETYPE => 'TXT',
                                         P_OWNER => l_trc_file.OWNER);

      COREFILE_API.get_locator(l_file,l_file_content);
      if p_file is null then
        
        if l_trc_file.file_source is null then raise_application_error(-20000,'File source and file name are empty.'); end if; 
        
        if l_trc_file.file_source = '$LOCAL$' then
          for i in ( select payload from V$DIAG_TRACE_FILE_CONTENTS where trace_filename=l_trc_file.filename  order by line_number) loop
            l_file_content:=l_file_content||i.payload;
          end loop;
        elsif l_trc_file.file_source != '$LOCAL$' then
          open crsr for 'select payload from V$DIAG_TRACE_FILE_CONTENTS@'||l_trc_file.file_source||' where trace_filename=:p1 order by line_number' using l_trc_file.filename;
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

      UPDATE trc_files
         SET file_content = l_file
       WHERE trc_file_id = p_trc_file_id;

	  TRC_FILE_LCC.trcfile_exec_action(l_trc_file,TRC_FILE_LCC.c_trcfile_load);
    end if;
  end;

  procedure register_trace_file(p_proj_id         trc_files.proj_id%type,
                                p_owner           trc_files.owner%type,
                                p_filename        trc_files.filename%type,
                                p_file_source     trc_files.file_source%type,
                                p_store_file      boolean,
                                p_trc_file_id out trc_files.trc_file_id%type)
  is
    l_db_source trc_files.file_source%type;
  begin
    if nvl(p_file_source,'$LOCAL$') = '$LOCAL$' then
      l_db_source := p_file_source;
    else
      select DB_LINK_NAME into l_db_source from v$opas_db_links where ORA_DB_LINK=p_file_source;
    end if;

    INSERT INTO trc_files (proj_id, filename, owner, created, status, file_source) VALUES (p_proj_id,p_filename, nvl(p_owner,COREMOD_API.gDefaultOwner), default, TRC_FILE_LCC.c_trcfilestate_new, l_db_source) returning trc_file_id into p_trc_file_id;

	TRC_FILE_LCC.trcfile_exec_action(p_trc_file_id,TRC_FILE_LCC.c_trcfile_create);
    if not p_store_file then
      TRC_FILE_LCC.trcfile_exec_action(p_trc_file_id,TRC_FILE_LCC.c_trcfile_load);    
    end if;
  end;

  procedure set_file_security
                        (p_trc_file_id         trc_files.trc_file_id%type,
                         p_owner               trc_files.owner%type default null,
                         p_source_keep_forever trc_files.source_keep_forever%type,
                         p_parsed_keep_forever trc_files.parsed_keep_forever%type)
  is
  begin
    TRC_FILE_LCC.trcfile_exec_action(p_trc_file_id,TRC_FILE_LCC.c_trcfile_edit);
    UPDATE trc_files
       SET owner = nvl(p_owner,owner),
           source_keep_forever = decode(p_source_keep_forever,'Y','Y','N','N','N'),
           parsed_keep_forever = decode(p_parsed_keep_forever,'Y','Y','N','N','N')
     WHERE trc_file_id = p_trc_file_id;  
  end;
                         
  procedure remove_source_data_i(p_trc_file_id trc_files.trc_file_id%type)
  is
    l_trc_file         trc_files%rowtype;
  begin
    l_trc_file:=get_file(p_trc_file_id,true);
    update trc_files set file_content=null where trc_file_id=p_trc_file_id;
    COREFILE_API.delete_file(l_trc_file.file_content);
  end;

  procedure remove_parsed_data_i(p_trc_file_id trc_files.trc_file_id%type)
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

  procedure remove_report_i(p_trc_file_id trc_files.trc_file_id%type)
  is
    l_trc_file         trc_files%rowtype;
  begin
    l_trc_file:=get_file(p_trc_file_id,true);
    update trc_files set report_content=null where trc_file_id=p_trc_file_id;
    COREFILE_API.delete_file(l_trc_file.report_content);
  end;

  procedure cleanup_files(p_proj_id trc_projects.proj_id%type, p_mode number, p_use_retention boolean)
  is
    l_errmsg varchar2(1000);
  begin
    coremod_log.log('TRC_FILE_API.cleanup_files: '||p_proj_id||';'||p_mode||';'||COREMOD_LOG.bool2str(p_use_retention)||';','DEBUG');
    for i in (select x.*, systimestamp - created src_duration, systimestamp - parsed prsd_duration from trc_files x where proj_id = p_proj_id) loop
      begin
        if p_mode in (TRC_PROJ_API.c_ALL, TRC_PROJ_API.c_SOURCEDATA) then
		  if p_use_retention and i.source_keep_forever='N' and i.src_duration > TO_DSINTERVAL(nvl(COREMOD_API.getconf('SOURCERETENTION',TRC_FILE_API.gMODNAME),8)||' 00:00:00') then
		    remove_source_data_i(i.trc_file_id);
		  elsif not (p_use_retention) then
		    remove_source_data_i(i.trc_file_id);
		  end if;
		end if;
        if p_mode in (TRC_PROJ_API.c_ALL, TRC_PROJ_API.c_PARSEDDATA) then
		  if p_use_retention and i.parsed_keep_forever='N' and i.prsd_duration > TO_DSINTERVAL(nvl(COREMOD_API.getconf('SOURCERETENTION',TRC_FILE_API.gMODNAME),8)||' 00:00:00') then
		    remove_parsed_data_i(i.trc_file_id);
		  elsif not (p_use_retention) then
		    remove_parsed_data_i(i.trc_file_id);
		  end if;
		end if;
		if p_mode in (TRC_PROJ_API.c_ALL) and not (p_use_retention) then
		  remove_report_i(i.trc_file_id);
		end if;
      exception
        when others then
          l_errmsg := 'The TRC_FILE_API.cleanup_files procedure failed for proj_id,mode,use_retention='||p_proj_id||','||p_mode||','||case when p_use_retention then 'true' else 'false' end||', see log for details.';
          coremod_log.log(l_errmsg);
          coremod_log.log(sqlerrm);
          raise_application_error(-20000,l_errmsg);
      end;
    end loop;
  end;

  procedure delete_file (P_TRC_FILE_ID trc_files.trc_file_id%type,
                         P_KEEP_SOURCE boolean,
                         P_KEEP_PARSED boolean,
                         P_KEEP_REPORT boolean)
  is
  begin
    coremod_log.log('TRC_FILE_API.delete_file: '||COREMOD_LOG.bool2str(P_KEEP_SOURCE)||';'||COREMOD_LOG.bool2str(P_KEEP_PARSED)||';'||COREMOD_LOG.bool2str(P_KEEP_REPORT)||';','DEBUG');
    if not P_KEEP_SOURCE and not P_KEEP_PARSED and not P_KEEP_REPORT then
      drop_file(P_TRC_FILE_ID);
    elsif not P_KEEP_SOURCE and P_KEEP_PARSED and P_KEEP_REPORT then
      compress_file(P_TRC_FILE_ID);
    elsif not P_KEEP_SOURCE and not P_KEEP_PARSED and P_KEEP_REPORT then
      archive_file(P_TRC_FILE_ID);
    elsif P_KEEP_SOURCE and not P_KEEP_PARSED and not P_KEEP_REPORT then
      cleanup_for_reparse(P_TRC_FILE_ID);
    else
      raise_application_error(-20000,'Unimplemented file action');
    end if;
  end;

  procedure compress_file(p_trc_file_id trc_files.trc_file_id%type)
  is
  begin
    coremod_log.log('TRC_FILE_API.compress_file: '||p_trc_file_id,'DEBUG');
    TRC_FILE_LCC.trcfile_exec_action(p_trc_file_id,TRC_FILE_LCC.c_trcfile_compress);
	remove_source_data_i(p_trc_file_id);
  end;

  procedure archive_file(p_trc_file_id trc_files.trc_file_id%type)
  is
  begin
    coremod_log.log('TRC_FILE_API.archive_file: '||p_trc_file_id,'DEBUG');
    TRC_FILE_LCC.trcfile_exec_action(p_trc_file_id,TRC_FILE_LCC.c_trcfile_archive);

	remove_source_data_i(p_trc_file_id);
	remove_parsed_data_i(p_trc_file_id);
  end;

  procedure drop_file(p_trc_file_id trc_files.trc_file_id%type)
  is
    l_trc_file         trc_files%rowtype;
  begin
    coremod_log.log('TRC_FILE_API.drop_file: '||p_trc_file_id,'DEBUG');
    l_trc_file:=get_file(p_trc_file_id,true);

    TRC_FILE_LCC.trcfile_exec_action(l_trc_file,TRC_FILE_LCC.c_trcfile_drop);

    remove_source_data_i(p_trc_file_id);
	remove_parsed_data_i(p_trc_file_id);
	remove_report_i    (p_trc_file_id);
	delete from trc_files where trc_file_id = p_trc_file_id;
  end;

  procedure cleanup_for_reparse(p_trc_file_id trc_files.trc_file_id%type)
  is
  begin
    coremod_log.log('TRC_FILE_API.cleanup_for_reparse: '||p_trc_file_id,'DEBUG');
    TRC_FILE_LCC.trcfile_exec_action(p_trc_file_id,TRC_FILE_LCC.c_trcfile_reparse);
	remove_parsed_data_i(p_trc_file_id);
	remove_report_i    (p_trc_file_id);
  end;

  procedure set_note(p_trc_file_id  trc_files.trc_file_id%type,
                     p_note         trc_files.file_note%type)
  is
    l_trc_file         trc_files%rowtype;
  begin
	TRC_FILE_LCC.trcfile_exec_action(p_trc_file_id,TRC_FILE_LCC.c_trcfile_edit);

    update trc_files set file_note=p_note where trc_file_id=p_trc_file_id;
  end;
END TRC_FILE_API;
/

--------------------------------------------------------
show errors
--------------------------------------------------------