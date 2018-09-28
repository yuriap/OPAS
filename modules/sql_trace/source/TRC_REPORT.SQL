create or replace package trc_report as

  procedure getreport(p_trc_file_id trc_files.trc_file_id%type);
  procedure get_sql_trace_report_async(p_trc_file_id trc_files.trc_file_id%type, p_tq_id out opas_task_queue.tq_id%type);
  
end;
/

--------------------------------------------------------
show errors
--------------------------------------------------------

create or replace package body trc_report as

  procedure getreport_i(p_trc_file_id trc_files.trc_file_id%type, p_report out coremod_report_utils.t_output_lines, p_topsql number default 0)
  is
    --l_report coremod_report_utils.t_output_lines;
    l_indx   number := 1;
    l_sql    varchar2(32765);
    l_sql_text clob;
    l_topsql   number := case when p_topsql = 0 then coremod_api.getconf('TOPSQL',TRC_FILE_API.gMODNAME) else p_topsql end;

    l_report_name varchar2(100):='Extended SQL Trace report';
    l_module_name varchar2(100):='SQL Trace Report';


    l_default_width number := 800;

    l_cnt number;

    l_file_tot_time number;
    l_cpu           number;
    l_ela           number;
    l_idle          number;
    l_nonidle       number;
    l_min_dep       number;
    l_very_first_we trc_wait.row_num%type;

    procedure p(p_line varchar2) is
    begin
      --l_report(l_indx):=p_line;
      l_indx := p_report.count + 1;
      p_report(l_indx):=p_line;
    end;
  begin
    COREMOD_LOG.Start_SQL_GATHER_STAT('TRC_REPORT.GETREPORT_I');
    COREMOD_LOG.Start_SQL_TRACE('TRC_REPORT.GETREPORT_I');

    execute immediate q'[alter session set nls_numeric_characters='. ']';

    COREMOD_REPORT_UTILS.set_report_timing(true);
    COREMOD_REPORT_UTILS.init_lo_report(p_op_name => l_report_name, p_target_desc => 'section', p_units => 'sections', p_totalwork => 5);

    p(HTF.header (1,l_report_name,cattributes=>'class="awr"'));
    p(HTF.BR);
    p(HTF.BR);
    p(HTF.header (2,cheader=>HTF.ANCHOR (curl=>'',ctext=>'Table of contents',cname=>'tblofcont',cattributes=>'class="awr"'),cattributes=>'class="awr"'));
    p(HTF.BR);
    p(HTF.LISTITEM(cattributes=>'class="awr"',ctext=>HTF.ANCHOR (curl=>'#summary',ctext=>'Summary',cattributes=>'class="awr"')));
    p(HTF.LISTITEM(cattributes=>'class="awr"',ctext=>HTF.ANCHOR (curl=>'#topsqls',ctext=>'Top '||l_topsql||' SQLs',cattributes=>'class="awr"')));
    p(HTF.LISTITEM(cattributes=>'class="awr"',ctext=>HTF.ANCHOR (curl=>'#call_tree',ctext=>'Call Tree',cattributes=>'class="awr"')));
    p(HTF.LISTITEM(cattributes=>'class="awr"',ctext=>HTF.ANCHOR (curl=>'#sqlstmts',ctext=>'SQL statements',cattributes=>'class="awr"')));
/*    p(HTF.LISTITEM(cattributes=>'class="awr"',ctext=>HTF.ANCHOR (curl=>'#exadata',ctext=>'Exadata statistics',cattributes=>'class="awr"')));
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
    */
    p(HTF.BR);
    p(HTF.BR);

