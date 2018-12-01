CREATE OR REPLACE
package body coremod_reports
as
  function queue_report_sql_memory_stats_i(p_modname varchar2, p_owner varchar2, p_sql_id varchar2, p_dblink varchar2, p_parent number) return opas_reports.report_id%type
  is
    l_report_id opas_reports.report_id%type;
  begin
    coremod_report_utils.init_report(p_modname,l_report_id, p_parent);
    coremod_report_utils.set_report_type(l_report_id, coremod_report_utils.gSQL_MEMORY_REPORT);
    coremod_report_utils.set_report_param(l_report_id,coremod_report_utils.gparOWNER,p_owner);
    coremod_report_utils.set_report_param(l_report_id,coremod_report_utils.gparSQLID,p_sql_id);
    coremod_report_utils.set_report_param(l_report_id,coremod_report_utils.gparDBLINK,p_dblink);
    coremod_report_utils.queue_report(l_report_id);
    return l_report_id;
  end;

  function queue_report_sql_memory_stats(p_modname varchar2, p_owner varchar2, p_sql_id varchar2, p_dblink varchar2) return opas_reports.report_id%type
  is
    l_report_id opas_reports.report_id%type;
    l_sql varchar2(32765) := replace(replace(
           q'[select sql_id from (
              select sql_id, count(1) cnt
                from gv$active_session_history<dblink>
               where top_level_sql_id = '<sql_id>'
                 and sql_id<>top_level_sql_id
               group by sql_id
              having count(1) > 60
               order by cnt desc)]','<dblink>',case when p_dblink is null then null else '@'||p_dblink end),'<sql_id>',p_sql_id);
    l_crsr sys_refcursor;
    l_sql_id varchar2(100);
    l_main_report opas_reports.report_id%type;
    l_rec_report  opas_reports.report_id%type;
  begin
    --main query report
    l_main_report := queue_report_sql_memory_stats_i(p_modname, p_owner, p_sql_id, p_dblink, null);
    commit;

    --recursive queries
    open l_crsr for l_sql;
    loop
      fetch l_crsr into l_sql_id;
      exit when l_crsr%notfound;
      l_rec_report := queue_report_sql_memory_stats_i(p_modname, p_owner, l_sql_id, p_dblink, l_main_report);
    end loop;
    close l_crsr;
    commit;
    return l_main_report;
  end;

  function getreport_sql_memory_stats(p_sql_id varchar2, p_dblink varchar2) return coremod_report_utils.t_output_lines
  is
    l_timing boolean := true;
    l_time number; l_tot_tim number:=0;
    l_cpu_tim number; l_tot_cpu_tim number:=0;
    l_script varchar2(32767);
    l_report coremod_report_utils.t_output_lines;

    l_output coremod_report_utils.t_output_lines;
    l_plsql_output clob;
    l_indx   number := 1;

    --longops
    rindex    BINARY_INTEGER;
    slno      BINARY_INTEGER;
    totalwork number;
    sofar     number;
    obj       BINARY_INTEGER;
    op_name   varchar2(100):='SQL V$ report: '||p_sql_id;
    target_desc varchar2(100):='section';
    units     varchar2(100):='sections';

    procedure p(p_line varchar2) is
    begin
      l_report(l_indx):=p_line;
      l_indx := l_indx + 1;
    end;
    procedure p1(p_output coremod_report_utils.t_output_lines) is
    begin
      for i in 1..p_output.count loop
        p(p_output(i));
      end loop;
    end;
    procedure stim is
    begin
      if l_timing then
        l_time:=DBMS_UTILITY.GET_TIME;
        l_cpu_tim:=DBMS_UTILITY.GET_CPU_TIME;
      end if;
    end;
    procedure etim(p_last boolean default false) is
      l_delta_t number;
      l_delta_c number;
    begin
      if l_timing then
        l_delta_t:=DBMS_UTILITY.GET_TIME-l_time;
        l_delta_c:=DBMS_UTILITY.GET_CPU_TIME-l_cpu_tim;
        l_tot_tim:=l_tot_tim+l_delta_t;
        l_tot_cpu_tim:=l_tot_cpu_tim+l_delta_c;

        if not p_last then
          p(HTF.header (6,cheader=>'Elapsed (sec): '||to_char(round((l_delta_t)/100,2))||'; CPU (sec): '||to_char(round((l_delta_c)/100,2)),cattributes=>'class="awr"'));
        else
          p(HTF.header (6,cheader=>'Totals: Elapsed (sec): '||to_char(round((l_tot_tim)/100,2))||'; CPU (sec): '||to_char(round((l_tot_cpu_tim)/100,2)),cattributes=>'class="awr"'));
        end if;
      end if;
    end;
  begin
    --p('SQL_ID='||p_sql_id||'; DB LINK='||p_dblink);

    --longops
    rindex := dbms_application_info.set_session_longops_nohint;
    sofar := 0;
    totalwork := 14;
    dbms_application_info.set_session_longops(rindex, slno, op_name, obj, 0, sofar, totalwork, target_desc, units);

    DBMS_APPLICATION_INFO.SET_MODULE ( module_name => 'SQL V$ report: '||p_sql_id, action_name => 'Preparation');

    p(HTF.header (1,'SQL Report for SQL_ID='||p_sql_id,cattributes=>'class="awr"'));
    p(HTF.BR);
    p(HTF.BR);
    p(HTF.header (2,cheader=>HTF.ANCHOR (curl=>'',ctext=>'Table of contents',cname=>'tblofcont',cattributes=>'class="awr"'),cattributes=>'class="awr"'));
    p(HTF.BR);
    p(HTF.LISTITEM(cattributes=>'class="awr"',ctext=>HTF.ANCHOR (curl=>'#sql_text',ctext=>'SQL text',cattributes=>'class="awr"')));
    p(HTF.LISTITEM(cattributes=>'class="awr"',ctext=>HTF.ANCHOR (curl=>'#non_shared',ctext=>'Non shared reason',cattributes=>'class="awr"')));
    p(HTF.LISTITEM(cattributes=>'class="awr"',ctext=>HTF.ANCHOR (curl=>'#v_sql_stat',ctext=>'V$SQL statistics',cattributes=>'class="awr"')));
    p(HTF.LISTITEM(cattributes=>'class="awr"',ctext=>HTF.ANCHOR (curl=>'#exadata',ctext=>'Exadata statistics',cattributes=>'class="awr"')));
    p(HTF.LISTITEM(cattributes=>'class="awr"',ctext=>HTF.ANCHOR (curl=>'#sql_mon',ctext=>'SQL Monitor report',cattributes=>'class="awr"')));
    p(HTF.LISTITEM(cattributes=>'class="awr"',ctext=>HTF.ANCHOR (curl=>'#sql_workarea',ctext=>'SQL Workarea',cattributes=>'class="awr"')));
    p(HTF.LISTITEM(cattributes=>'class="awr"',ctext=>HTF.ANCHOR (curl=>'#cbo_env',ctext=>'CBO environment',cattributes=>'class="awr"')));
    p(HTF.LISTITEM(cattributes=>'class="awr"',ctext=>HTF.ANCHOR (curl=>'#dp_last',ctext=>'Display cursor (last)',cattributes=>'class="awr"')));
    p(HTF.LISTITEM(cattributes=>'class="awr"',ctext=>HTF.ANCHOR (curl=>'#dp_rac',ctext=>'Display cursor (RAC)',cattributes=>'class="awr"')));
    p(HTF.LISTITEM(cattributes=>'class="awr"',ctext=>HTF.ANCHOR (curl=>'#dp_last_adv',ctext=>'Display cursor (LAST ADVANCED)',cattributes=>'class="awr"')));
    p(HTF.LISTITEM(cattributes=>'class="awr"',ctext=>HTF.ANCHOR (curl=>'#dp_all',ctext=>'Display cursor (ALL)',cattributes=>'class="awr"')));
    p(HTF.LISTITEM(cattributes=>'class="awr"',ctext=>HTF.ANCHOR (curl=>'#dp_adaptive',ctext=>'Display cursor (ADAPTIVE)',cattributes=>'class="awr"')));
    p(HTF.LISTITEM(cattributes=>'class="awr"',ctext=>HTF.ANCHOR (curl=>'#sql_mon_hist',ctext=>'SQL Monitor report history',cattributes=>'class="awr"')));
    p(HTF.LISTITEM(cattributes=>'class="awr"',ctext=>HTF.ANCHOR (curl=>'#ash_p3',ctext=>'ASH Summary',cattributes=>'class="awr"')));
    p(HTF.BR);
    p(HTF.BR);

