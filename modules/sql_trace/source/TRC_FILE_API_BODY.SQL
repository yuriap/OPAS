CREATE OR REPLACE
PACKAGE BODY TRC_FILE_API AS

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

      COREFILE_API.get_locator_for_storage(l_file,l_file_content);
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
    --if nvl(p_file_source,'$LOCAL$') = '$LOCAL$' then
    --  l_db_source := p_file_source;
    --else
    --  select DB_LINK_NAME into l_db_source from v$opas_db_links where ORA_DB_LINK=p_file_source;
    --end if;
    l_db_source := p_file_source;

    INSERT INTO trc_files (proj_id, filename, owner, created, status, file_source) VALUES (p_proj_id,p_filename, nvl(p_owner,COREMOD_API.gDefaultOwner), default, TRC_FILE_LCC.c_trcfilestate_new, l_db_source) returning trc_file_id into p_trc_file_id;

	TRC_FILE_LCC.trcfile_exec_action(p_trc_file_id,TRC_FILE_LCC.c_trcfile_create);
    if not p_store_file then
      TRC_FILE_LCC.trcfile_exec_action(p_trc_file_id,TRC_FILE_LCC.c_trcfile_load);
    end if;
  end;

  procedure set_file_security
                        (p_trc_file_id         trc_files.trc_file_id%type,
                         p_owner               trc_files.owner%type default null,
                         p_source_retention    trc_files.source_retention%type,
                         p_parsed_retention    trc_files.parsed_retention%type)
  is
  begin
    TRC_FILE_LCC.trcfile_exec_action(p_trc_file_id,TRC_FILE_LCC.c_trcfile_edit);
    UPDATE trc_files
       SET owner = nvl(p_owner,owner),
           source_retention = decode(p_source_retention,-1,null,p_source_retention),
           parsed_retention = decode(p_parsed_retention,-1,null,p_parsed_retention)
     WHERE trc_file_id = p_trc_file_id;
  end;

  procedure remove_source_data_i(p_trc_file_id trc_files.trc_file_id%type, p_set_status boolean)
  is
    l_trc_file         trc_files%rowtype;
  begin
    coremod_log.log('TRC_FILE_API.remove_source_data_i: '||p_trc_file_id,'DEBUG');
    l_trc_file:=get_file(p_trc_file_id,true);
    if p_set_status then
      if l_trc_file.status=TRC_FILE_LCC.c_trcfilestate_parsed then
        TRC_FILE_LCC.trcfile_exec_action(l_trc_file,TRC_FILE_LCC.c_trcfile_compress);
      else
        TRC_FILE_LCC.trcfile_exec_action(l_trc_file,TRC_FILE_LCC.c_trcfile_archive);
      end if;
    end if;
    update trc_files set file_content=null where trc_file_id=p_trc_file_id;
    COREFILE_API.delete_file(l_trc_file.file_content);
  end;

  procedure remove_parsed_data_ii(p_trc_file_id trc_files.trc_file_id%type)
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
    update trc_files set parsed=null where trc_file_id=p_trc_file_id;
  end;

  procedure remove_parsed_data_i(p_trc_file_id trc_files.trc_file_id%type, p_set_status boolean)
  is
    l_trc_file         trc_files%rowtype;
  begin
    coremod_log.log('TRC_FILE_API.remove_parsed_data_i: '||p_trc_file_id,'DEBUG');
    l_trc_file:=get_file(p_trc_file_id,true);
    if p_set_status then
      if l_trc_file.status=TRC_FILE_LCC.c_trcfilestate_parsed then
        TRC_FILE_LCC.trcfile_exec_action(l_trc_file,TRC_FILE_LCC.c_trcfile_reparse);
      else
        TRC_FILE_LCC.trcfile_exec_action(l_trc_file,TRC_FILE_LCC.c_trcfile_archive);
      end if;
    end if;
    remove_parsed_data_ii(p_trc_file_id);
  end;

  procedure remove_report_i(p_trc_file_id trc_files.trc_file_id%type)
  is
    l_trc_file         trc_files%rowtype;
  begin
    coremod_log.log('TRC_FILE_API.remove_report_i: '||p_trc_file_id,'DEBUG');
    l_trc_file:=get_file(p_trc_file_id,true);
    update trc_files set report_content=null where trc_file_id=p_trc_file_id;
    COREFILE_API.delete_file(l_trc_file.report_content);
  end;

  procedure cleanup_files(p_proj_id trc_projects.proj_id%type, p_mode number, p_use_retention boolean)
  is
    l_errmsg varchar2(1000);
  begin
    coremod_log.log('TRC_FILE_API.cleanup_files: '||p_proj_id||';'||p_mode||';'||COREMOD_LOG.bool2str(p_use_retention)||';','DEBUG');
    if not(p_use_retention) then
      for i in (select x.* from trc_files x where proj_id = p_proj_id) loop
        if p_mode in (TRC_PROJ_API.c_ALL, TRC_PROJ_API.c_SOURCEDATA) then
           remove_source_data_i(i.trc_file_id, false);
           coremod_log.log('Purged source, file: '||i.trc_file_id,'DEBUG');
        end if;
        if p_mode in (TRC_PROJ_API.c_ALL, TRC_PROJ_API.c_PARSEDDATA) then
          remove_parsed_data_i(i.trc_file_id, false);
          coremod_log.log('Purged parsed, file: '||i.trc_file_id,'DEBUG');
        end if;
		if p_mode in (TRC_PROJ_API.c_ALL) then
		  remove_report_i(i.trc_file_id);
          coremod_log.log('Purged report, file: '||i.trc_file_id,'DEBUG');
		end if;
      end loop;
    elsif p_use_retention then
      -- **********************************************
      -- source cleanup
      -- **********************************************
      for i in (select x.*
                  from trc_files x
                 where proj_id = p_proj_id) loop
        begin
          coremod_log.log('TRC_FILE_API.cleanup_files: '||i.trc_file_id||';'||p_proj_id||';'||
                          i.created||';'||i.source_retention||';'||
                          i.parsed||';'||i.parsed_retention||';'
                          ,'DEBUG'
                          );
          if p_mode in (TRC_PROJ_API.c_ALL, TRC_PROJ_API.c_SOURCEDATA) and i.status in (TRC_FILE_LCC.c_trcfilestate_LOADED,TRC_FILE_LCC.c_trcfilestate_PARSED)
          then
            --coremod_log.log(to_char(i.created + nvl(to_number(COREMOD_API.getconf('SOURCERETENTION',TRC_FILE_API.gMODNAME)),8),'YYYY/MM/DD HH24:MI:SS'));
            --coremod_log.log(to_char((i.created + i.source_retention),'YYYY/MM/DD HH24:MI:SS'));
            if i.source_retention is null and (i.created + nvl(to_number(COREMOD_API.getconf('SOURCERETENTION',TRC_FILE_API.gMODNAME)),8)) < sysdate
            then
		      remove_source_data_i(i.trc_file_id, true);
              coremod_log.log('Removed source by default retention, file: '||i.trc_file_id);
		    end if;

            if nvl(i.source_retention,-1)>0 and (i.created + i.source_retention) < sysdate
            then
              remove_source_data_i(i.trc_file_id, true);
              coremod_log.log('Removed source by '||i.source_retention||' retention, file: '||i.trc_file_id);
		    end if;
          end if;

          if p_mode in (TRC_PROJ_API.c_ALL, TRC_PROJ_API.c_PARSEDDATA) and i.status in (TRC_FILE_LCC.c_trcfilestate_COMPRESSED,TRC_FILE_LCC.c_trcfilestate_PARSED)
          then
            if i.parsed_retention is null and i.parsed + nvl(to_number(COREMOD_API.getconf('PARSEDRETENTION',TRC_FILE_API.gMODNAME)),8) < sysdate
            then
		      remove_parsed_data_i(i.trc_file_id, true);
              coremod_log.log('Removed parsed by default retention, file: '||i.trc_file_id);
		    end if;

            if nvl(i.parsed_retention,-1)>0 and (i.parsed + i.parsed_retention) < sysdate
            then
              remove_parsed_data_i(i.trc_file_id, true);
              coremod_log.log('Removed parsed by '||i.parsed_retention||' retention, file: '||i.trc_file_id);
		    end if;
          end if;
        exception
          when others then
            l_errmsg := 'The TRC_FILE_API.cleanup_files procedure failed for proj_id,mode,use_retention='||p_proj_id||','||p_mode||','||case when p_use_retention then 'true' else 'false' end||', see log for details.';
            coremod_log.log(l_errmsg);
            coremod_log.log(sqlerrm);
            raise_application_error(-20000,l_errmsg);
        end;
      end loop;

    end if;
  end;