--  =============================================================================================================================================
    COREMOD_REPORT_UTILS.start_lo_section(p_module_name => l_module_name, p_action_name => 'Calculating data');

    insert /*+ qb_name(TRC_REP1) */ into trc$tmp_call_stats
     select st.sqlid, c.call_type, count(c.call_type) cnt, sum(c) c, sum(e) e, sum(p) p, sum(cr) cr, sum(cu) cu, sum(r) r, sum(mis) mis
       from trc_call c, trc_statement st
      where c.trc_file_id=p_trc_file_id and c.trc_file_id=st.trc_file_id and c.stmt_id=st.stmt_id
      group by c.call_type,st.sqlid;

    insert /*+ qb_name(TRC_REP1) */ into trc$tmp_call_self_stats
    select st.sqlid, c.call_type, count(c.call_type) cnt, sum(cs.c) c, sum(cs.e) e, sum(cs.p) p, sum(cs.cr) cr, sum(cs.cu) cu
      from trc_call c, trc_call_self cs, trc_statement st
     where c.call_id=cs.call_id and c.trc_file_id=p_trc_file_id and c.trc_file_id=st.trc_file_id and c.stmt_id=st.stmt_id
     group by c.call_type, st.sqlid;

    insert /*+ qb_name(TRC_REP1) */ into trc$tmp_wait_stats
    select st.sqlid, ev.wait_class, nam, count(1) cnt, sum(ela) ela, avg(ela) avg_ela, max(ela) max_ela, PERCENTILE_CONT(0.95) within group (order by ela) ela_95
      from trc_wait w, trc_statement st, V$EVENT_NAME ev
     where w.trc_file_id=p_trc_file_id and w.trc_file_id=st.trc_file_id and nam = ev.name
       and w.stmt_id=st.stmt_id  group by nam, st.sqlid, ev.wait_class;

    insert /*+ qb_name(TRC_REP1) */ into trc$tmp_plan_stats
    select st.sqlid, p.plh, p.id, sum(cnt) cnt, p.pid, p.pos, p.obj, p.op, sum(cr)cr, sum(pr) pr, sum(pw) pw, sum(p.tim) tim, p.cost, p.sz, p.card
      from (select x.*, (select plh from trc_call y where trc_file_id=p_trc_file_id and x.stmt_id=y.stmt_id and nvl(plh,0)>0 and rownum=1) plh from trc_stat x) p,
           trc_statement st
     where p.trc_file_id=p_trc_file_id and p.trc_file_id=st.trc_file_id and p.stmt_id=st.stmt_id
     group by st.sqlid, p.plh, p.id, p.pid, p.pos, p.obj, p.op, p.cost,p.cost, p.sz, p.card;

    COREMOD_REPORT_UTILS.start_lo_section(p_module_name => l_module_name, p_action_name => 'Calculating main stats');

    select /*+ qb_name(TRC_REP1) */ min(dep) into l_min_dep from (
        select min(dep) dep from trc_statement where trc_file_id=p_trc_file_id union all
        select min(dep) from trc_call where trc_file_id=p_trc_file_id and call_type<>'CLOSE');

    select /*+ qb_name(TRC_REP1) */ max(tim)-min(tim) into l_file_tot_time from (
        select tim from trc_statement where trc_file_id=p_trc_file_id union all
        select tim from trc_trans where trc_file_id=p_trc_file_id union all
        select tim from trc_call where trc_file_id=p_trc_file_id union all
        select tim from trc_wait where trc_file_id=p_trc_file_id);

    select /*+ qb_name(TRC_REP1) */ sum(c) cpu_time, sum(e) ela_tim into l_cpu, l_ela from trc_call where trc_file_id=p_trc_file_id and dep=l_min_dep;

      --the very first idle wait event is excluded from calc
    begin
      select /*+ qb_name(TRC_REP1) */ row_num into l_very_first_we from trc_wait
       where row_num = (
      select min(x.row_num) from (
             select min(row_num) row_num from trc_statement where trc_file_id=p_trc_file_id union all
             select min(row_num) from trc_trans where trc_file_id=p_trc_file_id union all
             select min(row_num) from trc_call where trc_file_id=p_trc_file_id union all
             select min(row_num) from trc_wait where trc_file_id=p_trc_file_id) x)
             and nam in (select name from V$EVENT_NAME where wait_class='Idle')
             and trc_file_id=p_trc_file_id;
    exception
      when no_data_found then l_very_first_we:=-1;
    end;

    select /*+ qb_name(TRC_REP1) */ sum(ela) into l_idle from trc_wait
     where trc_file_id=p_trc_file_id and nam in (select name from V$EVENT_NAME where wait_class='Idle')
       and row_num != l_very_first_we;

    select /*+ qb_name(TRC_REP1) */ sum(ela) into l_nonidle from trc_wait where trc_file_id=p_trc_file_id and nam not in (select name from V$EVENT_NAME where wait_class='Idle');

--  =============================================================================================================================================

    --Summary
    COREMOD_REPORT_UTILS.start_lo_section(p_module_name => l_module_name, p_action_name => 'Summary');

    p(HTF.header (3,cheader=>HTF.ANCHOR (curl=>'',ctext=>'Summary',cname=>'summary',cattributes=>'class="awr"'),cattributes=>'class="awr"'));
    p(HTF.BR);