--  =============================================================================================================================================
    --SQL TEXT
    DBMS_APPLICATION_INFO.SET_MODULE ( module_name => 'SQL V$ report: '||p_sql_id, action_name => 'SQL TEXT');
    stim();
    l_script:=coremod_api.getscript('PROC_GETGTXT');
    p(HTF.header (3,cheader=>HTF.ANCHOR (curl=>'',ctext=>'SQL text',cname=>'sql_text',cattributes=>'class="awr"'),cattributes=>'class="awr"'));
    p(HTF.BR);
    COREMOD_REPORT_UTILS.prepare_script(l_script,p_sql_id);
    l_output.delete;
    coremod_report_utils.print_table_html_remotelly(p_query=>l_script,p_width=>500,p_summary=>'SQL text', p_dblink => p_dblink, p_output=> l_output);
    p1(l_output);
    p(HTF.BR);
    p(HTF.LISTITEM(cattributes=>'class="awr"',ctext=>HTF.ANCHOR (curl=>'#tblofcont',ctext=>'Back to top',cattributes=>'class="awr"')));
    p(HTF.BR);
    p(HTF.BR);
    etim();

    sofar := sofar + 1;
    dbms_application_info.set_session_longops(rindex, slno, op_name, obj, 0, sofar, totalwork, target_desc, units);
