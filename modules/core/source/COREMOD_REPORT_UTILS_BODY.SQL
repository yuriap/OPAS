CREATE OR REPLACE
PACKAGE BODY COREMOD_REPORT_UTILS AS

  --long ops for reports
/*
    g_rindex    BINARY_INTEGER;
    g_slno      BINARY_INTEGER;
    g_totalwork number;
    g_sofar     number;
    g_obj       BINARY_INTEGER;
    g_op_name   varchar2(100);
    g_target_desc varchar2(100);
    g_units     varchar2(100);
*/
    g_timing    boolean := false;
    g_time      number;
    g_tot_tim   number;
    g_cpu_tim   number;
    g_tot_cpu_tim number;
    g_lops_ind number;

  --gparReportType constant varchar2(32) := 'REPORT_TYPE';

  procedure init_report(p_modname opas_reports.modname%type, p_report_id out opas_reports.report_id%type, p_parent_report opas_reports.report_id%type default null)
  is
  begin
    INSERT INTO opas_reports (modname, tq_id, report_content, report_params_displ, parent_id)
         VALUES (p_modname, null, null, null, p_parent_report) returning report_id into p_report_id;
  end;

  procedure set_report_type(p_report_id opas_reports.report_id%type, p_report_type varchar2)
  is
  begin
    update opas_reports set report_type=p_report_type where report_id=p_report_id;
  end;

  function  get_report_type(p_report_id opas_reports.report_id%type) return varchar2
  is
    l_res opas_reports.report_type%type;
  begin
    select report_type into l_res from opas_reports where report_id = p_report_id;
    return l_res;
  end;

  procedure set_report_param(p_report_id opas_reports.report_id%type, p_name opas_reports_pars.par_name%type, p_num_par number)
  is
  begin
    merge into opas_reports_pars t using (select p_report_id id, p_name nm, p_num_par val from dual) s
    on (t.report_id = s.id and t.par_name=s.nm)
    when matched then update set num_par = s.val
    when not matched then insert (report_id,par_name,num_par) values (s.id, s.nm, s.val);
  end;

  procedure set_report_param(p_report_id opas_reports.report_id%type, p_name opas_reports_pars.par_name%type, p_varchar_par varchar2)
  is
  begin
    merge into opas_reports_pars t using (select p_report_id id, p_name nm, p_varchar_par val from dual) s
    on (t.report_id = s.id and t.par_name=s.nm)
    when matched then update set varchar_par = s.val
    when not matched then insert (report_id,par_name,varchar_par) values (s.id, s.nm, s.val);
  end;

  procedure set_report_param(p_report_id opas_reports.report_id%type, p_name opas_reports_pars.par_name%type, p_date_par date)
  is
  begin
    merge into opas_reports_pars t using (select p_report_id id, p_name nm, p_date_par val from dual) s
    on (t.report_id = s.id and t.par_name=s.nm)
    when matched then update set date_par = s.val
    when not matched then insert (report_id,par_name,date_par) values (s.id, s.nm, s.val);
  end;

  function get_reppar_n(p_report_id opas_reports.report_id%type, p_name opas_reports_pars.par_name%type, p_validate boolean default true) return number result_cache
  is
    l_val number;
  begin
    select num_par into l_val from opas_reports_pars where report_id = p_report_id and par_name=p_name;
    if p_validate and l_val is null then raise_application_error(-20000,'Parameter '||p_name||' for report '||p_report_id||' is empty'); end if;
    return l_val;
  exception
    when no_data_found then raise_application_error(-20000,'Parameter: '||p_name||' for report_id: '||p_report_id||' is not defined (get_reppar_n).');
  end;

  function get_reppar_c(p_report_id opas_reports.report_id%type, p_name opas_reports_pars.par_name%type, p_validate boolean default true) return varchar2 result_cache
  is
    l_val opas_reports_pars.varchar_par%type;
  begin
    select varchar_par into l_val from opas_reports_pars where report_id = p_report_id and par_name=p_name;
    if p_validate and l_val is null then raise_application_error(-20000,'Parameter '||p_name||' for report '||p_report_id||' is empty'); end if;
    return l_val;
  exception
    when no_data_found then raise_application_error(-20000,'Parameter: '||p_name||' for report_id: '||p_report_id||' is not defined (get_reppar_c).');
  end;

  function get_reppar_d(p_report_id opas_reports.report_id%type, p_name opas_reports_pars.par_name%type, p_validate boolean default true) return date result_cache
  is
    l_val date;
  begin
    select date_par into l_val from opas_reports_pars where report_id = p_report_id and par_name=p_name;
    if p_validate and l_val is null then raise_application_error(-20000,'Parameter '||p_name||' for report '||p_report_id||' is empty'); end if;
    return l_val;
  exception
    when no_data_found then raise_application_error(-20000,'Parameter: '||p_name||' for report_id: '||p_report_id||' is not defined (get_reppar_d).');
  end;

  function get_inst_list(p_list varchar2, p_col_nm varchar2) return varchar2
  is
    l_list varchar2(1000);
  begin
    if instr(p_list,'-1')>0 then
      return q'[ 1=1 ]';
    else
      l_list := replace(replace(p_list,';',','),':',',');
      return p_col_nm||' in ('||nvl(l_list,'0')||')';
    end if;
  end;

  function get_inst_list(p_list AWRRPT_INSTANCE_LIST_TYPE, p_col_nm varchar2) return varchar2
  is
    l_list varchar2(1000);
  begin
    l_list := p_col_nm||' in (';
    for i in 1..p_list.count loop
      l_list:=l_list||p_list(i)||',';
    end loop;
    l_list:=rtrim(l_list,',');
    return l_list||')';
  end;

  function get_inst_list(p_list varchar2) return AWRRPT_INSTANCE_LIST_TYPE
  is
    l_res  AWRRPT_INSTANCE_LIST_TYPE := AWRRPT_INSTANCE_LIST_TYPE ();
    l_list  varchar2(1000);
    l_token varchar2(100);
    l_delim varchar2(1):=',';
    l_cnt   number := 0;
  begin
    if instr(p_list,'-1')=0 then
      l_list:=replace(replace(p_list,';',l_delim),':',l_delim)||l_delim;
      loop
        l_token:=substr(l_list,1,instr(l_list,l_delim)-1);
        l_res.extend;l_res(l_res.count):=l_token;
        l_list:=ltrim(l_list,l_token||l_delim);
        l_cnt:=l_cnt+1;
        exit when  l_list is null or l_cnt>1000;
      end loop;
    end if;
    return l_res;
  end;

  function get_inst_lst_for_nm(p_list varchar2,p_pref varchar2 default null) return varchar2
  is
  begin
    coremod_log.log(p_list||':'||p_pref);
    if instr(p_list,'-1')>0 then
      return p_pref||'RAC';
    elsif get_inst_list(p_list).count>1 then
      return p_pref||'RAC';
    else
      return p_pref||p_list;
    end if;
  end;

  procedure set_report_task(p_report_id opas_reports.report_id%type, p_tq_id opas_task_queue.tq_id%type)
  is
  begin
    update opas_reports set tq_id=p_tq_id where report_id=p_report_id;
  end;

  procedure set_report_content(p_report_id opas_reports.report_id%type, p_content opas_reports.report_content%type, p_displ_params opas_reports.report_params_displ%type)
  is
  begin
    update opas_reports set report_content=p_content,report_params_displ=p_displ_params  where report_id=p_report_id;
  end;

  procedure queue_report(p_report_id opas_reports.report_id%type)
  is
    l_tq_id opas_task_queue.tq_id%type;
  begin
    l_tq_id:=COREMOD_TASKS.prep_execute_task (  P_TASKNAME => 'OPAS_REPORT', p_task_subname => get_report_type (p_report_id)) ;
    COREMOD_TASKS.set_task_param( p_tq_id => l_tq_id, p_name => 'B1', p_num_par => p_report_id);
    COREMOD_TASKS.queue_task ( p_tq_id => l_tq_id ) ;
    set_report_task(p_report_id,l_tq_id);
  end;

  procedure execute_report(p_report_id opas_reports.report_id%type)
  is
    l_report_type  varchar2(32);
    l_report       coremod_report_utils.t_output_lines;
    l_report_clob  clob;
    l_file_content clob;
    l_file         opas_files.file_id%type;
    l_file_type    opas_files.file_type%type;
    l_file_name    opas_files.file_name%type;
    l_mime         opas_files.FILE_MIMETYPE%type;
    l_displ_params opas_reports.report_params_displ%type;
    l_modname      opas_reports.modname%type;
  begin
    COREMOD_LOG.Start_SQL_GATHER_STAT('COREMOD_REPORT_UTILS.EXECUTE_REPORT.GATHER_SQL_STAT');
    COREMOD_LOG.Start_SQL_TRACE('COREMOD_REPORT_UTILS.EXECUTE_REPORT.SQL_TRACE');

    select modname, report_type into l_modname, l_report_type from opas_reports where report_id=p_report_id;

    coremod_tasks.log('Creating report: '||l_report_type,coremod_tasks.get_curr_tq_id);

    if l_report_type = gSQL_MEMORY_REPORT then
      l_file_type := 'SQL Memory stats report';
      l_file_name := 'opas_sql_'||get_reppar_c(p_report_id,gparSQLID)||'.html';
      l_mime := gReportMimeType;
      l_displ_params := 'SQL_ID: '||get_reppar_c(p_report_id,gparSQLID)||'; DBLINK: '||case when get_reppar_c(p_report_id,gparDBLINK,false) is not null then get_reppar_c(p_report_id,gparDBLINK) else 'Local' end;
      update opas_reports set report_params_displ=l_displ_params where report_id=p_report_id;
      commit;
      l_report := coremod_reports.getreport_sql_memory_stats(p_sql_id => get_reppar_c(p_report_id,gparSQLID),
                                                             p_dblink => case when get_reppar_c(p_report_id,gparDBLINK,false) is not null then COREMOD_API.get_ora_dblink(get_reppar_c(p_report_id,gparDBLINK)) else null end);
      begin
        coremod_reports.queue_report_sql_memory_stats_recursive(p_report_id);
      exception
        when others then coremod_tasks.log('Exception at coremod_reports.queue_report_sql_memory_stats_recursive: '||sqlerrm);
      end;
    elsif l_report_type = gSQL_AWR_REPORT then
      l_file_type := 'SQL AWR stats report';
      l_mime := gReportMimeType;
      l_file_name := 'opas_awr_'||get_reppar_c(p_report_id,gparSQLID)||'.html';
      l_displ_params := 'SQL_ID: '||get_reppar_c(p_report_id,gparSQLID)||case when get_reppar_c(p_report_id,gparDBLINK,false) is null then '; Local DB' else '; DBLINK: '||get_reppar_c(p_report_id,gparDBLINK,false) end||
                      case when nvl(get_reppar_n(p_report_id,gparREP_LIMIT,false),-1)>=0 then '; LIMIT: '||get_reppar_n(p_report_id,gparREP_LIMIT,false) else '; DBID SNAPS: '||get_reppar_n(p_report_id,gparDBID,false)||':'||get_reppar_n(p_report_id,gparMIN_SNAP,false)||':'||get_reppar_n(p_report_id,gparMAX_SNAP,false) end;
      update opas_reports set report_params_displ=l_displ_params where report_id=p_report_id;
      commit;
      l_report := coremod_reports.getreport_sql_awr_stats(p_sql_id       => get_reppar_c(p_report_id,gparSQLID),
                                                          p_dblink       => case when get_reppar_c(p_report_id,gparDBLINK,false) is not null then COREMOD_API.get_ora_dblink(get_reppar_c(p_report_id,gparDBLINK)) else null end,
                                                          p_report_limit => get_reppar_n(p_report_id,gparREP_LIMIT,false),
                                                          p_dbid         => get_reppar_n(p_report_id,gparDBID,false),
                                                          p_min_snap     => get_reppar_n(p_report_id,gparMIN_SNAP,false),
                                                          p_max_snap     => get_reppar_n(p_report_id,gparMAX_SNAP,false)/*,
                                                          p_filename     => l_file_name,
                                                          p_displ_params => l_displ_params*/);
      begin
        coremod_reports.queue_report_sql_awr_stats_recursive(p_report_id);
      exception
        when others then coremod_tasks.log('Exception at coremod_reports.queue_report_sql_awr_stats_recursive: '||sqlerrm);
      end;
    elsif l_report_type = qAWRRPT then
      l_file_type := 'AWR report';
      l_mime := gReportMimeType;
      if get_reppar_c(p_report_id,gparDBLINK,false) is null then

        l_report := coremod_reports.getreport_awrrpt(get_reppar_n(p_report_id,gparDBID),
                                                     get_reppar_n(p_report_id,gparMIN_SNAP),
                                                     get_reppar_n(p_report_id,gparMAX_SNAP),
                                                     get_reppar_c(p_report_id,gparINSTANCE_NUM),l_file_name,l_displ_params);
      else
        l_report_clob := coremod_reports.getreport_awrrpt(get_reppar_n(p_report_id,gparDBID),
                                                          get_reppar_n(p_report_id,gparMIN_SNAP),
                                                          get_reppar_n(p_report_id,gparMAX_SNAP),
                                                          get_reppar_c(p_report_id,gparINSTANCE_NUM),
                                                          get_reppar_c(p_report_id,gparDBLINK),l_file_name,l_displ_params);
      end if;
    elsif l_report_type = qSQAWRRPT then
      l_file_type := 'SQL AWR report';
      l_mime := gReportMimeType;

      if get_reppar_c(p_report_id,gparDBLINK,false) is null then
        l_report := coremod_reports.getreport_sqawrrpt(get_reppar_c(p_report_id,gparSQLID),
                                                       get_reppar_n(p_report_id,gparDBID),
                                                       get_reppar_n(p_report_id,gparMIN_SNAP),
                                                       get_reppar_n(p_report_id,gparMAX_SNAP),
                                                       get_reppar_n(p_report_id,gparINSTANCE_NUM),l_file_name,l_displ_params);
      else
        l_report_clob := coremod_reports.getreport_sqawrrpt(get_reppar_c(p_report_id,gparSQLID),
                                                            get_reppar_n(p_report_id,gparDBID),
                                                            get_reppar_n(p_report_id,gparMIN_SNAP),
                                                            get_reppar_n(p_report_id,gparMAX_SNAP),
                                                            get_reppar_n(p_report_id,gparINSTANCE_NUM),
                                                            get_reppar_c(p_report_id,gparDBLINK),l_file_name,l_displ_params);
      end if;
    elsif l_report_type = qAWRDIFF then
      l_file_type := 'AWR Diff report';
      l_mime := gReportMimeType;

      if get_reppar_c(p_report_id,gparDBLINK,false) is null then
        l_report := coremod_reports.getreport_diffrpt(get_reppar_n(p_report_id,gparDBID),
                                                      get_reppar_n(p_report_id,gparMIN_SNAP),
                                                      get_reppar_n(p_report_id,gparMAX_SNAP),
                                                      get_reppar_c(p_report_id,gparINSTANCE_NUM),
                                                      get_reppar_n(p_report_id,gparDBID2),
                                                      get_reppar_n(p_report_id,gparMIN_SNAP2),
                                                      get_reppar_n(p_report_id,gparMAX_SNAP2),
                                                      get_reppar_c(p_report_id,gparINSTANCE_NUM2),l_file_name,l_displ_params);
      else
        l_report_clob := coremod_reports.getreport_diffrpt(get_reppar_n(p_report_id,gparDBID),
                                                           get_reppar_n(p_report_id,gparMIN_SNAP),
                                                           get_reppar_n(p_report_id,gparMAX_SNAP),
                                                           get_reppar_c(p_report_id,gparINSTANCE_NUM),
                                                           get_reppar_n(p_report_id,gparDBID2),
                                                           get_reppar_n(p_report_id,gparMIN_SNAP2),
                                                           get_reppar_n(p_report_id,gparMAX_SNAP2),
                                                           get_reppar_c(p_report_id,gparINSTANCE_NUM2),
                                                           get_reppar_c(p_report_id,gparDBLINK),l_file_name,l_displ_params);
      end if;
    elsif l_report_type = qASHRPT then
      l_file_type := 'ASH report';
      l_mime := gReportMimeType;

      if get_reppar_c(p_report_id,gparDBLINK,false) is null then
        l_report := coremod_reports.getreport_ashrpt(get_reppar_n(p_report_id,gparDBID),
                                                     get_reppar_d(p_report_id,gparBTIME),
                                                     get_reppar_d(p_report_id,gparETIME),
                                                     get_reppar_c(p_report_id,gparINSTANCE_NUM),l_file_name,l_displ_params);
      else
        l_report_clob := coremod_reports.getreport_ashrpt(get_reppar_n(p_report_id,gparDBID),
                                                          get_reppar_d(p_report_id,gparBTIME),
                                                          get_reppar_d(p_report_id,gparETIME),
                                                          get_reppar_c(p_report_id,gparINSTANCE_NUM),
                                                          get_reppar_c(p_report_id,gparDBLINK),l_file_name,l_displ_params);
      end if;
    end if;

    l_file := COREFILE_API.create_file(P_MODNAME => l_modname,
                                       P_FILE_TYPE => l_file_type,
                                       P_FILE_NAME => l_file_name,
                                       P_MIMETYPE => l_mime,
                                       P_OWNER => get_reppar_c(p_report_id,gparOWNER));

    COREFILE_API.get_locator(l_file,l_file_content);

    if l_report.count>0 then
      for i in 1..l_report.count loop
        l_file_content:=l_file_content||l_report(i)||chr(10);
      end loop;
    else
      l_file_content := l_report_clob;
    end if;

    COREFILE_API.store_content(l_file,l_file_content);
    COREMOD_REPORT_UTILS.save_report_for_download (P_FILE => l_file) ;

    update opas_reports set report_content = l_file, report_params_displ=l_displ_params where report_id=p_report_id;

    commit;

    COREMOD_LOG.Stop_SQL_GATHER_STAT('COREMOD_REPORT_UTILS.EXECUTE_REPORT.GATHER_SQL_STAT');
    COREMOD_LOG.Stop_SQL_TRACE('COREMOD_REPORT_UTILS.EXECUTE_REPORT.SQL_TRACE');
  end;

  procedure drop_report(p_report_id opas_reports.report_id%type)
  is
    l_report_content      opas_reports.report_content%type;
    l_tq_id               opas_task_queue.tq_id%type;
    l_status              OPAS_TASK_QUEUE.status%type;
  begin
    select report_content, tq_id into l_report_content,l_tq_id from opas_reports where report_id=p_report_id;
    if l_tq_id is not null then
      select status into l_status from OPAS_TASK_QUEUE where tq_id=l_tq_id;
      if l_status = coremod_tasks.gtqRUNNING then
        raise_application_error(-20000,'Report can not be dropped while it is running.');
      elsif l_status = coremod_tasks.gtqQUEUED then
        coremod_tasks.cancel_task(l_tq_id);
      end if;
    end if;
    delete from opas_reports where report_id=p_report_id;
    COREFILE_API.delete_file(l_report_content);
  exception
    when no_data_found then raise_application_error(-20000,'Report not found: '||p_report_id);
  end;

