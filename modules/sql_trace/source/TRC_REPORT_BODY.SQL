CREATE OR REPLACE
package body trc_report as

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
    l_lobsect number;
    l_simsect number;

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

    procedure print_event_histogram(p_table_header varchar2, p_sqlid varchar2 default null)
    is
      l_tmpl1         varchar2(32765) := null;
      l_tmpl2         varchar2(32765) := null;
      l_colcnt        number := 0;
      l_t11           varchar2(32765) := q'[sum(<COL>)||' ('||round(100*sum(<COL>)/sum(cnt),2)||'%)']';
      l_t12           varchar2(32765) := q'[<COL>||' ('||round(100*<COL>/cnt,2)||'%)']';
      l_t2            varchar2(32765) := q'[sum(<COL>)||' ('||round(100*sum(<COL>)/sum(cnt),2)||'%)',]';
    begin
        p(HTF.BIG(p_table_header));
        for k in (SELECT sum(ela_32) ela_32, sum(ela_64) ela_64, sum(ela_128) ela_128, sum(ela_256) ela_256, sum(ela_512) ela_512,
                         sum(ela_1024) ela_1024, sum(ela_2048) ela_2048, sum(ela_4096) ela_4096, sum(ela_8192) ela_8192, sum(ela_16384) ela_16384,
                         sum(ela_32768) ela_32768, sum(ela_65536) ela_65536, sum(ela_131072) ela_131072, sum(ela_262144) ela_262144, sum(ela_524288) ela_524288,
                         sum(ela_1048576) ela_1048576, sum(ela_2097152) ela_2097152, sum(ela_4194304) ela_4194304, sum(ela_8388608) ela_8388608, sum(ela_16777216) ela_16777216, sum(ela_33554432) ela_33554432, sum(ELA_GR_32S) ELA_GR_32S
                    FROM trc$tmp_wait_hist where sqlid=nvl(p_sqlid,sqlid))
        loop
          if k.ela_32 > 0 then
            l_tmpl1 := l_tmpl1 || case when p_sqlid is null then replace(l_t11,'<COL>','ela_32') else replace(l_t12,'<COL>','ela_32') end || ' "Less than 32 us",';
            l_tmpl2 := l_tmpl2 || replace(l_t2,'<COL>','ela_32');
            l_colcnt := l_colcnt + 1;
          end if;
          if k.ela_64 > 0 then
            l_tmpl1 := l_tmpl1 || case when p_sqlid is null then replace(l_t11,'<COL>','ela_64') else replace(l_t12,'<COL>','ela_64') end || ' "32..64 us",';
            l_tmpl2 := l_tmpl2 || replace(l_t2,'<COL>','ela_64');
            l_colcnt := l_colcnt + 1;
          end if;
          if k.ela_128 > 0 then
            l_tmpl1 := l_tmpl1 || case when p_sqlid is null then replace(l_t11,'<COL>','ela_128') else replace(l_t12,'<COL>','ela_128') end || ' "64..128 us",';
            l_tmpl2 := l_tmpl2 || replace(l_t2,'<COL>','ela_128');
            l_colcnt := l_colcnt + 1;
          end if;
          if k.ela_256 > 0 then
            l_tmpl1 := l_tmpl1 || case when p_sqlid is null then replace(l_t11,'<COL>','ela_256') else replace(l_t12,'<COL>','ela_256') end || ' "128..256 us",';
            l_tmpl2 := l_tmpl2 || replace(l_t2,'<COL>','ela_256');
            l_colcnt := l_colcnt + 1;
          end if;
          if k.ela_512 > 0 then
            l_tmpl1 := l_tmpl1 || case when p_sqlid is null then replace(l_t11,'<COL>','ela_512') else replace(l_t12,'<COL>','ela_512') end || ' "256..512 us",';
            l_tmpl2 := l_tmpl2 || replace(l_t2,'<COL>','ela_512');
            l_colcnt := l_colcnt + 1;
          end if;
          if k.ela_1024 > 0 then
            l_tmpl1 := l_tmpl1 || case when p_sqlid is null then replace(l_t11,'<COL>','ela_1024') else replace(l_t12,'<COL>','ela_1024') end || ' "512..1024 us",';
            l_tmpl2 := l_tmpl2 || replace(l_t2,'<COL>','ela_1024');
            l_colcnt := l_colcnt + 1;
          end if;
          if k.ela_2048 > 0 then
            l_tmpl1 := l_tmpl1 || case when p_sqlid is null then replace(l_t11,'<COL>','ela_2048') else replace(l_t12,'<COL>','ela_2048') end || ' "1..2 ms",';
            l_tmpl2 := l_tmpl2 || replace(l_t2,'<COL>','ela_2048');
            l_colcnt := l_colcnt + 1;
          end if;
          if k.ela_4096 > 0 then
            l_tmpl1 := l_tmpl1 || case when p_sqlid is null then replace(l_t11,'<COL>','ela_4096') else replace(l_t12,'<COL>','ela_4096') end || ' "2..4 ms",';
            l_tmpl2 := l_tmpl2 || replace(l_t2,'<COL>','ela_4096');
            l_colcnt := l_colcnt + 1;
          end if;
          if k.ela_8192 > 0 then
            l_tmpl1 := l_tmpl1 || case when p_sqlid is null then replace(l_t11,'<COL>','ela_8192') else replace(l_t12,'<COL>','ela_8192') end || ' "4..8 ms",';
            l_tmpl2 := l_tmpl2 || replace(l_t2,'<COL>','ela_8192');
            l_colcnt := l_colcnt + 1;
          end if;
          if k.ela_16384 > 0 then
            l_tmpl1 := l_tmpl1 || case when p_sqlid is null then replace(l_t11,'<COL>','ela_16384') else replace(l_t12,'<COL>','ela_16384') end || ' "8..16 ms",';
            l_tmpl2 := l_tmpl2 || replace(l_t2,'<COL>','ela_16384');
            l_colcnt := l_colcnt + 1;
          end if;
          if k.ela_32768 > 0 then
            l_tmpl1 := l_tmpl1 || case when p_sqlid is null then replace(l_t11,'<COL>','ela_32768') else replace(l_t12,'<COL>','ela_32768') end || ' "16..32 ms",';
            l_tmpl2 := l_tmpl2 || replace(l_t2,'<COL>','ela_32768');
            l_colcnt := l_colcnt + 1;
          end if;
          if k.ela_65536 > 0 then
            l_tmpl1 := l_tmpl1 || case when p_sqlid is null then replace(l_t11,'<COL>','ela_65536') else replace(l_t12,'<COL>','ela_65536') end || ' "32..64 ms",';
            l_tmpl2 := l_tmpl2 || replace(l_t2,'<COL>','ela_65536');
            l_colcnt := l_colcnt + 1;
          end if;
          if k.ela_131072 > 0 then
            l_tmpl1 := l_tmpl1 || case when p_sqlid is null then replace(l_t11,'<COL>','ela_131072') else replace(l_t12,'<COL>','ela_131072') end || ' "64..128 ms",';
            l_tmpl2 := l_tmpl2 || replace(l_t2,'<COL>','ela_131072');
            l_colcnt := l_colcnt + 1;
          end if;
          if k.ela_262144 > 0 then
            l_tmpl1 := l_tmpl1 || case when p_sqlid is null then replace(l_t11,'<COL>','ela_262144') else replace(l_t12,'<COL>','ela_262144') end || ' "128..256 ms",';
            l_tmpl2 := l_tmpl2 || replace(l_t2,'<COL>','ela_262144');
            l_colcnt := l_colcnt + 1;
          end if;
          if k.ela_524288 > 0 then
            l_tmpl1 := l_tmpl1 || case when p_sqlid is null then replace(l_t11,'<COL>','ela_524288') else replace(l_t12,'<COL>','ela_524288') end || ' "256..512 ms",';
            l_tmpl2 := l_tmpl2 || replace(l_t2,'<COL>','ela_524288');
            l_colcnt := l_colcnt + 1;
          end if;
          if k.ela_1048576 > 0 then
            l_tmpl1 := l_tmpl1 || case when p_sqlid is null then replace(l_t11,'<COL>','ela_1048576') else replace(l_t12,'<COL>','ela_1048576') end || ' "0.5..1 sec",';
            l_tmpl2 := l_tmpl2 || replace(l_t2,'<COL>','ela_1048576');
            l_colcnt := l_colcnt + 1;
          end if;
          if k.ela_2097152 > 0 then
            l_tmpl1 := l_tmpl1 || case when p_sqlid is null then replace(l_t11,'<COL>','ela_2097152') else replace(l_t12,'<COL>','ela_2097152') end || ' "1..2 sec",';
            l_tmpl2 := l_tmpl2 || replace(l_t2,'<COL>','ela_2097152');
            l_colcnt := l_colcnt + 1;
          end if;
          if k.ela_4194304 > 0 then
            l_tmpl1 := l_tmpl1 || case when p_sqlid is null then replace(l_t11,'<COL>','ela_4194304') else replace(l_t12,'<COL>','ela_4194304') end || ' "2..4 sec",';
            l_tmpl2 := l_tmpl2 ||  replace(l_t2,'<COL>','ela_4194304');
            l_colcnt := l_colcnt + 1;
          end if;
          if k.ela_8388608 > 0 then
            l_tmpl1 := l_tmpl1 || case when p_sqlid is null then replace(l_t11,'<COL>','ela_8388608') else replace(l_t12,'<COL>','ela_8388608') end || ' "4..8 sec",';
            l_tmpl2 := l_tmpl2 || replace(l_t2,'<COL>','ela_8388608');
            l_colcnt := l_colcnt + 1;
          end if;
          if k.ela_16777216 > 0 then
            l_tmpl1 := l_tmpl1 || case when p_sqlid is null then replace(l_t11,'<COL>','ela_16777216') else replace(l_t12,'<COL>','ela_16777216') end || ' "8..16 sec",';
            l_tmpl2 := l_tmpl2 || replace(l_t2,'<COL>','ela_16777216');
            l_colcnt := l_colcnt + 1;
          end if;
          if k.ela_33554432 > 0 then
            l_tmpl1 := l_tmpl1 || case when p_sqlid is null then replace(l_t11,'<COL>','ela_33554432') else replace(l_t12,'<COL>','ela_33554432') end || ' "16..32 sec",';
            l_tmpl2 := l_tmpl2 || replace(l_t2,'<COL>','ela_33554432');
            l_colcnt := l_colcnt + 1;
          end if;
          if k.ELA_GR_32S > 0 then
            l_tmpl1 := l_tmpl1 || case when p_sqlid is null then replace(l_t11,'<COL>','ELA_GR_32S') else replace(l_t12,'<COL>','ELA_GR_32S') end || ' "More than 32 sec",';
            l_tmpl2 := l_tmpl2 || replace(l_t2,'<COL>','ELA_GR_32S');
            l_colcnt := l_colcnt + 1;
          end if;
        end loop;
        l_sql := q'[select /*+ qb_name(TRC_REP1) */ 0 noprn_lastrow, nam "Event", <CNT> "Times waited", <ELA>/1e6 "Total time, sec", <HISTCOLS>