--  =============================================================================================================================================
    --Non shared
    DBMS_APPLICATION_INFO.SET_MODULE ( module_name => 'SQL V$ report: '||p_sql_id, action_name => 'Non shared');
    stim();
    l_script:=coremod_api.getscript('PROC_NON_SHARED');
    p(HTF.header (3,cheader=>HTF.ANCHOR (curl=>'',ctext=>'Non shared reason',cname=>'non_shared',cattributes=>'class="awr"'),cattributes=>'class="awr"'));
    p(HTF.BR);
    COREMOD_REPORT_UTILS.prepare_script(l_script,p_sql_id);
    l_output.delete;
    coremod_report_utils.print_table_html_remotelly(p_query=>l_script,p_width=>1000,p_summary=>'Non shared reason', p_dblink => p_dblink, p_output=> l_output);
    p1(l_output);
    p(HTF.BR);
    p(HTF.LISTITEM(cattributes=>'class="awr"',ctext=>HTF.ANCHOR (curl=>'#tblofcont',ctext=>'Back to top',cattributes=>'class="awr"')));
    p(HTF.BR);
    p(HTF.BR);
    etim();

    sofar := sofar + 1;
    dbms_application_info.set_session_longops(rindex, slno, op_name, obj, 0, sofar, totalwork, target_desc, units);
--  =============================================================================================================================================
    --V$SQL statistics
    DBMS_APPLICATION_INFO.SET_MODULE ( module_name => 'SQL V$ report: '||p_sql_id, action_name => 'V$SQL statistics');
    stim();
    l_script:=coremod_api.getscript('PROC_VSQL_STAT');
    p(HTF.header (3,cheader=>HTF.ANCHOR (curl=>'',ctext=>'V$SQL statistics',cname=>'v_sql_stat',cattributes=>'class="awr"'),cattributes=>'class="awr"'));
    p(HTF.BR);

    COREMOD_REPORT_UTILS.prepare_script(l_script,p_sql_id);

    l_plsql_output:=null;
    coremod_report_utils.execute_plsql_remotelly(p_sql => l_script, p_dblink => p_dblink, p_output => l_plsql_output);

    declare
      l_user varchar2(512); l_host varchar2(512);
    begin
      select username, host into l_user, l_host from user_db_links where db_link=upper(p_dblink);
      l_plsql_output:=replace(replace(l_plsql_output,'&_USER.',l_user),'&_CONNECT_IDENTIFIER.',l_host);
    exception
      when no_data_found then
        l_user:='<UNKNOWN>'; l_host:='<UNKNOWN>';
        l_plsql_output:=replace(replace(l_plsql_output,'&_USER.',l_user),'&_CONNECT_IDENTIFIER.',l_host);
    end;

    coremod_report_utils.print_text_as_table(p_text=>l_plsql_output,p_t_header=>'V$SQL',p_width=>600, p_search=>'CHILD_NUMBER=([[:digit:]]*)',p_replacement=>HTF.ANCHOR (curl=>'#child_last_\1',ctext=>'CHILD_NUMBER=\1',cattributes=>'class="awr"'), p_output=> l_output);
    p1(l_output);

    p(HTF.BR);
    p(HTF.LISTITEM(cattributes=>'class="awr"',ctext=>HTF.ANCHOR (curl=>'#tblofcont',ctext=>'Back to top',cattributes=>'class="awr"')));
    p(HTF.BR);
    p(HTF.BR);
    etim();

    sofar := sofar + 1;
    dbms_application_info.set_session_longops(rindex, slno, op_name, obj, 0, sofar, totalwork, target_desc, units);