/*    declare
      l_file_tot_time number;
      l_cpu           number;
      l_ela           number;
      l_idle          number;
      l_nonidle       number;

      l_min_dep       number;
      l_very_first_we trc_wait.row_num%type;
    begin*/


      p('Total file time, us (tim column): '||trim(to_char(l_file_tot_time,'999g999g999g999g999g999')));p(HTF.BR);
      p(case when l_min_dep=0 then 'Top' else 'The highest dep='||l_min_dep end ||' level calls:');p(HTF.BR);
      p('Elapsed, us: '||trim(to_char(l_ela,'999g999g999g999g999g999')));p(HTF.BR);
      p('CPU time, us: '||trim(to_char(l_cpu,'999g999g999g999g999g999')));p(HTF.BR);
      p('Idle wait time, us: '||trim(to_char(nvl(l_idle,0),'999g999g999g999g999g999')));p(HTF.BR);
      p('Nonidle wait time, us: '||trim(to_char(nvl(l_nonidle,0),'999g999g999g999g999g999')));p(HTF.BR);
      p('Total file time - Elapsed - Idle (% of total), us: '||trim(to_char((l_file_tot_time-l_ela-nvl(l_idle,0)),'999g999g999g999g999g999'))||' ( '||round(100*(l_file_tot_time-l_ela-nvl(l_idle,0))/l_file_tot_time,2)||'% )');p(HTF.BR);
      p('Elapsed - CPU - NonIdle (% of Elapsed), us: '||trim(to_char((l_ela-l_cpu-nvl(l_nonidle,0)),'999g999g999g999g999g999'))||' ( '||round(100*(l_ela-l_cpu-nvl(l_nonidle,0))/l_ela,2)||'% )');p(HTF.BR);

      p(COREMOD_REPORT_UTILS.end_lo_section);

      p(HTF.BR);

      p(HTF.BIG('Top level calls, time in seconds.'));

      l_sql := q'[select * from (
with call_list as (select 'PARSE' nm from dual union select 'EXEC' from dual union select 'FETCH' from dual union select 'CLOSE' from dual)
select /*+ qb_name(TRC_REP1) */
  call_list.nm "Call", count(trc_call.call_type) "Count", sum(c)/1e6 "CPU", sum(e)/1e6 "Elapsed", sum(p) "Disk",
  sum(cr) "Query", sum(cu) "Current", sum(r) "Rows", sum(mis) "Mis", 0 noprn_lastrow
from trc_call, call_list where call_type(+)=call_list.nm and trc_file_id(+)=<P_TRC_FILE_ID> and dep(+)=<MIN_DEP>
group by call_list.nm
union all
select
  'Total:' "Call", count(1) "Count", sum(c)/1e6 "CPU", sum(e)/1e6 "Elapsed", sum(p) "Disk",
  sum(cr) "Query", sum(cu) "Current", sum(r) "Rows", sum(mis) "Mis", 1  noprn_lastrow
from trc_call where trc_file_id=<P_TRC_FILE_ID> and dep=<MIN_DEP>)
order by decode("Call",'PARSE',1,'EXEC',2,'FETCH',3,'CLOSE',4,5)]';
      l_sql:=replace(replace(l_sql,'<P_TRC_FILE_ID>',p_trc_file_id),'<MIN_DEP>',l_min_dep);
      COREMOD_REPORT_UTILS.print_table_html_new
                                           (p_query => l_sql,
                                            p_width => l_default_width,
                                            p_summary => 'Top level calls',
                                            --p_search varchar2 default null,
                                            --p_replacement varchar2 default null,
                                            p_style_tab => 'trctd',
                                            p_style_head => 'trchd', --head
                                            p_style_r1 => 'trcr1',   --odd rows
                                            p_style_r2  => 'trcr2', --even rows
                                            p_style_finrow => 'trctotr',
                                            --p_header number default 0,
                                            --p_break_col varchar2 default null,
                                            p_output => p_report);

      p(HTF.BR);
      p(HTF.BR);

      p(HTF.BIG('NonIdle Wait events, time in seconds.'));

      l_sql := q'[select /*+ qb_name(TRC_REP1) */ 0 noprn_lastrow, nam "Event", count(1) "Times waited", sum(ela)/1e6 "Total time", round(avg(ela)/1e6,6) "Avg time", max(ela)/1e6 "Max time", PERCENTILE_CONT(0.95) within group (order by ela)/1e6 "95% Percetile"
from trc_wait where trc_file_id=<P_TRC_FILE_ID> and nam not in (select name from V$EVENT_NAME where wait_class='Idle') group by nam
union all
select 1 noprn_lastrow, 'Total:' "Event", count(1) "Times waited", sum(ela)/1e6 "Total time", round(avg(ela)/1e6,6) "Avg time", max(ela)/1e6 "Max time", PERCENTILE_CONT(0.95) within group (order by ela)/1e6 "95% Percetile"
from trc_wait where trc_file_id=<P_TRC_FILE_ID> and nam not in (select name from V$EVENT_NAME where wait_class='Idle')
order by 1,4 desc]';
      l_sql:=replace(l_sql,'<P_TRC_FILE_ID>',p_trc_file_id);
      COREMOD_REPORT_UTILS.print_table_html_new
                                           (p_query => l_sql,
                                            p_width => l_default_width,
                                            p_summary => 'NonIdle Wait events',
                                            --p_search varchar2 default null,
                                            --p_replacement varchar2 default null,
                                            p_style_tab => 'trctd',
                                            p_style_head => 'trchd', --head
                                            p_style_r1 => 'trcr1',   --odd rows
                                            p_style_r2  => 'trcr2', --even rows
                                            p_style_finrow => 'trctotr',
                                            --p_header number default 0,
                                            --p_break_col varchar2 default null,
                                            p_output => p_report);

      p(HTF.BR);
      p(HTF.BR);

      p(HTF.BIG('Idle Wait events, time in seconds.'));

      l_sql := q'[select /*+ qb_name(TRC_REP1) */ 0 noprn_lastrow, nam "Event", count(1) "Times waited", sum(ela)/1e6 "Total time", round(avg(ela)/1e6,6) "Avg time", max(ela)/1e6 "Max time", PERCENTILE_CONT(0.95) within group (order by ela)/1e6 "95% Percetile"