from trc$tmp_wait_hist
where <SQL_ID> <GRPBY>
union all
select 1 noprn_lastrow, 'Total:' "Event", sum(CNT) "Times waited", sum(ela)/1e6 "Total time, sec", <HISTCOLSTOT>
from trc$tmp_wait_hist
where <SQL_ID>
order by 1,4 desc]';
        if p_sqlid is not null then
          l_sql := replace(replace(replace(replace(l_sql,'<SQL_ID>',q'[sqlid=']'||p_sqlid||q'[']'),'<CNT>','cnt'),'<ELA>','ela'),'<GRPBY>',null);
        else
          l_sql := replace(replace(replace(replace(l_sql,'<SQL_ID>','1=1'),'<CNT>','sum(cnt)'),'<ELA>','sum(ela)'),'<GRPBY>',' group by nam');
        end if;
        l_sql:=replace(replace(l_sql,'<HISTCOLS>',rtrim(l_tmpl1,',')),'<HISTCOLSTOT>',rtrim(l_tmpl2,','));
        COREMOD_REPORT_UTILS.print_table_html_new
                                           (p_query => l_sql,
                                            p_width => case when l_colcnt <=3 then l_default_width else l_default_width + l_colcnt * 50 end,
                                            p_summary => p_table_header,
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

    end;
  begin
    COREMOD_LOG.Start_SQL_GATHER_STAT('TRC_REPORT.GETREPORT_I.GATHER_SQL_STAT');
    COREMOD_LOG.Start_SQL_TRACE('TRC_REPORT.GETREPORT_I.SQL_TRACE');

    execute immediate q'[alter session set nls_numeric_characters='. ']';
    select count(1) into l_lobsect from dual where exists (select 1 from trc_lobcall where trc_file_id=p_trc_file_id);
    select count(1) into l_simsect from dual where exists (select 1 from trc_similar_stmt where trc_file_id=p_trc_file_id);

    COREMOD_REPORT_UTILS.set_report_timing(true);
    COREMOD_REPORT_UTILS.init_lo_report(p_op_name => l_report_name, p_target_desc => 'section', p_units => 'sections', p_totalwork => 5 + nvl(l_lobsect,0) + nvl(l_simsect,0) );

    p(HTF.header (1,l_report_name,cattributes=>'class="awr"'));
    p(HTF.BR);
    p(HTF.BR);
    p(HTF.header (2,cheader=>HTF.ANCHOR (curl=>'',ctext=>'Table of contents',cname=>'tblofcont',cattributes=>'class="awr"'),cattributes=>'class="awr"'));
    p(HTF.BR);
    p(HTF.LISTITEM(cattributes=>'class="awr"',ctext=>HTF.ANCHOR (curl=>'#summary',ctext=>'Summary',cattributes=>'class="awr"')));
    p(HTF.LISTITEM(cattributes=>'class="awr"',ctext=>HTF.ANCHOR (curl=>'#topsqls',ctext=>'Top '||l_topsql||' SQLs',cattributes=>'class="awr"')));
    --p(HTF.LISTITEM(cattributes=>'class="awr"',ctext=>HTF.ANCHOR (curl=>'#call_tree',ctext=>'Call Tree',cattributes=>'class="awr"')));
    p(HTF.LISTITEM(cattributes=>'class="awr"',ctext=>HTF.ANCHOR (curl=>'#sqlstmts',ctext=>'SQL statements',cattributes=>'class="awr"')));

    if nvl(l_lobsect,0)=1 then
      p(HTF.LISTITEM(cattributes=>'class="awr"',ctext=>HTF.ANCHOR (curl=>'#lobops',ctext=>'LOB Operations',cattributes=>'class="awr"')));
    end if;
    if nvl(l_simsect,0)=1 then
      p(HTF.LISTITEM(cattributes=>'class="awr"',ctext=>HTF.ANCHOR (curl=>'#simsqlstmts',ctext=>'Similar SQL statements',cattributes=>'class="awr"')));
    end if;

/*    p(HTF.LISTITEM(cattributes=>'class="awr"',ctext=>HTF.ANCHOR (curl=>'#sql_mon',ctext=>'SQL Monitor report',cattributes=>'class="awr"')));
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
     select /*+ leading(st) index(c idx_trc_call_sess) use_nl(c) */ st.sqlid, c.call_type, count(c.call_type) cnt, sum(c) c, sum(e) e, sum(p) p, sum(cr) cr, sum(cu) cu, sum(r) r, sum(mis) mis
       from trc_call c, trc_statement st
      where c.trc_file_id=p_trc_file_id and c.trc_file_id=st.trc_file_id and c.stmt_id=st.stmt_id
      group by c.call_type,st.sqlid;

    insert /*+ qb_name(TRC_REP1) */ into trc$tmp_call_self_stats
    select /*+ leading(st c cs) index(c idx_trc_call_sess) use_nl(c) */ st.sqlid, c.call_type, count(c.call_type) cnt, sum(nvl(cs.c,c.c)) c, sum(nvl(cs.e,c.e)) e, sum(nvl(cs.p,c.p)) p, sum(nvl(cs.cr,c.cr)) cr, sum(nvl(cs.cu,c.cu)) cu
      from trc_call c, trc_call_self cs, trc_statement st
     where c.call_id=cs.call_id(+) and c.trc_file_id=p_trc_file_id and c.trc_file_id=st.trc_file_id and c.stmt_id=st.stmt_id
     group by c.call_type, st.sqlid;

    insert /*+ qb_name(TRC_REP1) */ into trc$tmp_wait_stats
    select /*+ leading(st w) index(w idx_trc_wait_stmt) use_nl(w) */ st.sqlid, ev.wait_class, nam, count(1) cnt, sum(ela) ela, avg(ela) avg_ela, max(ela) max_ela, PERCENTILE_CONT(0.95) within group (order by ela) ela_95
      from trc_wait w, trc_statement st, V$EVENT_NAME ev
     where w.trc_file_id=p_trc_file_id and w.trc_file_id=st.trc_file_id and nam = ev.name
       and w.stmt_id=st.stmt_id  group by nam, st.sqlid, ev.wait_class;

    insert /*+ qb_name(TRC_REP1) */ into trc$tmp_wait_hist
    (
    sqlid, wait_class, nam, cnt, ela,
    ela_32, ela_64, ela_128, ela_256, ela_512,
    ela_1024, ela_2048, ela_4096, ela_8192, ela_16384,
    ela_32768, ela_65536, ela_131072, ela_262144, ela_524288,
    ela_1048576, ela_2097152, ela_4194304, ela_8388608, ela_16777216, ela_33554432, ELA_GR_32S
    )
    select /*+ leading(st w) index(w idx_trc_wait_stmt) use_nl(w) */ st.sqlid, ev.wait_class, nam, count(1) cnt, sum(ela) ela,
    sum(case when ela <= 32 then 1 else 0 end),
    sum(case when ela > 32 and ela <= 64 then 1 else 0 end),
    sum(case when ela > 64 and ela <= 128 then 1 else 0 end),
    sum(case when ela > 128 and ela <= 256 then 1 else 0 end),
    sum(case when ela > 256 and ela <= 512 then 1 else 0 end),
    sum(case when ela > 512 and ela <= 1000 then 1 else 0 end),
    sum(case when ela > 1000 and ela <= 2000 then 1 else 0 end),
    sum(case when ela > 2000 and ela <= 4000 then 1 else 0 end),
    sum(case when ela > 4000 and ela <= 8000 then 1 else 0 end),
    sum(case when ela > 8000 and ela <= 16000 then 1 else 0 end),
    sum(case when ela > 16000 and ela <= 32000 then 1 else 0 end),
    sum(case when ela > 32000 and ela <= 64000 then 1 else 0 end),
    sum(case when ela > 64000 and ela <= 128000 then 1 else 0 end),
    sum(case when ela > 128000 and ela <= 256000 then 1 else 0 end),
    sum(case when ela > 256000 and ela <= 512000 then 1 else 0 end),
    sum(case when ela > 512000 and ela <= 1000000 then 1 else 0 end),
    sum(case when ela > 1000000 and ela <= 2000000 then 1 else 0 end),
    sum(case when ela > 2000000 and ela <= 4000000 then 1 else 0 end),
    sum(case when ela > 4000000 and ela <= 8000000 then 1 else 0 end),
    sum(case when ela > 8000000 and ela <= 16000000 then 1 else 0 end),
    sum(case when ela > 16000000 and ela <= 32000000 then 1 else 0 end),
    sum(case when ela > 32000000 then 1 else 0 end)
      from trc_wait w, trc_statement st, V$EVENT_NAME ev
     where w.trc_file_id=p_trc_file_id and w.trc_file_id=st.trc_file_id and nam = ev.name
       and w.stmt_id=st.stmt_id
     group by nam, st.sqlid, ev.wait_class;

    insert /*+ qb_name(TRC_REP1) */ into trc$tmp_plan_stats
    select st.sqlid, p.plh, p.id, sum(cnt) cnt, p.pid, p.pos, p.obj, p.op, sum(cr)cr, sum(pr) pr, sum(pw) pw, sum(p.tim) tim, p.cost, p.sz, p.card, sum(p.str)
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
  call_list.nm "Call", count(trc_call.call_type) "Count", sum(c)/1e6 "CPU, sec", sum(e)/1e6 "Elapsed, sec", sum(p) "Disk",
  sum(cr) "Query", sum(cu) "Current", sum(r) "Rows", sum(mis) "Mis", 0 noprn_lastrow
from trc_call, call_list where call_type(+)=call_list.nm and trc_file_id(+)=<P_TRC_FILE_ID> and dep(+)=<MIN_DEP>
group by call_list.nm
union all
select
  'Total:' "Call", count(1) "Count", sum(c)/1e6 "CPU, sec", sum(e)/1e6 "Elapsed, sec", sum(p) "Disk",
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

      l_sql := q'[select /*+ qb_name(TRC_REP1) */ 0 noprn_lastrow, nam "Event", count(1) "Times waited", sum(ela)/1e6 "Total time, sec", round(avg(ela)/1e6,6) "Avg time, sec", max(ela)/1e6 "Max time, sec", PERCENTILE_CONT(0.95) within group (order by ela)/1e6 "95% Percetile, sec"
from trc_wait where trc_file_id=<P_TRC_FILE_ID> and nam not in (select name from V$EVENT_NAME where wait_class='Idle') group by nam
union all
select 1 noprn_lastrow, 'Total:' "Event", count(1) "Times waited", sum(ela)/1e6 "Total time, sec", round(avg(ela)/1e6,6) "Avg time, sec", max(ela)/1e6 "Max time, sec", PERCENTILE_CONT(0.95) within group (order by ela)/1e6 "95% Percetile, sec"
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

      l_sql := q'[select /*+ qb_name(TRC_REP1) */ 0 noprn_lastrow, nam "Event", count(1) "Times waited", sum(ela)/1e6 "Total time, sec", round(avg(ela)/1e6,6) "Avg time, sec", max(ela)/1e6 "Max time, sec", PERCENTILE_CONT(0.95) within group (order by ela)/1e6 "95% Percetile, sec"
from trc_wait where trc_file_id=<P_TRC_FILE_ID> and nam in (select name from V$EVENT_NAME where wait_class='Idle') and row_num!=<P_FIRST_IDLE>
group by nam
union all
select 1 noprn_lastrow, 'Total:' "Event", count(1) "Times waited", sum(ela)/1e6 "Total time, sec", round(avg(ela)/1e6,6) "Avg time, sec", max(ela)/1e6 "Max time, sec", PERCENTILE_CONT(0.95) within group (order by ela)/1e6 "95% Percetile, sec"
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
    p(HTF.BR);

    print_event_histogram('Wait events histogram');

    p(HTF.BR);
    p(HTF.BR);

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
e "ELA, us", case when <TOTELA> <> 0 then round(100*e/<TOTELA>,2)||'%' else null end "ELA %Tot",
c "CPU, us", case when <TOTCPU> <> 0 then round(100*c/<TOTCPU>,2)||'%' else null end "CPU %Tot",
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
  call_list.nm "Call", cnt "Count", c/1e6 "CPU, sec", e/1e6 "Elapsed, sec", p "Disk", cr "Query", cu "Current", r "Rows", mis "Mis" , 0 noprn_lastrow
  from trc$tmp_call_stats c1, call_list
 where c1.call_type(+)=call_list.nm and c1.sqlid(+)='<SQL_ID>'
union all
select
  'Total:' "Call", sum(cnt) "Count", sum(c)/1e6 "CPU, sec", sum(e)/1e6 "Elapsed, sec", sum(p) "Disk", sum(cr) "Query", sum(cu) "Current", sum(r) "Rows", sum(mis) "Mis", 1  noprn_lastrow
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

        l_sql := q'[select /*+ qb_name(TRC_REP1) */ 0 noprn_lastrow, nam "Event", CNT "Times waited", ela/1e6 "Total time, sec", round(AVG_ELA/1e6,6) "Avg time, sec", MAX_ELA/1e6 "Max time, sec", ELA_95/1e6 "95% Percetile, sec"
from trc$tmp_wait_stats
where sqlid='<SQL_ID>'
union all
select 1 noprn_lastrow, 'Total:' "Event", sum(CNT) "Times waited, sec", sum(ela)/1e6 "Total time, sec", null "Avg time, sec", max(MAX_ELA)/1e6 "Max time, sec", null "95% Percetile, sec"
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
        print_event_histogram('Cursor waits histogram', i.sqlid);
        p(HTF.BR);
      end if;

      select count(1) into l_cnt from dual where exists (select 1 from TRC$TMP_CALL_SELF_STATS where sqlid=i.sqlid);
      if l_cnt>0 then
        p(HTF.BIG('Self statistics'));

        l_sql := q'[select * from (
with call_list as (select 'PARSE' nm from dual union select 'EXEC' from dual union select 'FETCH' from dual union select 'CLOSE' from dual)
select /*+ qb_name(TRC_REP1) */
  call_list.nm "Call", CNT "Count", c/1e6 "CPU, sec", e/1e6 "Elapsed, sec", p "Disk", cr "Query", cu "Current", 0 noprn_lastrow
from TRC$TMP_CALL_SELF_STATS c, call_list where c.call_type(+)=call_list.nm and c.sqlid(+)='<SQL_ID>'
union all
select
  'Total:' "Call", sum(CNT) "Count", sum(c.c)/1e6 "CPU, sec", sum(c.e)/1e6 "Elapsed, sec", sum(c.p) "Disk", sum(c.cr) "Query", sum(c.cu) "Current", 1  noprn_lastrow
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
      for j in (select sqlid, PLH, sum(str) restarts from trc$tmp_plan_stats where sqlid=i.sqlid group by sqlid, PLH) loop
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
dbms_xplan.format_number(pw) "Writes"]' || case when j.restarts > 0 then q'[, str "Restarts"]' else null end ||
q'[from pl
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