--  =============================================================================================================================================
    --Exadata statistics
    DBMS_APPLICATION_INFO.SET_MODULE ( module_name => 'SQL V$ report: '||p_sql_id, action_name => 'Exadata statistics');
    stim();
    p(HTF.header (3,cheader=>HTF.ANCHOR (curl=>'',ctext=>'Exadata statistics',cname=>'exadata',cattributes=>'class="awr"'),cattributes=>'class="awr"'));
    p(HTF.BR);

    l_script:=coremod_api.getscript('PROC_OFFLOAD_PCT1');
    COREMOD_REPORT_UTILS.prepare_script(l_script,p_sql_id);
    l_output.delete;
    coremod_report_utils.print_table_html_remotelly(p_query=>l_script,p_width=>1000,p_summary=>'Exadata statistics #1', p_dblink => p_dblink, p_output=> l_output);
    p1(l_output);

    p(HTF.BR);

    l_script:=coremod_api.getscript('PROC_OFFLOAD_PCT2');
    COREMOD_REPORT_UTILS.prepare_script(l_script,p_sql_id);
    l_output.delete;
    coremod_report_utils.print_table_html_remotelly(p_query=>l_script,p_width=>1000,p_summary=>'Exadata statistics #2', p_dblink => p_dblink, p_output=> l_output);
    p1(l_output);

    p(HTF.BR);
    p(HTF.LISTITEM(cattributes=>'class="awr"',ctext=>HTF.ANCHOR (curl=>'#tblofcont',ctext=>'Back to top',cattributes=>'class="awr"')));
    p(HTF.BR);
    p(HTF.BR);
    etim();

    sofar := sofar + 1;
    dbms_application_info.set_session_longops(rindex, slno, op_name, obj, 0, sofar, totalwork, target_desc, units);
--  =============================================================================================================================================
    --SQL Monitor report
    DBMS_APPLICATION_INFO.SET_MODULE ( module_name => 'SQL V$ report: '||p_sql_id, action_name => 'SQL Monitor report');
    stim();
    l_script:=coremod_api.getscript('PROC_SQLMON');
    p(HTF.header (3,cheader=>HTF.ANCHOR (curl=>'',ctext=>'SQL Monitor report (11g+)',cname=>'sql_mon',cattributes=>'class="awr"'),cattributes=>'class="awr"'));
    p(HTF.BR);
    COREMOD_REPORT_UTILS.prepare_script(l_script,p_sql_id);

    l_plsql_output:=null;
    coremod_report_utils.execute_plsql_remotelly(p_sql => l_script, p_dblink => p_dblink, p_output => l_plsql_output);
    coremod_report_utils.print_text_as_table(p_text=>l_plsql_output||chr(10),p_t_header=>'SQL Monitor report',p_width=>600, p_output=> l_output);
    p1(l_output);

    p(HTF.BR);
    p(HTF.LISTITEM(cattributes=>'class="awr"',ctext=>HTF.ANCHOR (curl=>'#tblofcont',ctext=>'Back to top',cattributes=>'class="awr"')));
    p(HTF.BR);
    p(HTF.BR);
    etim();

    sofar := sofar + 1;
    dbms_application_info.set_session_longops(rindex, slno, op_name, obj, 0, sofar, totalwork, target_desc, units);
--  =============================================================================================================================================
    --SQL Workarea
    DBMS_APPLICATION_INFO.SET_MODULE ( module_name => 'SQL V$ report: '||p_sql_id, action_name => 'SQL Workarea');
    stim();
    l_script:=coremod_api.getscript('PROC_SQLWORKAREA');
    p(HTF.header (3,cheader=>HTF.ANCHOR (curl=>'',ctext=>'SQL Workarea',cname=>'sql_workarea',cattributes=>'class="awr"'),cattributes=>'class="awr"'));
    p(HTF.BR);
    COREMOD_REPORT_UTILS.prepare_script(l_script,p_sql_id);
    l_output.delete;
    coremod_report_utils.print_table_html_remotelly(p_query=>l_script,p_width=>1000,p_summary=>'SQL Workarea', p_dblink => p_dblink, p_output=> l_output);
    p1(l_output);

    p(HTF.BR);
    p(HTF.LISTITEM(cattributes=>'class="awr"',ctext=>HTF.ANCHOR (curl=>'#tblofcont',ctext=>'Back to top',cattributes=>'class="awr"')));
    p(HTF.BR);
    p(HTF.BR);
    etim();

    sofar := sofar + 1;
    dbms_application_info.set_session_longops(rindex, slno, op_name, obj, 0, sofar, totalwork, target_desc, units);
