CREATE OR REPLACE
PACKAGE BODY COREMOD_EXPIMP AS

  g_Lock_Handle     varchar2(100);
  g_lops_ind        number;

  --session parameters
  procedure set_param(p_sess_id opas_expimp_params.sess_id%type,
                      p_par_name opas_expimp_params.par_name%type,
                      p_par_value opas_expimp_params.par_value%type)
  is
  begin
    merge into opas_expimp_params t
    using (select p_sess_id sess_id, p_par_name par_name, p_par_value par_value from dual) s
    on (t.sess_id=s.sess_id and t.par_name=s.par_name)
    when matched then update set t.par_value=s.par_value
    when not matched then insert (t.sess_id,t.par_name,t.par_value) values (s.sess_id,s.par_name,s.par_value);
  end;

  function  get_param(p_sess_id          opas_expimp_params.sess_id%type,
                      p_par_name         opas_expimp_params.par_name%type) return opas_expimp_params.par_value%type
  is
    l_res opas_expimp_params.par_value%type;
  begin
    select par_value into l_res from opas_expimp_params where sess_id=p_sess_id and par_name=p_par_name;
    return l_res;
  exception
    when no_data_found then return null;
  end;


  procedure init_file_name_for_export(p_modname opas_expimp_metadata.modname%type,
                                      p_file_name out opas_files.file_name%type)
  is
  begin
    p_file_name := 'OPASDATAEXCH_'||p_modname||'_'||DBMS_RANDOM.STRING('X',4);
  end;

  procedure create_ei_table(p_table varchar2, p_prefix varchar2)
  is
  begin
    execute immediate 'create table '||p_prefix||p_table||' as select * from '||p_table||' where 1=2';
    execute immediate 'alter table '||p_prefix||p_table||' add new_id number';
  end;

  procedure drop_ei_table(p_table varchar2, p_prefix varchar2)
  is
  begin
    execute immediate 'drop table '||p_prefix||p_table;
  exception
    when others then null;
  end;

  procedure init(p_prefix varchar2, p_table_lst t_object_names)
  is
  begin
    for i in 1..p_table_lst.count loop
      drop_ei_table(p_table_lst(i),p_prefix);
    end loop;
    for i in 1..p_table_lst.count loop
      create_ei_table(p_table_lst(i),p_prefix);
    end loop;
  end;

  procedure init AS
  BEGIN
    init(gTabPref, gTableList);
  END init;

  procedure set_status_a(p_exp_sess_id opas_expimp_sessions.sess_id%type,
                         p_status      opas_expimp_sessions.status%type)
  is
    pragma autonomous_transaction;
  begin
    update opas_expimp_sessions set status=p_status where sess_id=p_exp_sess_id;
    commit;
  end;

  procedure set_status(p_exp_sess_id opas_expimp_sessions.sess_id%type,
                       p_status      opas_expimp_sessions.status%type,
                       p_autonomous  boolean default false)
  is
  begin
    if not p_autonomous then
      update opas_expimp_sessions set status=p_status where sess_id=p_exp_sess_id;
    else
      set_status_a(p_exp_sess_id, p_status);
    end if;
  end;

  procedure truncate_ei_tables(p_prefix varchar2)
  is
    l_names t_object_names;
  begin
    select table_name bulk collect into l_names from user_tables where table_name like p_prefix||'%';
    for i in 1..l_names.count loop
      execute immediate 'truncate table '||l_names(i)||' drop storage';
    end loop;
  end;

  procedure datapump_export_ei_tables(p_filename opas_files.file_name%type)
  is
    l_dp_handle       NUMBER;
    l_last_job_state  VARCHAR2(30) := 'UNDEFINED';
    l_job_state       VARCHAR2(30) := 'UNDEFINED';
    l_sts             KU$_STATUS;
  begin

    l_dp_handle := DBMS_DATAPUMP.open(
      operation   => 'EXPORT',
      job_mode    => 'TABLE',
      remote_link => NULL,
      job_name    => 'OPAS_EXPORT'||'_'||DBMS_RANDOM.STRING('X',6),
      version     => COREMOD_API.getconf(P_KEY => 'EXPIMPVER',P_MODULE => COREMOD_API.gMODNAME));

    DBMS_DATAPUMP.add_file(
      handle    => l_dp_handle,
      filename  => p_filename||'.DMP',
      directory => COREMOD_API.getconf(P_KEY => 'EXPIMPDIR',P_MODULE => COREMOD_API.gMODNAME),
      reusefile => 1
      );

    DBMS_DATAPUMP.add_file(
      handle    => l_dp_handle,
      filename  => p_filename||'.LOG',
      directory => COREMOD_API.getconf(P_KEY => 'EXPIMPDIR',P_MODULE => COREMOD_API.gMODNAME),
      filetype  => DBMS_DATAPUMP.KU$_FILE_TYPE_LOG_FILE);

    DBMS_DATAPUMP.metadata_filter(
      handle => l_dp_handle,
      name   => 'NAME_EXPR',
      value  => 'like ''EI$%''');

    DBMS_DATAPUMP.start_job(l_dp_handle);

    --DBMS_DATAPUMP.detach(l_dp_handle);
    DBMS_DATAPUMP.WAIT_FOR_JOB (
      handle      => l_dp_handle,
      job_state   => l_job_state);
  exception
    when others then
      coremod_log.log('Error in COREMOD_EXPIMP.datapump_export_ei_tables: '||sqlerrm);
      declare
        l_status ku$_Status;
        l_js     varchar2(1000);
      begin
        DBMS_DATAPUMP.GET_STATUS(
          handle    => l_dp_handle,
          mask      => DBMS_DATAPUMP.KU$_STATUS_WIP + DBMS_DATAPUMP.KU$_STATUS_JOB_DESC + DBMS_DATAPUMP.KU$_STATUS_JOB_STATUS + DBMS_DATAPUMP.KU$_STATUS_JOB_ERROR,
          job_state => l_js,
          status    => l_status);
        coremod_log.log('Error in COREMOD_EXPIMP.datapump_export_ei_tables: DP job_state: '||l_js);
        for i in 1..l_status.error.count loop
          coremod_log.log('Error in COREMOD_EXPIMP.datapump_export_ei_tables: DP status: '||l_status.error(i).LogText);
        end loop;
      end;
      raise;
  end;

  procedure datapump_import_ei_tables(p_filename opas_files.file_name%type,
                                      p_sess_id opas_expimp_sessions.sess_id%type)
  is
    l_dp_handle       NUMBER;
    l_last_job_state  VARCHAR2(30) := 'UNDEFINED';
    l_job_state       VARCHAR2(30) := 'UNDEFINED';
    l_sts             KU$_STATUS;
  begin
    l_dp_handle := DBMS_DATAPUMP.open(
      operation   => 'IMPORT',
      job_mode    => 'TABLE',
      remote_link => NULL,
      job_name    => 'OPAS_IMPORT'||'_'||DBMS_RANDOM.STRING('X',6),
      version     => COREMOD_API.getconf(P_KEY => 'EXPIMPVER',P_MODULE => COREMOD_API.gMODNAME));

    DBMS_DATAPUMP.add_file(
      handle    => l_dp_handle,
      filename  => p_filename,
      directory => COREMOD_API.getconf(P_KEY => 'EXPIMPDIR',P_MODULE => COREMOD_API.gMODNAME),
      reusefile => 1
      );

    DBMS_DATAPUMP.add_file(
      handle    => l_dp_handle,
      filename  => p_filename||'.LOG',
      directory => COREMOD_API.getconf(P_KEY => 'EXPIMPDIR',P_MODULE => COREMOD_API.gMODNAME),
      filetype  => DBMS_DATAPUMP.KU$_FILE_TYPE_LOG_FILE);