--=============================================================================================

    procedure set_report_timing(p_timing boolean) is begin g_timing:=p_timing; end;

    procedure start_tim is
    begin
      if g_timing then
        g_time:=DBMS_UTILITY.GET_TIME;
        g_cpu_tim:=DBMS_UTILITY.GET_CPU_TIME;
      end if;
    end;

    function end_tim(p_is_finished boolean default false) return varchar2 is
      l_delta_t number;
      l_delta_c number;
    begin
      if g_timing then
        l_delta_t:=DBMS_UTILITY.GET_TIME-g_time;
        l_delta_c:=DBMS_UTILITY.GET_CPU_TIME-g_cpu_tim;
        g_tot_tim:=g_tot_tim+l_delta_t;
        g_tot_cpu_tim:=g_tot_cpu_tim+l_delta_c;

        if not p_is_finished then
          return HTF.header (6,cheader=>'Elapsed (sec): '||to_char(round((l_delta_t)/100,2))||'; CPU (sec): '||to_char(round((l_delta_c)/100,2)),cattributes=>'class="awr"');
        else
          return HTF.header (6,cheader=>'Totals: Elapsed (sec): '||to_char(round((g_tot_tim)/100,2))||'; CPU (sec): '||to_char(round((g_tot_cpu_tim)/100,2)),cattributes=>'class="awr"');
        end if;
      else
        return null;
      end if;
    end;


  procedure init_lo_report(p_op_name varchar2, p_target_desc varchar2, p_units varchar2, p_totalwork number)
  is
  begin
    COREMOD_API.init_longops(p_op_name,p_target_desc,p_units,p_totalwork,g_lops_ind);

    g_tot_tim := 0;
    g_tot_cpu_tim := 0;
  end;

  procedure start_lo_section(p_module_name varchar2, p_action_name varchar2)
  is
  begin
    COREMOD_API.start_longops_section ( p_module_name, p_action_name);
    start_tim();
  end;
  function end_lo_section(p_is_finished boolean default false) return varchar2
  is
  begin
    COREMOD_API.end_longops_section(1,g_lops_ind);
    return end_tim(p_is_finished);
  end;

  procedure prepare_saved_sql_script(p_script_name opas_scripts.script_id%type)
  is
    l_script clob;
    l_scr    clob;
    l_line   varchar2(32765);
    l_eol    number;
    l_iter   number := 1;
  begin
    l_script:= coremod_api.getscript(p_script_name);

    --Put at least one EOL into script
    --if instr(l_script,chr(10))=0 then
      l_script:=l_script||chr(10);
    --end if;

    --remove sqlplus settings
    l_scr := l_script;
    l_script:=null;
    loop
      l_eol:=instr(l_scr,chr(10));
      l_line:=substr(l_scr,1,l_eol);

      if upper(l_line) like 'SET%' or
         upper(l_line) like 'COL%' or
         upper(l_line) like 'BREAK%' or
         upper(l_line) like 'ALTER SESSION%' or
         upper(l_line) like 'SERVEROUTPUT%' or
         upper(l_line) like 'REM%' or
         upper(l_line) like '--%'
      then
        null;
      else
        l_script:=l_script||l_line;--||chr(10);
      end if;

      l_scr:=substr(l_scr,l_eol+1);
      l_iter:=l_iter+1;
      exit when l_iter>100000 or dbms_lob.getlength(l_scr)=0;
    end loop;

    if instr(upper(l_script),'BEGIN')=0 then l_script:=replace(l_script,';'); end if;

    update opas_scripts set script_content=l_script where script_id=p_script_name;
  end;

  procedure prepare_script(p_script in out clob,
                           p_sqlid varchar2,
                           p_dbid varchar2 default null,
                           p_inst_id varchar2 default null,
                           p_start_snap number default null,
                           p_end_snap number default null) is
  begin
    p_script:=replace(replace(replace(replace(replace(p_script,'&SQLID.',p_sqlid),'&SQLID',p_sqlid),'&1.',p_sqlid),'&1',p_sqlid),'&VSQL.','gv$sql');
    p_script:=replace(replace(replace(replace(p_script,'&INST_ID.',p_inst_id),'&INST_ID',p_inst_id),'&DBID.',p_dbid),'&DBID',p_dbid);
    p_script:=replace(replace(p_script,'&start_sn.',p_start_snap),'&end_sn.',p_end_snap);
  end;

  procedure get_clob_remotelly(p_sql varchar2, p_dblink varchar2, p_output out clob)
  is
    l_theCursor     integer;
    l_status        integer;
    l_line          varchar2(32767);
    l_output        varchar2(32767);
    l_open          boolean;
    l_sql2exec      varchar2(32767);
    l_sql clob:=
