CREATE OR REPLACE
PACKAGE BODY ASHA_EXPIMP AS

  gCubeTables COREMOD_EXPIMP.t_object_names :=
                         COREMOD_EXPIMP.t_object_names('ASHA_CUBE','ASHA_CUBE_BLOCK','ASHA_CUBE_METRICS',
                                                       'ASHA_CUBE_REPORTS','ASHA_CUBE_SEG',
                                                       'ASHA_CUBE_SESS','ASHA_CUBE_SESS_PARS','ASHA_CUBE_SNAP_ASH',
                                                       'ASHA_CUBE_TIMELINE','ASHA_CUBE_TOP_SESS','ASHA_CUBE_UNKNOWN');
  gProjList COREMOD_EXPIMP.t_object_names :=
                         COREMOD_EXPIMP.t_object_names('ASHA_CUBE_PROJECTS');

  gTableList COREMOD_EXPIMP.t_object_names := gCubeTables multiset union distinct gProjList;

  g_lops_ind number;

  g_ImpTP_Cube    constant varchar2(100) := 'CUBE';
  g_ImpTP_Project constant varchar2(100) := 'PROJ';

  procedure init AS
  BEGIN
    COREMOD_EXPIMP.init(COREMOD_EXPIMP.gTabPref, gTableList);
  END init;

  procedure queue_export_cube (p_sess_ids    coremod_tasks.t_ids,
                               p_descr       opas_expimp_metadata.file_descr%type,
                               p_tq_id   out opas_task_queue.tq_id%type,
                               p_exp_sess_id out opas_expimp_sessions.sess_id%type)
  is
  begin
    p_tq_id:=COREMOD_TASKS.prep_execute_task (  P_TASKNAME => 'ASHA_EXP_CUBE', p_task_subname => null) ;

    COREMOD_EXPIMP.create_exp_session
    ( P_OWNER       => nvl(V('APP_USER'),COREMOD_API.gDefaultOwner),
      P_MODNAME     => ASHA_CUBE_API.gMODNAME,
      P_IMPORT_PRC  => g_ImpTP_Cube,
      P_FILE_DESCR  => p_descr,
      P_SESS_ID     => p_exp_sess_id) ;

    COREMOD_TASKS.set_task_param_list( p_tq_id => p_tq_id, p_name => 'B1', p_list_par => coremod_tasks.lsttochr(p_sess_ids));
    COREMOD_TASKS.set_task_param( p_tq_id => p_tq_id, p_name => 'B2', p_num_par => p_exp_sess_id);
    COREMOD_TASKS.queue_task ( p_tq_id => p_tq_id ) ;

    COREMOD_EXPIMP.queue_execution_session(p_exp_sess_id, p_tq_id);
  end;

  procedure queue_export_proj (p_proj_ids    coremod_tasks.t_ids,
                               p_descr       opas_expimp_metadata.file_descr%type,
                               p_tq_id   out opas_task_queue.tq_id%type,
                               p_exp_sess_id out opas_expimp_sessions.sess_id%type)
  is
  begin
    p_tq_id:=COREMOD_TASKS.prep_execute_task (  P_TASKNAME => 'ASHA_EXP_PROJ', p_task_subname => null) ;

    COREMOD_EXPIMP.create_exp_session
    ( P_OWNER       => nvl(V('APP_USER'),COREMOD_API.gDefaultOwner),
      P_MODNAME     => ASHA_CUBE_API.gMODNAME,
      P_IMPORT_PRC  => g_ImpTP_Project,
      P_FILE_DESCR  => p_descr,
      P_SESS_ID     => p_exp_sess_id) ;

    COREMOD_TASKS.set_task_param_list( p_tq_id => p_tq_id, p_name => 'B1', p_list_par => coremod_tasks.lsttochr(p_proj_ids));
    COREMOD_TASKS.set_task_param( p_tq_id => p_tq_id, p_name => 'B2', p_num_par => p_exp_sess_id);
    COREMOD_TASKS.queue_task ( p_tq_id => p_tq_id ) ;

    COREMOD_EXPIMP.queue_execution_session(p_exp_sess_id, p_tq_id);
  end;

  procedure queue_import_processing ( p_exp_sess_id      opas_expimp_sessions.sess_id%type,
                                      p_proj_id_to_merge asha_cube_projects.proj_id%type,
                                      p_tq_id        out opas_task_queue.tq_id%type)
  is
  begin
    p_tq_id:=COREMOD_TASKS.prep_execute_task (  P_TASKNAME => 'ASHA_IMP_PROCESSING', p_task_subname => null) ;

    COREMOD_TASKS.set_task_param( p_tq_id => p_tq_id, p_name => 'B1', p_num_par => p_exp_sess_id);
    COREMOD_TASKS.set_task_param( p_tq_id => p_tq_id, p_name => 'B2', p_num_par => nvl(p_proj_id_to_merge,-1));
    COREMOD_TASKS.queue_task ( p_tq_id => p_tq_id ) ;

    COREMOD_EXPIMP.queue_execution_session(p_exp_sess_id, p_tq_id);
  end;

  procedure load_cube_tables_i(p_sess_ids    coremod_tasks.t_ids, p_exp_sess_id opas_expimp_sessions.sess_id%type)
  is
  begin
    for j in 1..p_sess_ids.count loop
      for i in 1..gCubeTables.count loop
        execute immediate 'insert into '||COREMOD_EXPIMP.gTabPref||gTableList(i)||' select x.*, null new_id from '||gTableList(i)||' x where sess_id=:a1' using p_sess_ids(j);
      end loop;
    end loop;
  end;

  procedure load_proj_tables_i(p_proj_ids    coremod_tasks.t_ids, p_exp_sess_id opas_expimp_sessions.sess_id%type)
  is
    l_sess_ids    coremod_tasks.t_ids;
  begin
    for k in 1..p_proj_ids.count loop
      select sess_id bulk collect into l_sess_ids from asha_cube_sess where sess_proj_id=p_proj_ids(k);
      load_cube_tables_i(l_sess_ids, p_exp_sess_id);

      execute immediate 'insert into EI$ASHA_CUBE_REPORTS select x.*, null new_id from ASHA_CUBE_REPORTS x where sess_id is null and proj_id=:a1' using p_proj_ids(k);

      for i in 1..gProjList.count loop
        execute immediate 'insert into '||COREMOD_EXPIMP.gTabPref||gProjList(i)||' select x.*, null new_id from '||gProjList(i)||' x where proj_id=:a1' using p_proj_ids(k);
      end loop;
    end loop;
  end;

  procedure load_comm_tables_to_ei(p_exp_sess_id opas_expimp_sessions.sess_id%type)
  is
  begin
    --execute immediate 'insert into EI$OPAS_EXPIMP_METADATA select x.*, null new_id from OPAS_EXPIMP_METADATA x where sess_id=:a1' using p_exp_sess_id;
    execute immediate 'insert into EI$OPAS_REPORTS select x.*, null new_id from OPAS_REPORTS x where report_id in (select report_id from EI$ASHA_CUBE_REPORTS)';
    execute immediate 'insert into EI$OPAS_REPORTS_PARS select x.*, null new_id from OPAS_REPORTS_PARS x where report_id in (select report_id from EI$ASHA_CUBE_REPORTS)';
    execute immediate 'insert into EI$OPAS_FILES select x.*, null new_id from OPAS_FILES x where file_id in (select report_content from EI$OPAS_REPORTS)';
    execute immediate 'insert into EI$OPAS_QRY_CACHE select x.*, null new_id from OPAS_QRY_CACHE x where sql_id in (select sql_id from EI$ASHA_CUBE where sql_id is not null)';
  end;

  procedure export_i     (p_sess_ids    coremod_tasks.t_ids,
                          p_proj_ids    coremod_tasks.t_ids,
                          p_exp_sess_id opas_expimp_sessions.sess_id%type)
  is
    l_module varchar2(100);
  begin
    if p_sess_ids is not null then
      l_module := 'Export ASHA Cube';
    elsif p_proj_ids is not null then
      l_module := 'Export ASHA Project';
    end if;

    COREMOD_API.init_longops(l_module,'section','sections',3,g_lops_ind);
    COREMOD_API.start_longops_section ( l_module, 'Preparing export structures');
    --==================================================
    COREMOD_EXPIMP.start_execution_session(p_exp_sess_id);
    --==================================================
    COREMOD_API.end_longops_section(1,g_lops_ind);
    COREMOD_API.start_longops_section ( l_module, 'Extract data for export');
    --==================================================
    if p_sess_ids is not null then
      load_cube_tables_i(p_sess_ids, p_exp_sess_id);
    elsif p_proj_ids is not null then
      load_proj_tables_i(p_proj_ids, p_exp_sess_id);
    end if;
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
      coremod_log.log('Error in ASHA_EXPIMP.export_i: sess_id: '||p_exp_sess_id||'; '||sqlerrm);
      coremod_log.log(DBMS_UTILITY.FORMAT_ERROR_STACK);
      COREMOD_EXPIMP.finish_export_session(p_exp_sess_id,COREMOD_EXPIMP.gstFAILED);
      raise;
  end;

  procedure export_cube (p_sess_ids    coremod_tasks.t_ids,  p_exp_sess_id opas_expimp_sessions.sess_id%type)
  is
  begin
    export_i(p_sess_ids, null, p_exp_sess_id);
  end;

  procedure export_proj (p_proj_ids    coremod_tasks.t_ids,  p_exp_sess_id opas_expimp_sessions.sess_id%type)
  is
  begin
    export_i(null, p_proj_ids, p_exp_sess_id);
  end;

  procedure import_project(p_proj_id in asha_cube_sess.sess_proj_id%type)
  is
  begin
    if p_proj_id = -1 then
      --create new project
      execute immediate q'[
      declare
        l_proj ei$asha_cube_projects%rowtype;
      begin
        for i in (select * from ei$asha_cube_projects) loop

          INSERT INTO asha_cube_projects
                    ( proj_name, owner, created, status, proj_note, keep_forever, is_public, priority)
             VALUES ( i.proj_name || ' (imported)', COREMOD_API.gDefaultOwner, i.created, i.status, i.proj_note, 'Y' /*l_proj.keep_forever*/, i.is_public, nvl(i.priority,100)) returning proj_id into l_proj.PROJ_ID;

          update ei$asha_cube_projects set new_id = l_proj.PROJ_ID where proj_id=i.proj_id;
        end loop;
      end;]';
    elsif p_proj_id > 0 then
      --load into existing poject
      null;
    else
      raise_application_error(-20000,'Invalid project ID for import: '||p_proj_id);
    end if;
  end;

  procedure import_cube(p_proj_id asha_cube_sess.sess_proj_id%type, p_exp_sess_id    opas_expimp_sessions.sess_id%type) is
  begin
    execute immediate 'declare
        l_proj_id number;
      begin
        l_proj_id := :a1;
        update ei$asha_cube_sess set new_id=asha_sq_cube.nextval;

        for i in (select * from ei$asha_cube_projects where l_proj_id = -1) loop
          INSERT INTO asha_cube_sess
                    ( sess_id, sess_proj_id, sess_created, sess_retention_days, sess_status, sess_tq_id, sess_description, sess_tq_id_snap, parent_id)
               select new_id, i.new_id, sess_created, 0 /*sess_retention_days*/, sess_status, null, sess_description, null,
                      case when parent_id is not null then (select new_id from ei$asha_cube_sess i where i.sess_id=s.parent_id) else null end
                 from ei$asha_cube_sess s where sess_proj_id = i.proj_id;
          INSERT INTO asha_cube_reports (proj_id, report_id, sess_id, report_retention, report_note, created)
               select i.new_id,
                      (select new_id from EI$OPAS_REPORTS t where s.report_id=t.report_id),
                      (select new_id from ei$asha_cube_sess i where i.sess_id=s.sess_id), 0 /*report_retention*/, report_note, created
                 from ei$asha_cube_reports s where proj_id = i.proj_id;
        end loop;

        for i in (select * from asha_cube_projects where proj_id = l_proj_id) loop
          INSERT INTO asha_cube_sess
                    ( sess_id, sess_proj_id, sess_created, sess_retention_days, sess_status, sess_tq_id, sess_description, sess_tq_id_snap, parent_id)
               select new_id, i.proj_id, sess_created, 0 /*sess_retention_days*/, sess_status, null, sess_description, null,
                      case when parent_id is not null then (select new_id from ei$asha_cube_sess i where i.sess_id=s.parent_id) else null end
                 from ei$asha_cube_sess s;
          INSERT INTO asha_cube_reports (proj_id, report_id, sess_id, report_retention, report_note, created)
               select i.proj_id,
                      (select new_id from EI$OPAS_REPORTS t where s.report_id=t.report_id),
                      (select new_id from ei$asha_cube_sess i where i.sess_id=s.sess_id), 0 /*report_retention*/, report_note, created
                 from ei$asha_cube_reports s;
        end loop;

        INSERT INTO asha_cube_sess_pars ( sess_id, sess_par_nm, sess_par_val)
             select (select new_id from ei$asha_cube_sess i where i.sess_id=s.sess_id), sess_par_nm, sess_par_val from ei$asha_cube_sess_pars s;
        INSERT INTO asha_cube (sess_id,sample_time,wait_class,sql_id,event,event_id,module,action,sql_id1,sql_plan_hash_value,segment_id,g1,g2,g3,g4,g5,g6,smpls)
             select (select new_id from ei$asha_cube_sess i where i.sess_id=s.sess_id),sample_time,wait_class,sql_id,event,event_id,module,action,sql_id1,sql_plan_hash_value,segment_id,g1,g2,g3,g4,g5,g6,smpls from ei$asha_cube s;
        INSERT INTO asha_cube_block (sess_id,session_id,session_serial#,inst_id,sql_id,module,action,blocking_session,blocking_session_serial#,blocking_inst_id,cnt,blocker_id)
             select (select new_id from ei$asha_cube_sess i where i.sess_id=s.sess_id),session_id,session_serial#,inst_id,sql_id,module,action,blocking_session,blocking_session_serial#,blocking_inst_id,cnt,blocker_id from ei$asha_cube_block s;
        INSERT INTO asha_cube_metrics (sess_id,metric_id,end_time,value,inst_id,group_id,aggfnc)
             select (select new_id from ei$asha_cube_sess i where i.sess_id=s.sess_id),metric_id,end_time,value,inst_id,group_id,aggfnc from ei$asha_cube_metrics s;
        INSERT INTO asha_cube_seg (sess_id,segment_id,segment_name)
             select (select new_id from ei$asha_cube_sess i where i.sess_id=s.sess_id),segment_id,segment_name from ei$asha_cube_seg s;
        INSERT INTO asha_cube_snap_ash (sess_id,inst_id,sample_id,sample_time,sample_time_utc,usecs_per_row,is_awr_sample,
          session_id,session_serial#,session_type,flags,user_id,sql_id,is_sqlid_current,sql_child_number,sql_opcode,force_matching_signature,
          top_level_sql_id,top_level_sql_opcode,sql_opname,sql_adaptive_plan_resolved,sql_full_plan_hash_value,sql_plan_hash_value,sql_plan_line_id,
          sql_plan_operation,sql_plan_options,sql_exec_id,sql_exec_start,plsql_entry_object_id,plsql_entry_subprogram_id,plsql_object_id,plsql_subprogram_id,
          qc_instance_id,qc_session_id,qc_session_serial#,px_flags,event,event_id,event#,seq#,p1text,p1,p2text,p2,p3text,p3,wait_class,wait_class_id,
          wait_time,session_state,time_waited,blocking_session_status,blocking_session,blocking_session_serial#,blocking_inst_id,blocking_hangchain_info,
          current_obj#,current_file#,current_block#,current_row#,top_level_call#,top_level_call_name,consumer_group_id,xid,remote_instance#,time_model,
          in_connection_mgmt,in_parse,in_hard_parse,in_sql_execution,in_plsql_execution,in_plsql_rpc,in_plsql_compilation,in_java_execution,in_bind,in_cursor_close,
          in_sequence_load,in_inmemory_query,in_inmemory_populate,in_inmemory_prepopulate,in_inmemory_repopulate,in_inmemory_trepopulate,in_tablespace_encryption,
          capture_overhead,replay_overhead,is_captured,is_replayed,is_replay_sync_token_holder,service_hash,program,module,action,client_id,machine,port,ecid,dbreplay_file_id,
          dbreplay_call_counter,tm_delta_time,tm_delta_cpu_time,tm_delta_db_time,delta_time,delta_read_io_requests,delta_write_io_requests,delta_read_io_bytes,delta_write_io_bytes,
          delta_interconnect_io_bytes,delta_read_mem_bytes,pga_allocated,temp_space_allocated,con_dbid,con_id,dbop_name,dbop_exec_id)
          select (select new_id from ei$asha_cube_sess i where i.sess_id=s.sess_id),inst_id,sample_id,sample_time,sample_time_utc,usecs_per_row,is_awr_sample,
          session_id,session_serial#,session_type,flags,user_id,sql_id,is_sqlid_current,sql_child_number,sql_opcode,force_matching_signature,
          top_level_sql_id,top_level_sql_opcode,sql_opname,sql_adaptive_plan_resolved,sql_full_plan_hash_value,sql_plan_hash_value,sql_plan_line_id,
          sql_plan_operation,sql_plan_options,sql_exec_id,sql_exec_start,plsql_entry_object_id,plsql_entry_subprogram_id,plsql_object_id,plsql_subprogram_id,
          qc_instance_id,qc_session_id,qc_session_serial#,px_flags,event,event_id,event#,seq#,p1text,p1,p2text,p2,p3text,p3,wait_class,wait_class_id,
          wait_time,session_state,time_waited,blocking_session_status,blocking_session,blocking_session_serial#,blocking_inst_id,blocking_hangchain_info,
          current_obj#,current_file#,current_block#,current_row#,top_level_call#,top_level_call_name,consumer_group_id,xid,remote_instance#,time_model,
          in_connection_mgmt,in_parse,in_hard_parse,in_sql_execution,in_plsql_execution,in_plsql_rpc,in_plsql_compilation,in_java_execution,in_bind,in_cursor_close,
          in_sequence_load,in_inmemory_query,in_inmemory_populate,in_inmemory_prepopulate,in_inmemory_repopulate,in_inmemory_trepopulate,in_tablespace_encryption,
          capture_overhead,replay_overhead,is_captured,is_replayed,is_replay_sync_token_holder,service_hash,program,module,action,client_id,machine,port,ecid,dbreplay_file_id,
          dbreplay_call_counter,tm_delta_time,tm_delta_cpu_time,tm_delta_db_time,delta_time,delta_read_io_requests,delta_write_io_requests,delta_read_io_bytes,delta_write_io_bytes,
          delta_interconnect_io_bytes,delta_read_mem_bytes,pga_allocated,temp_space_allocated,con_dbid,con_id,dbop_name,dbop_exec_id from ei$asha_cube_snap_ash s;
        INSERT INTO asha_cube_timeline (sess_id,sample_time)
             select (select new_id from ei$asha_cube_sess i where i.sess_id=s.sess_id),sample_time from ei$asha_cube_timeline s;
        INSERT INTO asha_cube_top_sess (sess_id,session_id,session_serial#,inst_id,module,action,program,client_id,machine,ecid,username,smpls)
             select (select new_id from ei$asha_cube_sess i where i.sess_id=s.sess_id),session_id,session_serial#,inst_id,module,action,program,client_id,machine,ecid,username,smpls from ei$asha_cube_top_sess s;
        INSERT INTO asha_cube_unknown (sess_id,unknown_type,session_type,program,client_id,machine,ecid,username,smpls)
             select (select new_id from ei$asha_cube_sess i where i.sess_id=s.sess_id),unknown_type,session_type,program,client_id,machine,ecid,username,smpls from ei$asha_cube_unknown s;
      end;' using p_proj_id;
  end;

  procedure import_processing (p_exp_sess_id    opas_expimp_sessions.sess_id%type,
                               p_proj_id        asha_cube_sess.sess_proj_id%type)
  is
    l_module varchar2(100) := 'Process imported file';
    l_ei_metadata OPAS_EXPIMP_METADATA%rowtype;
    l_proj_id     asha_cube_sess.sess_proj_id%type:=p_proj_id;
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

    if l_ei_metadata.import_prc=g_ImpTP_Cube then
      import_cube(l_proj_id,p_exp_sess_id);
    elsif l_ei_metadata.import_prc=g_ImpTP_Project then
      import_project(l_proj_id);
      import_cube(l_proj_id,p_exp_sess_id);
    else
      raise_application_error(-20000,'Unknown import entry point procedure: '||l_ei_metadata.import_prc);
    end if;
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
      coremod_log.log('Error in ASHA_EXPIMP.import_processing: sess_id: '||p_exp_sess_id||'; '||sqlerrm);
      coremod_log.log(DBMS_UTILITY.FORMAT_ERROR_STACK);
      COREMOD_EXPIMP.finish_import_session (  P_EXP_SESS_ID => p_exp_sess_id, P_STATUS => COREMOD_EXPIMP.gstFAILED) ;
      raise_application_error(-20000,'Error in ASHA_EXPIMP.import_processing: sess_id: '||p_exp_sess_id||'; '||sqlerrm);
  end;

  procedure cleanup_expimp
  is
  begin
    COREMOD_EXPIMP.cleanup_expimp_sess(ASHA_CUBE_API.gMODNAME, COREMOD_API.getconf(P_KEY => 'EXPIMPSESS',P_MODULE => ASHA_CUBE_API.gMODNAME));
  end;

END ASHA_EXPIMP;
/
