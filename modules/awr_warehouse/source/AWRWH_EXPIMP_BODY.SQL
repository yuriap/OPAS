CREATE OR REPLACE
PACKAGE BODY AWRWH_EXPIMP AS

  gDumpTables COREMOD_EXPIMP.t_object_names :=
                         COREMOD_EXPIMP.t_object_names('AWRWH_DUMPS','AWRWH_REPORTS');
  gProjList COREMOD_EXPIMP.t_object_names :=
                         COREMOD_EXPIMP.t_object_names('AWRWH_PROJECTS');

  gTableList COREMOD_EXPIMP.t_object_names := gDumpTables multiset union distinct gProjList;

  g_lops_ind number;

  g_ImpTP_Dump    constant varchar2(100) := 'DUMP';
  g_ImpTP_Project constant varchar2(100) := 'PROJ';

  procedure init AS
  BEGIN
    COREMOD_EXPIMP.init(COREMOD_EXPIMP.gTabPref, gTableList);
  END init;

  procedure queue_export_dump (p_dump_ids    coremod_tasks.t_ids,
                               p_descr       opas_expimp_metadata.file_descr%type,
                               p_tq_id       out opas_task_queue.tq_id%type,
                               p_exp_sess_id out opas_expimp_sessions.sess_id%type)
  is
  begin
    p_tq_id:=COREMOD_TASKS.prep_execute_task (  P_TASKNAME => 'AWRWH_EXP_DUMP', p_task_subname => null) ;

    COREMOD_EXPIMP.create_exp_session
    ( P_OWNER       => nvl(V('APP_USER'),COREMOD_API.gDefaultOwner),
      P_MODNAME     => AWRWH_API.gMODNAME,
      P_IMPORT_PRC  => g_ImpTP_Dump,
      P_FILE_DESCR  => p_descr,
      P_SESS_ID     => p_exp_sess_id) ;

    COREMOD_TASKS.set_task_param_list( p_tq_id => p_tq_id, p_name => 'B1', p_list_par => coremod_tasks.lsttochr(p_dump_ids));
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
    p_tq_id:=COREMOD_TASKS.prep_execute_task (  P_TASKNAME => 'AWRWH_EXP_PROJ', p_task_subname => null) ;

    COREMOD_EXPIMP.create_exp_session
    ( P_OWNER       => nvl(V('APP_USER'),COREMOD_API.gDefaultOwner),
      P_MODNAME     => AWRWH_API.gMODNAME,
      P_IMPORT_PRC  => g_ImpTP_Project,
      P_FILE_DESCR  => p_descr,
      P_SESS_ID     => p_exp_sess_id) ;

    COREMOD_TASKS.set_task_param_list( p_tq_id => p_tq_id, p_name => 'B1', p_list_par => coremod_tasks.lsttochr(p_proj_ids));
    COREMOD_TASKS.set_task_param( p_tq_id => p_tq_id, p_name => 'B2', p_num_par => p_exp_sess_id);
    COREMOD_TASKS.queue_task ( p_tq_id => p_tq_id ) ;

    COREMOD_EXPIMP.queue_execution_session(p_exp_sess_id, p_tq_id);
  end;

  procedure queue_import_processing ( p_exp_sess_id      opas_expimp_sessions.sess_id%type,
                                      p_proj_id_to_merge awrwh_projects.proj_id%type,
                                      p_tq_id            out opas_task_queue.tq_id%type)
  is
    l_proj asha_cube_projects%rowtype;
  begin
    p_tq_id:=COREMOD_TASKS.prep_execute_task (  P_TASKNAME => 'AWRWH_IMP_PROCESSING', p_task_subname => null) ;

    COREMOD_TASKS.set_task_param( p_tq_id => p_tq_id, p_name => 'B1', p_num_par => p_exp_sess_id);
    COREMOD_TASKS.set_task_param( p_tq_id => p_tq_id, p_name => 'B2', p_num_par => nvl(p_proj_id_to_merge,-1));
    COREMOD_TASKS.queue_task ( p_tq_id => p_tq_id ) ;

    COREMOD_EXPIMP.queue_execution_session(p_exp_sess_id, p_tq_id);
  end;

  procedure load_dump_tables_i(p_dump_ids    coremod_tasks.t_ids, p_exp_sess_id opas_expimp_sessions.sess_id%type)
  is
  begin
    for j in 1..p_dump_ids.count loop
      for i in 1..gDumpTables.count loop
       -- if gTableList(i) = 'AWRWH_REPORTS' then
       --   execute immediate 'insert into '||COREMOD_EXPIMP.gTabPref||gTableList(i)||' select x.*, null new_id from '||gTableList(i)||' x where dump_id=:a1 or nvl(dump_id_2,-1)=:a2' using p_dump_ids(j), p_dump_ids(j);
       -- else
          execute immediate 'insert into '||COREMOD_EXPIMP.gTabPref||gTableList(i)||' select x.*, null new_id from '||gTableList(i)||' x where dump_id=:a1' using p_dump_ids(j);
       -- end if;
      end loop;
    end loop;
  end;

  procedure load_proj_tables_i(p_proj_ids    coremod_tasks.t_ids, p_exp_sess_id opas_expimp_sessions.sess_id%type)
  is
    l_dump_ids    coremod_tasks.t_ids;
  begin
    for k in 1..p_proj_ids.count loop
      select dump_id bulk collect into l_dump_ids from awrwh_dumps where proj_id=p_proj_ids(k);
      load_dump_tables_i(l_dump_ids, p_exp_sess_id);

      execute immediate 'insert into EI$AWRWH_REPORTS select x.*, null new_id from AWRWH_REPORTS x where (proj_id,report_id) not in (select proj_id,report_id from EI$AWRWH_REPORTS) and proj_id=:a1' using p_proj_ids(k);

      for i in 1..gProjList.count loop
        execute immediate 'insert into '||COREMOD_EXPIMP.gTabPref||gProjList(i)||' select x.*, null new_id from '||gProjList(i)||' x where proj_id=:a1' using p_proj_ids(k);
      end loop;
    end loop;
  end;

  procedure load_comm_tables_to_ei(p_exp_sess_id opas_expimp_sessions.sess_id%type)
  is
  begin
    execute immediate 'insert into EI$OPAS_REPORTS select x.*, null new_id from OPAS_REPORTS x where report_id in (select report_id from EI$AWRWH_REPORTS)';
    execute immediate 'insert into EI$OPAS_REPORTS_PARS select x.*, null new_id from OPAS_REPORTS_PARS x where report_id in (select report_id from EI$AWRWH_REPORTS)';
    execute immediate 'insert into EI$OPAS_FILES select x.*, null new_id from OPAS_FILES x where file_id in (select filebody from EI$AWRWH_DUMPS where filebody is not null)';
    execute immediate 'insert into EI$OPAS_FILES select x.*, null new_id from OPAS_FILES x where file_id in (select report_content from EI$OPAS_REPORTS)';
  end;

  procedure export_i     (p_dump_ids    coremod_tasks.t_ids,
                          p_proj_ids    coremod_tasks.t_ids,
                          p_exp_sess_id opas_expimp_sessions.sess_id%type)
  is
    l_module varchar2(100);
  begin
    if p_dump_ids is not null then
      l_module := 'Export AWRWH Dump';
    elsif p_proj_ids is not null then
      l_module := 'Export AWRWH Project';
    end if;

    COREMOD_API.init_longops(l_module,'section','sections',3,g_lops_ind);
    COREMOD_API.start_longops_section ( l_module, 'Preparing export structures');
    --==================================================
    COREMOD_EXPIMP.start_execution_session(p_exp_sess_id);
    --==================================================
    COREMOD_API.end_longops_section(1,g_lops_ind);
    COREMOD_API.start_longops_section ( l_module, 'Extract data for export');
    --==================================================
    if p_dump_ids is not null then
      load_dump_tables_i(p_dump_ids, p_exp_sess_id);
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
      coremod_log.log('Error in AWRWH_EXPIMP.export_i: sess_id: '||p_exp_sess_id||'; '||sqlerrm);
      coremod_log.log(DBMS_UTILITY.FORMAT_ERROR_STACK);
      COREMOD_EXPIMP.finish_export_session(p_exp_sess_id,COREMOD_EXPIMP.gstFAILED);
      raise;
  end;

  procedure export_dump (p_dump_ids    coremod_tasks.t_ids,  p_exp_sess_id opas_expimp_sessions.sess_id%type)
  is
  begin
    export_i(p_dump_ids, null, p_exp_sess_id);
  end;

  procedure export_proj (p_proj_ids    coremod_tasks.t_ids,  p_exp_sess_id opas_expimp_sessions.sess_id%type)
  is
  begin
    export_i(null, p_proj_ids, p_exp_sess_id);
  end;

  procedure import_project(p_proj_id in out awrwh_projects.proj_id%type)
  is
  begin
    if p_proj_id = -1 then
      --create new project
      execute immediate q'[
      declare
        l_proj ei$awrwh_projects%rowtype;
      begin
        for i in (select * from ei$awrwh_projects) loop

          INSERT INTO awrwh_projects
                    ( proj_name, owner, created, status, proj_note, keep_forever, is_public, priority)
             VALUES ( i.proj_name || ' (imported)', COREMOD_API.gDefaultOwner, i.created, i.status, i.proj_note, 'Y' /*l_proj.keep_forever*/, i.is_public, nvl(i.priority,100)) returning proj_id into l_proj.PROJ_ID;

          update ei$awrwh_projects set new_id = l_proj.PROJ_ID where proj_id=i.proj_id;
        end loop;
      end;]';
    elsif p_proj_id > 0 then
      --load into existing poject
      null;
    else
      raise_application_error(-20000,'Invalid project ID for import: '||p_proj_id);
    end if;
  end;

  procedure import_dump(p_proj_id awrwh_projects.proj_id%type) is
  begin
    execute immediate '
      declare
        l_proj_id number;
        l_proj_id_new number;
        l_dump_id number;
      begin
        l_proj_id := :a1;

        for i in (select f.*, nvl(p.new_id,l_proj_id) pnew_id from ei$awrwh_dumps f, (select * from ei$awrwh_projects where l_proj_id = -1) p where f.proj_id=p.proj_id(+)) loop
          insert into awrwh_dumps
                  (proj_id, filename,
                   status,
                   dbid, min_snap_id, max_snap_id, min_snap_dt, max_snap_dt, is_remote, db_description,
                   dump_description, dump_name,
                   filebody,
                   source_retention, parsed_retention, loaded, parsed, owner, tq_id)
           values  (i.pnew_id, i.filename,
                    case when i.status in (AWRWH_FILE_LCC.c_dmpfilestate_awrloaded) then AWRWH_FILE_LCC.c_dmpfilestate_dmploaded
                         when i.status in (AWRWH_FILE_LCC.c_dmpfilestate_compressed) then AWRWH_FILE_LCC.c_dmpfilestate_archived
                         else i.status end,
                    i.dbid, i.min_snap_id, i.max_snap_id, i.min_snap_dt, i.max_snap_dt, i.is_remote, i.db_description,
                    i.dump_description, i.dump_name,
                    (select d.new_id from ei$opas_files d where d.file_id = i.filebody),
                    0, null, i.loaded, null, i.owner, null) returning dump_id, proj_id into l_dump_id, l_proj_id_new;
          update ei$awrwh_dumps set new_id=l_dump_id, proj_id=l_proj_id_new where dump_id=i.dump_id;
        end loop;

        if l_proj_id = -1 then
          update ei$awrwh_reports r set
            proj_id = (select d.new_id from ei$awrwh_projects d where d.proj_id = r.proj_id);
        else
          update ei$awrwh_reports r set
            proj_id = l_proj_id;
        end if;

        update ei$awrwh_reports r set
          dump_id = (select d.new_id from ei$awrwh_dumps d where d.dump_id = r.dump_id),
          dump_id_2 = (select d.new_id from ei$awrwh_dumps d where d.dump_id = r.dump_id_2),
          report_id = (select t.new_id from EI$OPAS_REPORTS t where t.report_id=r.report_id);

        insert into awrwh_reports (
                 proj_id, report_id, dump_id, dump_id_2, report_retention, report_note, created)
          SELECT proj_id, report_id, dump_id, dump_id_2, report_retention, report_note, created
          FROM ei$awrwh_reports;

      end;' using p_proj_id;
  end;

  procedure import_processing (p_exp_sess_id    opas_expimp_sessions.sess_id%type,
                               p_proj_id        awrwh_projects.proj_id%type)
  is
    l_module      varchar2(100) := 'Process imported file';
    l_ei_metadata OPAS_EXPIMP_METADATA%rowtype;
    l_proj_id     awrwh_projects.proj_id%type:=p_proj_id;
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

    if l_ei_metadata.import_prc=g_ImpTP_Dump then
      import_dump(l_proj_id);
    elsif l_ei_metadata.import_prc=g_ImpTP_Project then
      import_project(l_proj_id);
      import_dump(l_proj_id);
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
      coremod_log.log('Error in AWRWH_EXPIMP.import_processing: sess_id: '||p_exp_sess_id||'; '||sqlerrm);
      coremod_log.log(DBMS_UTILITY.FORMAT_ERROR_STACK);
      COREMOD_EXPIMP.finish_import_session (  P_EXP_SESS_ID => p_exp_sess_id, P_STATUS => COREMOD_EXPIMP.gstFAILED) ;
      raise_application_error(-20000,'Error in AWRWH_EXPIMP.import_processing: sess_id: '||p_exp_sess_id||'; '||sqlerrm);
  end;

  procedure cleanup_expimp
  is
  begin
    COREMOD_EXPIMP.cleanup_expimp_sess(AWRWH_API.gMODNAME, COREMOD_API.getconf(P_KEY => 'EXPIMPSESS',P_MODULE => AWRWH_API.gMODNAME));
  end;

END AWRWH_EXPIMP;
/