from trc_wait where trc_file_id=<P_TRC_FILE_ID> and nam in (select name from V$EVENT_NAME where wait_class='Idle') and row_num!=<P_FIRST_IDLE>
group by nam
union all
select 1 noprn_lastrow, 'Total:' "Event", count(1) "Times waited", sum(ela)/1e6 "Total time", round(avg(ela)/1e6,6) "Avg time", max(ela)/1e6 "Max time", PERCENTILE_CONT(0.95) within group (order by ela)/1e6 "95% Percetile"
from trc_wait where trc_file_id=<P_TRC_FILE_ID> and nam in (select name from V$EVENT_NAME where wait_class='Idle') and row_num!=<P_FIRST_IDLE>
order by 1,4 desc]';
      l_sql:=replace(replace(l_sql,'<P_TRC_FILE_ID>',p_trc_file_id),'<P_FIRST_IDLE>',l_very_first_we);
      COREMOD_REPORT_UTILS.print_table_html_new
                                           (p_query => l_sql,
                                            p_width => l_default_width,
                                            p_summary => 'Idle Wait events',
                                            --p_search varchar2 default null,
                                            --p_replacement varchar2 default null,
                                            p_style_tab => 'trctd',
                                            p_style_head => 'trchd', --head
                                            p_style_r1 => 'trcr1',   --odd rows
                                            p_style_r2  => 'trcr2', --even rows
                                            p_style_finrow => 'trctotr',
                                            --p_header number default 0,
                                            --p_break_col varchar2 default null,
                                            p_output => p_report);
--    end;

    p(HTF.BR);
    p(HTF.LISTITEM(cattributes=>'class="awr"',ctext=>HTF.ANCHOR (curl=>'#tblofcont',ctext=>'Back to top',cattributes=>'class="awr"')));
    p(HTF.BR);
    p(HTF.BR);

    p(COREMOD_REPORT_UTILS.end_lo_section);
    --p(COREMOD_REPORT_UTILS.end_lo_section(p_is_finished=>true));

--  =============================================================================================================================================
    --Top N SQLs
    COREMOD_REPORT_UTILS.start_lo_section(p_module_name => l_module_name, p_action_name => 'Top '||l_topsql||' SQLs');

    p(HTF.header (3,cheader=>HTF.ANCHOR (curl=>'',ctext=>'Top '||l_topsql||' SQLs',cname=>'topsqls',cattributes=>'class="awr"'),cattributes=>'class="awr"'));
    p(HTF.BR);


    l_sql := q'[select /*+ qb_name(TRC_REP1) */ x.*,
(select substr(sql_text,1,100)||case when length(sql_text)>100 then '...' else null end from trc_statement s where x.SQL_ID=s.sqlid and rownum=1) sql_text
from (
select
e "ELA", case when <TOTELA> <> 0 then round(100*e/<TOTELA>,2)||'%' else null end "ELA %Tot",
c "CPU", case when <TOTCPU> <> 0 then round(100*c/<TOTCPU>,2)||'%' else null end "CPU %Tot",
en "Execs",
ti.sqlid SQL_ID
from (select sqlid, sum(c) c, sum(e) e, sum(decode(call_type,'EXEC',cnt,0)) en
        from trc$tmp_call_stats
       group by sqlid) ti
order by e desc, c desc
) x where rownum<=<TOPN>]';
    l_sql:=replace(replace(replace(l_sql,'<TOTCPU>',l_cpu),'<TOTELA>', l_ela),'<TOPN>',l_topsql);
    COREMOD_REPORT_UTILS.print_table_html_new
                                         (p_query => l_sql,
                                          p_width => l_default_width+200,
                                          p_summary => 'Top 20 SQLs',
                                          p_search => 'SQL_ID',
                                          p_replacement => HTF.ANCHOR (curl=>'#sqlid_\1',ctext=>'\1',cattributes=>'class="awr1"'),
                                          p_style_tab => 'trctd',
                                          p_style_head => 'trchd', --head
                                          p_style_r1 => 'trcr1',   --odd rows
                                          p_style_r2  => 'trcr2', --even rows
                                          p_style_finrow => null, -- 'trctotr',
                                          --p_header number default 0,
                                          --p_break_col varchar2 default null,
                                          p_output => p_report);

    p(HTF.BR);
    p(HTF.LISTITEM(cattributes=>'class="awr"',ctext=>HTF.ANCHOR (curl=>'#tblofcont',ctext=>'Back to top',cattributes=>'class="awr"')));
    p(HTF.BR);
    p(HTF.BR);

    p(COREMOD_REPORT_UTILS.end_lo_section);

