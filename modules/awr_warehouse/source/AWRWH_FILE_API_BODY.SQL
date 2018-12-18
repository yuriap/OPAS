CREATE OR REPLACE
PACKAGE BODY AWRWH_FILE_API AS

  function get_file(p_dump_id awrwh_dumps.dump_id%type, p_lock boolean default false) return awrwh_dumps%rowtype
  is
    exResourceBusy exception;
    pragma     exception_init(exResourceBusy,-54);
	l_dmp_file awrwh_dumps%rowtype;
  begin
    if p_lock then
      select * into l_dmp_file from awrwh_dumps where dump_id = p_dump_id for update nowait;
    else
      select * into l_dmp_file from awrwh_dumps where dump_id = p_dump_id;
    end if;

	return l_dmp_file;
  exception
    when no_data_found  then raise_application_error(-20000, 'File ID:'||p_dump_id||' not found');
    when exResourceBusy then raise_application_error(-20000, 'File ID:'||p_dump_id||' is being processed now.');
  end;

  procedure store_file(p_dump_id awrwh_dumps.dump_id%type, p_file blob default null)
  is
    l_dmp_file awrwh_dumps%rowtype;
    l_file opas_files.file_id%type;
    l_file_content opas_files.file_contentb%type;
  begin
    l_dmp_file:=get_file(p_dump_id,true);

    l_file := COREFILE_API.create_file(P_MODNAME => AWRWH_API.gMODNAME,
                                       P_FILE_TYPE => AWRWH_API.gDUMPFILETYPE,
                                       P_FILE_NAME => l_dmp_file.filename,
                                       P_MIMETYPE => 'bin',
                                       P_OWNER => l_dmp_file.OWNER);

    COREFILE_API.get_locator(l_file,l_file_content);
    l_file_content:=p_file;
    COREFILE_API.store_content(l_file,l_file_content);

    UPDATE awrwh_dumps
       SET filebody = l_file
     WHERE dump_id = p_dump_id;

    AWRWH_FILE_LCC.dmpfile_exec_action(l_dmp_file,AWRWH_FILE_LCC.c_dmpfile_loadfile);
  end;

  procedure register_dump_file (p_proj_id         awrwh_dumps.proj_id%type,
                                p_owner           awrwh_dumps.owner%type,
                                p_filename        awrwh_dumps.filename%type,
                                p_dump_name       awrwh_dumps.dump_name%type,
                                p_description     awrwh_dumps.dump_description%type,
                                p_dump_id     out awrwh_dumps.dump_id%type)
  is
  begin
    INSERT INTO awrwh_dumps ( proj_id, filename, dump_description, dump_name,  owner)
                     VALUES (p_proj_id, p_filename, p_description, p_dump_name,  nvl(p_owner,COREMOD_API.gDefaultOwner)) returning dump_id into p_dump_id;

	AWRWH_FILE_LCC.dmpfile_exec_action(p_dump_id,AWRWH_FILE_LCC.c_dmpfile_create);
  end;

  procedure set_file_security
                        (p_dump_id             awrwh_dumps.dump_id%type,
                         p_owner               awrwh_dumps.owner%type default null,
                         p_source_retention    awrwh_dumps.source_retention%type,
                         p_parsed_retention    awrwh_dumps.parsed_retention%type)
  is
  begin
    AWRWH_FILE_LCC.dmpfile_exec_action(p_dump_id,AWRWH_FILE_LCC.c_dmpfile_editfile);
    UPDATE awrwh_dumps
       SET owner = nvl(p_owner,owner),
           source_retention = p_source_retention,
           parsed_retention = p_parsed_retention
     WHERE dump_id = p_dump_id;
  end;

  procedure set_note(p_dump_id  awrwh_dumps.dump_id%type,
                     p_description     awrwh_dumps.dump_description%type)
  is
    l_dmp_file         awrwh_dumps%rowtype;
  begin
	AWRWH_FILE_LCC.dmpfile_exec_action(p_dump_id,AWRWH_FILE_LCC.c_dmpfile_editfile);

    update awrwh_dumps set dump_description=p_description where dump_id=p_dump_id;
  end;

  procedure set_awr_dest(p_dump_id  awrwh_dumps.dump_id%type,
                         p_remote_dest varchar2)
  is
  begin
    update awrwh_dumps set is_remote = p_remote_dest where dump_id   = p_dump_id;
  end;

  procedure remove_source_data_i(p_dump_id awrwh_dumps.dump_id%type)
  is
    l_dmp_file         awrwh_dumps%rowtype;
  begin
    coremod_log.log('AWRWH_FILE_API.remove_source_data_i: '||p_dump_id,'DEBUG');
    l_dmp_file:=get_file(p_dump_id,true);
    update awrwh_dumps set filebody=null where dump_id=p_dump_id;
    COREFILE_API.delete_file(l_dmp_file.filebody);
  end;

  procedure remove_parsed_data_i(p_dump_id awrwh_dumps.dump_id%type)
  is
    l_dmp_file         awrwh_dumps%rowtype;
  begin
    coremod_log.log('AWRWH_FILE_API.remove_parsed_data_i: '||p_dump_id,'DEBUG');

    l_dmp_file:=get_file(p_dump_id,true);
    AWRWH_API.unload_awr_ranges_for_dump
                         (p_is_remote => l_dmp_file.is_remote,
                          p_snap_min => l_dmp_file.min_snap_id,
                          p_snap_max => l_dmp_file.max_snap_id,
                          p_dbid => l_dmp_file.dbid);

    update awrwh_dumps set parsed=null where dump_id=p_dump_id;
  end;

  procedure compress_file_i(p_dump_id awrwh_dumps.dump_id%type)
  is
  begin
    coremod_log.log('AWRWH_FILE_API.compress_file: '||p_dump_id,'DEBUG');
	remove_source_data_i(p_dump_id);
  end;

  procedure archive_file_i(p_dump_id awrwh_dumps.dump_id%type)
  is
  begin
    coremod_log.log('AWRWH_FILE_API.archive_file: '||p_dump_id,'DEBUG');
	remove_source_data_i(p_dump_id);
	remove_parsed_data_i(p_dump_id);
  end;

  procedure drop_file_i(p_dump_id awrwh_dumps.dump_id%type)
  is
    l_dmp_file         awrwh_dumps%rowtype;
  begin
    coremod_log.log('AWRWH_FILE_API.drop_file: '||p_dump_id,'DEBUG');
    l_dmp_file:=get_file(p_dump_id,true);

    remove_source_data_i(p_dump_id);
	remove_parsed_data_i(p_dump_id);

	delete from awrwh_dumps where dump_id = p_dump_id;
  end;

  procedure load_dump_to_awr_repository_i(p_dump_id awrwh_dumps.dump_id%type)
  is
    l_dmp_file         awrwh_dumps%rowtype;
    l_file             blob;
  begin
    coremod_log.log('AWRWH_FILE_API.load_dump_to_awr_repository_i: '||p_dump_id,'DEBUG');
    l_dmp_file:=get_file(p_dump_id,true);

    COREFILE_API.get_locator(l_dmp_file.filebody, l_file);
    AWRWH_API.put_file_to_fs(l_file ,l_dmp_file.filename,COREMOD_API.getconf('WORKDIR',AWRWH_API.gMODNAME));

    if l_dmp_file.is_remote='YES' then
      AWRWH_API.remote_awr_load(
          p_stg_user       => COREMOD_API.getconf('AWRSTGUSER',AWRWH_API.gMODNAME),
          p_stg_tablespace => COREMOD_API.getconf('AWRSTGTBLSPS',AWRWH_API.gMODNAME),
          p_stg_temp       => COREMOD_API.getconf('AWRSTGTMP',AWRWH_API.gMODNAME),
          p_dir            => COREMOD_API.getconf('WORKDIR',AWRWH_API.gMODNAME),
          p_dmpfile        => substr(l_dmp_file.filename,1,instr(l_dmp_file.filename,'.',-1)-1),
          p_dbid           => l_dmp_file.dbid,
          p_min_snap_id    => l_dmp_file.min_snap_id,
          p_max_snap_id    => l_dmp_file.max_snap_id,
          p_min_snap_dt    => l_dmp_file.min_snap_dt,
          p_max_snap_dt    => l_dmp_file.max_snap_dt,
          p_db_description => l_dmp_file.db_description);
    else
      AWRWH_API.local_awr_load(
          p_stg_user       => COREMOD_API.getconf('AWRSTGUSER',AWRWH_API.gMODNAME),
          p_stg_tablespace => COREMOD_API.getconf('AWRSTGTBLSPS',AWRWH_API.gMODNAME),
          p_stg_temp       => COREMOD_API.getconf('AWRSTGTMP',AWRWH_API.gMODNAME),
          p_dir            => COREMOD_API.getconf('WORKDIR',AWRWH_API.gMODNAME),
          p_dmpfile        => substr(l_dmp_file.filename,1,instr(l_dmp_file.filename,'.',-1)-1),
          p_dbid           => l_dmp_file.dbid,
          p_min_snap_id    => l_dmp_file.min_snap_id,
          p_max_snap_id    => l_dmp_file.max_snap_id,
          p_min_snap_dt    => l_dmp_file.min_snap_dt,
          p_max_snap_dt    => l_dmp_file.max_snap_dt,
          p_db_description => l_dmp_file.db_description);
    end if;
    update awrwh_dumps set
        dbid           = l_dmp_file.dbid,
        min_snap_id    = l_dmp_file.min_snap_id,
        max_snap_id    = l_dmp_file.max_snap_id,
        min_snap_dt    = l_dmp_file.min_snap_dt,
        max_snap_dt    = l_dmp_file.max_snap_dt,
        db_description = l_dmp_file.db_description
     where dump_id   = p_dump_id;

    AWRWH_API.remove_file_from_fs(l_dmp_file.filename,COREMOD_API.getconf('WORKDIR',AWRWH_API.gMODNAME));
  exception
    when others then
      raise_application_error(-20000,'load_dump_to_awr_repository exception: '||sqlerrm);
  end;

  procedure unload_dump_from_awr_repository_i       (p_dump_id awrwh_dumps.dump_id%type)
  is
    l_dmp_file         awrwh_dumps%rowtype;
  begin
    coremod_log.log('AWRWH_FILE_API.unload_dump_from_awr_repository: '||p_dump_id,'DEBUG');
    l_dmp_file:=get_file(p_dump_id,false);

    AWRWH_API.unload_awr_ranges_for_dump (
      P_IS_REMOTE => l_dmp_file.IS_REMOTE,
      P_SNAP_MIN  => l_dmp_file.min_snap_id,
      P_SNAP_MAX  => l_dmp_file.max_snap_id,
      P_DBID      => l_dmp_file.DBID) ;
  end;

  --============================================================================================================================
  --============================================================================================================================
  --============================================================================================================================

  procedure exec_file_action_async(p_dump_id awrwh_dumps.dump_id%type, p_action varchar2, p_tq_id out opas_task_queue.tq_id%type)
  is
    L_TASKNAME VARCHAR2(128) := 'AWRWH_EXECFILEACTION';
  begin
    AWRWH_FILE_LCC.dmpfile_exec_action(p_dump_id,AWRWH_FILE_LCC.c_dmpfile_putinqueue);
    p_tq_id:=COREMOD_TASKS.prep_execute_task (  P_TASKNAME => L_TASKNAME) ;
    COREMOD_TASKS.set_task_param( p_tq_id => p_tq_id, p_name => 'B1', p_num_par => p_dump_id);
    COREMOD_TASKS.set_task_param( p_tq_id => p_tq_id, p_name => 'B2', p_varchar_par => p_action);
    COREMOD_TASKS.queue_task ( p_tq_id => p_tq_id ) ;
    commit;
  end;

  procedure exec_file_action      (p_dump_id awrwh_dumps.dump_id%type, p_action varchar2)
  is
    l_dmp_file         awrwh_dumps%rowtype;
  begin
    coremod_log.log('AWRWH_FILE_API.exec_file_action: '||p_dump_id||':'||p_action,'DEBUG');

    if p_action not in (AWRWH_FILE_LCC.c_dmpfile_awrload, AWRWH_FILE_LCC.c_dmpfile_awrunload, AWRWH_FILE_LCC.c_dmpfile_compress, AWRWH_FILE_LCC.c_dmpfile_archive, AWRWH_FILE_LCC.c_dmpfile_dropfile) then
      raise_application_error(-20000,'Invalid action: '||p_action||'; p_dump_id='||p_dump_id);
    end if;

    COREMOD_API.lock_resource (
      P_RESOURCE_NAME => 'OPASAWRWHFILEPROCESSING',
      P_MODE => DBMS_LOCK.X_MODE,
      P_TIMEOUT => COREMOD_API.getconf('FILEPROCESSTIMEOUT',AWRWH_API.gMODNAME),
      P_RELEASE_ON_COMMIT => false) ;

    l_dmp_file:=get_file(p_dump_id,true);

    AWRWH_FILE_LCC.dmpfile_exec_action(p_dump_id,AWRWH_FILE_LCC.c_dmpfile_startprocess);
    case
      when p_action = AWRWH_FILE_LCC.c_dmpfile_awrload   then load_dump_to_awr_repository_i(p_dump_id);
      when p_action = AWRWH_FILE_LCC.c_dmpfile_awrunload then unload_dump_from_awr_repository_i(p_dump_id);
      when p_action = AWRWH_FILE_LCC.c_dmpfile_compress  then compress_file_i(p_dump_id);
      when p_action = AWRWH_FILE_LCC.c_dmpfile_archive   then archive_file_i(p_dump_id);
      when p_action = AWRWH_FILE_LCC.c_dmpfile_dropfile  then drop_file_i(p_dump_id);
    end case;
    AWRWH_FILE_LCC.dmpfile_exec_action(p_dump_id,AWRWH_FILE_LCC.c_dmpfile_finishprocess,p_action);
  exception
    when others then
      AWRWH_FILE_LCC.dmpfile_exec_action(p_dump_id,AWRWH_FILE_LCC.c_dmpfile_failprocess,p_action);
      coremod_log.log('AWRWH_FILE_API.exec_file_action'||chr(10)||sqlerrm||chr(10)||DBMS_UTILITY.FORMAT_ERROR_BACKTRACE);
      raise_application_error(-20000,'AWRWH_FILE_API.exec_file_action'||chr(10)||sqlerrm);
  end;

  /*import dump utility*/
  procedure load_dump_from_file(p_proj_id          awrwh_dumps.proj_id%type,
                                p_filename         awrwh_dumps.filename%type,
                                p_dump_description awrwh_dumps.dump_description%type,
                                p_loaded           awrwh_dumps.loaded%type default null,
                                p_dbid             awrwh_dumps.dbid%type default null,
                                p_min_snap_id      awrwh_dumps.min_snap_id%type default null,
                                p_max_snap_id      awrwh_dumps.max_snap_id%type default null,
                                p_min_snap_dt      awrwh_dumps.min_snap_dt%type default null,
                                p_max_snap_dt      awrwh_dumps.max_snap_dt%type default null,
                                p_db_description   awrwh_dumps.db_description%type default null,
                                p_dump_name        awrwh_dumps.dump_name%type default null)
  is
    l_filebody opas_files.file_contentb%type;
    l_d_off    number := 1;
    l_s_off    number := 1;
    l_bfile bfile := BFILENAME(COREMOD_API.getconf('WORKDIR',AWRWH_API.gMODNAME), p_filename);
    l_dump_id number;
    l_opas_file opas_files.file_id%type;
  begin

    DBMS_LOB.CREATETEMPORARY(l_filebody, false);
    DBMS_LOB.fileopen(l_bfile, DBMS_LOB.file_readonly);
    DBMS_LOB.LOADBLOBFROMFILE (
      dest_lob    => l_filebody,
      src_bfile   => l_bfile,
      amount      => DBMS_LOB.LOBMAXSIZE,
      dest_offset => l_d_off,
      src_offset  => l_s_off);

    AWRWH_FILE_API.register_dump_file (
      P_PROJ_ID => P_PROJ_ID,
      P_OWNER => COREMOD_API.gDefaultOwner,
      P_FILENAME => P_FILENAME,
      P_DUMP_NAME => p_dump_name,
      P_DESCRIPTION => p_dump_description,
      P_DUMP_ID => l_dump_id) ;
    AWRWH_FILE_API.set_file_security (
      P_DUMP_ID => l_dump_id,
      P_SOURCE_RETENTION => 0,
      P_PARSED_RETENTION => 0) ;

    store_file(l_dump_id,l_filebody);

    DBMS_LOB.FILECLOSE (l_bfile);

    UPDATE awrwh_dumps SET
      loaded         = p_loaded,
      dbid           = p_dbid,
      min_snap_id    = p_min_snap_id,
      max_snap_id    = p_max_snap_id,
      min_snap_dt    = p_min_snap_dt,
      max_snap_dt    = p_max_snap_dt,
      db_description = p_db_description,
	  dump_name      = p_dump_name,
      status         = AWRWH_FILE_LCC.c_dmpfilestate_dmploaded
     WHERE dump_id   = l_dump_id;

   end;

END AWRWH_FILE_API;
/
