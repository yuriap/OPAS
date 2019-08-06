CREATE OR REPLACE
PACKAGE BODY DB_GROWTH_EXPIMP AS

  gDBGTables COREMOD_EXPIMP.t_object_names :=
                         COREMOD_EXPIMP.t_object_names('DB_GROWTH_SEGS','DB_GROWTH_TABLES','DB_GROWTH_INDEXES','DB_GROWTH_LOBS');
  gProjList COREMOD_EXPIMP.t_object_names :=
                         COREMOD_EXPIMP.t_object_names('DB_GROWTH_PROJECTS');


  gTableList COREMOD_EXPIMP.t_object_names := gDBGTables multiset union distinct gProjList;

  g_lops_ind number;

  g_ImpTP_Project constant varchar2(100) := 'PROJ';

  procedure init AS
  BEGIN
    COREMOD_EXPIMP.init(COREMOD_EXPIMP.gTabPref, gTableList);
--    execute immediate 'create index ixei$ei$trc_files_1 on ei$trc_files(trc_file_id)';
  END init;

  procedure queue_export_proj (p_proj_ids    coremod_tasks.t_ids,
                               p_descr       opas_expimp_metadata.file_descr%type,
                               p_tq_id   out opas_task_queue.tq_id%type,
                               p_exp_sess_id out opas_expimp_sessions.sess_id%type)
  is
  begin
    p_tq_id:=COREMOD_TASKS.prep_execute_task (  P_TASKNAME => 'DB_GROWTH_EXP_PROJ', p_task_subname => null) ;

    COREMOD_EXPIMP.create_exp_session
    ( P_OWNER       => nvl(V('APP_USER'),COREMOD_API.gDefaultOwner),
      P_MODNAME     => DB_GROWTH_API.gMODNAME,
      P_IMPORT_PRC  => g_ImpTP_Project,
      P_FILE_DESCR  => p_descr,
      P_SESS_ID     => p_exp_sess_id) ;

    COREMOD_TASKS.set_task_param_list( p_tq_id => p_tq_id, p_name => 'B1', p_list_par => coremod_tasks.lsttochr(p_proj_ids));
    COREMOD_TASKS.set_task_param( p_tq_id => p_tq_id, p_name => 'B2', p_num_par => p_exp_sess_id);
    COREMOD_TASKS.queue_task ( p_tq_id => p_tq_id ) ;

    COREMOD_EXPIMP.queue_execution_session(p_exp_sess_id, p_tq_id);
  end;

  procedure queue_import_processing ( p_exp_sess_id      opas_expimp_sessions.sess_id%type,
                                      p_tq_id            out opas_task_queue.tq_id%type)
  is
  begin
    p_tq_id:=COREMOD_TASKS.prep_execute_task (  P_TASKNAME => 'DB_GROWTH_IMP_PROCESSING', p_task_subname => null) ;

    COREMOD_TASKS.set_task_param( p_tq_id => p_tq_id, p_name => 'B1', p_num_par => p_exp_sess_id);
    COREMOD_TASKS.set_task_param( p_tq_id => p_tq_id, p_name => 'B2', p_num_par => -1); -- for future use
    COREMOD_TASKS.queue_task ( p_tq_id => p_tq_id ) ;

    COREMOD_EXPIMP.queue_execution_session(p_exp_sess_id, p_tq_id);
  end;

  procedure load_proj_tables_i(p_proj_ids    coremod_tasks.t_ids, p_exp_sess_id opas_expimp_sessions.sess_id%type)
  is
  begin
    for k in 1..p_proj_ids.count loop
      for i in 1..gTableList.count loop
        execute immediate 'insert into '||COREMOD_EXPIMP.gTabPref||gTableList(i)||' select x.*, null new_id from '||gTableList(i)||' x where proj_id=:a1' using p_proj_ids(k);
      end loop;
    end loop;
  end;

  procedure load_comm_tables_to_ei(p_exp_sess_id opas_expimp_sessions.sess_id%type)
  is
  begin
    --execute immediate 'insert into EI$OPAS_REPORTS select x.*, null new_id from OPAS_REPORTS x where report_id in (select report_id from EI$AWRWH_REPORTS)';
    --execute immediate 'insert into EI$OPAS_REPORTS_PARS select x.*, null new_id from OPAS_REPORTS_PARS x where report_id in (select report_id from EI$AWRWH_REPORTS)';
    --execute immediate 'insert into EI$OPAS_FILES select x.*, null new_id from OPAS_FILES x where file_id in (select file_content from EI$TRC_FILES where file_content is not null)';
    --execute immediate 'insert into EI$OPAS_FILES select x.*, null new_id from OPAS_FILES x where file_id in (select report_content from EI$TRC_FILES where report_content is not null)';
    --execute immediate 'insert into EI$OPAS_QRY_CACHE select x.*, null new_id from OPAS_QRY_CACHE x where sql_id in (select sql_id from EI$ASHA_CUBE where sql_id is not null)';
    null;
  end;

  procedure export_i     (p_proj_ids    coremod_tasks.t_ids,
                          p_exp_sess_id opas_expimp_sessions.sess_id%type)
  is
    l_module varchar2(100);
  begin
    l_module := 'Export DB Growth Tracking Project';

    COREMOD_API.init_longops(l_module,'section','sections',3,g_lops_ind);
    COREMOD_API.start_longops_section ( l_module, 'Preparing export structures');
    --==================================================
    COREMOD_EXPIMP.start_execution_session(p_exp_sess_id);
    --==================================================
    COREMOD_API.end_longops_section(1,g_lops_ind);
    COREMOD_API.start_longops_section ( l_module, 'Extract data for export');
    --==================================================

    load_proj_tables_i(p_proj_ids, p_exp_sess_id);

    load_comm_tables_to_ei(p_exp_sess_id);

    COREMOD_EXPIMP.load_expimp_tables_to_ei(p_exp_sess_id);
    commit;
    --==================================================
    COREMOD_API.end_longops_section(1,g_lops_ind);
    COREMOD_API.start_longops_section ( l_module, 'Export data by DataPump');
    --==================================================
    COREMOD_EXPIMP.execute_export_session(p_exp_sess_id);
    --==================================================
    COREMOD_API.end_longops_section(1,g_lops_ind);
    --==================================================
    commit;
    COREMOD_EXPIMP.finish_export_session(p_exp_sess_id,COREMOD_EXPIMP.gstFINISHED);
  exception
    when others then
      rollback;
      coremod_log.log('Error in DB_GROWTH_EXPIMP.export_i: sess_id: '||p_exp_sess_id||'; '||sqlerrm);
      coremod_log.log(DBMS_UTILITY.FORMAT_ERROR_STACK);
      COREMOD_EXPIMP.finish_export_session(p_exp_sess_id,COREMOD_EXPIMP.gstFAILED);
      raise;
  end;

  procedure export_proj (p_proj_ids    coremod_tasks.t_ids,  p_exp_sess_id opas_expimp_sessions.sess_id%type)
  is
  begin
    export_i(p_proj_ids, p_exp_sess_id);
  end;

  procedure import_project(p_proj_id db_growth_projects.proj_id%type)
  is
  begin
    if p_proj_id = -1 then
      --create new project
      execute immediate q'[
      declare
        l_proj ei$db_growth_projects%rowtype;
      begin
        for i in (select * from ei$db_growth_projects) loop

          INSERT INTO db_growth_projects
                    ( proj_name, owner, created, status, proj_note, keep_forever, is_public, priority)
             VALUES ( i.proj_name || ' (imported)', COREMOD_API.gDefaultOwner, i.created, 'PREPARING' /*i.status*/ , i.proj_note, 'Y' /*l_proj.keep_forever*/, i.is_public, nvl(i.priority,100))
          returning proj_id into l_proj.PROJ_ID;

          update ei$db_growth_projects set new_id = l_proj.PROJ_ID where proj_id=i.proj_id;
        end loop;
      end;]';
    else
      raise_application_error(-20000,'Invalid project ID for import: '||p_proj_id); -- only new project allowed
    end if;
  end;

  procedure import_data(p_proj_id db_growth_projects.proj_id%type, p_exp_sess_id    opas_expimp_sessions.sess_id%type) is
  begin
    execute immediate q'[
      declare
        l_proj_id number;
      begin
        for i in (select * from  ei$db_growth_projects) loop
          l_proj_id := i.new_id;

          INSERT INTO db_growth_segs ( proj_id, last_updated, owner, segment_type, segment_name, partition_name, tablespace_name, size_b)
            select l_proj_id, last_updated, owner, segment_type, segment_name, partition_name, tablespace_name, size_b
            from ei$db_growth_segs
            where proj_id = i.proj_id;

          INSERT INTO db_growth_tables ( proj_id, last_updated, owner, table_name, tablespace_name, cluster_name, iot_name, status, partitioned,
              iot_type, temporary, secondary, nested, cluster_owner, compression, compress_for, segment_created)
            select l_proj_id, last_updated, owner, table_name, tablespace_name, cluster_name, iot_name, status, partitioned,
              iot_type, temporary, secondary, nested, cluster_owner, compression, compress_for, segment_created
            from ei$db_growth_tables
            where proj_id = i.proj_id;

          INSERT INTO db_growth_indexes ( proj_id, last_updated, owner, index_name, index_type, table_owner, table_name, table_type, compression,
              prefix_length, tablespace_name, include_column, status, partitioned, temporary, secondary, funcidx_status, join_index, dropped, segment_created)
            select l_proj_id, last_updated, owner, index_name, index_type, table_owner, table_name, table_type, compression,
              prefix_length, tablespace_name, include_column, status, partitioned, temporary, secondary, funcidx_status, join_index, dropped, segment_created
            from ei$db_growth_indexes
            where proj_id = i.proj_id;

          INSERT INTO db_growth_lobs ( proj_id, last_updated, owner, table_name, column_name, segment_name, tablespace_name, index_name, chunk,
              compression, deduplication, in_row, partitioned, securefile, segment_created)
            select l_proj_id, last_updated, owner, table_name, column_name, segment_name, tablespace_name, index_name, chunk,
              compression, deduplication, in_row, partitioned, securefile, segment_created
            from ei$db_growth_lobs
            where proj_id = i.proj_id;
        end loop;
      end;
      ]';
  end;

  procedure import_processing (p_exp_sess_id    opas_expimp_sessions.sess_id%type,
                               p_proj_id        db_growth_projects.proj_id%type)
  is
    l_module      varchar2(100) := 'Process imported file';
    l_ei_metadata OPAS_EXPIMP_METADATA%rowtype;
    l_proj_id     db_growth_projects.proj_id%type:=p_proj_id; -- -1: project mode, all traces projects preserved,  >0: either project or file mode, all goes to the specified project
  begin
    COREMOD_API.init_longops(l_module,'section','sections',2,g_lops_ind);
    COREMOD_API.start_longops_section ( l_module, 'Analyzing import structures');
    --==================================================
    COREMOD_EXPIMP.continue_execution_session(p_exp_sess_id);
    --==================================================
    COREMOD_API.end_longops_section(1,g_lops_ind);
    COREMOD_API.start_longops_section ( l_module, 'Process imported data');
    --==================================================
    select * into l_ei_metadata from OPAS_EXPIMP_METADATA where sess_id=p_exp_sess_id;

    COREMOD_EXPIMP.import_common_data_from_ei();

    if l_ei_metadata.import_prc=g_ImpTP_Project and p_proj_id = -1 then
      import_project(l_proj_id);
      import_data(l_proj_id, p_exp_sess_id);
    else
      raise_application_error(-20000,'Unknown import entry point procedure: '||l_ei_metadata.import_prc);
    end if;

    DB_GROWTH_API.refresh_matviews();

    commit;
    --==================================================
    COREMOD_API.end_longops_section(1,g_lops_ind);
    COREMOD_EXPIMP.finish_import_session (  P_EXP_SESS_ID => p_exp_sess_id, P_STATUS => COREMOD_EXPIMP.gstFINISHED) ;
    if COREMOD_API.getconf('LOGGING_LEVEL',COREMOD_API.gMODNAME)!='DEBUG' then
      COREMOD_EXPIMP.cleanup_expimp_session (P_EXP_SESS_ID => p_exp_sess_id, p_inlcuding_metadata => false );
    end if;
  exception
    when others then
      rollback;
      coremod_log.log('Error in DB_GROWTH_EXPIMP.import_processing: sess_id: '||p_exp_sess_id||'; '||sqlerrm);
      coremod_log.log(DBMS_UTILITY.FORMAT_ERROR_STACK);
      COREMOD_EXPIMP.finish_import_session (  P_EXP_SESS_ID => p_exp_sess_id, P_STATUS => COREMOD_EXPIMP.gstFAILED) ;
      raise_application_error(-20000,'Error in DB_GROWTH_EXPIMP.import_processing: sess_id: '||p_exp_sess_id||'; '||sqlerrm);
  end;

END DB_GROWTH_EXPIMP;
/