--  =============================================================================================================================================
    --LOB Operations
    if nvl(l_lobsect,0)=1 then
      COREMOD_REPORT_UTILS.start_lo_section(p_module_name => l_module_name, p_action_name => 'LOB Operations');

      p(HTF.header (3,cheader=>HTF.ANCHOR (curl=>'',ctext=>'LOB Operations',cname=>'lobops',cattributes=>'class="awr"'),cattributes=>'class="awr"'));
      p(HTF.BR);

      p(HTF.BIG('Operation list'));

      l_sql := q'[with l as (select min(row_num) mi, max(row_num) ma from trc_wait where trc_file_id=<TRC_FILE_ID> and trc_slot=0)
select call_type "Call",lob_type "LOB Type", bytes "Bytes", c "CPU",e "ELA",p "Phy Reads",cr "LIO",cu "Curr Reads" from (
select row_num, call_type, lob_type, bytes, c,e,p,cr,cu from trc_lobcall where trc_file_id=<TRC_FILE_ID> union all
select row_num, nam,       null,     null,  null, ela, null, null, null from trc_wait where trc_file_id=<TRC_FILE_ID> and trc_slot=0 union all
select row_num, 'TRANSACTION: '||decode(rlbk,0,'COMMIT','ROLLBACK')||' '||decode(rd_only,0,'RO','RW'),
       null, null, null, null, null, null, null from trc_trans, l where trc_file_id=<TRC_FILE_ID> and row_num between l.mi and l.ma
order by row_num)]';
      l_sql:=replace(l_sql,'<TRC_FILE_ID>',p_trc_file_id);
      COREMOD_REPORT_UTILS.print_table_html_new
                                           (p_query => l_sql,
                                            p_width => l_default_width,
                                            p_summary => 'Operation list',
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
    end if;
--  =============================================================================================================================================
--  =============================================================================================================================================
    --Similar SQL statements
    COREMOD_REPORT_UTILS.start_lo_section(p_module_name => l_module_name, p_action_name => 'Similar SQL statements');

    p(HTF.header (3,cheader=>HTF.ANCHOR (curl=>'',ctext=>'Similar SQL statements',cname=>'simsqlstmts',cattributes=>'class="awr"'),cattributes=>'class="awr"'));
    p(HTF.BR);

    for i in (select /*+ qb_name(TRC_REP1) */ x.stmt_id_base, x.cnt, st.hv, substr(st.sql_text,1,100) sql_short
               from (select stmt_id_base, count(1) cnt from trc_similar_stmt where trc_file_id = p_trc_file_id group by stmt_id_base) x,
                    trc_statement st
                where st.stmt_id=x.stmt_id_base
               order by 1)
    loop
      p(HTF.LISTITEM(cattributes=>'class="awr"',ctext=>HTF.ANCHOR (curl=>'#stmt_id_base'||i.stmt_id_base,ctext=>i.cnt||' Similars SQLs, PLAN_HASH='||i.hv||' "'||i.sql_short||'..."',cattributes=>'class="awr"')));
    end loop;

    for i in (select /*+ qb_name(TRC_REP1) */ stmt_id_base, count(1) cnt from trc_similar_stmt where trc_file_id = p_trc_file_id group by stmt_id_base order by 1)
    loop
      p(HTF.header (4,cheader=>HTF.ANCHOR (curl=>'',ctext=>i.cnt||' Similars SQLs',cname=>'stmt_id_base'||i.stmt_id_base,cattributes=>'class="awr"'),cattributes=>'class="awr"'));
      select sql_text into l_sql_text from trc_statement where trc_file_id=p_trc_file_id and stmt_id=i.stmt_id_base;
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
  call_list.nm "Call", sum(cnt) "Count", sum(c)/1e6 "CPU, sec", sum(e)/1e6 "Elapsed, sec", sum(p) "Disk", sum(cr) "Query", sum(cu) "Current", sum(r) "Rows", sum(mis) "Mis" , 0 noprn_lastrow
  from trc$tmp_call_stats c1, call_list, trc_similar_stmt ss, trc_statement st
 where c1.call_type(+)=call_list.nm and c1.sqlid(+)= st.sqlid
   and ss.stmt_id_base=<STMT_BASE>
   and ss.trc_file_id=<TRC_FILE_ID>
   and ss.stmt_id_sim = st.stmt_id
group by nm
union all
select
  'Total:' "Call", sum(cnt) "Count", sum(c)/1e6 "CPU, sec", sum(e)/1e6 "Elapsed, sec", sum(p) "Disk", sum(cr) "Query", sum(cu) "Current", sum(r) "Rows", sum(mis) "Mis", 1  noprn_lastrow
  from trc$tmp_call_stats c, trc_similar_stmt ss, trc_statement st
 where c.sqlid=st.sqlid
   and ss.stmt_id_base=<STMT_BASE>
   and ss.trc_file_id=<TRC_FILE_ID>
   and ss.stmt_id_sim = st.stmt_id
 )