--  =============================================================================================================================================
    --Call Tree
/*    COREMOD_REPORT_UTILS.start_lo_section(p_module_name => l_module_name, p_action_name => 'Call Tree');

    p(HTF.header (3,cheader=>HTF.ANCHOR (curl=>'',ctext=>'Call Tree',cname=>'call_tree',cattributes=>'class="awr"'),cattributes=>'class="awr"'));
    p(HTF.BR);


    l_sql := q'[with call_tree as (
select *+ no_merge NO_ELIMINATE_OBY qb_name(TRC_REP1) * rpad('..',(level-1)*2,'..')||call_type lvl_capt, level lvl, CONNECT_BY_ISLEAF ilf, c.*
from trc_call c
where trc_file_id=<P_TRC_FILE_ID>
start with parent_id is null and call_type<>'CLOSE' and trc_file_id=<P_TRC_FILE_ID>
connect by prior call_id=parent_id and trc_file_id=<P_TRC_FILE_ID>
order siblings by row_num)
select lvl_capt "CALL",
       ct.c "CPU", case when <TOTCPU> <> 0 and ct.c/<TOTCPU> > 0.009 then round(100*ct.c/<TOTCPU>)||'%' else null end "CPU %Tot",
       ct.e "ELA", case when <TOTELA> <> 0 and ct.e/<TOTELA> > 0.009 then round(100*ct.e/<TOTELA>)||'%' else null end "ELA %Tot",
       cs.c||case when cs.c is not null and ct.c<>0 then ' ('||round(100*cs.c/ct.c,2)||'%)' else null end "Self CPU (%Cumul)",
       cs.e||case when cs.e is not null and ct.e<>0 then ' ('||round(100*cs.e/ct.e,2)||'%)' else null end "Self ELA (%Cumul)",
       ct.dep, st.sqlid "SQL_ID",
       case when call_type='PARSE' then
         substr(st.sql_text,1,100)||case when length(st.sql_text)>100 then '...' else null end
       else null end sql_text
from (select ct0.*, rownum rn from call_tree ct0)  ct
     left outer join trc_call_self cs on ct.call_id=cs.call_id
     left outer join trc_statement st on ct.stmt_id=st.stmt_id and st.trc_file_id=<P_TRC_FILE_ID>
where case when ilf=1 and case when <TOTELA> <> 0 then ct.e/<TOTELA> else 0 end > 0.008 then 1
           when ilf=0 then 1
           else 0 end = 1
     order by rn]';
    l_sql:=replace(replace(replace(l_sql,'<P_TRC_FILE_ID>',p_trc_file_id),'<TOTCPU>',l_cpu),'<TOTELA>', l_ela);
    COREMOD_REPORT_UTILS.print_table_html_new
                                         (p_query => l_sql,
                                          p_width => l_default_width+500,
                                          p_summary => 'Call Tree',
                                          p_search => 'SQL_ID',
                                          p_replacement => HTF.ANCHOR (curl=>'#sqlid_\1',ctext=>'\1',cattributes=>'class="awr1"'),
                                          p_style_tab => 'trctd',
                                          p_style_head => 'trchd', --head
                                          p_style_r1 => 'trcr1',   --odd rows
                                          p_style_r2  => 'trcr2', --even rows
                                          p_style_finrow => null, -- 'trctotr',
                                          --p_header number default 0,
                                          --p_break_col varchar2 default null,
                                          p_output => p_report);

    p(HTF.BR);
    p(HTF.LISTITEM(cattributes=>'class="awr"',ctext=>HTF.ANCHOR (curl=>'#tblofcont',ctext=>'Back to top',cattributes=>'class="awr"')));
    p(HTF.BR);
    p(HTF.BR);

    p(COREMOD_REPORT_UTILS.end_lo_section);
    --p(COREMOD_REPORT_UTILS.end_lo_section(p_is_finished=>true));
*/
--  =============================================================================================================================================
    --SQL statements
    COREMOD_REPORT_UTILS.start_lo_section(p_module_name => l_module_name, p_action_name => 'SQL statements');

    p(HTF.header (3,cheader=>HTF.ANCHOR (curl=>'',ctext=>'SQL statements',cname=>'sqlstmts',cattributes=>'class="awr"'),cattributes=>'class="awr"'));
    p(HTF.BR);

    for i in (select /*+ qb_name(TRC_REP1) */ sqlid from (select sqlid, e_tot from (select sqlid, sum(e) e_tot from trc$tmp_call_stats group by sqlid order by 2 desc) where rownum<=l_topsql) order by e_tot desc)
    loop
      p(HTF.header (4,cheader=>HTF.ANCHOR (curl=>'',ctext=>'SQL_ID='||i.sqlid,cname=>'sqlid_'||i.sqlid,cattributes=>'class="awr"'),cattributes=>'class="awr"'));
      select sql_text into l_sql_text from trc_statement where trc_file_id=p_trc_file_id and sqlid=i.sqlid and rownum=1;
      COREMOD_REPORT_UTILS.print_text_as_table_new
                                               (  P_TEXT => l_sql_text,
                                                  P_T_HEADER => 'SQL Text',
                                                  P_WIDTH => l_default_width,
                                                  --P_SEARCH => P_SEARCH,
                                                  --P_REPLACEMENT => P_REPLACEMENT,
                                                  --P_COMPARISON => P_COMPARISON,
                                                  p_style_tab => 'trctd',
                                                  p_style_head => 'trchd', --head
                                                  p_style_r1 => 'trcr1',   --odd rows
                                                  p_style_r2  => 'trcr2', --even rows
                                                  P_OUTPUT => p_report) ;
      p(HTF.BR);

      p(HTF.BIG('Cumulative statistics'));

      l_sql := q'[select * from (