--  =============================================================================================================================================
    --CBO environment
    DBMS_APPLICATION_INFO.SET_MODULE ( module_name => 'SQL V$ report: '||p_sql_id, action_name => 'CBO environment');
    stim();
    l_script:=coremod_api.getscript('PROC_OPTENV');
    p(HTF.header (3,cheader=>HTF.ANCHOR (curl=>'',ctext=>'CBO environment',cname=>'cbo_env',cattributes=>'class="awr"'),cattributes=>'class="awr"'));
    p(HTF.BR);
    COREMOD_REPORT_UTILS.prepare_script(l_script,p_sql_id);
    l_output.delete;
    coremod_report_utils.print_table_html_remotelly(p_query=>l_script,p_width=>1000,p_summary=>'CBO environment', p_dblink => p_dblink, p_output=> l_output);
    p1(l_output);
    p(HTF.BR);
    p(HTF.LISTITEM(cattributes=>'class="awr"',ctext=>HTF.ANCHOR (curl=>'#tblofcont',ctext=>'Back to top',cattributes=>'class="awr"')));
    p(HTF.BR);
    p(HTF.BR);
    etim();

    sofar := sofar + 1;
    dbms_application_info.set_session_longops(rindex, slno, op_name, obj, 0, sofar, totalwork, target_desc, units);
--  =============================================================================================================================================
    --Execution plans
    p(HTF.header (3,cheader=>HTF.ANCHOR (curl=>'',ctext=>'Execution plans',cname=>'tblofcont_plans',cattributes=>'class="awr"'),cattributes=>'class="awr"'));
    p(HTF.BR);
    p(HTF.LISTITEM(cattributes=>'class="awr"',ctext=>HTF.ANCHOR (curl=>'#dp_last',ctext=>'Display cursor (last)',cattributes=>'class="awr"')));
    p(HTF.LISTITEM(cattributes=>'class="awr"',ctext=>HTF.ANCHOR (curl=>'#dp_rac',ctext=>'Display cursor (RAC)',cattributes=>'class="awr"')));
    p(HTF.LISTITEM(cattributes=>'class="awr"',ctext=>HTF.ANCHOR (curl=>'#dp_last_adv',ctext=>'Display cursor (LAST ADVANCED)',cattributes=>'class="awr"')));
    p(HTF.LISTITEM(cattributes=>'class="awr"',ctext=>HTF.ANCHOR (curl=>'#dp_all',ctext=>'Display cursor (ALL)',cattributes=>'class="awr"')));
    p(HTF.LISTITEM(cattributes=>'class="awr"',ctext=>HTF.ANCHOR (curl=>'#dp_adaptive',ctext=>'Display cursor (ADAPTIVE)',cattributes=>'class="awr"')));
    p(HTF.LISTITEM(cattributes=>'class="awr"',ctext=>HTF.ANCHOR (curl=>'#tblofcont',ctext=>'Back to top',cattributes=>'class="awr"')));
    p(HTF.BR);
    p(HTF.BR);