/*
  procedure cleanup_for_reparse(p_trc_file_id trc_files.trc_file_id%type,
                                P_KEEP_PARSED boolean,
                                P_KEEP_REPORT boolean)
  is
  begin
    coremod_log.log('TRC_FILE_API.cleanup_for_reparse: '||p_trc_file_id,'DEBUG');

    TRC_FILE_LCC.trcfile_exec_action(p_trc_file_id,TRC_FILE_LCC.c_trcfile_reparse);
	if not P_KEEP_PARSED then remove_parsed_data_i(p_trc_file_id); end if;
	if not P_KEEP_REPORT then remove_report_i     (p_trc_file_id); end if;
  end;
*/
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
--    elsif (P_KEEP_SOURCE and P_KEEP_PARSED and not P_KEEP_REPORT) or (P_KEEP_SOURCE and not P_KEEP_PARSED and not P_KEEP_REPORT) then
--      cleanup_for_reparse(P_TRC_FILE_ID,P_KEEP_PARSED,P_KEEP_REPORT);
    else
      raise_application_error(-20000,'[TRC_FILE_API.delete_file] Unimplemented file action');
    end if;
  end;

  procedure compress_file(p_trc_file_id trc_files.trc_file_id%type)
  is
  begin
    coremod_log.log('TRC_FILE_API.compress_file: '||p_trc_file_id,'DEBUG');
    TRC_FILE_LCC.trcfile_exec_action(p_trc_file_id,TRC_FILE_LCC.c_trcfile_compress);
	remove_source_data_i(p_trc_file_id, false);
  end;

  procedure archive_file(p_trc_file_id trc_files.trc_file_id%type)
  is
  begin
    coremod_log.log('TRC_FILE_API.archive_file: '||p_trc_file_id,'DEBUG');
    TRC_FILE_LCC.trcfile_exec_action(p_trc_file_id,TRC_FILE_LCC.c_trcfile_archive);

	remove_source_data_i(p_trc_file_id, false);
	remove_parsed_data_i(p_trc_file_id, false);
  end;

  procedure drop_file(p_trc_file_id trc_files.trc_file_id%type)
  is
    l_trc_file         trc_files%rowtype;
  begin
    coremod_log.log('TRC_FILE_API.drop_file: '||p_trc_file_id,'DEBUG');
    l_trc_file:=get_file(p_trc_file_id,true);

    TRC_FILE_LCC.trcfile_exec_action(l_trc_file,TRC_FILE_LCC.c_trcfile_drop);

    remove_source_data_i(p_trc_file_id, false);
	remove_parsed_data_i(p_trc_file_id, false);
	remove_report_i     (p_trc_file_id);
	delete from trc_files where trc_file_id = p_trc_file_id;
  end;

  procedure set_note(p_trc_file_id  trc_files.trc_file_id%type,
                     p_note         trc_files.file_note%type)
  is
    l_trc_file         trc_files%rowtype;
  begin
	TRC_FILE_LCC.trcfile_exec_action(p_trc_file_id,TRC_FILE_LCC.c_trcfile_edit);

    update trc_files set file_note=p_note where trc_file_id=p_trc_file_id;
  end;

  procedure parse_file_async(p_trc_file_id trc_files.trc_file_id%type, p_tq_id out opas_task_queue.tq_id%type)
  is
    L_TASKNAME VARCHAR2(128) := 'TRC_PARSEFILE';
  begin
    TRC_FILE_LCC.trcfile_exec_action(p_trc_file_id,TRC_FILE_LCC.c_trcfile_inparsequeue);
    p_tq_id:=COREMOD_TASKS.prep_execute_task (  P_TASKNAME => L_TASKNAME) ;
    COREMOD_TASKS.set_task_param( p_tq_id => p_tq_id, p_name => 'B1', p_num_par => p_trc_file_id);
    COREMOD_TASKS.queue_task ( p_tq_id => p_tq_id ) ;
    update trc_files set tq_id = p_tq_id where trc_file_id = p_trc_file_id;
    commit;
  end;