with call_list
  as (select 'PARSE' nm from dual union select 'EXEC' from dual union select 'FETCH' from dual union select 'CLOSE' from dual)
select /*+ qb_name(TRC_REP1) */
  call_list.nm "Call", cnt "Count", c/1e6 "CPU", e/1e6 "Elapsed", p "Disk", cr "Query", cu "Current", r "Rows", mis "Mis" , 0 noprn_lastrow
  from trc$tmp_call_stats c1, call_list
 where c1.call_type(+)=call_list.nm and c1.sqlid(+)='<SQL_ID>'
union all
select
  'Total:' "Call", sum(cnt) "Count", sum(c)/1e6 "CPU", sum(e)/1e6 "Elapsed", sum(p) "Disk", sum(cr) "Query", sum(cu) "Current", sum(r) "Rows", sum(mis) "Mis", 1  noprn_lastrow
  from trc$tmp_call_stats where sqlid='<SQL_ID>')
order by decode("Call",'PARSE',1,'EXEC',2,'FETCH',3,'CLOSE',4,5)]';
      l_sql:=replace(l_sql,'<SQL_ID>',i.sqlid);
      COREMOD_REPORT_UTILS.print_table_html_new
                                           (p_query => l_sql,
                                            p_width => l_default_width,
                                            p_summary => 'Cumulative statistics',
                                            --p_search varchar2 default null,
                                            --p_replacement varchar2 default null,
                                            p_style_tab => 'trctd',
                                            p_style_head => 'trchd', --head
                                            p_style_r1 => 'trcr1',   --odd rows
                                            p_style_r2  => 'trcr2', --even rows
                                            p_style_finrow => 'trctotr',
                                            --p_header number default 0,
                                            --p_break_col varchar2 default null,
                                            p_output => p_report);
      p(HTF.BR);

      select count(1) into l_cnt from dual where exists (select 1 from trc$tmp_wait_stats where sqlid=i.sqlid);
      if l_cnt>0 then
        p(HTF.BIG('Cursor waits'));

        l_sql := q'[select /*+ qb_name(TRC_REP1) */ 0 noprn_lastrow, nam "Event", CNT "Times waited", ela/1e6 "Total time", round(AVG_ELA/1e6,6) "Avg time", MAX_ELA/1e6 "Max time", ELA_95/1e6 "95% Percetile"
from trc$tmp_wait_stats
where sqlid='<SQL_ID>'
union all
select 1 noprn_lastrow, 'Total:' "Event", sum(CNT) "Times waited", sum(ela)/1e6 "Total time", null "Avg time", max(MAX_ELA)/1e6 "Max time", null "95% Percetile"
from trc$tmp_wait_stats
where sqlid='<SQL_ID>'
order by 1,4 desc]';
        l_sql:=replace(l_sql,'<SQL_ID>',i.sqlid);
        COREMOD_REPORT_UTILS.print_table_html_new
                                           (p_query => l_sql,
                                            p_width => l_default_width,
                                            p_summary => 'Cursor waits',
                                            --p_search varchar2 default null,
                                            --p_replacement varchar2 default null,
                                            p_style_tab => 'trctd',
                                            p_style_head => 'trchd', --head
                                            p_style_r1 => 'trcr1',   --odd rows
                                            p_style_r2  => 'trcr2', --even rows
                                            p_style_finrow => 'trctotr',
                                            --p_header number default 0,
                                            --p_break_col varchar2 default null,
                                            p_output => p_report);

        p(HTF.BR);
      end if;

      select count(1) into l_cnt from dual where exists (select 1 from TRC$TMP_CALL_SELF_STATS where sqlid=i.sqlid);
      if l_cnt>0 then
        p(HTF.BIG('Self statistics'));

        l_sql := q'[select * from (