--  =============================================================================================================================================
    --Display cursor (last)
    DBMS_APPLICATION_INFO.SET_MODULE ( module_name => 'SQL V$ report: '||p_sql_id, action_name => 'Display cursor (last)');
    stim();
    p(HTF.header (3,cheader=>HTF.ANCHOR (curl=>'',ctext=>'Display cursor (last)',cname=>'dp_last',cattributes=>'class="awr"'),cattributes=>'class="awr"'));
    p(HTF.BR);
    l_script:=q'[select * from table(dbms_xplan.display_cursor('&SQLID', null, 'LAST ALLSTATS +peeked_binds'))]'||chr(10);
    COREMOD_REPORT_UTILS.prepare_script(l_script,p_sql_id);
    l_output.delete;
    coremod_report_utils.print_table_html_remotelly(p_query=>l_script,
                               p_width=>1500,
                               p_summary=>'Display cursor (last)',
                               p_search => 'child number ([[:digit:]]*)',
                               p_replacement => HTF.ANCHOR(curl=>'#child_all_\1',ctext=>'child number \1',cname=>'child_last_\1',cattributes=>'class="awr"'),
                               p_dblink => p_dblink, p_output=> l_output);
    p1(l_output);
    p(HTF.BR);
    p(HTF.LISTITEM(cattributes=>'class="awr"',ctext=>HTF.ANCHOR (curl=>'#tblofcont_plans',ctext=>'Back to Execution plans',cattributes=>'class="awr"')));
    p(HTF.LISTITEM(cattributes=>'class="awr"',ctext=>HTF.ANCHOR (curl=>'#tblofcont',ctext=>'Back to top',cattributes=>'class="awr"')));
    p(HTF.BR);
    p(HTF.BR);
    etim();

    sofar := sofar + 1;
    dbms_application_info.set_session_longops(rindex, slno, op_name, obj, 0, sofar, totalwork, target_desc, units);
--  =============================================================================================================================================
    --Display cursor (RAC)
    DBMS_APPLICATION_INFO.SET_MODULE ( module_name => 'SQL V$ report: '||p_sql_id, action_name => 'Display cursor (RAC)');
    stim();
    l_script:=coremod_api.getscript('PROC_RACPLAN');
    p(HTF.header (3,cheader=>HTF.ANCHOR (curl=>'',ctext=>'Display cursor (RAC)',cname=>'dp_rac',cattributes=>'class="awr"'),cattributes=>'class="awr"'));
    p(HTF.BR);
    COREMOD_REPORT_UTILS.prepare_script(l_script,p_sql_id);
    l_output.delete;
    coremod_report_utils.print_table_html_remotelly(p_query=>l_script,p_width=>1500,p_summary=>'Display cursor (RAC)', p_dblink => p_dblink, p_output=> l_output);
    p1(l_output);
    p(HTF.BR);
    p(HTF.LISTITEM(cattributes=>'class="awr"',ctext=>HTF.ANCHOR (curl=>'#tblofcont_plans',ctext=>'Back to Execution plans',cattributes=>'class="awr"')));
    p(HTF.LISTITEM(cattributes=>'class="awr"',ctext=>HTF.ANCHOR (curl=>'#tblofcont',ctext=>'Back to top',cattributes=>'class="awr"')));
    p(HTF.BR);
    p(HTF.BR);
    etim();

    sofar := sofar + 1;
    dbms_application_info.set_session_longops(rindex, slno, op_name, obj, 0, sofar, totalwork, target_desc, units);
--  =============================================================================================================================================
    --Display cursor (LAST ADVANCED)
    DBMS_APPLICATION_INFO.SET_MODULE ( module_name => 'SQL V$ report: '||p_sql_id, action_name => 'Display cursor (LAST ADVANCED)');
    stim();
    p(HTF.header (3,cheader=>HTF.ANCHOR (curl=>'Display cursor (RAC)',ctext=>'Display cursor (LAST ADVANCED)',cname=>'dp_last_adv',cattributes=>'class="awr"'),cattributes=>'class="awr"'));
    p(HTF.BR);
    l_script:=q'[select * from table(dbms_xplan.display_cursor('&SQLID', null, 'LAST ADVANCED'))]'||chr(10);
    COREMOD_REPORT_UTILS.prepare_script(l_script,p_sql_id);
    l_output.delete;
    coremod_report_utils.print_table_html_remotelly(p_query=>l_script,
                               p_width=>1500,
                               p_summary=>'Display cursor (LAST ADVANCED)',
                               p_dblink => p_dblink, p_output=> l_output);
    p1(l_output);
    p(HTF.BR);
    p(HTF.LISTITEM(cattributes=>'class="awr"',ctext=>HTF.ANCHOR (curl=>'#tblofcont_plans',ctext=>'Back to Execution plans',cattributes=>'class="awr"')));
    p(HTF.LISTITEM(cattributes=>'class="awr"',ctext=>HTF.ANCHOR (curl=>'#tblofcont',ctext=>'Back to top',cattributes=>'class="awr"')));
    p(HTF.BR);
    p(HTF.BR);
    etim();

    sofar := sofar + 1;
    dbms_application_info.set_session_longops(rindex, slno, op_name, obj, 0, sofar, totalwork, target_desc, units);
