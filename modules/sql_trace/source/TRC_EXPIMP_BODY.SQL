CREATE OR REPLACE
PACKAGE BODY TRC_EXPIMP AS

  gTrcTables COREMOD_EXPIMP.t_object_names :=
                         COREMOD_EXPIMP.t_object_names('TRC_BINDS','TRC_CALL','TRC_CALL_SELF','TRC_CLIENT_IDENTITY','TRC_FILES','TRC_OBJ_DIC','TRC_SESSION','TRC_STAT','TRC_STATEMENT','TRC_TRANS','TRC_WAIT', 'TRC_LOBCALL');
  gProjList COREMOD_EXPIMP.t_object_names :=
                         COREMOD_EXPIMP.t_object_names('TRC_PROJECTS');

  gTrcTablesWOParsed COREMOD_EXPIMP.t_object_names :=
                         COREMOD_EXPIMP.t_object_names('TRC_FILES');


  gTableList COREMOD_EXPIMP.t_object_names := gTrcTables multiset union distinct gProjList;

  g_lops_ind number;

  g_ImpTP_Trc    constant varchar2(100) := 'TRC';
  g_ImpTP_Project constant varchar2(100) := 'PROJ';

  gExpPar_IncludeParsed constant varchar2(100) := 'INCLUDEPARSED';

  procedure init AS
  BEGIN
    COREMOD_EXPIMP.init(COREMOD_EXPIMP.gTabPref, gTableList);
    execute immediate 'create index ixei$ei$trc_files_1 on ei$trc_files(trc_file_id)';
    execute immediate 'create index ixei$ei$trc_session_1 on ei$trc_session(session_id)';
    execute immediate 'create index ixei$ei$trc_statement_1 on ei$trc_statement(stmt_id)';
    execute immediate 'create index ixei$ei$trc_call_1 on ei$trc_call(call_id)';
  END init;

  procedure queue_export_trc  (p_trc_ids    coremod_tasks.t_ids,
                               p_descr       opas_expimp_metadata.file_descr%type,
                               p_including_parsed boolean default false,
                               p_tq_id       out opas_task_queue.tq_id%type,
                               p_exp_sess_id out opas_expimp_sessions.sess_id%type)
  is
  begin
    p_tq_id:=COREMOD_TASKS.prep_execute_task (  P_TASKNAME => 'TRC_EXP_TRACE', p_task_subname => null) ;

    COREMOD_EXPIMP.create_exp_session
    ( P_OWNER       => nvl(V('APP_USER'),COREMOD_API.gDefaultOwner),
      P_MODNAME     => TRC_FILE_API.gMODNAME,
      P_IMPORT_PRC  => g_ImpTP_Trc,
      P_FILE_DESCR  => p_descr,
      P_SESS_ID     => p_exp_sess_id) ;

    COREMOD_EXPIMP.set_param (  P_SESS_ID => p_exp_sess_id,
                                P_PAR_NAME => gExpPar_IncludeParsed,
                                P_PAR_VALUE => case when p_including_parsed then 'YES' else 'NO' end) ;

    COREMOD_TASKS.set_task_param_list( p_tq_id => p_tq_id, p_name => 'B1', p_list_par => coremod_tasks.lsttochr(p_trc_ids));
    COREMOD_TASKS.set_task_param( p_tq_id => p_tq_id, p_name => 'B2', p_num_par => p_exp_sess_id);
    COREMOD_TASKS.queue_task ( p_tq_id => p_tq_id ) ;

    COREMOD_EXPIMP.queue_execution_session(p_exp_sess_id, p_tq_id);
  end;

  procedure queue_export_proj (p_proj_ids    coremod_tasks.t_ids,
                               p_descr       opas_expimp_metadata.file_descr%type,
                               p_including_parsed boolean default false,
                               p_tq_id   out opas_task_queue.tq_id%type,
                               p_exp_sess_id out opas_expimp_sessions.sess_id%type)
  is
  begin
    p_tq_id:=COREMOD_TASKS.prep_execute_task (  P_TASKNAME => 'TRC_EXP_PROJ', p_task_subname => null) ;

    COREMOD_EXPIMP.create_exp_session
    ( P_OWNER       => nvl(V('APP_USER'),COREMOD_API.gDefaultOwner),
      P_MODNAME     => TRC_FILE_API.gMODNAME,
      P_IMPORT_PRC  => g_ImpTP_Project,
      P_FILE_DESCR  => p_descr,
      P_SESS_ID     => p_exp_sess_id) ;

    COREMOD_EXPIMP.set_param (  P_SESS_ID => p_exp_sess_id,
                                P_PAR_NAME => gExpPar_IncludeParsed,
                                P_PAR_VALUE => case when p_including_parsed then 'YES' else 'NO' end) ;

    COREMOD_TASKS.set_task_param_list( p_tq_id => p_tq_id, p_name => 'B1', p_list_par => coremod_tasks.lsttochr(p_proj_ids));
    COREMOD_TASKS.set_task_param( p_tq_id => p_tq_id, p_name => 'B2', p_num_par => p_exp_sess_id);
    COREMOD_TASKS.queue_task ( p_tq_id => p_tq_id ) ;

    COREMOD_EXPIMP.queue_execution_session(p_exp_sess_id, p_tq_id);
  end;

  procedure queue_import_processing ( p_exp_sess_id      opas_expimp_sessions.sess_id%type,
                                      p_proj_id_to_merge trc_projects.proj_id%type,
                                      p_tq_id            out opas_task_queue.tq_id%type)
  is
  begin
    p_tq_id:=COREMOD_TASKS.prep_execute_task (  P_TASKNAME => 'TRC_IMP_PROCESSING', p_task_subname => null) ;

    COREMOD_TASKS.set_task_param( p_tq_id => p_tq_id, p_name => 'B1', p_num_par => p_exp_sess_id);
    COREMOD_TASKS.set_task_param( p_tq_id => p_tq_id, p_name => 'B2', p_num_par => nvl(p_proj_id_to_merge,-1));
    COREMOD_TASKS.queue_task ( p_tq_id => p_tq_id ) ;

    COREMOD_EXPIMP.queue_execution_session(p_exp_sess_id, p_tq_id);
  end;

  procedure load_trc_tables_i(p_trc_ids    coremod_tasks.t_ids, p_exp_sess_id opas_expimp_sessions.sess_id%type)
  is
  begin
    if COREMOD_EXPIMP.get_param(P_SESS_ID => p_exp_sess_id,P_PAR_NAME => gExpPar_IncludeParsed) = 'YES' then
      for j in 1..p_trc_ids.count loop
        for i in 1..gTrcTables.count loop
          if gTableList(i) = 'TRC_CALL_SELF' then
            execute immediate 'insert into '||COREMOD_EXPIMP.gTabPref||gTableList(i)||' select x.*, null new_id from '||gTableList(i)||' x where call_id in (select call_id from trc_call where trc_file_id=:a1)' using p_trc_ids(j);
          else
            execute immediate 'insert into '||COREMOD_EXPIMP.gTabPref||gTableList(i)||' select x.*, null new_id from '||gTableList(i)||' x where trc_file_id=:a1' using p_trc_ids(j);
          end if;
        end loop;
      end loop;
    else
      for j in 1..p_trc_ids.count loop
        for i in 1..gTrcTablesWOParsed.count loop
           execute immediate 'insert into '||COREMOD_EXPIMP.gTabPref||gTrcTablesWOParsed(i)||' select x.*, null new_id from '||gTrcTablesWOParsed(i)||' x where trc_file_id=:a1' using p_trc_ids(j);
        end loop;
      end loop;
    end if;
  end;

  procedure load_proj_tables_i(p_proj_ids    coremod_tasks.t_ids, p_exp_sess_id opas_expimp_sessions.sess_id%type)
  is
    l_trc_ids    coremod_tasks.t_ids;
  begin
    for k in 1..p_proj_ids.count loop
      select trc_file_id bulk collect into l_trc_ids from trc_files where proj_id=p_proj_ids(k);
      load_trc_tables_i(l_trc_ids, p_exp_sess_id);

      for i in 1..gProjList.count loop
        execute immediate 'insert into '||COREMOD_EXPIMP.gTabPref||gProjList(i)||' select x.*, null new_id from '||gProjList(i)||' x where proj_id=:a1' using p_proj_ids(k);
      end loop;
    end loop;
  end;

  procedure load_comm_tables_to_ei(p_exp_sess_id opas_expimp_sessions.sess_id%type)
  is
  begin
    --execute immediate 'insert into EI$OPAS_REPORTS select x.*, null new_id from OPAS_REPORTS x where report_id in (select report_id from EI$AWRWH_REPORTS)';
    --execute immediate 'insert into EI$OPAS_REPORTS_PARS select x.*, null new_id from OPAS_REPORTS_PARS x where report_id in (select report_id from EI$AWRWH_REPORTS)';
    execute immediate 'insert into EI$OPAS_FILES select x.*, null new_id from OPAS_FILES x where file_id in (select file_content from EI$TRC_FILES where file_content is not null)';
    execute immediate 'insert into EI$OPAS_FILES select x.*, null new_id from OPAS_FILES x where file_id in (select report_content from EI$TRC_FILES where report_content is not null)';
    --execute immediate 'insert into EI$OPAS_QRY_CACHE select x.*, null new_id from OPAS_QRY_CACHE x where sql_id in (select sql_id from EI$ASHA_CUBE where sql_id is not null)';
  end;

  procedure export_i     (p_trc_ids     coremod_tasks.t_ids,
                          p_proj_ids    coremod_tasks.t_ids,
                          p_exp_sess_id opas_expimp_sessions.sess_id%type)
  is
    l_module varchar2(100);
  begin
    if p_trc_ids is not null then
      l_module := 'Export SQL Trace file';
    elsif p_proj_ids is not null then
      l_module := 'Export SQL Trace Project';
    end if;

    COREMOD_API.init_longops(l_module,'section','sections',3,g_lops_ind);
    COREMOD_API.start_longops_section ( l_module, 'Preparing export structures');
    --==================================================
    COREMOD_EXPIMP.start_execution_session(p_exp_sess_id);
    --==================================================
    COREMOD_API.end_longops_section(1,g_lops_ind);
    COREMOD_API.start_longops_section ( l_module, 'Extract data for export');
    --==================================================
    if p_trc_ids is not null then
      load_trc_tables_i(p_trc_ids, p_exp_sess_id);
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
      coremod_log.log('Error in TRC_EXPIMP.export_i: sess_id: '||p_exp_sess_id||'; '||sqlerrm);
      coremod_log.log(DBMS_UTILITY.FORMAT_ERROR_STACK);
      COREMOD_EXPIMP.finish_export_session(p_exp_sess_id,COREMOD_EXPIMP.gstFAILED);
      raise;
  end;

  procedure export_trc (p_trc_ids    coremod_tasks.t_ids,  p_exp_sess_id opas_expimp_sessions.sess_id%type)
  is
  begin
    export_i(p_trc_ids, null, p_exp_sess_id);
  end;

  procedure export_proj (p_proj_ids    coremod_tasks.t_ids,  p_exp_sess_id opas_expimp_sessions.sess_id%type)
  is
  begin
    export_i(null, p_proj_ids, p_exp_sess_id);
  end;

  procedure import_project(p_proj_id trc_projects.proj_id%type)
  is
  begin
    if p_proj_id = -1 then
      --create new project
      execute immediate q'[
      declare
        l_proj ei$trc_projects%rowtype;
      begin
        for i in (select * from ei$trc_projects) loop

          INSERT INTO trc_projects
                    ( proj_name, owner, created, status, proj_note, keep_forever, is_public, priority)
             VALUES ( i.proj_name || ' (imported)', COREMOD_API.gDefaultOwner, i.created, i.status, i.proj_note, 'Y' /*l_proj.keep_forever*/, i.is_public, nvl(i.priority,100)) returning proj_id into l_proj.PROJ_ID;

          update ei$trc_projects set new_id = l_proj.PROJ_ID where proj_id=i.proj_id;
        end loop;
      end;]';
    elsif p_proj_id > 0 then
      --load into existing poject
      --execute immediate 'update ei$awrwh_projects set PROJ_ID = :a1' using p_proj_id;
      null;
    else
      raise_application_error(-20000,'Invalid project ID for import: '||p_proj_id);
    end if;
  end;

  procedure import_trc(p_proj_id trc_projects.proj_id%type, p_exp_sess_id    opas_expimp_sessions.sess_id%type) is
  begin
    coremod_log.log('Param "'||gExpPar_IncludeParsed||'": sess_id: '||p_exp_sess_id||'; '||COREMOD_EXPIMP.get_param(P_SESS_ID => p_exp_sess_id,P_PAR_NAME => gExpPar_IncludeParsed),'DEBUG');
    execute immediate q'[
      declare
        l_proj_id number;
        l_trc_file_id number;
        l_session_id number;
        l_cli_id number;
        l_stmt_id number;
        l_call_id number;
        l_included_parsed varchar2(10);
      begin
        l_proj_id := :a1;
        l_included_parsed := :a2;

        for i in (select f.*, nvl(p.new_id,l_proj_id) pnew_id from ei$trc_files f, (select * from ei$trc_projects where l_proj_id = -1) p where f.proj_id=p.proj_id(+)) loop
          insert into trc_files
                  (proj_id,
                   filename, file_header, owner, db_version, created, parsed,
                   status,
                   file_note, file_source,
                   file_content, report_content,
                   source_retention, parsed_retention, tq_id)
           values  (i.pnew_id,
                   i.filename, i.file_header, i.owner, i.db_version, i.created, i.parsed,
                   case when l_included_parsed='YES' then i.status else case when i.file_content is not null then TRC_FILE_LCC.c_trcfilestate_loaded else i.status end end,
                   i.file_note, i.file_source,
                   (select s.new_id from EI$OPAS_FILES s where s.file_id=i.file_content), (select s.new_id from EI$OPAS_FILES s where s.file_id=i.report_content),
                   0, 0, null) returning trc_file_id into l_trc_file_id;
          update ei$trc_files set new_id=l_trc_file_id where trc_file_id=i.trc_file_id;
        end loop;

        if l_included_parsed='YES' then

          for j in (select s.*, f.new_id fnew_id from ei$trc_session s, ei$trc_files f where s.trc_file_id=f.trc_file_id) loop
            insert into trc_session
                   (trc_file_id, row_num, sid, serial#, start_ts, end_ts)
            values (j.fnew_id, j.row_num, j.sid, j.serial#, j.start_ts, j.end_ts) returning session_id into l_session_id;
            update ei$trc_session set new_id=l_session_id where session_id=j.session_id;
          end loop;

          for j in (select t.*, f.new_id n_trc_file_id, s.new_id n_session_id from ei$trc_client_identity t, ei$trc_files f, ei$trc_session s where t.trc_file_id=f.trc_file_id and t.session_id=s.session_id) loop
            insert into trc_client_identity
                    (session_id, trc_file_id, client_id, service_name, module, action, client_driver)
              values(j.n_session_id, j.n_trc_file_id, j.client_id, j.service_name, j.module, j.action, j.client_driver) returning cli_id into l_cli_id;
            update ei$trc_client_identity set new_id=l_cli_id where cli_id=j.cli_id;
          end loop;

          for j in (select ss.*, f.new_id n_trc_file_id, s.new_id n_session_id from ei$trc_statement ss, ei$trc_files f, ei$trc_session s where ss.trc_file_id=f.trc_file_id and ss.session_id=s.session_id) loop
            insert into trc_statement
                    (session_id, trc_file_id, row_num, trc_slot, len, dep, uid#, oct, lid, tim, hv, ad, sqlid, sql_text, cli_ident, err)
             values (j.n_session_id, j.n_trc_file_id, j.row_num, j.trc_slot, j.len, j.dep, j.uid#, j.oct, j.lid, j.tim, j.hv, j.ad, j.sqlid, j.sql_text, j.cli_ident, j.err) returning stmt_id into l_stmt_id;
            update ei$trc_statement set new_id=l_stmt_id where stmt_id=j.stmt_id;
          end loop;

          insert into trc_trans (session_id, trc_file_id, stmt_id, row_num, rlbk, rd_only, tim)
          SELECT (select new_id from ei$trc_session i where i.session_id=o.session_id) session_id,
                 (select new_id from ei$trc_files i where i.trc_file_id=o.trc_file_id) trc_file_id,
                 (select new_id from ei$trc_statement i where i.stmt_id=o.stmt_id) stmt_id,
                 row_num, rlbk, rd_only, tim FROM ei$trc_trans o;

          for j in(select c.*, f.new_id n_trc_file_id, ss.new_id n_stmt_id from ei$trc_call c, ei$trc_statement ss, ei$trc_files f where c.trc_file_id=f.trc_file_id and c.stmt_id=ss.stmt_id) loop
            insert into trc_call
                    (stmt_id, trc_file_id, parent_id, call_type, row_num, trc_slot, c, e, p, cr, cu, mis, r, dep, og, plh, tim, typ)
             values (j.n_stmt_id, j.n_trc_file_id, j.parent_id, j.call_type, j.row_num, j.trc_slot, j.c, j.e, j.p, j.cr, j.cu, j.mis, j.r, j.dep, j.og, j.plh, j.tim, j.typ) returning call_id into l_call_id;
            update ei$trc_call set new_id=l_call_id where call_id=j.call_id;
          end loop;

          update /*+ full(o) leading(i1) */ trc_call o set parent_id = (select new_id from ei$trc_call i where i.call_id=o.parent_id)
            where parent_id is not null and trc_file_id in (select new_id from ei$trc_files i1);

          insert into trc_call_self (call_id, c, e, p, cr, cu)
          SELECT (select new_id from ei$trc_call i where i.call_id=o.call_id), c, e, p, cr, cu FROM ei$trc_call_self o;

          insert into trc_binds (stmt_id, trc_file_id, call_id, row_num, trc_slot, bind#, value)
          SELECT (select new_id from ei$trc_statement i where i.stmt_id=o.stmt_id) stmt_id,
                 (select new_id from ei$trc_files i where i.trc_file_id=o.trc_file_id) trc_file_id,
                 (select new_id from ei$trc_call i where i.call_id=o.call_id) call_id,
                 row_num, trc_slot, bind#, value FROM ei$trc_binds o;

          insert into trc_wait(stmt_id, trc_file_id, row_num, trc_slot, nam, ela, p1_name, p1, p2_name, p2, p3_name, p3, pars, obj#, tim, call_id)
          SELECT (select new_id from ei$trc_statement i where i.stmt_id=o.stmt_id) stmt_id,
                 (select new_id from ei$trc_files i where i.trc_file_id=o.trc_file_id) trc_file_id,
                 row_num, trc_slot, nam, ela, p1_name, p1, p2_name, p2, p3_name, p3, pars, obj#, tim,
                 (select new_id from ei$trc_call i where i.call_id=o.call_id) call_id
                 FROM ei$trc_wait o;

          insert into trc_stat (stmt_id, trc_file_id, row_num, trc_slot, id, cnt, pid, pos, obj, op, cr, pr, pw, str, tim, cost, sz, card, call_id)
          SELECT (select new_id from ei$trc_statement i where i.stmt_id=o.stmt_id) stmt_id,
                 (select new_id from ei$trc_files i where i.trc_file_id=o.trc_file_id) trc_file_id,
                 row_num, trc_slot, id, cnt, pid, pos, obj, op, cr, pr, pw, str, tim, cost, sz, card,
                 (select new_id from ei$trc_call i where i.call_id=o.call_id) call_id
                 FROM ei$trc_stat o;

          INSERT INTO trc_lobcall (stmt_id, trc_file_id, call_type, lob_type, row_num, trc_slot, bytes, c, e, p, cr, cu, tim)
          select
            (select new_id from ei$trc_statement i where i.stmt_id=o.stmt_id) stmt_id,
            (select new_id from ei$trc_files i where i.trc_file_id=o.trc_file_id) trc_file_id,
            call_type, lob_type, row_num, trc_slot, bytes, c, e, p, cr, cu, tim
          from ei$trc_lobcall o;

          insert into trc_obj_dic (trc_file_id, object_id, object_name)
          SELECT (select new_id from ei$trc_files i where i.trc_file_id=o.trc_file_id) trc_file_id, object_id, object_name FROM ei$trc_obj_dic o;
        end if;
      end;
      ]' using p_proj_id,
               COREMOD_EXPIMP.get_param(P_SESS_ID => p_exp_sess_id,P_PAR_NAME => gExpPar_IncludeParsed);
  end;

  procedure import_processing (p_exp_sess_id    opas_expimp_sessions.sess_id%type,
                               p_proj_id        trc_projects.proj_id%type)
  is
    l_module      varchar2(100) := 'Process imported file';
    l_ei_metadata OPAS_EXPIMP_METADATA%rowtype;
    l_proj_id     awrwh_projects.proj_id%type:=p_proj_id; -- -1: project mode, all traces projects preserved,  >0: either project or file mode, all goes to the specified project
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

    if l_ei_metadata.import_prc=g_ImpTP_Trc and p_proj_id > 0 then
      import_trc(l_proj_id, p_exp_sess_id);
    elsif l_ei_metadata.import_prc=g_ImpTP_Project and (p_proj_id > 0 or p_proj_id = -1) then
      import_project(l_proj_id);
      import_trc(l_proj_id, p_exp_sess_id);
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
      coremod_log.log('Error in TRC_EXPIMP.import_processing: sess_id: '||p_exp_sess_id||'; '||sqlerrm);
      coremod_log.log(DBMS_UTILITY.FORMAT_ERROR_STACK);
      COREMOD_EXPIMP.finish_import_session (  P_EXP_SESS_ID => p_exp_sess_id, P_STATUS => COREMOD_EXPIMP.gstFAILED) ;
      raise_application_error(-20000,'Error in TRC_EXPIMP.import_processing: sess_id: '||p_exp_sess_id||'; '||sqlerrm);
  end;

END TRC_EXPIMP;
/