with call_list as (select 'PARSE' nm from dual union select 'EXEC' from dual union select 'FETCH' from dual union select 'CLOSE' from dual)
select /*+ qb_name(TRC_REP1) */
  call_list.nm "Call", CNT "Count", c/1e6 "CPU", e/1e6 "Elapsed", p "Disk", cr "Query", cu "Current", 0 noprn_lastrow
from TRC$TMP_CALL_SELF_STATS c, call_list where c.call_type(+)=call_list.nm and c.sqlid(+)='<SQL_ID>'
union all
select
  'Total:' "Call", sum(CNT) "Count", sum(c.c)/1e6 "CPU", sum(c.e)/1e6 "Elapsed", sum(c.p) "Disk", sum(c.cr) "Query", sum(c.cu) "Current", 1  noprn_lastrow
from TRC$TMP_CALL_SELF_STATS c where c.sqlid='<SQL_ID>')
order by decode("Call",'PARSE',1,'EXEC',2,'FETCH',3,'CLOSE',4,5)]';
        l_sql:=replace(l_sql,'<SQL_ID>',i.sqlid);
        COREMOD_REPORT_UTILS.print_table_html_new
                                           (p_query => l_sql,
                                            p_width => l_default_width,
                                            p_summary => 'Self statistics',
                                            --p_search varchar2 default null,
                                            --p_replacement varchar2 default null,
                                            p_style_tab => 'trctd',
                                            p_style_head => 'trchd', --head
                                            p_style_r1 => 'trcr1',   --odd rows
                                            p_style_r2  => 'trcr2', --even rows
                                            p_style_finrow => 'trctotr',
                                            --p_header number default 0,
                                            --p_break_col varchar2 default null,
                                            p_output => p_report);
        p(HTF.BR);
      end if;
      --select count(1) into l_cnt from dual where exists (select 1 from trc$tmp_plan_stats where sqlid=i.sqlid);

      --if l_cnt>0 then
      for j in (select unique sqlid, PLH from trc$tmp_plan_stats where sqlid=i.sqlid) loop
        p(HTF.BIG('Execution Plan Hash: '||j.PLH)); --||p_trc_file_id||':'||i.stmt_id));

        l_sql := q'[with pl as (select /*+ materialize */ * from trc$tmp_plan_stats where sqlid='<SQL_ID>'<PLANHASH>)
select /*+ qb_name(TRC_REP1) */
id,
rpad('.',(level-1),'.')||op "Operation/Name",
dbms_xplan.format_number(card) "E-Rows",
dbms_xplan.format_size(sz) "Bytes",
dbms_xplan.format_number(cost) "Cost",
dbms_xplan.format_number(cnt) "A-Rows",
tim/1e6 "A-Time, sec",
dbms_xplan.format_number(cr) "Buffers",
dbms_xplan.format_number(pr) "Reads",
dbms_xplan.format_number(pw) "Writes"
from pl
start with pid=0 connect by prior id=pid
order siblings by pos]';
        l_sql:=replace(l_sql,'<SQL_ID>',i.sqlid);
        if j.PLH is not null then
          l_sql:=replace(l_sql,'<PLANHASH>',' and plh='||j.PLH);
        else
          l_sql:=replace(l_sql,'<PLANHASH>','');
        end if;
        COREMOD_REPORT_UTILS.print_table_html_new
                                             (p_query => l_sql,
                                              p_width => l_default_width,
                                              p_summary => 'Execution Plan',
                                             --p_search varchar2 default null,
                                             --p_replacement varchar2 default null,
                                              p_style_tab => 'trctd',
                                              p_style_head => 'trchd', --head
                                              p_style_r1 => 'trcr1',   --odd rows
                                              p_style_r2  => 'trcr2', --even rows
                                              p_style_finrow => null, --'trctotr',
                                              --p_header number default 0,
                                              --p_break_col varchar2 default null,
                                              p_output => p_report);
        p(HTF.BR);
      --end if;
      end loop;

      p(HTF.LISTITEM(cattributes=>'class="awr"',ctext=>HTF.ANCHOR (curl=>'#tblofcont',ctext=>'Back to top',cattributes=>'class="awr"')));
      p(HTF.BR);
      p(HTF.BR);
    end loop;


    p(COREMOD_REPORT_UTILS.end_lo_section);
    p(COREMOD_REPORT_UTILS.end_lo_section(p_is_finished=>true));