--  =============================================================================================================================================
    --Display cursor (ALL)
    DBMS_APPLICATION_INFO.SET_MODULE ( module_name => 'SQL V$ report: '||p_sql_id, action_name => 'Display cursor (ALL)');
    stim();
    p(HTF.header (3,cheader=>HTF.ANCHOR (curl=>'',ctext=>'Display cursor (ALL)',cname=>'dp_all',cattributes=>'class="awr"'),cattributes=>'class="awr"'));
    p(HTF.BR);
    l_script:=q'[select * from table(dbms_xplan.display_cursor('&SQLID', null, 'ALL ALLSTATS +peeked_binds'))]'||chr(10);
    COREMOD_REPORT_UTILS.prepare_script(l_script,p_sql_id);
    l_output.delete;
    coremod_report_utils.print_table_html_remotelly(p_query=>l_script,
                               p_width=>2000,
                               p_summary=>'Display cursor (ALL)',
                               p_search => 'child number ([[:digit:]]*)',
                               p_replacement => HTF.ANCHOR(curl=>'',ctext=>'child number \1',cname=>'child_all_\1',cattributes=>'class="awr"'),
                               p_dblink => p_dblink, p_output=> l_output);
    p1(l_output);
    p(HTF.BR);
    p(HTF.LISTITEM(cattributes=>'class="awr"',ctext=>HTF.ANCHOR (curl=>'#tblofcont_plans',ctext=>'Back to Execution plans',cattributes=>'class="awr"')));
    p(HTF.LISTITEM(cattributes=>'class="awr"',ctext=>HTF.ANCHOR (curl=>'#tblofcont',ctext=>'Back to top',cattributes=>'class="awr"')));
    p(HTF.BR);
    p(HTF.BR);
    etim();

    sofar := sofar + 1;
    dbms_application_info.set_session_longops(rindex, slno, op_name, obj, 0, sofar, totalwork, target_desc, units);
--  =============================================================================================================================================
    --Display cursor (ADAPTIVE)
    DBMS_APPLICATION_INFO.SET_MODULE ( module_name => 'SQL V$ report: '||p_sql_id, action_name => 'Display cursor (ADAPTIVE)');
    stim();
    p(HTF.header (3,cheader=>HTF.ANCHOR (curl=>'',ctext=>'Display cursor (ADAPTIVE)',cname=>'dp_adaptive',cattributes=>'class="awr"'),cattributes=>'class="awr"'));
    p(HTF.BR);
    l_script:=q'[SELECT * FROM TABLE(DBMS_XPLAN.display_cursor('&SQLID', null, format => 'adaptive LAST ALLSTATS +peeked_binds'))]'||chr(10);
    COREMOD_REPORT_UTILS.prepare_script(l_script,p_sql_id);
    l_output.delete;
    coremod_report_utils.print_table_html_remotelly(p_query=>l_script,
                               p_width=>1500,
                               p_summary=>'Display cursor (ADAPTIVE)',
                               p_dblink => p_dblink, p_output=> l_output);
    p1(l_output);
    p(HTF.BR);
    p(HTF.LISTITEM(cattributes=>'class="awr"',ctext=>HTF.ANCHOR (curl=>'#tblofcont_plans',ctext=>'Back to Execution plans',cattributes=>'class="awr"')));
    p(HTF.LISTITEM(cattributes=>'class="awr"',ctext=>HTF.ANCHOR (curl=>'#tblofcont',ctext=>'Back to top',cattributes=>'class="awr"')));
    etim();
    stim();
    p(HTF.BR);
    p(HTF.BR);
    l_script:=q'[SELECT * FROM TABLE(DBMS_XPLAN.display_cursor('&SQLID', null, format => 'adaptive ALL ALLSTATS +peeked_binds'))]'||chr(10);
    COREMOD_REPORT_UTILS.prepare_script(l_script,p_sql_id);
    l_output.delete;
    coremod_report_utils.print_table_html_remotelly(p_query=>l_script,
                               p_width=>2000,
                               p_summary=>'Display cursor (ADAPTIVE)',
                               p_dblink => p_dblink, p_output=> l_output);
    p1(l_output);
    p(HTF.BR);
    p(HTF.LISTITEM(cattributes=>'class="awr"',ctext=>HTF.ANCHOR (curl=>'#tblofcont_plans',ctext=>'Back to Execution plans',cattributes=>'class="awr"')));
    p(HTF.LISTITEM(cattributes=>'class="awr"',ctext=>HTF.ANCHOR (curl=>'#tblofcont',ctext=>'Back to top',cattributes=>'class="awr"')));
    p(HTF.BR);
    p(HTF.BR);
    etim();

    sofar := sofar + 1;
    dbms_application_info.set_session_longops(rindex, slno, op_name, obj, 0, sofar, totalwork, target_desc, units);