q'[declare
l_out clob; l_len number;
l_chunk varchar2(32767);
l_status integer;
l_pos number;
l_chunk_length number := 32767;
l_r raw(32767);
l_rc raw(32767);
begin
DBMS_OUTPUT.ENABLE(NULL);
begin
<PLSQL_BLOCK>
exception when no_data_found then l_out:='<NO_DATA_FOUND>'; end;
l_pos:=1;l_len:=length(l_out);
loop
  l_chunk:=substr(l_out,l_pos,l_chunk_length);
  l_pos:=l_pos+l_chunk_length;
  l_r:=utl_raw.cast_to_raw(l_chunk);
  l_rc:=UTL_COMPRESS.LZ_COMPRESS(l_r);
  dbms_output.put(l_rc);
  DBMS_OUTPUT.NEW_LINE;
  exit when l_len<l_pos;
end loop;
end;]';
    l_time number := 0;
  begin
    coremod_log.log(p_sql,'DEBUG');
    l_sql:=replace(l_sql,'<PLSQL_BLOCK>',p_sql);
    if length(l_sql) > 32767 then raise_application_error(-20000,'SQL <'||substr(l_sql,1,100)||'...> too long for remote table printing.');end if;
    l_sql2exec:=l_sql;
--dbms_output.put_line(l_sql2exec);
    l_time:=DBMS_UTILITY.GET_TIME;
    execute immediate 'begin :p_theCursor:=dbms_sql.open_cursor@'||p_dblink||'; end;' using out l_theCursor;
    execute immediate 'begin dbms_sql.parse@'||p_dblink||'(:p_theCursor, :p_stmt , :p_flg ); end;' using l_theCursor, l_sql2exec, dbms_sql.native;
    execute immediate 'begin :a:=dbms_sql.execute@'||p_dblink||'(:p_theCursor); end;' using out l_status, in l_theCursor;
    execute immediate 'begin dbms_sql.close_cursor@'||p_dblink||'(:p_theCursor); end;' using in out l_theCursor;
    l_time:=DBMS_UTILITY.GET_TIME-l_time;
    coremod_log.log('Executing: '||(l_time/100),'DEBUG');
    l_time:=DBMS_UTILITY.GET_TIME;
    loop
      execute immediate 'begin DBMS_OUTPUT.GET_LINE@'||p_dblink||'(line => :p_line, status => :p_status); end;' using out l_line, out l_status;
      exit when l_status=1;
      --p_output:=p_output||l_line||chr(10);
      p_output:=p_output||utl_raw.cast_to_varchar2(UTL_COMPRESS.LZ_UNCOMPRESS(l_line));
    end loop;
    if instr(p_output,'<NO_DATA_FOUND>')>0 then p_output:=null; end if;
    l_time:=DBMS_UTILITY.GET_TIME-l_time;
    coremod_log.log('Getting output: '||(l_time/100),'DEBUG');
  exception
    when others then
       execute immediate 'begin :p_open:=dbms_sql.IS_OPEN@'||p_dblink||'(:p_theCursor); end;' using out l_open, in l_theCursor;
      if l_open then
        execute immediate 'begin dbms_sql.close_cursor@'||p_dblink||'(:p_theCursor); end;' using in out l_theCursor;
      end if;
      coremod_log.log('Error in COREMOD_REPORT_UTILS.get_clob_emotelly: '||sqlerrm);
      coremod_log.log('Error in COREMOD_REPORT_UTILS.get_clob_emotelly: SQL: '||l_sql2exec);
      coremod_log.log('Error in COREMOD_REPORT_UTILS.get_clob_emotelly: Error stack: '||DBMS_UTILITY.FORMAT_ERROR_STACK);
      raise_application_error(-20000,'Error in COREMOD_REPORT_UTILS.get_clob_emotelly: '||sqlerrm);
  end;

  procedure execute_plsql(p_sql varchar2, p_output out clob, p_is_output boolean default true)
  is
    l_chunk varchar2(32767);
    l_status integer;
  begin
    if p_is_output then dbms_output.enable(null); end if;
    execute immediate p_sql;
    if p_is_output then
      loop
        DBMS_OUTPUT.GET_LINE(l_chunk,l_status);
        exit when l_status=1;
        p_output:=p_output||l_chunk||chr(10);
      end loop;
    end if;
  end;

  procedure execute_plsql_remotelly(p_sql varchar2, p_dblink varchar2, p_output out clob, p_is_output boolean default true)
  is
    l_theCursor     integer;
    l_status        integer;
    l_line          varchar2(32767);
    l_output        varchar2(32767);
    l_open          boolean;
    l_sql2exec      varchar2(32767);
    l_sql clob:=