--  =============================================================================================================================================
--  =============================================================================================================================================
--  =============================================================================================================================================
--  =============================================================================================================================================
--  =============================================================================================================================================
    commit; --to cleanup temp tables

    COREMOD_LOG.Stop_SQL_GATHER_STAT('TRC_REPORT.GETREPORT_I');
    COREMOD_LOG.Stop_SQL_TRACE('TRC_REPORT.GETREPORT_I');
  exception
    when others then
      rollback; --to cleanup temp tables
      coremod_log.log(sqlerrm);
      coremod_log.log(l_sql);
      coremod_log.log(DBMS_UTILITY.FORMAT_ERROR_STACK);
      coremod_log.log(DBMS_UTILITY.FORMAT_ERROR_BACKTRACE);
      raise_application_error(-20000, sqlerrm);
  end;
  
  procedure getreport(p_trc_file_id trc_files.trc_file_id%type)
  is
    l_report coremod_report_utils.t_output_lines;
    l_file_content clob;
    l_file opas_files.file_id%type;
    l_trc_file trc_files%rowtype;
  begin
    l_trc_file:=TRC_FILE_API.get_file(p_trc_file_id,true);
    
    getreport_i(p_trc_file_id, p_report => l_report, p_topsql => COREMOD_API.getconf('TOPSQL',TRC_FILE_API.gMODNAME));

    l_file := COREFILE_API.create_file(P_MODNAME => TRC_FILE_API.gMODNAME,
                                       P_FILE_TYPE => 'Extended SQL Trace Report',
                                       P_FILE_NAME => l_trc_file.filename||'.html',
                                       P_MIMETYPE => 'HTML',
                                       P_OWNER => l_trc_file.OWNER);

    COREFILE_API.get_locator(l_file,l_file_content);    
    
    for i in 1..l_report.count loop
      l_file_content:=l_file_content||l_report(i)||chr(10);
    end loop;    
    
    COREFILE_API.store_content(l_file,l_file_content);

    UPDATE trc_files
       SET report_content = l_file
     WHERE trc_file_id = p_trc_file_id;    

    commit;
  end;
  procedure get_sql_trace_report_async(p_trc_file_id trc_files.trc_file_id%type, p_tq_id out opas_task_queue.tq_id%type)
  is
    L_TASKNAME VARCHAR2(128) := 'TRC_CREATEREPORT';
  begin
    p_tq_id:=COREMOD_TASKS.prep_execute_task (  P_TASKNAME => L_TASKNAME) ;
    COREMOD_TASKS.set_task_param( p_tq_id => p_tq_id, p_name => 'B1', p_num_par => p_trc_file_id);
    COREMOD_TASKS.queue_task ( p_tq_id => p_tq_id ) ;
    commit;
  end;

  procedure getreport_i2(p_sql_id varchar2, p_dblink varchar2, p_id in number, p_parent_id number default null)
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
    --prepare_script(l_script,p_sql_id);
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
    --prepare_script(l_script,p_sql_id);
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
    --prepare_script(l_script,p_sql_id, p_plsql=>true);
    --l_script:=replace(l_script,'procedure p(msg varchar2) is begin dbms_output.put_line(msg);end;','procedure p(msg varchar2) is begin :l_res:=:l_res||msg||chr(10);end;');

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
    --prepare_script(l_script,p_sql_id);
    l_output.delete;
    coremod_report_utils.print_table_html_remotelly(p_query=>l_script,p_width=>1000,p_summary=>'Exadata statistics #1', p_dblink => p_dblink, p_output=> l_output);
    p1(l_output);

    p(HTF.BR);

    l_script:=coremod_api.getscript('PROC_OFFLOAD_PCT2');
    --prepare_script(l_script,p_sql_id);
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
    --prepare_script(l_script,p_sql_id, p_plsql=>true);
    --l_sqlmon1:=replace(l_sqlmon1,'procedure p(msg varchar2) is begin dbms_output.put_line(msg);end;','procedure p(msg varchar2) is begin :l_res:=:l_res||msg||chr(10);end;');

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
    --prepare_script(l_script,p_sql_id);
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
    --prepare_script(l_script,p_sql_id);
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
    --prepare_script(l_script,p_sql_id);
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
    --prepare_script(l_script,p_sql_id);
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
    --prepare_script(l_script,p_sql_id);
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
    --prepare_script(l_script,p_sql_id);
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
    --prepare_script(l_script,p_sql_id);
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
    --prepare_script(l_script,p_sql_id);
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
    --prepare_script(l_script,p_sql_id,true);
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
    --prepare_script(l_script,p_sql_id);

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

    coremod_report_utils.save_report_for_download('sql_'||p_sql_id||'.html', l_report, p_id, p_parent_id);
  exception
    when others then
      coremod_log.log(sqlerrm);
      coremod_log.log(DBMS_UTILITY.FORMAT_ERROR_STACK);
      coremod_log.log(DBMS_UTILITY.FORMAT_ERROR_BACKTRACE);
      raise_application_error(-20000, sqlerrm);
  end;
end;
/

--------------------------------------------------------
show errors
--------------------------------------------------------