order by decode("Call",'PARSE',1,'EXEC',2,'FETCH',3,'CLOSE',4,5)]';
      l_sql:=replace(replace(l_sql,'<STMT_BASE>',i.stmt_id_base),'<TRC_FILE_ID>',p_trc_file_id);
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

      select count(1) into l_cnt from dual where exists (select 1 from trc$tmp_wait_stats w, trc_similar_stmt ss, trc_statement st
                                                          where st.sqlid=w.sqlid
                                                            and st.stmt_id=ss.stmt_id_sim
                                                            and ss.stmt_id_base=i.stmt_id_base);
      if l_cnt>0 then
        p(HTF.BIG('Cursor waits'));

        l_sql := q'[select /*+ qb_name(TRC_REP1) */ 0 noprn_lastrow, nam "Event", sum(CNT) "Times waited", sum(ela)/1e6 "Total time, sec", max(MAX_ELA)/1e6 "Max time, sec"
from trc$tmp_wait_stats w, trc_similar_stmt ss, trc_statement st
where w.sqlid=st.sqlid
 and ss.stmt_id_base=<STMT_BASE>
 and ss.trc_file_id=<TRC_FILE_ID>
 and ss.stmt_id_sim = st.stmt_id
group by nam
union all
select 1 noprn_lastrow, 'Total:' "Event", sum(CNT) "Times waited, sec", sum(ela)/1e6 "Total time, sec", max(MAX_ELA)/1e6 "Max time, sec"
from trc$tmp_wait_stats w, trc_similar_stmt ss, trc_statement st
where w.sqlid=st.sqlid
 and ss.stmt_id_base=<STMT_BASE>
 and ss.trc_file_id=<TRC_FILE_ID>
 and ss.stmt_id_sim = st.stmt_id