--    DBMS_DATAPUMP.metadata_filter(
--      handle => l_dp_handle,
--      name   => 'NAME_EXPR',
--      value  => 'like ''EI$%''');

    DBMS_DATAPUMP.SET_PARAMETER(
      handle => l_dp_handle,
      name   => 'TABLE_EXISTS_ACTION',
      value  => 'TRUNCATE');

   DBMS_DATAPUMP.METADATA_REMAP (
      handle      => l_dp_handle,
      name        => 'REMAP_SCHEMA',
      old_value   => nvl(upper(get_param(p_sess_id => datapump_import_ei_tables.p_sess_id, p_par_name => gparSOURCEUSER)),'OPAS45'),
      value       => user);

    DBMS_DATAPUMP.start_job(l_dp_handle);

    --DBMS_DATAPUMP.detach(l_dp_handle);
    DBMS_DATAPUMP.WAIT_FOR_JOB (
      handle      => l_dp_handle,
      job_state   => l_job_state);
  exception
    when others then
      coremod_log.log('Error in COREMOD_EXPIMP.datapump_import_ei_tables: '||sqlerrm);
      declare
        l_status ku$_Status;
        l_js     varchar2(1000);
      begin
        DBMS_DATAPUMP.GET_STATUS(
          handle    => l_dp_handle,
          mask      => DBMS_DATAPUMP.KU$_STATUS_WIP + DBMS_DATAPUMP.KU$_STATUS_JOB_DESC + DBMS_DATAPUMP.KU$_STATUS_JOB_STATUS + DBMS_DATAPUMP.KU$_STATUS_JOB_ERROR,
          job_state => l_js,
          status    => l_status);
        coremod_log.log('Error in COREMOD_EXPIMP.datapump_import_ei_tables: DP job_state: '||l_js);
        for i in 1..l_status.error.count loop
          coremod_log.log('Error in COREMOD_EXPIMP.datapump_import_ei_tables: DP status: '||l_status.error(i).LogText);
        end loop;
      end;
      raise;
  end;

  procedure create_exp_session(p_owner        opas_expimp_sessions.owner%type,
                               p_modname      opas_expimp_metadata.modname%type,
                               p_import_prc   opas_expimp_metadata.import_prc%type,
                               p_file_descr   opas_expimp_metadata.file_descr%type,
                               p_sess_id  out opas_expimp_sessions.sess_id%type)
  is
  begin
    INSERT INTO opas_expimp_sessions ( tq_id,  expimp_file, created,  owner, sess_type, status)
       VALUES (null, null, default, default, 'EXP', default) returning sess_id into p_sess_id;
    INSERT INTO opas_expimp_metadata ( sess_id, modname, import_prc, file_descr, src_version, src_core_version)
       VALUES (p_sess_id, p_modname, p_import_prc, p_file_descr, COREMOD_API.getmodver(p_modname), COREMOD_API.getmodver(COREMOD_API.gMODNAME));
  end;

  procedure create_imp_session(p_owner        opas_expimp_sessions.owner%type,
                               p_expimp_file  opas_expimp_sessions.expimp_file%type,
                               p_sess_id  out opas_expimp_sessions.sess_id%type)
  is
  begin
    INSERT INTO opas_expimp_sessions ( tq_id,  expimp_file, created,  owner, sess_type, status)
       VALUES (null, p_expimp_file, default, p_owner, 'IMP', default) returning sess_id into p_sess_id;
    INSERT INTO opas_expimp_metadata ( sess_id, modname, import_prc, file_descr, src_version)
       VALUES (p_sess_id, null, null, null, null);
  end;


  procedure queue_execution_session(p_exp_sess_id opas_expimp_sessions.sess_id%type,
                                    p_tq_id       opas_expimp_sessions.tq_id%type)
  is
  begin
    update opas_expimp_sessions set tq_id = p_tq_id where sess_id = p_exp_sess_id;
    set_status(p_exp_sess_id, gstINQUEUE);
  end;

  procedure discard_staged_session(p_exp_sess_id opas_expimp_sessions.sess_id%type)
  is
  begin
    update opas_expimp_sessions set status = gstFAILED where sess_id = p_exp_sess_id and status=gstNEXTSTAGE;
  end;

  procedure start_execution_session(p_exp_sess_id opas_expimp_sessions.sess_id%type)
  is
    l_cnt number;
    l_status opas_expimp_sessions.status%type;
  begin
    select count(1) into l_cnt from opas_expimp_sessions where status=gstNEXTSTAGE;
    if l_cnt > 0 then raise_application_error(-20000,'Pending import session exists'); end if;

    select status into l_status from opas_expimp_sessions where sess_id=p_exp_sess_id;
    if l_status <> gstINQUEUE then raise_application_error(-20000,'Session in a wrong state: sess, status: '||p_exp_sess_id||', '||l_status); end if;

    set_status(p_exp_sess_id, gstEXECUTING, true);

    g_Lock_Handle := COREMOD_API.lock_resource (
      P_RESOURCE_NAME => 'OPASEXPIMP',
      P_MODE => 6,
      P_TIMEOUT => 3600,
      P_RELEASE_ON_COMMIT => false) ;

    truncate_ei_tables(gTabPref);
  exception
    when others then
      set_status(p_exp_sess_id, gstFAILED, true);
      raise;
  end;

  procedure continue_execution_session(p_exp_sess_id opas_expimp_sessions.sess_id%type)
  is
    l_status opas_expimp_sessions.status%type;
  begin
    select status into l_status from opas_expimp_sessions where sess_id=p_exp_sess_id;