--  =============================================================================================================================================
    --SQL Monitor report history
    DBMS_APPLICATION_INFO.SET_MODULE ( module_name => 'SQL V$ report: '||p_sql_id, action_name => 'SQL Monitor report history');
    stim();
    l_script:=coremod_api.getscript('PROC_SQLMON_HIST');
    p(HTF.header (3,cheader=>HTF.ANCHOR (curl=>'',ctext=>'SQL Monitor report history (12c+)',cname=>'sql_mon_hist',cattributes=>'class="awr"'),cattributes=>'class="awr"'));
    p(HTF.BR);
    COREMOD_REPORT_UTILS.prepare_script(l_script,p_sql_id);
    l_plsql_output:=null;
    coremod_report_utils.execute_plsql_remotelly(p_sql => l_script, p_dblink => p_dblink, p_output => l_plsql_output);
    coremod_report_utils.print_text_as_table(p_text=>l_plsql_output,p_t_header=>'SQL Monitor report history',p_width=>600, p_output=> l_output);
    p1(l_output);
    p(HTF.BR);
    p(HTF.LISTITEM(cattributes=>'class="awr"',ctext=>HTF.ANCHOR (curl=>'#tblofcont',ctext=>'Back to top',cattributes=>'class="awr"')));

    p(HTF.BR);
    p(HTF.BR);
    etim();

    sofar := sofar + 1;
    dbms_application_info.set_session_longops(rindex, slno, op_name, obj, 0, sofar, totalwork, target_desc, units);
--  =============================================================================================================================================
    --AWR ASH (SQL Monitor) P3
    DBMS_APPLICATION_INFO.SET_MODULE ( module_name => 'SQL V$ report: '||p_sql_id, action_name => 'ASH Summary');
    stim();
    p(HTF.header (3,cheader=>HTF.ANCHOR (curl=>'',ctext=>'ASH Summary',cname=>'ash_p3',cattributes=>'class="awr"'),cattributes=>'class="awr"'));
    p(HTF.BR);

    l_script:=coremod_api.getscript('PROC_AWRASHP3');
    COREMOD_REPORT_UTILS.prepare_script(l_script,p_sql_id);

    l_output.delete;
    coremod_report_utils.print_table_html_remotelly(p_query=>l_script,
                               p_width=>1000,
                               p_summary=>'ASH summary',
                               p_style1 =>'awrncbbt',
                               p_style2 =>'awrcbbt',
                               --p_search => 'PLAN_HASH',
                               --p_replacement => HTF.ANCHOR (curl=>'#awrplan_\1',ctext=>'\1',cattributes=>'class="awr"'),
                               p_header=>25,
                               p_break_col=>'SQL_EXEC_START',
                               p_dblink => p_dblink, p_output=> l_output);
    p1(l_output);
    p(HTF.BR);
    p(HTF.LISTITEM(cattributes=>'class="awr"',ctext=>HTF.ANCHOR (curl=>'#tblofcont',ctext=>'Back to top',cattributes=>'class="awr"')));
    p(HTF.BR);
    etim();

    p(HTF.BR);
    p(HTF.BR);
    p(HTF.BR);
    p('End of report.');
    etim(true);

    sofar := sofar + 1;
    dbms_application_info.set_session_longops(rindex, slno, op_name, obj, 0, sofar, totalwork, target_desc, units);
--  =============================================================================================================================================
    DBMS_APPLICATION_INFO.SET_MODULE ( module_name => 'SQL V$ report: '||p_sql_id, action_name => 'Finished');

    return l_report;
    --coremod_report_utils.save_report_for_download('sql_'||p_sql_id||'.html', l_report, p_id, p_parent_id);
--  exception
--    when others then
--      coremod_log.log(sqlerrm);
--      coremod_log.log(DBMS_UTILITY.FORMAT_ERROR_STACK);
--      coremod_log.log(DBMS_UTILITY.FORMAT_ERROR_BACKTRACE);
--      raise_application_error(-20000, sqlerrm);
  end;

end;
/