order by 1,4 desc]';
        l_sql:=replace(replace(l_sql,'<STMT_BASE>',i.stmt_id_base),'<TRC_FILE_ID>',p_trc_file_id);
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

        --p(HTF.BR);
        --print_event_histogram('Cursor waits histogram', i.sqlid);
        p(HTF.BR);
      end if;

      select count(1) into l_cnt from dual where exists (select 1 from TRC$TMP_CALL_SELF_STATS s, trc_similar_stmt ss, trc_statement st
                                                          where st.sqlid=s.sqlid
                                                            and st.stmt_id=ss.stmt_id_sim
                                                            and ss.stmt_id_base=i.stmt_id_base);
      if l_cnt>0 then
        p(HTF.BIG('Self statistics'));

        l_sql := q'[select * from (
with call_list as (select 'PARSE' nm from dual union select 'EXEC' from dual union select 'FETCH' from dual union select 'CLOSE' from dual)
select /*+ qb_name(TRC_REP1) */
  call_list.nm "Call", sum(CNT) "Count", sum(c)/1e6 "CPU, sec", sum(e)/1e6 "Elapsed, sec", sum(p) "Disk", sum(cr) "Query", sum(cu) "Current", 0 noprn_lastrow
from TRC$TMP_CALL_SELF_STATS c, call_list, trc_similar_stmt ss, trc_statement st
where c.call_type(+)=call_list.nm and c.sqlid(+)=st.sqlid
 and ss.stmt_id_base=<STMT_BASE>
 and ss.trc_file_id=<TRC_FILE_ID>
 and ss.stmt_id_sim = st.stmt_id