/*
  procedure reparse_file_async(p_trc_file_id trc_files.trc_file_id%type, p_tq_id out opas_task_queue.tq_id%type)
  is
  begin
    TRC_FILE_LCC.trcfile_exec_action(p_trc_file_id,TRC_FILE_LCC.c_trcfile_inparsequeue);
	parse_file_async(p_trc_file_id,p_tq_id);
  end;
*/

  procedure parse_file(p_trc_file_id trc_files.trc_file_id%type)
  is
    l_trc_file         trc_files%rowtype;
  begin
    coremod_log.log('TRC_FILE_API.parse_file: '||p_trc_file_id,'DEBUG');
    l_trc_file:=get_file(p_trc_file_id,false);

    if l_trc_file.report_content is not null or l_trc_file.parsed is not null then
      remove_parsed_data_ii(p_trc_file_id);
      remove_report_i(p_trc_file_id);
      commit;
    end if;

    TRC_FILE_LCC.trcfile_exec_action(p_trc_file_id,TRC_FILE_LCC.c_trcfile_startparse);	 --autonomous

    TRC_PROCESSFILE.parse_file(p_trc_file_id);
    --commit;

    --for i in (select table_name from user_tables where table_name like 'TRC%') loop
    --  dbms_stats.gather_table_stats(OWNNAME => user, TABNAME=> i.table_name, CASCADE => true);
    --end loop;

    trc_report.getreport(p_trc_file_id);

    --commit;

    TRC_FILE_LCC.trcfile_exec_action(p_trc_file_id,TRC_FILE_LCC.c_trcfile_finishparse);

    exception
      when others then
        rollback;
        coremod_log.log('TRC_FILE_API.parse_file error: '||sqlerrm);
        COREMOD_LOG.log(DBMS_UTILITY.FORMAT_ERROR_STACK);
        COREMOD_LOG.log(DBMS_UTILITY.FORMAT_ERROR_BACKTRACE);
        TRC_FILE_LCC.trcfile_exec_action(p_trc_file_id,TRC_FILE_LCC.c_trcfile_failparse);
        raise_application_error(-20000,'parse_file exception: '||sqlerrm);
  end;

  -- for debug only
  procedure recreate_report(p_trc_file_id trc_files.trc_file_id%type)
  is
    l_trc_file         trc_files%rowtype;
  begin
    l_trc_file:=TRC_FILE_API.get_file(p_trc_file_id,true);

    if l_trc_file.report_content is not null then
      update trc_files set report_content=null where trc_file_id=p_trc_file_id;
      COREFILE_API.delete_file(l_trc_file.report_content);
      commit;
    end if;
    trc_report.getreport(p_trc_file_id);
  end;
END TRC_FILE_API;
/