q'[declare
l_out clob; l_len number;
l_chunk varchar2(32767);
l_status integer;
l_pos number;
l_chunk_length number := 32767;
l_r raw(32767);
l_rc raw(32767);
begin
DBMS_OUTPUT.ENABLE(NULL);
<PLSQL_BLOCK>
]'||
case when p_is_output then
q'[loop
  DBMS_OUTPUT.GET_LINE(l_chunk,l_status);
  exit when l_status=1;
  l_out:=l_out||l_chunk||chr(10);
end loop;
if l_out is null then l_out:='No data found.';end if;
l_pos:=1;l_len:=length(l_out);
loop
  l_chunk:=substr(l_out,l_pos,l_chunk_length);
  l_pos:=l_pos+l_chunk_length;
  l_r:=utl_raw.cast_to_raw(l_chunk);
  l_rc:=UTL_COMPRESS.LZ_COMPRESS(l_r);
  dbms_output.put(l_rc);
  DBMS_OUTPUT.NEW_LINE;
  exit when l_len<l_pos;
end loop;
end;]'
else q'[end;]' end;
    l_time number := 0;
  begin
    coremod_log.log(p_sql,'DEBUG');
    l_sql:=replace(l_sql,'<PLSQL_BLOCK>',p_sql);
    if length(l_sql) > 32767 then raise_application_error(-20000,'SQL <'||substr(l_sql,1,100)||'...> too long for remote table printing.');end if;
    l_sql2exec:=l_sql;
--dbms_output.put_line(l_sql2exec);
--coremod_log.log('l_sql2exec: '||l_sql2exec);
    l_time:=DBMS_UTILITY.GET_TIME;
    execute immediate 'begin :p_theCursor:=dbms_sql.open_cursor@'||p_dblink||'; end;' using out l_theCursor;
    execute immediate 'begin dbms_sql.parse@'||p_dblink||'(:p_theCursor, :p_stmt , :p_flg ); end;' using l_theCursor, l_sql2exec, dbms_sql.native;
    execute immediate 'begin :a:=dbms_sql.execute@'||p_dblink||'(:p_theCursor); end;' using out l_status, in l_theCursor;
    execute immediate 'begin dbms_sql.close_cursor@'||p_dblink||'(:p_theCursor); end;' using in out l_theCursor;
    l_time:=DBMS_UTILITY.GET_TIME-l_time;
    coremod_log.log('Executing: '||(l_time/100),'DEBUG');
    l_time:=DBMS_UTILITY.GET_TIME;
    loop
      execute immediate 'begin DBMS_OUTPUT.GET_LINE@'||p_dblink||'(line => :p_line, status => :p_status); end;' using out l_line, out l_status;
      exit when l_status=1;
      --p_output:=p_output||l_line||chr(10);
      p_output:=p_output||utl_raw.cast_to_varchar2(UTL_COMPRESS.LZ_UNCOMPRESS(l_line));
    end loop;
    l_time:=DBMS_UTILITY.GET_TIME-l_time;
    coremod_log.log('Getting output: '||(l_time/100),'DEBUG');
  exception
    when others then
       execute immediate 'begin :p_open:=dbms_sql.IS_OPEN@'||p_dblink||'(:p_theCursor); end;' using out l_open, in l_theCursor;
      if l_open then
        execute immediate 'begin dbms_sql.close_cursor@'||p_dblink||'(:p_theCursor); end;' using in out l_theCursor;
      end if;
      coremod_log.log('execute_plsql_remotelly: Error: '||sqlerrm);
      coremod_log.log('execute_plsql_remotelly: Original SQL: '||p_sql);
      coremod_log.log('execute_plsql_remotelly: Final SQL: '||l_sql2exec);
      coremod_log.log('execute_plsql_remotelly: Error stack: '||DBMS_UTILITY.FORMAT_ERROR_STACK);
      raise_application_error(-20000,'Error in COREMOD_REPORT_UTILS.execute_plsql_remotelly: '||sqlerrm);
  end;

  procedure execute_plsql_remotelly(p_sql varchar2, p_dblink varchar2, p_output out t_output_lines)
  is
    l_output        clob;
    l_line varchar2(32767);
    l_eof  number;
    l_iter number := 1;
    l_off  number:=1;
  begin
    execute_plsql_remotelly(p_sql, p_dblink, l_output);
    loop
      l_eof:=instr(l_output,chr(10),l_off);
      if l_eof=0 then
        p_output(l_iter):=rtrim(rtrim(substr(l_output,l_off),chr(13)),chr(10));
      else
        p_output(l_iter):=rtrim(rtrim(substr(l_output,l_off,l_eof-l_off+1),chr(13)),chr(10));
      end if;
      l_off:=1+l_eof;
      l_iter:=l_iter+1;
      exit when l_eof=0;
    end loop;
  end;

  procedure print_table_html_remotelly(p_query in varchar2,
                                       p_width number,
                                       p_summary varchar2,
                                       p_search varchar2 default null,
                                       p_replacement varchar2 default null,
                                       p_style1 varchar2 default 'awrc1',
                                       p_style2  varchar2 default 'awrnc1',
                                       p_header number default 0,
                                       p_break_col varchar2 default null,
                                       p_dblink varchar2,
                                       p_output out t_output_lines)
  is
    l_sql clob:=  q'[declare
  l_sql varchar2(32767) := q'^<SQL_QUERY>^';
  <PRN_HTML_TBL_PROC>
begin
  print_table_html(
   p_query => l_sql
   ,p_width => ]'||p_width||q'[
   ,p_summary => q'^]'||p_summary||q'[^' <p_search> <p_replacement> <p_style1> <p_style2> <p_header> <p_break_col> <p_row_limit>);