group by nm
union all
select
  'Total:' "Call", sum(CNT) "Count", sum(c.c)/1e6 "CPU, sec", sum(c.e)/1e6 "Elapsed, sec", sum(c.p) "Disk", sum(c.cr) "Query", sum(c.cu) "Current", 1  noprn_lastrow
from TRC$TMP_CALL_SELF_STATS c, trc_similar_stmt ss, trc_statement st
where c.sqlid=st.sqlid
 and ss.stmt_id_base=<STMT_BASE>
 and ss.trc_file_id=<TRC_FILE_ID>
 and ss.stmt_id_sim = st.stmt_id
)
order by decode("Call",'PARSE',1,'EXEC',2,'FETCH',3,'CLOSE',4,5)]';
        l_sql:=replace(replace(l_sql,'<STMT_BASE>',i.stmt_id_base),'<TRC_FILE_ID>',p_trc_file_id);
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
      for j in (select p.sqlid, p.PLH, sum(str) restarts
                 from trc$tmp_plan_stats p, trc_statement st
                where p.sqlid=st.sqlid
                  and st.stmt_id = i.stmt_id_base
                group by p.sqlid, p.PLH) loop
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
dbms_xplan.format_number(pw) "Writes"]' || case when j.restarts > 0 then q'[, str "Restarts"]' else null end ||
q'[from pl
start with pid=0 connect by prior id=pid
order siblings by pos]';
        l_sql:=replace(l_sql,'<SQL_ID>',j.sqlid);
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
    --commit; --to cleanup temp tables

    COREMOD_LOG.Stop_SQL_GATHER_STAT('TRC_REPORT.GETREPORT_I.GATHER_SQL_STAT');
    COREMOD_LOG.Stop_SQL_TRACE('TRC_REPORT.GETREPORT_I.SQL_TRACE');
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
                                       P_MIMETYPE => COREMOD_REPORT_UTILS.gReportMimeType,
                                       P_OWNER => l_trc_file.OWNER);

    COREFILE_API.get_locator(l_file,l_file_content);

    for i in 1..l_report.count loop
      l_file_content:=l_file_content||l_report(i)||chr(10);
    end loop;

    COREFILE_API.store_content(l_file,l_file_content);

    UPDATE trc_files
       SET report_content = l_file
     WHERE trc_file_id = p_trc_file_id;

    --commit;

    COREMOD_REPORT_UTILS.save_report_for_download (  P_FILE => l_file) ;
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

  procedure getstatssect(p_trc_file_id trc_files.trc_file_id%type, p_call_id trc_call.call_id%type, p_report out coremod_report_utils.t_output_lines)
  is
    l_sql varchar2(32765);
    l_default_width number := 800;
    l_indx   number := 1;
    procedure p(p_line varchar2) is
    begin
      --l_report(l_indx):=p_line;
      l_indx := p_report.count + 1;
      p_report(l_indx):=p_line;
    end;
  begin
    insert into trc$tmp_plan_stats
    select st.sqlid, p.plh, p.id, sum(cnt) cnt, p.pid, p.pos, p.obj, p.op, sum(cr)cr, sum(pr) pr, sum(pw) pw, sum(p.tim) tim, p.cost, p.sz, p.card, sum(p.str)
      from (select x.*, (select plh from trc_call y where trc_file_id=p_trc_file_id and x.stmt_id=y.stmt_id and nvl(plh,0)>0 and rownum=1) plh from trc_stat x) p,
           trc_statement st
     where p.trc_file_id=p_trc_file_id and p.call_id=p_call_id and p.trc_file_id=st.trc_file_id and p.stmt_id=st.stmt_id
     group by st.sqlid, p.plh, p.id, p.pid, p.pos, p.obj, p.op, p.cost,p.cost, p.sz, p.card;

    for j in (select sqlid, PLH, sum(str) restarts from trc$tmp_plan_stats group by sqlid, PLH) loop
      p(HTF.BIG('Execution Plan Hash: '||j.PLH)); --||p_trc_file_id||':'||i.stmt_id));

      l_sql := q'[with pl as (select /*+ materialize */ * from trc$tmp_plan_stats)
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
dbms_xplan.format_number(pw) "Writes"]' || case when j.restarts > 0 then q'[, str "Restarts"]' else null end ||
q'[from pl
start with pid=0 connect by prior id=pid
order siblings by pos]';
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
    end loop;
  end;
end;
/