--    if l_status <> gstNEXTSTAGE then raise_application_error(-20000,'Import session in a wrong state: sess, status: '||p_exp_sess_id||', '||l_status); end if;

    if l_status <> gstINQUEUE then
      raise_application_error(-20000,'continue_execution_session: Invalid status for session:status '||p_exp_sess_id||':'||l_status);
    end if;

    set_status(p_exp_sess_id, gstEXECUTING, true);

    g_Lock_Handle := COREMOD_API.lock_resource (
      P_RESOURCE_NAME => 'OPASEXPIMP',
      P_MODE => 6,
      P_TIMEOUT => 3600,
      P_RELEASE_ON_COMMIT => false) ;

  exception
    when others then
      set_status(p_exp_sess_id, gstFAILED, true);
      raise;
  end;

  procedure execute_export_session(p_exp_sess_id opas_expimp_sessions.sess_id%type)
  is
    l_file    opas_files.file_id%type;
    l_modname opas_expimp_metadata.modname%type;
    l_owner   opas_expimp_sessions.owner%type;
    l_exp_file_name opas_files.file_name%type;
  begin
    select owner,modname into l_owner, l_modname from opas_expimp_sessions s, opas_expimp_metadata m where s.sess_id=m.sess_id and s.sess_id=p_exp_sess_id;
    init_file_name_for_export(l_modname,l_exp_file_name);
    COREFILE_API.remove_file_from_fs(l_exp_file_name||'.DMP', COREMOD_API.getconf(P_KEY => 'EXPIMPDIR',P_MODULE => COREMOD_API.gMODNAME));
    datapump_export_ei_tables(l_exp_file_name);
    --zip file
    --load to opas_files and return ID
    l_file := COREFILE_API.create_file(P_MODNAME => l_modname,
                                       P_FILE_TYPE => 'OPAS Exp/Imp file',
                                       P_FILE_NAME => l_exp_file_name||'.DMP.LZ',
                                       P_MIMETYPE => 'APPLICATION/OCTET-STREAM',
                                       P_OWNER => l_owner);
    COREFILE_API.get_file_from_fs(l_file,l_exp_file_name||'.DMP', COREMOD_API.getconf(P_KEY => 'EXPIMPDIR',P_MODULE => COREMOD_API.gMODNAME), p_compress => true);
    COREFILE_API.remove_file_from_fs(l_exp_file_name||'.DMP', COREMOD_API.getconf(P_KEY => 'EXPIMPDIR',P_MODULE => COREMOD_API.gMODNAME));
    update opas_expimp_sessions set expimp_file=l_file where sess_id = p_exp_sess_id;
    commit;
    truncate_ei_tables(gTabPref);
    --set_status(p_exp_sess_id, gstFINISHED, true);
    --COREMOD_API.release_resource (  P_HANDLE => g_Lock_Handle) ;
  exception
    when others then
      coremod_log.log('Error in COREMOD_EXPIMP.execute_export_session: sess_id: '||p_exp_sess_id||'; '||sqlerrm);
      coremod_log.log(DBMS_UTILITY.FORMAT_ERROR_STACK);
      COREFILE_API.remove_file_from_fs(l_exp_file_name||'.DMP', COREMOD_API.getconf(P_KEY => 'EXPIMPDIR',P_MODULE => COREMOD_API.gMODNAME));
      --set_status(p_exp_sess_id, gstFAILED, true);
      --COREMOD_API.release_resource (  P_HANDLE => g_Lock_Handle) ;
      raise_application_error(-20000,'Error in COREMOD_EXPIMP.execute_export_session: sess_id: '||p_exp_sess_id||'; '||sqlerrm);
  end;

  procedure finish_export_session(p_exp_sess_id opas_expimp_sessions.sess_id%type, p_status varchar2)
  is
  begin
    if p_status in (gstFINISHED,gstFAILED) then
      set_status(p_exp_sess_id, p_status, true);
      truncate_ei_tables(gTabPref);
      COREMOD_API.release_resource (  P_HANDLE => g_Lock_Handle) ;
    else
      raise_application_error(-20000,'finish_export_session: Invalid session:status '||p_exp_sess_id||':'||p_status);
    end if;
  end;


  procedure queue_import_file(p_expimp_file opas_expimp_sessions.expimp_file%type,
                              p_tq_id   out opas_task_queue.tq_id%type,
                              p_exp_sess_id out opas_expimp_sessions.sess_id%type)
  is
    l_proj asha_cube_projects%rowtype;
  begin
    p_tq_id:=COREMOD_TASKS.prep_execute_task (  P_TASKNAME => 'OPAS_UPLOAD_IMP_FILE', p_task_subname => null) ;

    COREMOD_EXPIMP.create_imp_session
    ( p_owner       => nvl(V('APP_USER'),COREMOD_API.gDefaultOwner),
      P_EXPIMP_FILE => p_expimp_file,
      P_SESS_ID     => p_exp_sess_id) ;

    COREMOD_TASKS.set_task_param( p_tq_id => p_tq_id, p_name => 'B1', p_num_par => p_exp_sess_id);
    COREMOD_TASKS.queue_task ( p_tq_id => p_tq_id ) ;

    COREMOD_EXPIMP.queue_execution_session(p_exp_sess_id, p_tq_id);
  end;

  procedure import_file (p_exp_sess_id opas_expimp_sessions.sess_id%type)
  is
    l_module varchar2(100) := 'Import file';
  begin
    COREMOD_API.init_longops(l_module,'section','sections',2,g_lops_ind);
    COREMOD_API.start_longops_section ( l_module, 'Preparing import structures');
    --==================================================
    COREMOD_EXPIMP.start_execution_session(p_exp_sess_id);
    --==================================================
    COREMOD_API.end_longops_section(1,g_lops_ind);
    COREMOD_API.start_longops_section ( l_module, 'Import data by DataPump');
    --==================================================
    COREMOD_EXPIMP.execute_import_session(p_exp_sess_id);
    --==================================================
    COREMOD_API.end_longops_section(1,g_lops_ind);
    commit;
    COREMOD_EXPIMP.finish_import_file_session(p_exp_sess_id,COREMOD_EXPIMP.gstNEXTSTAGE);
  exception
    when others then
      rollback;
      coremod_log.log('Error in COREMOD_EXPIMP.import_file: sess_id: '||p_exp_sess_id||'; '||sqlerrm);
      coremod_log.log(DBMS_UTILITY.FORMAT_ERROR_STACK);
      COREMOD_EXPIMP.finish_import_file_session(p_exp_sess_id,COREMOD_EXPIMP.gstFAILED);
      raise;
  end;

  procedure execute_import_session(p_exp_sess_id opas_expimp_sessions.sess_id%type)
  is
    l_file          opas_files.file_contentb%type;
    l_modname       opas_expimp_metadata.modname%type;
    l_owner         opas_expimp_sessions.owner%type;
    l_expimp_file   opas_expimp_sessions.expimp_file%type;
    l_ei_metadata   OPAS_EXPIMP_METADATA%rowtype;
    l_compat_mod number;
    l_compat_core number;
    l_exp_file_name opas_files.file_name%type;
  begin
    select s.owner, m.modname, s.expimp_file, f.file_name, f.file_contentb
      into l_owner, l_modname, l_expimp_file, l_exp_file_name, l_file
      from opas_expimp_sessions s,
           opas_expimp_metadata m,
           opas_files f
     where s.sess_id=m.sess_id
       and s.sess_id=p_exp_sess_id
       and s.expimp_file=f.file_id;

    COREFILE_API.remove_file_from_fs(l_exp_file_name, COREMOD_API.getconf(P_KEY => 'EXPIMPDIR',P_MODULE => COREMOD_API.gMODNAME));
    COREFILE_API.put_file_to_fs (P_BLOB => l_file, P_FILENAME => l_exp_file_name, P_DIR => COREMOD_API.getconf(P_KEY => 'EXPIMPDIR',P_MODULE => COREMOD_API.gMODNAME), p_uncompress => true) ;

    datapump_import_ei_tables(l_exp_file_name, p_exp_sess_id);

    COREFILE_API.remove_file_from_fs(l_exp_file_name, COREMOD_API.getconf(P_KEY => 'EXPIMPDIR',P_MODULE => COREMOD_API.gMODNAME));

    execute immediate 'update ei$opas_expimp_metadata set sess_id=:a1' using p_exp_sess_id;
    execute immediate 'update ei$opas_expimp_params set sess_id=:a1'   using p_exp_sess_id;
    execute immediate 'merge into opas_expimp_metadata t
    using (select * from ei$opas_expimp_metadata where sess_id=:a1) s
    on (t.sess_id=s.sess_id)
    when matched then update set
      t.modname     = s.modname,
      t.import_prc  = s.import_prc,
      t.file_descr  = s.file_descr,
      t.src_version = s.src_version,
      t.src_core_version = s.src_core_version' using p_exp_sess_id;

    execute immediate 'INSERT INTO opas_expimp_params (sess_id,par_name,par_value) select sess_id,par_name,par_value from ei$opas_expimp_params';

    select * into l_ei_metadata from opas_expimp_metadata where sess_id=p_exp_sess_id;

    select count(1) into l_compat_mod from opas_expimp_compat where modname=l_ei_metadata.modname and src_version=l_ei_metadata.src_version and trg_version=COREMOD_API.getmodver(l_ei_metadata.modname);
    if l_compat_mod=0 then
      raise_application_error(-20000,'Data being imported is incompatible with current structure: sess:module:source:target '||p_exp_sess_id||':'||l_ei_metadata.modname||':'||l_ei_metadata.src_version||':'||COREMOD_API.getmodver(l_ei_metadata.modname));
    end if;

    select count(1) into l_compat_core from opas_expimp_compat where modname=COREMOD_API.gMODNAME and src_version=l_ei_metadata.src_core_version and trg_version=COREMOD_API.getmodver(COREMOD_API.gMODNAME);
    if l_compat_core=0 then
      raise_application_error(-20000,'Data being imported is incompatible with current structure: sess:module:source:target '||p_exp_sess_id||':'||COREMOD_API.gMODNAME||':'||l_ei_metadata.src_core_version||':'||COREMOD_API.getmodver(COREMOD_API.gMODNAME));
    end if;

    commit;
    --set_status(p_exp_sess_id, gstNEXTSTAGE, true);
    --COREMOD_API.release_resource (  P_HANDLE => g_Lock_Handle) ;
  exception
    when others then
      rollback;
      coremod_log.log('Error in COREMOD_EXPIMP.execute_import_session: sess_id: '||p_exp_sess_id||'; '||sqlerrm);
      coremod_log.log(DBMS_UTILITY.FORMAT_ERROR_STACK);
      --set_status(p_exp_sess_id, gstFAILED, true);
      --COREMOD_API.release_resource (  P_HANDLE => g_Lock_Handle) ;
      raise_application_error(-20000,'Error in COREMOD_EXPIMP.execute_import_session: sess_id: '||p_exp_sess_id||'; '||sqlerrm);
  end;

  procedure finish_import_file_session(p_exp_sess_id opas_expimp_sessions.sess_id%type, p_status varchar2)
  is
  begin
    if p_status in (gstNEXTSTAGE,gstFAILED) then
      set_status(p_exp_sess_id, p_status, true);
      COREMOD_API.release_resource (  P_HANDLE => g_Lock_Handle) ;
    else
      raise_application_error(-20000,'finish_import_file_session: Invalid session:status '||p_exp_sess_id||':'||p_status);
    end if;
  end;

  procedure finish_import_session(p_exp_sess_id opas_expimp_sessions.sess_id%type, p_status varchar2)
  is
  begin
    if p_status in (gstFINISHED,gstFAILED) then
      set_status(p_exp_sess_id, p_status, true);
      COREMOD_API.release_resource (  P_HANDLE => g_Lock_Handle) ;
    else
      raise_application_error(-20000,'finish_import_session: Invalid session:status '||p_exp_sess_id||':'||p_status);
    end if;
  end;

  procedure cleanup_expimp_session(p_exp_sess_id opas_expimp_sessions.sess_id%type, p_inlcuding_metadata boolean default true)
  is
  begin
    for i in (select s.expimp_file, s.sess_id from opas_expimp_sessions s
               where s.sess_id=p_exp_sess_id)
    loop
      if p_inlcuding_metadata then
        delete from opas_expimp_sessions where sess_id=i.sess_id;
      else
        update opas_expimp_sessions set expimp_file=null where sess_id=p_exp_sess_id;
      end if;

      if i.expimp_file is not null then
        COREFILE_API.delete_file (  P_FILE_ID => i.expimp_file) ;
      end if;
    end loop;
    truncate_ei_tables(gTabPref);
  end;

  procedure cleanup_expimp_sess(p_modname        opas_expimp_metadata.modname%type,
                                p_retention_days number)
  is
    l_cnt number := 0;
  begin
    coremod_log.log('Exp/Imp: '||p_modname||' '||p_retention_days);
    for i in (select s.expimp_file, s.sess_id from opas_expimp_sessions s, opas_expimp_metadata m
               where s.sess_id=m.sess_id
                 and (
                      (created < sysdate - p_retention_days and m.modname=p_modname) or
                      (created < sysdate - 5/24/60 and status in (gstFAILED)) or
                      (created < sysdate - 20/24/60 and status in (gstNEXTSTAGE))
                     )
            )
    loop
      delete from opas_expimp_sessions where sess_id=i.sess_id;

      if i.expimp_file is not null then
        COREFILE_API.delete_file (  P_FILE_ID => i.expimp_file) ;
      end if;
      l_cnt:=l_cnt+1;
    end loop;
    commit;
    coremod_log.log('Exp/Imp '||l_cnt||' session(s) cleaned');
  exception
    when others then
      rollback;
      coremod_log.log('Error in COREMOD_EXPIMP.cleanup_expimp_sess: p_modname: '||p_modname||'; '||sqlerrm);
      coremod_log.log(DBMS_UTILITY.FORMAT_ERROR_STACK);
      raise_application_error(-20000,'Error in COREMOD_EXPIMP.cleanup_expimp_sess: p_modname: '||p_modname||'; '||sqlerrm);
  end;

  --commonly used procedures

  procedure import_common_data_from_ei
  is
  begin
    execute immediate '
      declare
        l_id number;
      begin
        for i in (select * from EI$OPAS_FILES s) loop
          INSERT INTO opas_files (modname,file_type,file_name,file_mimetype,file_contentb,file_contentc,created,owner)
                          values (i.modname,i.file_type,i.file_name,i.file_mimetype,i.file_contentb,i.file_contentc,i.created,COREMOD_API.gDefaultOwner)
                          returning file_id into l_id;
          update EI$OPAS_FILES set new_id=l_id where file_id=i.file_id;
        end loop;

        -- fix links to files  from reports
        update EI$OPAS_REPORTS t set report_content=(select new_id from EI$OPAS_FILES s where s.file_id=t.report_content);
        for i in (select * from EI$OPAS_REPORTS) loop
          INSERT INTO opas_reports (modname,tq_id,report_content,report_params_displ,parent_id,report_type)
                             values(i.modname,null,i.report_content,i.report_params_displ,null,i.report_type) returning report_id into l_id;
          update EI$OPAS_REPORTS set new_id=l_id where report_id=i.report_id;
        end loop;
        -- fix links to parent report
        update opas_reports t set t.parent_id=(select new_id from EI$OPAS_REPORTS i where i.report_id=(select parent_id from EI$OPAS_REPORTS s where t.report_id=s.new_id))
         where t.report_id in (select new_id from EI$OPAS_REPORTS where parent_id is not null);

        INSERT INTO opas_reports_pars (report_id,par_name,num_par,varchar_par,date_par)
        select (select new_id from EI$OPAS_REPORTS s where s.report_id=t.report_id) ,par_name,num_par,varchar_par,date_par from ei$opas_reports_pars t;

        merge into OPAS_QRY_CACHE t
          using (select * from EI$OPAS_QRY_CACHE) s
        on (t.sql_id=s.sql_id)
        when matched then update set
          t.hit_num=t.hit_num+s.hit_num+100
        when not matched then
         insert (t.sql_id,t.sql_text,t.created,t.hit_num)
         values (s.sql_id,s.sql_text,s.created,s.hit_num);
      end;';
  end;

  procedure load_expimp_tables_to_ei(p_exp_sess_id opas_expimp_sessions.sess_id%type)
  is
  begin
    execute immediate 'insert into EI$OPAS_EXPIMP_METADATA select x.*, null new_id from OPAS_EXPIMP_METADATA x where sess_id=:a1' using p_exp_sess_id;
    execute immediate 'insert into EI$OPAS_EXPIMP_PARAMS select x.*, null new_id from OPAS_EXPIMP_PARAMS x where sess_id=:a1' using p_exp_sess_id;
  end;
END COREMOD_EXPIMP;
/