end;]';
    l_sql_to_exec varchar2(32767);
  BEGIN
    if p_dblink is null then raise_application_error(-20000, 'Parameter p_dblink must be specified'); end if;

    l_sql:=replace(replace(l_sql,'<PRN_HTML_TBL_PROC>',coremod_api.getscript('PROC_PRNHTMLTBL')),'<SQL_QUERY>',p_query);

    if p_search is not null then l_sql:=replace(l_sql,'<p_search>',q'[,p_search => q'^]'||p_search||q'[^']'||chr(10)); else l_sql:=replace(l_sql,'<p_search>'); end if;
    if p_replacement is not null then l_sql:=replace(l_sql,'<p_replacement>',q'[,p_replacement => q'^]'||p_replacement||q'[^']'||chr(10)); else l_sql:=replace(l_sql,'<p_replacement>'); end if;
    if p_style1 is not null then l_sql:=replace(l_sql,'<p_style1>',q'[,p_style1 => q'^]'||p_style1||q'[^']'||chr(10)); else l_sql:=replace(l_sql,'<p_style1>'); end if;
    if p_style2 is not null then l_sql:=replace(l_sql,'<p_style2>',q'[,p_style2 => q'^]'||p_style2||q'[^']'||chr(10)); else l_sql:=replace(l_sql,'<p_style2>'); end if;
    if p_header is not null then l_sql:=replace(l_sql,'<p_header>',q'[,p_header => ]'||p_header||chr(10)); else l_sql:=replace(l_sql,'<p_header>'); end if;
    if p_break_col is not null then l_sql:=replace(l_sql,'<p_break_col>',q'[,p_break_col => q'^]'||p_break_col||q'[^']'||chr(10)); else l_sql:=replace(l_sql,'<p_break_col>'); end if;

    l_sql:=replace(l_sql,'<p_row_limit>',',p_row_limit => '||COREMOD_API.getconf('LONGSECTROWS',COREMOD_API.gMODNAME)||chr(10));

    if length(L_SQL) > 32767 then raise_application_error(-20000,'SQL <'||substr(p_query,1,100)||'...> too long for remote table printing.');end if;
    --dbms_output.put_line('length(P_SQL): '||length(L_SQL));
    l_sql_to_exec:=l_sql;
    --dbms_output.put_line(l_sql_to_exec);
    execute_plsql_remotelly
       (  P_SQL => l_sql_to_exec,
          P_DBLINK => P_DBLINK,
          P_OUTPUT => P_OUTPUT) ;
  END;

  procedure print_table_html(p_query in varchar2,
                             p_width number,
                             p_summary varchar2,
                             p_search varchar2 default null,
                             p_replacement varchar2 default null,
                             p_style1 varchar2 default 'awrc1',
                             p_style2  varchar2 default 'awrnc1',
                             p_header number default 0,
                             p_break_col varchar2 default null,
                             p_output in out t_output_lines) is
    l_theCursor   integer default dbms_sql.open_cursor;
    l_columnValue varchar2(32767);
    l_status      integer;
    l_descTbl     dbms_sql.desc_tab2;
    l_colCnt      number;
    l_rn          number := 0;
    l_style       varchar2(100);
    l_break_value varchar2(4000) := null;
    l_break_cnt   number := 1;
    l_indx   number := p_output.count + 1;
    l_output t_output_lines;
    l_widest number := 0;

    l_long_sect_rows    number := COREMOD_API.getconf('LONGSECTROWS',COREMOD_API.gMODNAME);

    procedure p(p_line varchar2) is
    begin
      l_output(l_indx):=p_line;
      l_indx := l_indx + 1;
    end;

    procedure output is
      l_indx number;
    begin
      if l_output.count<=nvl(l_long_sect_rows,1000) then
        for i in 1..l_output.count loop
          p_output(i):=l_output(i);
        end loop;
      else
        for i in 1..round(nvl(l_long_sect_rows,1000)/2) loop
          p_output(i):=l_output(i);
        end loop;
        l_indx := p_output.count+1;
        for i in l_output.count-round(nvl(l_long_sect_rows,1000)/2)..l_output.count loop
          p_output(l_indx):=l_output(i);
          l_indx:=l_indx+1;
        end loop;
        p_output(p_output.count+1) := 'Output is truncated: first and last '||round(nvl(l_long_sect_rows,1000)/2)||' rows are shown';
      end if;
    end;
  begin
    --p(HTF.TABLEOPEN(cborder=>0,cattributes=>'width="'||p_width||'" class="tdiff" summary="'||p_summary||'"'));
    p(HTF.TABLEOPEN(cborder=>0,cattributes=>'width="<width>" class="tdiff" summary="'||p_summary||'"'));

    dbms_sql.parse(l_theCursor, p_query, dbms_sql.native);
    dbms_sql.describe_columns2(l_theCursor, l_colCnt, l_descTbl);

    for i in 1 .. l_colCnt loop
      dbms_sql.define_column(l_theCursor, i, l_columnValue, 4000);
    end loop;

    l_status := dbms_sql.execute(l_theCursor);

    --column names
    p(HTF.TABLEROWOPEN);
    for i in 1 .. l_colCnt loop
      p(HTF.TABLEHEADER(cvalue=>l_descTbl(i).col_name,calign=>'left',cattributes=>'class="awrbg" scope="col"'));
    end loop;
    p(HTF.TABLEROWCLOSE);

    while (dbms_sql.fetch_rows(l_theCursor) > 0) loop
      p(HTF.TABLEROWOPEN);
      l_rn := l_rn + 1;
      --coloring for rows for breaking column value
      if p_break_col is null then
        l_style := case when mod(l_rn,2)=0 then p_style1 else p_style2 end;
      else
        for i in 1 .. l_colCnt loop
          dbms_sql.column_value(l_theCursor, i, l_columnValue);

          if p_break_col is not null and upper(p_break_col)=upper(l_descTbl(i).col_name) then
            if nvl(l_break_value,'$~') <> nvl(l_columnValue,'$~') then
              l_break_value:=l_columnValue;
              l_break_cnt:=l_break_cnt+1;
            end if;
          end if;

          if p_break_col is not null then
            l_style := case when mod(l_break_cnt,2)=0 then p_style1 else p_style2 end;
          end if;
        end loop;
      end if;
      -----------------------------------------------------------------------------
      for i in 1 .. l_colCnt loop
        dbms_sql.column_value(l_theCursor, i, l_columnValue);

        if l_colCnt = 1 and nvl(length(l_columnValue),0)>l_widest then l_widest:=length(l_columnValue); end if;

        l_columnValue:=replace(replace(l_columnValue,chr(13)||chr(10),chr(10)||'<br/>'),chr(10),chr(10)||'<br/>');
        if p_search is not null then
          if instr(l_descTbl(i).col_name,p_search)>0 then
            l_columnValue:=REGEXP_REPLACE(l_columnValue,'(.*)',p_replacement);
            p(HTF.TABLEDATA(cvalue=>l_columnValue,calign=>'left',cattributes=>'class="'|| l_style ||'"'));
          elsif regexp_instr(l_columnValue,p_search)>0 then
            l_columnValue:=REGEXP_REPLACE(l_columnValue,p_search,p_replacement);
            p(HTF.TABLEDATA(cvalue=>l_columnValue,calign=>'left',cattributes=>'class="'|| l_style ||'"'));
          else
            p(HTF.TABLEDATA(cvalue=>replace(l_columnValue,'  ','&nbsp;&nbsp;'),calign=>'left',cattributes=>'class="'|| l_style ||'"'));
          end if;
        else
          p(HTF.TABLEDATA(cvalue=>replace(l_columnValue,'  ','&nbsp;&nbsp;'),calign=>'left',cattributes=>'class="'|| l_style ||'"'));
        end if;
      end loop;
      p(HTF.TABLEROWCLOSE);
      if p_header > 0 then
        if mod(l_rn,p_header)=0 then
          p(HTF.TABLEROWOPEN);
          for i in 1 .. l_colCnt loop
            p(HTF.TABLEHEADER(cvalue=>l_descTbl(i).col_name,calign=>'left',cattributes=>'class="awrbg" scope="col"'));
          end loop;
          p(HTF.TABLEROWCLOSE);
        end if;
      end if;
    end loop;
    dbms_sql.close_cursor(l_theCursor);
    p(HTF.TABLECLOSE);

    output();

    if l_colCnt = 1 then
      p_output(1):=replace(p_output(1),'<width>',round(l_widest*8));
    end if;
    p_output(1):=replace(p_output(1),'<width>',p_width);

  exception
    when others then
      if DBMS_SQL.IS_OPEN(l_theCursor) then dbms_sql.close_cursor(l_theCursor);end if;
      coremod_log.log('print_table_html: Error: '||sqlerrm);
      coremod_log.log('print_table_html: Original SQL: '||p_query);
      coremod_log.log('print_table_html: Error stack: '||DBMS_UTILITY.FORMAT_ERROR_STACK);
      raise_application_error(-20000, 'print_table_html'||chr(10)||sqlerrm||chr(10));
  end;

  procedure print_text_as_table(p_text clob, p_t_header varchar2, p_width number, p_search varchar2 default null, p_replacement varchar2 default null, p_comparison boolean default false, p_output out t_output_lines) is
    l_line varchar2(32765);  l_eof number;  l_iter number; l_length number;
    l_text clob;
    l_style1 varchar2(10) := 'awrc1';
    l_style2 varchar2(10) := 'awrnc1';

    l_style_comp1 varchar2(10) := 'awrcc1';
    l_style_comp2 varchar2(10) := 'awrncc1';

    l_pref varchar2(10) := 'z';

    l_indx   number := 1;
    procedure p(p_line varchar2) is
    begin
      p_output(l_indx):=p_line;
      l_indx := l_indx + 1;
    end;
  begin

    --p(HTF.TABLEOPEN(cborder=>0,cattributes=>'width="'||p_width||'" class="tdiff" summary="'||p_t_header||'"'));
    p(HTF.TABLEOPEN(cborder=>0,cattributes=>'width="<width>" class="tdiff" summary="'||p_t_header||'"'));

    if p_t_header<>'#FIRST_LINE#' then
      p(HTF.TABLEROWOPEN);
      p(HTF.TABLEHEADER(cvalue=>replace(p_t_header,' ','&nbsp;'),calign=>'left',cattributes=>'class="awrbg" scope="col"'));
      p(HTF.TABLEROWCLOSE);
    end if;

    if instr(p_text,chr(10))=0 then
      l_iter := 1;
      l_length:=dbms_lob.getlength(p_text);
      loop
        l_text := l_text||substr(p_text,l_iter,200)||chr(10);
        l_iter:=l_iter+200;
        exit when l_iter>=l_length;
      end loop;
    else
      l_text := p_text||chr(10);
    end if;

    l_iter := 1;
    loop
      l_eof:=instr(l_text,chr(10));
      l_line:=substr(l_text,1,l_eof);

      if p_t_header='#FIRST_LINE#' and l_iter = 1 then
        p(HTF.TABLEROWOPEN);
        p(HTF.TABLEHEADER(cvalue=>replace(l_line,' ','&nbsp;'),calign=>'left',cattributes=>'class="awrbg" scope="col"'));
        p(HTF.TABLEROWCLOSE);
      else
        p(HTF.TABLEROWOPEN);

        if p_comparison and substr(l_line,1,3)='~~*' then
          l_pref:=substr(l_line,1,7);
          l_line:=substr(l_line,8);
          l_pref:=substr(l_pref,4,1);
        end if;

        if p_search is not null and regexp_instr(l_line,p_search)>0 then
          l_line:=REGEXP_REPLACE(l_line,p_search,p_replacement);
        else
          l_line:=replace(l_line,' ','&nbsp;');
        end if;
        l_line:=replace(l_line,'`',' ');

        if p_comparison and l_pref in ('-') then
          p(HTF.TABLEDATA(cvalue=>l_line,calign=>'left',cattributes=>'class="'|| case when mod(l_iter,2)=0 then l_style_comp1 else l_style_comp2 end ||'"'));
        else
          p(HTF.TABLEDATA(cvalue=>l_line,calign=>'left',cattributes=>'class="'|| case when mod(l_iter,2)=0 then l_style1 else l_style2 end ||'"'));
        end if;

        p(HTF.TABLEROWCLOSE);
      end if;
      l_text:=substr(l_text,l_eof+1);  l_iter:=l_iter+1;
      exit when l_iter>10000 or dbms_lob.getlength(l_text)=0;
    end loop;

    p(HTF.TABLECLOSE);
  end;

  procedure print_clob_as_text(p_text clob, p_output out t_output_lines) is
    l_line varchar2(32765);  l_eof number;  l_iter number; l_length number;
    l_text clob;

    l_indx   number := 1;
    procedure p(p_line varchar2) is
    begin
      p_output(l_indx):=p_line;
      l_indx := l_indx + 1;
    end;
  begin

    if instr(p_text,chr(10))=0 then
      l_iter := 1;
      l_length:=dbms_lob.getlength(p_text);
      loop
        l_text := l_text||substr(p_text,l_iter,200)||chr(10);
        l_iter:=l_iter+200;
        exit when l_iter>=l_length;
      end loop;
    else
      l_text := p_text||chr(10);
    end if;

    l_iter := 1;
    loop
      l_eof:=instr(l_text,chr(10));
      l_line:=substr(l_text,1,l_eof);
      p(l_line);
      l_text:=substr(l_text,l_eof+1);  l_iter:=l_iter+1;
      exit when l_iter>100000 or dbms_lob.getlength(l_text)=0;
    end loop;

  end;

  procedure save_report_for_download(p_file opas_files.file_id%type)
  is
    --PRAGMA AUTONOMOUS_TRANSACTION;
    l_rpt clob;
    l_pref clob;
    l_brpt blob;
    l_doff number := 1;
    l_soff number := 1;
    l_cont integer := DBMS_LOB.DEFAULT_LANG_CTX;
    l_warn integer;

    l_file opas_files%rowtype;
  begin
    select * into l_file from opas_files where file_id=p_file for update;
    update opas_files set file_contentb=empty_blob() where file_id=p_file returning file_contentb into l_file.file_contentb;

    l_pref:=l_pref||HTF.HTMLOPEN||chr(10);
    l_pref:=l_pref||HTF.HEADOPEN||chr(10);
    l_pref:=l_pref||HTF.TITLE(l_file.file_type)||chr(10);

    l_pref:=l_pref||'<style type="text/css">'||chr(10);
    l_pref:=l_pref||coremod_api.getscript('PROC_AWRCSS')||chr(10);
    l_pref:=l_pref||'</style>'||chr(10);
    l_pref:=l_pref||HTF.HEADCLOSE||chr(10);
    l_pref:=l_pref||HTF.BODYOPEN(cattributes=>'class="awr"')||chr(10);

    l_rpt:=l_rpt||l_file.file_contentc;

    l_rpt:=l_pref||chr(10)||l_rpt;
    l_rpt:=l_rpt||(HTF.BODYCLOSE)||chr(10);
    l_rpt:=l_rpt||(HTF.HTMLCLOSE);

    DBMS_LOB.CONVERTTOBLOB(
      dest_lob       => l_file.file_contentb,
      src_clob       => l_rpt,
      amount         => DBMS_LOB.LOBMAXSIZE,
      dest_offset    => l_doff,
      src_offset     => l_soff,
      blob_csid      => DBMS_LOB.DEFAULT_CSID,
      lang_context   => l_cont,
      warning        => l_warn);
    --commit;
  end;

  procedure print_table_html_new
                            (p_query in varchar2,
                             p_width number,
                             p_summary varchar2,
                             p_style_tab varchar2,
                             p_style_head varchar2, --head
                             p_style_r1 varchar2,   --odd rows
                             p_style_r2  varchar2, --even rows
                             p_style_finrow  varchar2, --final row
                             p_search varchar2 default null,
                             p_replacement varchar2 default null,
                             p_header number default 0,
                             p_break_col varchar2 default null,
                             p_output in out t_output_lines) is
    l_theCursor   integer default dbms_sql.open_cursor;
    l_columnValue varchar2(32767);
    l_status      integer;
    l_descTbl     dbms_sql.desc_tab2;
    l_colCnt      number;
    l_rn          number := 0;
    l_style       varchar2(100);
    l_break_value varchar2(4000) := null;
    l_break_cnt   number := 1;
    l_indx   number := p_output.count + 1;

    l_final_row_col number;

    procedure p(p_line varchar2) is
    begin
      p_output(l_indx):=p_line;
      l_indx := l_indx + 1;
    end;
  begin
    p(HTF.TABLEOPEN(cborder=>0,cattributes=>'width="'||p_width||'" class="'||p_style_tab||'" summary="'||p_summary||'"'));

    dbms_sql.parse(l_theCursor, p_query, dbms_sql.native);
    dbms_sql.describe_columns2(l_theCursor, l_colCnt, l_descTbl);

    for i in 1 .. l_colCnt loop
      dbms_sql.define_column(l_theCursor, i, l_columnValue, 4000);
    end loop;

    l_status := dbms_sql.execute(l_theCursor);

    --column names
    if p_style_head is not null then
      p(HTF.TABLEROWOPEN);
      for i in 1 .. l_colCnt loop
        if instr(upper(l_descTbl(i).col_name),'NOPRN')=0 then
          p(HTF.TABLEHEADER(cvalue=>l_descTbl(i).col_name,calign=>'left',cattributes=>'class="'||p_style_head||'" scope="col"'));
        elsif instr(upper(l_descTbl(i).col_name),'LASTROW')>0 then
          l_final_row_col:=i;
        end if;
      end loop;
      p(HTF.TABLEROWCLOSE);
    end if;

    while dbms_sql.fetch_rows(l_theCursor) > 0 loop
      p(HTF.TABLEROWOPEN);
      l_rn := l_rn + 1;
      --coloring for rows for breaking column value
      if p_break_col is null then
        l_style := case when mod(l_rn,2)=0 then p_style_r1 else p_style_r2 end;
      else
        for i in 1 .. l_colCnt loop
          if instr(upper(l_descTbl(i).col_name),'NOPRN')=0 then
            dbms_sql.column_value(l_theCursor, i, l_columnValue);

            if p_break_col is not null and upper(p_break_col)=upper(l_descTbl(i).col_name) then
              if nvl(l_break_value,'$~') <> nvl(l_columnValue,'$~') then
                l_break_value:=l_columnValue;
                l_break_cnt:=l_break_cnt+1;
              end if;
            end if;

            if p_break_col is not null then
              l_style := case when mod(l_break_cnt,2)=0 then p_style_r1 else p_style_r2 end;
            end if;
          end if;
        end loop;
      end if;
      if p_style_finrow is not null then
        dbms_sql.column_value(l_theCursor, l_final_row_col, l_columnValue);
        if l_columnValue = 1 then l_style:=p_style_finrow; end if;
      end if;
      -----------------------------------------------------------------------------
      for i in 1 .. l_colCnt loop
        if instr(upper(l_descTbl(i).col_name),'NOPRN')=0 then
          dbms_sql.column_value(l_theCursor, i, l_columnValue);

          l_columnValue:=replace(replace(l_columnValue,chr(13)||chr(10),chr(10)||'<br/>'),chr(10),chr(10)||'<br/>');
          if p_search is not null then
            if instr(l_descTbl(i).col_name,p_search)>0 then
              l_columnValue:=REGEXP_REPLACE(l_columnValue,'(.*)',p_replacement);
              p(HTF.TABLEDATA(cvalue=>l_columnValue,calign=>'left',cattributes=>'class="'|| l_style ||'"'));
            elsif regexp_instr(l_columnValue,p_search)>0 then
              l_columnValue:=REGEXP_REPLACE(l_columnValue,p_search,p_replacement);
              p(HTF.TABLEDATA(cvalue=>l_columnValue,calign=>'left',cattributes=>'class="'|| l_style ||'"'));
            else
              p(HTF.TABLEDATA(cvalue=>replace(l_columnValue,'  ','&nbsp;&nbsp;'),calign=>'left',cattributes=>'class="'|| l_style ||'"'));
            end if;
          else
            p(HTF.TABLEDATA(cvalue=>replace(l_columnValue,'  ','&nbsp;&nbsp;'),calign=>'left',cattributes=>'class="'|| l_style ||'"'));
          end if;
        end if;
      end loop;
      p(HTF.TABLEROWCLOSE);
      if p_header > 0 and p_style_head is not null then
        if mod(l_rn,p_header)=0 then
          p(HTF.TABLEROWOPEN);
          for i in 1 .. l_colCnt loop
            if instr(upper(l_descTbl(i).col_name),'NOPRN')=0 then
              p(HTF.TABLEHEADER(cvalue=>l_descTbl(i).col_name,calign=>'left',cattributes=>'class="'||p_style_head||'" scope="col"'));
            end if;
          end loop;
          p(HTF.TABLEROWCLOSE);
        end if;
      end if;
    end loop;
    dbms_sql.close_cursor(l_theCursor);
    p(HTF.TABLECLOSE);
  exception
    when others then
      if DBMS_SQL.IS_OPEN(l_theCursor) then dbms_sql.close_cursor(l_theCursor);end if;
      p(p_query);
      raise_application_error(-20000, 'print_table_html'||chr(10)||sqlerrm||chr(10)||chr(10)||DBMS_UTILITY.FORMAT_ERROR_BACKTRACE);
  end print_table_html_new;


  procedure print_text_as_table_new(p_text clob,
                                    p_t_header varchar2,
                                    p_width number,
                                    p_search varchar2 default null,
                                    p_replacement varchar2 default null,
                                    p_comparison boolean default false,
                                    p_style_tab varchar2,
                                    p_style_head varchar2, --head
                                    p_style_r1 varchar2,   --odd rows
                                    p_style_r2  varchar2, --even rows
                                    p_output in out t_output_lines) is
    l_line varchar2(32765);  l_eof number;  l_iter number; l_length number;
    l_text clob;
    --l_style1 varchar2(10) := 'awrc1';
    --l_style2 varchar2(10) := 'awrnc1';

    --l_style_comp1 varchar2(10) := 'awrcc1';
    --l_style_comp2 varchar2(10) := 'awrncc1';

    l_pref varchar2(10) := 'z';

    l_indx   number := p_output.count + 1;
    procedure p(p_line varchar2) is
    begin
      p_output(l_indx):=p_line;
      l_indx := l_indx + 1;
    end;
  begin

    p(HTF.TABLEOPEN(cborder=>0,cattributes=>'width="'||p_width||'" class="'||p_style_tab||'" summary="'||p_t_header||'"'));
    if p_t_header<>'#FIRST_LINE#' then
      p(HTF.TABLEROWOPEN);
      p(HTF.TABLEHEADER(cvalue=>replace(p_t_header,' ','&nbsp;'),calign=>'left',cattributes=>'class="'||p_style_head||'" scope="col"'));
      p(HTF.TABLEROWCLOSE);
    end if;

    if instr(p_text,chr(10))=0 then
      l_iter := 1;
      l_length:=dbms_lob.getlength(p_text);
      loop
        l_text := l_text||substr(p_text,l_iter,200)||chr(10);
        l_iter:=l_iter+200;
        exit when l_iter>=l_length;
      end loop;
    else
      l_text := p_text||chr(10);
    end if;

    l_iter := 1;
    loop
      l_eof:=instr(l_text,chr(10));
      l_line:=substr(l_text,1,l_eof);

      if p_t_header='#FIRST_LINE#' and l_iter = 1 then
        p(HTF.TABLEROWOPEN);
        p(HTF.TABLEHEADER(cvalue=>replace(l_line,' ','&nbsp;'),calign=>'left',cattributes=>'class="awrbg" scope="col"'));
        p(HTF.TABLEROWCLOSE);
      else
        p(HTF.TABLEROWOPEN);

        if p_comparison and substr(l_line,1,3)='~~*' then
          l_pref:=substr(l_line,1,7);
          l_line:=substr(l_line,8);
          l_pref:=substr(l_pref,4,1);
        end if;

        if p_search is not null and regexp_instr(l_line,p_search)>0 then
          l_line:=REGEXP_REPLACE(l_line,p_search,p_replacement);
        else
          l_line:=replace(l_line,' ','&nbsp;');
        end if;
        l_line:=replace(l_line,'`',' ');
        if p_comparison and l_pref in ('-') then
          p(HTF.TABLEDATA(cvalue=>l_line,calign=>'left',cattributes=>'class="'|| case when mod(l_iter,2)=0 then p_style_r1 else p_style_r2 end ||'"'));
        else
          p(HTF.TABLEDATA(cvalue=>l_line,calign=>'left',cattributes=>'class="'|| case when mod(l_iter,2)=0 then p_style_r1 else p_style_r2 end ||'"'));
        end if;

        p(HTF.TABLEROWCLOSE);
      end if;
      l_text:=substr(l_text,l_eof+1);  l_iter:=l_iter+1;
      exit when l_iter>10000 or dbms_lob.getlength(l_text)=0;
    end loop;

    p(HTF.TABLECLOSE);
  end print_text_as_table_new;

  procedure CLEANUP_CACHE
  is
  begin
    delete from opas_qry_cache where hit_num <= 0 and created < (systimestamp - to_number(COREMOD_API.getconf('SQLCACHERETENTION',COREMOD_API.gMODNAME)));
    coremod_log.log('Cleanup query cache: Deleted '||sql%rowcount||' query text(s).');
    if sysdate - trunc(sysdate) between 23.05/24 and 23.45/24 then --decrement of cache hit once per day
      update opas_qry_cache set hit_num = hit_num - 1;
    end if;
    commit;
  exception
    when others then
      rollback;
      dbms_output.put_line(sqlerrm);
      coremod_log.log('COREMOD_REPORT_UTILS.CLEANUP_CACHE_INT error: '||sqlerrm);
  end;

  procedure add_qry2cache_i(p_sql_id varchar2, p_qry_text clob)
  is
  begin
    MERGE INTO opas_qry_cache t
      using (select p_sql_id sql_id, p_qry_text txt from dual) s
      on (t.sql_id=s.sql_id)
      when not matched then
        insert (sql_id,sql_text,created)
         VALUES (s.sql_id,s.txt,default);
  end;

  procedure add_qry2cache(p_sql_id varchar2, p_qry_text clob)
  is
    pragma autonomous_transaction;
  begin
    add_qry2cache_i(p_sql_id, p_qry_text);
    pin_sql_in_cache(p_sql_id,365);
    commit;
  end;

  procedure set_sql_cache_hit(p_sql_id opas_qry_cache.sql_id%type, p_hit opas_qry_cache.hit_num%type)
  is
  begin
    update opas_qry_cache set hit_num = hit_num + p_hit where sql_id = p_sql_id;
  end;

  procedure pin_sql_in_cache(p_sql_id varchar2, p_days number default 180)
  is
  begin
    update opas_qry_cache set hit_num = case when p_days > hit_num then p_days else hit_num end where sql_id = p_sql_id;
  end;

  function get_sql_search_query(p_srcdb varchar2, p_sql_search_str varchar2, p_use_cache varchar2 default 'N', p_result_limit number default 0) return varchar2
  is
    l_dblink varchar2(512);
  begin
    if (p_srcdb is null and p_sql_search_str is null) or p_sql_search_str is null then
      return q'[select /*+ qb_name(OPAS_SEARCH) */ 1 nn#, 'Local query cache' source_tab, '$LOCAL$' source_db, sql_id, cast(substr(sql_text,1,4000) as varchar2(4000)) sql_text from opas_qry_cache
                 where 1=2]';
    elsif p_srcdb is null or p_srcdb = '$LOCAL$' then
      return q'[select * from
               (select /*+ qb_name(OPAS_SEARCH) */ 1 nn#, 'Local query cache' source_tab, '$LOCAL$' source_db, sql_id, cast(substr(sql_text,1,4000) as varchar2(4000)) sql_text from opas_qry_cache
                 where (sql_text like ']'||p_sql_search_str||q'[' or upper(sql_text) like upper(']'||p_sql_search_str||q'[')) and 'Y'=']'||p_use_cache||q'['
                union all
                select 2 nn#, 'Local AWR repository' source_tab, '$LOCAL$' source_db, sql_id, cast(substr(sql_text,1,4000) as varchar2(4000)) sql_text from dba_hist_sqltext
                 where (sql_text like ']'||p_sql_search_str||q'[' or upper(sql_text) like upper(']'||p_sql_search_str||q'['))
                   and sql_text not like '%qb_name(OPAS_SEARCH)%'
                union all
                select 3 nn#, 'Local V$SQL' source_tab, '$LOCAL$' source_db, sql_id, cast(substr(SQL_FULLTEXT,1,4000) as varchar2(4000)) sql_text from gv$sql
                  where (SQL_FULLTEXT like ']'||p_sql_search_str||q'[' or upper(SQL_FULLTEXT) like upper(']'||p_sql_search_str||q'['))
                    and sql_fulltext not like '%qb_name(OPAS_SEARCH)%'
                ) ]' || case when p_result_limit = 0 then null else ' where rownum <= '||p_result_limit end || q'[ order by nn#]';
    else
      l_dblink := COREMOD_API.get_ora_dblink(p_srcdb);
      return q'[select * from (
                select /*+ qb_name(OPAS_SEARCH) */ 1 nn#, 'Local query cache' source_tab, '$LOCAL$' source_db, sql_id, cast(substr(sql_text,1,4000) as varchar2(4000)) sql_text from opas_qry_cache
                 where (sql_text like ']'||p_sql_search_str||q'[' or upper(sql_text) like upper(']'||p_sql_search_str||q'[')) and 'Y'=']'||p_use_cache||q'['
                union all
                select 2 nn#, 'Local AWR repository' source_tab, '$LOCAL$' source_db, sql_id, cast(substr(sql_text,1,4000) as varchar2(4000)) sql_text from dba_hist_sqltext
                 where sql_text not like '%Local AWR repository%' and (sql_text like ']'||p_sql_search_str||q'[' or upper(sql_text) like upper(']'||p_sql_search_str||q'['))
                union all
                select 3 nn#, 'Remote AWR repository' source_tab, ']'||p_srcdb||q'[' source_db, sql_id, cast(substr(sql_text,1,4000) as varchar2(4000)) sql_text from dba_hist_sqltext@]'||p_srcdb||q'[
                 where sql_text not like '%Remote AWR repository%' and sql_text not like '%Remote V$SQL%' and sql_text not like '%l_rc:=UTL_COMPRESS.LZ_COMPRESS%'
                   and (sql_text like ']'||p_sql_search_str||q'[' or upper(sql_text) like upper(']'||p_sql_search_str||q'['))
                union all
                select 4 nn#, 'Remote V$SQL' source_tab, ']'||p_srcdb||q'[' source_db, sql_id, cast(substr(SQL_FULLTEXT,1,4000) as varchar2(4000)) sql_text from gv$sql@]'||p_srcdb||q'[
                 where SQL_FULLTEXT not like '%Remote AWR repository%' and SQL_FULLTEXT not like '%Remote V$SQL%' and SQL_FULLTEXT not like '%l_rc:=UTL_COMPRESS.LZ_COMPRESS%'
                   and (SQL_FULLTEXT like ']'||p_sql_search_str||q'[' or upper(SQL_FULLTEXT) like upper(']'||p_sql_search_str||q'['))
                ) ]' || case when p_result_limit = 0 then null else ' where rownum <= '||p_result_limit end || q'[ order by nn#]';
    end if;
  end;

  function get_sql_search_query(p_srcdb varchar2, p_sql_search_expr varchar2, p_use_cache varchar2 default 'N', p_result_limit number default 0) return varchar2
  is
    l_dblink varchar2(512);
    l_sql    varchar2(32765);
  begin
    if (p_srcdb is null and p_sql_search_expr is null) or p_sql_search_expr is null then
      l_sql := q'[select /*+ qb_name(OPAS_SEARCH) */ 1 nn#, 'Local query cache' source_tab, '$LOCAL$' source_db, sql_id, cast(substr(sql_text,1,2000) as varchar2(2000)) sql_text from opas_qry_cache
                 where 1=2]';
    elsif p_srcdb is null or p_srcdb = '$LOCAL$' then
      l_sql := q'[select nn#, source_tab, source_db, sql_id, sql_text from (select * from
               (select /*+ qb_name(OPAS_SEARCH) */ 1 nn#, 'Local query cache' source_tab, '$LOCAL$' source_db, sql_id, cast(substr(sql_text,1,2000) as varchar2(2000)) sql_text from opas_qry_cache
                 where 'Y'=']'||p_use_cache||q'['
                union all
                select 2 nn#, 'Local AWR repository' source_tab, '$LOCAL$' source_db, sql_id, cast(substr(sql_text,1,2000) as varchar2(2000)) sql_text from dba_hist_sqltext
                 where sql_text not like '%qb_name(OPAS_SEARCH)%'
                union all
                select 3 nn#, 'Local V$SQL' source_tab, '$LOCAL$' source_db, sql_id, cast(substr(SQL_FULLTEXT,1,2000) as varchar2(2000)) sql_text from gv$sql
                  where sql_fulltext not like '%qb_name(OPAS_SEARCH)%'
                ) where ]'||p_sql_search_expr||q'[ ) ]' || case when p_result_limit = 0 then null else ' where rownum <= '||p_result_limit end || q'[ order by nn#]';
    else
      l_dblink := COREMOD_API.get_ora_dblink(p_srcdb);
      l_sql := q'[select nn#, source_tab, source_db, sql_id, sql_text from (select * from (
                select /*+ qb_name(OPAS_SEARCH) */ 1 nn#, 'Local query cache' source_tab, '$LOCAL$' source_db, sql_id, cast(substr(sql_text,1,2000) as varchar2(2000)) sql_text from opas_qry_cache
                 where 'Y'=']'||p_use_cache||q'['
                union all
                select 2 nn#, 'Local AWR repository' source_tab, '$LOCAL$' source_db, sql_id, cast(substr(sql_text,1,2000) as varchar2(2000)) sql_text from dba_hist_sqltext
                 where sql_text not like '%Local AWR repository%'
                union all
                select 3 nn#, 'Remote AWR repository' source_tab, ']'||p_srcdb||q'[' source_db, sql_id, cast(substr(sql_text,1,2000) as varchar2(2000)) sql_text from dba_hist_sqltext@]'||p_srcdb||q'[ a
                 where sql_text not like '%Remote AWR repository%' and sql_text not like '%Remote V$SQL%' and sql_text not like '%l_rc:=UTL_COMPRESS.LZ_COMPRESS%'
                union all
                select 4 nn#, 'Remote V$SQL' source_tab, ']'||p_srcdb||q'[' source_db, sql_id, cast(substr(SQL_FULLTEXT,1,2000) as varchar2(2000)) sql_text from gv$sql@]'||p_srcdb||q'[ b
                 where SQL_FULLTEXT not like '%Remote AWR repository%' and SQL_FULLTEXT not like '%Remote V$SQL%' and SQL_FULLTEXT not like '%l_rc:=UTL_COMPRESS.LZ_COMPRESS%'
                ) where ]'||p_sql_search_expr||q'[ )]' || case when p_result_limit = 0 then null else ' where rownum <= '||p_result_limit end || q'[ order by nn#]';
    end if;
    coremod_log.log(l_sql,'DEBUG');
    return l_sql;
  end;

  function get_sql_qry_txt(p_srcdb varchar2, p_sql_id varchar2) return clob AS
    --l_txt    varchar2(4000);
    l_dbid   number;
    l_sql    varchar2(32765);
    l_output clob;
    l_dblink varchar2(512);
    pragma autonomous_transaction;
  BEGIN
    if p_sql_id = upper('<UNKNOWN SQL>') then
      return 'Unknown sql_id.';
    else
      select sql_text into l_output from opas_qry_cache where sql_id=p_sql_id;
      set_sql_cache_hit(p_sql_id,10);
      commit;
      return l_output;
    end if;
  exception
    when no_data_found then
      begin
        begin
          select sql_text into l_output from dba_hist_sqltext where sql_id=p_sql_id and rownum=1;
        exception
          when no_data_found then
            begin
              select sql_fulltext into l_output from gv$sql where sql_id=p_sql_id and rownum=1;
            exception
              when no_data_found then null;
            end;
        end;

        if l_output is null and p_srcdb is not null and p_srcdb <> '$LOCAL$' then
          l_dblink := COREMOD_API.get_ora_dblink(p_srcdb);
          execute immediate 'select dbid from v$database@'||l_dblink into l_dbid;

          l_sql := q'[select sql_text into l_out from dba_hist_sqltext where sql_id=']'||p_sql_id||q'[' and dbid=]'||l_dbid||q'[ and rownum<2;]';
          COREMOD_REPORT_UTILS.get_clob_remotelly
            (  P_SQL => l_sql,
               P_DBLINK => l_dblink,
               P_OUTPUT => l_output) ;

          if l_output is null and p_srcdb is not null and p_srcdb <> '$LOCAL$' then
            l_sql := q'[select SQL_FULLTEXT into l_out from gv$sql where sql_id=']'||p_sql_id||q'['  and rownum<2;]';
            COREMOD_REPORT_UTILS.get_clob_remotelly
              (  P_SQL => l_sql,
                 P_DBLINK => l_dblink,
                 P_OUTPUT => l_output) ;
          end if;
        end if;

        if l_output is null then
          l_output := 'No sql text found.';
        else
          add_qry2cache_i(p_sql_id,l_output);
          commit;
        end if;
        commit;
        return l_output;
      end;
  END get_sql_qry_txt;

end;
/
