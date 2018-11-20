CREATE OR REPLACE
PACKAGE BODY ASHA_CUBE_PKG AS

  type tt_params_t is table of asha_cube_sess_pars.sess_par_val%type index by asha_cube_sess_pars.sess_par_nm%type;

  g_params_t tt_params_t;

  c_sess               constant varchar2(100) := 'SESS_ID';

  type tt_all_params_r is record (
    pa_source varchar2(100),
    pa_dblink varchar2(100),
    pa_cubeagg varchar2(100),
    pa_inst_id varchar2(100),
    pa_start_dt date,
    pa_end_dt date,
    pa_filter varchar2(4000),
    pa_dump_id number,
    pa_metric_id number,
    pa_metricgroup_id number,
    pa_metricagg varchar2(100),
    pa_block_analyze boolean,
    pa_unknown_analyze boolean,
    pa_monitor boolean,
    pa_top_sess boolean
    );

  g_allpars   tt_all_params_r;

  function to_bool(p_val varchar2) return boolean is begin return case upper(p_val) when 'TRUE' then true when 'FALSE' then false when 'T' then true when 'F' then false when 'Y' then true when 'N' then false else false end; end;

  function get_parameter(p_param_name      asha_cube_sess_pars.sess_par_nm%type) return asha_cube_sess_pars.sess_par_val%type
  is
  begin
    coremod_log.log('get param:'||p_param_name||':'||g_params_t(upper(p_param_name)),'DEBUG');
    return g_params_t(upper(p_param_name));
  exception
    when no_data_found then raise_application_error(-20000,'Parameter "'||p_param_name||'" is not specified for session '||g_params_t(c_sess)||chr(10)||DBMS_UTILITY.FORMAT_ERROR_BACKTRACE);
  end;

  procedure check_params(p_sess_id          asha_cube_sess.sess_id%type) is
    l_dt1 date;
    l_dt2 date;
  begin

    if get_parameter(c_date_interval) = '-1' then
      coremod_log.log('select max(st1), max(st2) from (select min(sample_time) st1, max(sample_time)st2 from gv$active_session_history'||case when get_parameter(c_dblink)<>'$LOCAL$' then '@'||get_parameter(c_dblink) else null end||' group by inst_id)','DEBUG');
      execute immediate 'select max(st1), max(st2) from (select min(sample_time) st1, max(sample_time)st2 from gv$active_session_history'||case when get_parameter(c_dblink)<>'$LOCAL$' then '@'||get_parameter(c_dblink) else null end||' group by inst_id)' into l_dt1,l_dt2;
    elsif TO_NUMBER(get_parameter(c_date_interval) DEFAULT -1 ON CONVERSION ERROR)<>-1 then
      coremod_log.log('select systimestamp - '||get_parameter(c_date_interval)||'/60/24, systimestamp from dual'||case when get_parameter(c_dblink)<>'$LOCAL$' then '@'||get_parameter(c_dblink) else null end,'DEBUG');
      execute immediate 'select systimestamp - '||get_parameter(c_date_interval)||'/60/24, systimestamp from dual'||case when get_parameter(c_dblink)<>'$LOCAL$' then '@'||get_parameter(c_dblink) else null end into l_dt1,l_dt2;
    end if;

    add_parameter(p_sess_id,c_start_dt,to_char(l_dt1,c_datetime_fmt));
    add_parameter(p_sess_id,c_end_dt,to_char(l_dt2,c_datetime_fmt));

    g_allpars.pa_source := get_parameter(c_source);
    g_allpars.pa_dblink := get_parameter(c_dblink);
    g_allpars.pa_cubeagg := get_parameter(c_cubeagg);
    g_allpars.pa_inst_id := get_parameter(c_inst_id);
    g_allpars.pa_start_dt := to_date(get_parameter(c_start_dt),c_datetime_fmt);
    g_allpars.pa_end_dt := to_date(get_parameter(c_end_dt),c_datetime_fmt);
    g_allpars.pa_filter := get_parameter(c_filter);
    g_allpars.pa_dump_id := get_parameter(c_dump_id);
    g_allpars.pa_metric_id := get_parameter(c_metric_id);
    g_allpars.pa_metricgroup_id := get_parameter(c_metricgroup_id);
    g_allpars.pa_metricagg := get_parameter(c_metricagg);
    g_allpars.pa_block_analyze := to_bool(get_parameter(c_block_analyze));
    g_allpars.pa_unknown_analyze := to_bool(get_parameter(c_unknown_analyze));
    g_allpars.pa_monitor := to_bool(get_parameter(c_monitor));
    g_allpars.pa_top_sess := to_bool(get_parameter(c_top_sess));
  end;

  procedure load_par_tmpl(p_tmpl_id          asha_cube_sess_tmpl.tmpl_id%type,
                          p_sess_id          asha_cube_sess.sess_id%type)
  is
    l_params_t tt_params_t;
    l_dt1 date;
    l_dt2 date;
  begin
    coremod_log.log('load_par_tmpl p_sess_id:p_tmpl_id: '||p_sess_id||':'||p_tmpl_id,'DEBUG');

    for i in (select * from asha_cube_sess_tmpl_pars where tmpl_id=p_tmpl_id) loop
      l_params_t(i.tmpl_par_nm):=i.tmpl_par_expr;
    end loop;

    if l_params_t.exists(c_source) then add_parameter(p_sess_id,c_source,l_params_t(c_source)); end if;
    if l_params_t.exists(c_dblink) then add_parameter(p_sess_id,c_dblink,l_params_t(c_dblink)); end if;
    if l_params_t.exists(c_cubeagg) then add_parameter(p_sess_id,c_cubeagg,l_params_t(c_cubeagg)); end if;
    if l_params_t.exists(c_inst_id) then add_parameter(p_sess_id,c_inst_id,l_params_t(c_inst_id)); end if;
    if l_params_t.exists(c_start_dt) then add_parameter(p_sess_id,c_start_dt,l_params_t(c_start_dt)); end if;
    if l_params_t.exists(c_end_dt) then add_parameter(p_sess_id,c_end_dt,l_params_t(c_end_dt)); end if;
    if l_params_t.exists(c_filter) then add_parameter(p_sess_id,c_filter,l_params_t(c_filter)); end if;
    if l_params_t.exists(c_dump_id) then add_parameter(p_sess_id,c_dump_id,l_params_t(c_dump_id)); end if;
    if l_params_t.exists(c_metric_id) then add_parameter(p_sess_id,c_metric_id,l_params_t(c_metric_id)); end if;
    if l_params_t.exists(c_metricgroup_id) then add_parameter(p_sess_id,c_metricgroup_id,l_params_t(c_metricgroup_id)); end if;
    if l_params_t.exists(c_metricagg) then add_parameter(p_sess_id,c_metricagg,l_params_t(c_metricagg)); end if;
    if l_params_t.exists(c_block_analyze) then add_parameter(p_sess_id,c_block_analyze,l_params_t(c_block_analyze)); end if;
    if l_params_t.exists(c_unknown_analyze) then add_parameter(p_sess_id,c_unknown_analyze,l_params_t(c_unknown_analyze)); end if;
    if l_params_t.exists(c_monitor) then add_parameter(p_sess_id,c_monitor,l_params_t(c_monitor)); end if;
    if l_params_t.exists(c_top_sess) then add_parameter(p_sess_id,c_top_sess,l_params_t(c_top_sess)); end if;
    if l_params_t.exists(c_date_interval) then add_parameter(p_sess_id,c_date_interval,l_params_t(c_date_interval)); end if;

    coremod_log.log('load_par_tmpl finished','DEBUG');
  end;

  procedure init_session(p_proj_id          asha_cube_sess.sess_proj_id%type,
                         p_retention        asha_cube_sess.sess_retention_days%type,
                         p_sess_id   in out asha_cube_sess.sess_id%type)
  is
  begin
    insert into asha_cube_sess (sess_id, sess_proj_id, sess_created, sess_retention_days) values (asha_sq_cube.nextval, p_proj_id, default, p_retention) returning sess_id into p_sess_id;
    g_params_t.delete;
    g_params_t(c_sess):=p_sess_id;
  end;

  procedure add_parameter(p_sess_id         asha_cube_sess.sess_id%type,
                          p_param_name      asha_cube_sess_pars.sess_par_nm%type,
                          p_value           asha_cube_sess_pars.sess_par_val%type)
  is
  begin
    MERGE INTO asha_cube_sess_pars t
      using (select p_sess_id sess_id, upper(p_param_name) param_name, p_value value from dual) s
      on (t.sess_id=s.sess_id and t.sess_par_nm=s.param_name)
      when matched then update set t.sess_par_val=s.value
      when not matched then insert ( sess_id, sess_par_nm, sess_par_val)
         VALUES ( s.sess_id, s.param_name, s.value);

    g_params_t(upper(p_param_name)):=p_value;
    coremod_log.log('add param:'||p_sess_id||':'||p_param_name||':'||p_value,'DEBUG');
  end;

  procedure calc_main_cube    (p_sess_id number,
                               p_source varchar2,
                               p_dblink varchar2,
                               p_cubeagg varchar2,
                               p_start_dt date,
                               p_end_dt date,
                               p_filter varchar2,
                               p_inst_list varchar2,
                               p_dbid number,
                               p_min_snap number,
                               p_max_snap number,
                               p_monitor boolean
                               )
  is
    l_sql_template varchar2(32765):=
   q'[SELECT   /*+ driving_site(x) */ :P_SESS_ID, <GROUPBY_COL>
            ,NVL(WAIT_CLASS,'CPU'),nvl(sql_id,'<UNKNOWN SQL>'),nvl(event, 'CPU'),nvl(EVENT_ID,-1),MODULE,ACTION,SQL_ID,SQL_PLAN_HASH_VALUE,current_obj#
            ,COUNT(1)
            ,GROUPING_ID (<GROUPBY_COL>, NVL(WAIT_CLASS,'CPU')) g1
            ,GROUPING_ID (nvl(sql_id,'<UNKNOWN SQL>')) g2
            ,GROUPING_ID (nvl(event, 'CPU'), nvl(EVENT_ID,-1)) g3
            ,GROUPING_ID (module,ACTION) g4
            ,GROUPING_ID (sql_id, SQL_PLAN_HASH_VALUE) g5
            ,GROUPING_ID (current_obj#) g6
     FROM   <SOURCE_TABLE> x
    WHERE   <DBID>
      AND   <INSTANCE_NUMBER> in (<P_INST_ID>)
      AND   <SNAP_FILTER>
      AND   SAMPLE_TIME BETWEEN :P_START_DT AND :P_END_DT
      AND   <FILTER>
    GROUP BY  grouping sets (
                            (<GROUPBY_COL>, NVL(WAIT_CLASS,'CPU')),
                            (nvl(sql_id,'<UNKNOWN SQL>')),
                            (nvl(event, 'CPU'), nvl(EVENT_ID,-1)),
                            (module,ACTION),
                            (sql_id, SQL_PLAN_HASH_VALUE),
                            (current_obj# )
                           )]';
    l_sql varchar2(32765);
    l_crsr sys_refcursor;
  begin
    coremod_log.log('Start calc_main_cube','DEBUG');

    l_sql := replace(replace(replace(replace(replace(replace(l_sql_template,
                                                          '<SOURCE_TABLE>',case
                                                                             when p_source = 'V$VIEW' then case when p_dblink = '$LOCAL$' then 'gv$active_session_history'
                                                                                                          else 'gv$active_session_history@'||p_dblink
                                                                                                          end
                                                                             when p_source = 'AWR' then case when p_dblink = '$LOCAL$' then 'dba_hist_active_sess_history'
                                                                                                        else 'dba_hist_active_sess_history@'||p_dblink
                                                                                                        end
                                                                           end),
                                                  '<DBID>',case when p_source = 'V$VIEW' then ':P_DBID is null' else 'DBID = :P_DBID' end),
                                          '<INSTANCE_NUMBER>',case when p_source = 'V$VIEW' then 'INST_ID' else 'INSTANCE_NUMBER' end),
                                  '<SNAP_FILTER>',case when p_source = 'AWR' then 'SNAP_ID BETWEEN :P_MIN_SNAP AND :P_MAX_SNAP' else ':P_MIN_SNAP is null and :P_MAX_SNAP is null' end),
                          '<FILTER>',nvl(p_filter,'1=1')),'<P_INST_ID>',p_inst_list);
    case
      when p_cubeagg = 'no_agg'  then
        l_sql := replace(l_sql,'<GROUPBY_COL>',q'[cast(sample_time as date)]'); --somehow duplicates can be produced here and main diagram breaks, because several samples during a single second can appear.
      when p_cubeagg = 'by_mi'   then
        l_sql := replace(l_sql,'<GROUPBY_COL>',q'[trunc(sample_time,'mi')]');
      when p_cubeagg = 'by_hour' then
        l_sql := replace(l_sql,'<GROUPBY_COL>',q'[trunc(sample_time,'hh')]');
      when p_cubeagg = 'by_day'  then
        l_sql := replace(l_sql,'<GROUPBY_COL>',q'[trunc(sample_time,'dd')]');
      else
        null;
    end case;

    declare
      type ta_sess_id is table of asha_cube.sess_id%type; la_sess_id ta_sess_id;
      type ta_sample_time is table of asha_cube.sample_time%type; la_sample_time ta_sample_time;
      type ta_wait_class is table of asha_cube.wait_class%type; la_wait_class ta_wait_class;
      type ta_sql_id is table of asha_cube.sql_id%type; la_sql_id ta_sql_id;
      type ta_event is table of asha_cube.event%type; la_event ta_event;
      type ta_event_id is table of asha_cube.event_id%type; la_event_id ta_event_id;
      type ta_module is table of asha_cube.module%type; la_module ta_module;
      type ta_action is table of asha_cube.action%type; la_action ta_action;
      type ta_sql_id1 is table of asha_cube.sql_id1%type; la_sql_id1 ta_sql_id1;
      type ta_sql_plan_hash_value is table of asha_cube.sql_plan_hash_value%type; la_sql_plan_hash_value ta_sql_plan_hash_value;
      type ta_segment_id is table of asha_cube.segment_id%type; la_segment_id ta_segment_id;
      type ta_smpls is table of asha_cube.smpls%type; la_smpls ta_smpls;
      type ta_g1 is table of asha_cube.g1%type; la_g1 ta_g1;
      type ta_g2 is table of asha_cube.g2%type; la_g2 ta_g2;
      type ta_g3 is table of asha_cube.g3%type; la_g3 ta_g3;
      type ta_g4 is table of asha_cube.g4%type; la_g4 ta_g4;
      type ta_g5 is table of asha_cube.g5%type; la_g5 ta_g5;
      type ta_g6 is table of asha_cube.g6%type; la_g6 ta_g6;
    begin
      coremod_log.log(l_sql,'DEBUG');

      open l_crsr for l_sql using p_sess_id, p_dbid, p_min_snap, p_max_snap, p_start_dt, p_end_dt;
      fetch l_crsr bulk collect into la_sess_id, la_sample_time, la_wait_class, la_sql_id, la_event, la_event_id,
                          la_module, la_action, la_sql_id1,la_sql_plan_hash_value,
                          la_segment_id, la_smpls , la_g1, la_g2, la_g3, la_g4, la_g5, la_g6;
      close l_crsr;

      coremod_log.log('Start saving cube','DEBUG');

      if p_monitor then
        delete from asha_cube where sess_id=p_sess_id;
        delete from asha_cube_timeline where sess_id=p_sess_id;
      end if;

      forall i in la_sess_id.first..la_sess_id.last
        INSERT INTO asha_cube
                 (sess_id, sample_time, wait_class, sql_id, event, event_id,
                  module, action, sql_id1,sql_plan_hash_value,
                  segment_id, smpls , g1, g2, g3, g4, g5, g6)
          values (la_sess_id(i), la_sample_time(i), la_wait_class(i), la_sql_id(i), la_event(i), la_event_id(i),
                  la_module(i), la_action(i), la_sql_id1(i),la_sql_plan_hash_value(i),
                  la_segment_id(i), la_smpls(i), la_g1(i), la_g2(i), la_g3(i), la_g4(i), la_g5(i), la_g6(i));
    exception
      when others then
        coremod_log.log('Error SQL: '||chr(10)||l_sql||chr(10)||sqlerrm);
        raise_application_error(-20000,sqlerrm);
    end;
    if not p_monitor then
      coremod_log.log('Start loading segments','DEBUG');

      insert into asha_cube_seg (sess_id,segment_id)
      select * from (select p_sess_id, SEGMENT_ID from asha_cube where sess_id=p_sess_id and g6=0 order by smpls desc) where rownum<21;
      if p_dblink != '$LOCAL$' then
        begin
          coremod_log.log('Start loading seg names','DEBUG');
          l_sql := q'[update asha_cube_seg set segment_name=(select object_type||': '||owner||'.'||object_name from dba_objects]'||
                              case when p_dblink != '$LOCAL$' then '@'||p_dblink else null end||
                              q'[ where object_id=SEGMENT_ID) where sess_id=]'||p_sess_id;
          execute immediate l_sql;
        exception
          when others then
            coremod_log.log('Error SQL: '||chr(10)||l_sql||chr(10)||sqlerrm);
            raise_application_error(-20000,sqlerrm);
        end;
      end if;
      coremod_log.log('End loading segments','DEBUG');
    end if;

    coremod_log.log('Start calc of timeline','DEBUG');
    if p_cubeagg = 'no_agg' then
      insert into asha_cube_timeline select unique p_sess_id, sample_time from asha_cube where sess_id = p_sess_id and g1=0;
    else
      if p_cubeagg = 'by_mi' then
        insert into asha_cube_timeline
          select p_sess_id,
                 trunc(p_start_dt,'mi')+(level-1)/24/60 from dual connect by level <=round((p_end_dt-trunc(p_start_dt,'mi'))*24*60)+1;
      end if;
      if p_cubeagg = 'by_hour' then
        insert into asha_cube_timeline
          select p_sess_id,
                 trunc(p_start_dt,'hh')+(level-1)/24 from dual connect by level <=round((p_end_dt-trunc(p_start_dt,'hh'))*24)+1;
      end if;
      if p_cubeagg = 'by_day' then
        insert into asha_cube_timeline
          select p_sess_id,
                 trunc(p_start_dt)+(level-1) from dual connect by level <=round(p_end_dt-trunc(p_start_dt))+1;
      end if;
    end if;
    coremod_log.log('End calc of timeline','DEBUG');
    coremod_log.log('End calc_main_cube','DEBUG');
  end;
  --============================================================================================================================
  procedure calc_metric_cube  (p_sess_id number,
                               p_source varchar2,
                               p_dblink varchar2,
                               p_cubeagg varchar2,
                               p_start_dt date,
                               p_end_dt date,
                               p_filter varchar2,
                               p_inst_list varchar2,
                               p_dbid number,
                               p_min_snap number,
                               p_max_snap number,
                               p_monitor boolean,
                               p_metric_id number,
                               p_metricgroup_id number,
                               p_metricagg varchar2
                               )
  is
    l_sql_template_metrics varchar2(32765):=
q'[insert into asha_cube_metrics (sess_id, metric_id, end_time, value)
   select   :P_SESS_ID, metric_id, <GROUPBY_COL>, <AGGFNC>
     from   <SOURCE_TABLE>
    where   <DBID>
      AND   <INSTANCE_NUMBER> in (<P_INST_ID>)
      AND   <SNAP_FILTER>
      AND   end_time BETWEEN :P_START_DT AND :P_END_DT
      and   metric_id = :P_METRIC_ID
      and   group_id=:p_metricgroup_id
    group by <GROUPBY_COL>, metric_id]';
    l_sql varchar2(32765);
    l_crsr sys_refcursor;
    l_int_size number;
  begin
    coremod_log.log('Start calc_metric_cube','DEBUG');
    if p_metric_id is not null then

      l_sql := replace(replace(replace(replace(replace(replace(l_sql_template_metrics,
                                                            '<SOURCE_TABLE>',case
                                                                               when p_source = 'V$VIEW' then case when p_dblink = '$LOCAL$' then 'gv$sysmetric_history'
                                                                                                            else 'gv$sysmetric_history@'||p_dblink
                                                                                                            end
                                                                               when p_source = 'AWR' then case when p_dblink = '$LOCAL$' then 'dba_hist_sysmetric_history'
                                                                                                          else 'dba_hist_sysmetric_history@'||p_dblink
                                                                                                          end
                                                                             end),
                                                    '<DBID>',case when p_source = 'V$VIEW' then ':P_DBID is null' else 'DBID = :P_DBID' end),
                                            '<INSTANCE_NUMBER>',case when p_source = 'V$VIEW' then 'INST_ID' else 'INSTANCE_NUMBER' end),
                                    '<SNAP_FILTER>',case when p_source = 'AWR' then 'SNAP_ID BETWEEN :P_MIN_SNAP AND :P_MAX_SNAP' else ':P_MIN_SNAP is null and :P_MAX_SNAP is null' end),
                            '<AGGFNC>',case when p_metricagg in ('AVG', 'COUNT', 'SUM') then p_metricagg||'(value)'
                                            when instr(p_metricagg,'PCT')>0 then 'PERCENTILE_CONT('||to_number(ltrim(p_metricagg,'PCT'))/100||') WITHIN GROUP (ORDER BY value ASC)'
                                            end),
                            '<P_INST_ID>',p_inst_list);

      select interval_size into l_int_size from V$METRICGROUP where group_id = p_metricgroup_id;
      case
        when p_cubeagg = 'no_agg'  then
          l_sql := replace(l_sql,'<GROUPBY_COL>','end_time');
        when p_cubeagg = 'by_mi'   then
          if l_int_size<6000 then
            l_sql := replace(l_sql,'<GROUPBY_COL>',q'[trunc(end_time,'mi')]');
          else
            l_sql := replace(l_sql,'<GROUPBY_COL>','end_time');
          end if;
        when p_cubeagg = 'by_hour' then
          if l_int_size<360000 then
            l_sql := replace(l_sql,'<GROUPBY_COL>',q'[trunc(end_time,'hh')]');
          else
            l_sql := replace(l_sql,'<GROUPBY_COL>','end_time');
          end if;
        when p_cubeagg = 'by_day'  then
          l_sql := replace(l_sql,'<GROUPBY_COL>',q'[trunc(end_time,'dd')]');
        else
          null;
      end case;

      begin
        coremod_log.log('Start metrics loading','DEBUG');
        coremod_log.log(l_sql,'DEBUG');

        if p_monitor then
          delete from asha_cube_metrics where sess_id=p_sess_id;
        end if;

        execute immediate l_sql using p_sess_id, p_dbid, p_min_snap, p_max_snap, p_start_dt, p_end_dt, p_metric_id, p_metricgroup_id;

        coremod_log.log('End metrics loading','DEBUG');
      exception
        when others then
          coremod_log.log('Error SQL: '||chr(10)||l_sql||chr(10)||sqlerrm);
          raise_application_error(-20000,sqlerrm);
      end;
    end if;
    coremod_log.log('End calc_metric_cube','DEBUG');
  end;

  procedure calc_block_cube   (p_sess_id number,
                               p_source varchar2,
                               p_dblink varchar2,
                               p_start_dt date,
                               p_end_dt date,
                               p_filter varchar2,
                               p_inst_list varchar2,
                               p_dbid number,
                               p_min_snap number,
                               p_max_snap number,
                               p_monitor boolean,
                               p_block_analyze boolean
                               )
  is
    l_sql_block_template varchar2(32765):=
   q'[insert into ASHA_CUBE_BLOCK (SESS_ID,SESSION_ID,SESSION_SERIAL#,INST_ID,SQL_ID,MODULE,ACTION,BLOCKING_SESSION,BLOCKING_SESSION_SERIAL#,BLOCKING_INST_ID,CNT)
      select /*+ driving_site(x) */
            :P_SESS_ID, session_id, session_serial#, <INSTANCE_NUMBER>, sql_id, module, action, blocking_session, blocking_session_serial#, blocking_inst_id, cnt<MULT> from(
      select  x1.*, sum(cnt)over() tot from (
         select
                 session_id, session_serial#, <INSTANCE_NUMBER>, sql_id, module, action, blocking_session, blocking_session_serial#, blocking_inst_id,
                 count(1) cnt
            from <SOURCE_TABLE> x
           where <DBID>
             AND <INSTANCE_NUMBER> in (<P_INST_ID>)
             AND <SNAP_FILTER>
             AND SAMPLE_TIME BETWEEN :P_START_DT AND :P_END_DT
             AND <FILTER>
             and wait_class = 'Application'
           group by session_id, session_serial#, <INSTANCE_NUMBER>, sql_id, module, action, blocking_session, blocking_session_serial#, blocking_inst_id) x1)
           where cnt/tot>0.001]';
    l_sql varchar2(32765);
    l_crsr sys_refcursor;
  begin
    coremod_log.log('Start calc_block_cube','DEBUG');
    if p_block_analyze and not p_monitor then
      l_sql := replace(replace(replace(replace(replace(replace(replace(l_sql_block_template,
                                                          '<SOURCE_TABLE>',case
                                                                             when p_source = 'V$VIEW' then case when p_dblink = '$LOCAL$' then 'gv$active_session_history'
                                                                                                          else 'gv$active_session_history@'||p_dblink
                                                                                                          end
                                                                             when p_source = 'AWR' then case when p_dblink = '$LOCAL$' then 'dba_hist_active_sess_history'
                                                                                                        else 'dba_hist_active_sess_history@'||p_dblink
                                                                                                        end
                                                                           end),
                                                  '<DBID>',case when p_source = 'V$VIEW' then ':P_DBID is null' else 'DBID = :P_DBID' end),
                                          '<INSTANCE_NUMBER>',case when p_source = 'V$VIEW' then 'INST_ID' else 'INSTANCE_NUMBER' end),
                                  '<SNAP_FILTER>',case when p_source = 'AWR' then 'SNAP_ID BETWEEN :P_MIN_SNAP AND :P_MAX_SNAP' else ':P_MIN_SNAP is null and :P_MAX_SNAP is null' end),
                          '<FILTER>',nvl(p_filter,'1=1')),
                          '<MULT>',case when p_source = 'AWR' then '*10' else null end),'<P_INST_ID>',p_inst_list);
      begin
        coremod_log.log('Start block loading','DEBUG');
        coremod_log.log(l_sql,'DEBUG');

        execute immediate l_sql using p_sess_id, p_dbid, p_min_snap, p_max_snap, p_start_dt, p_end_dt;

        coremod_log.log('End block loading','DEBUG');
      exception
        when others then
          coremod_log.log('Error SQL: '||chr(10)||l_sql||chr(10)||sqlerrm);
          raise_application_error(-20000,sqlerrm);
      end;
    end if;
    coremod_log.log('End calc_block_cube','DEBUG');
  end;

  procedure calc_unknown_cube (p_sess_id number,
                               p_source varchar2,
                               p_dblink varchar2,
                               p_start_dt date,
                               p_end_dt date,
                               p_filter varchar2,
                               p_inst_list varchar2,
                               p_dbid number,
                               p_min_snap number,
                               p_max_snap number,
                               p_monitor boolean,
                               p_unknown_analyze boolean
                               )
  is
    l_sql_unknown_template varchar2(32765):=
   q'[insert into asha_cube_unknown (sess_id,unknown_type,session_type,program,client_id,machine,ecid,username,smpls)
      select /*+ driving_site(x) */
            :P_SESS_ID, unknown_type,
            session_type, program, client_id, machine, ecid, coalesce((select username from <DBA_USERS> u where u.user_id=x2.user_id),to_char(x2.user_id)) username, cnt from(
      select  x1.*, sum(cnt)over() tot from (
         select  case when sql_id is null and module is null then 'SQL_ID and MODULE'
                        when sql_id is null and module is not null then 'SQL_ID'
                        when sql_id is not null and module is null then 'MODULE' end unknown_type,
                 session_type, program, client_id, machine, ecid, user_id, count(1) cnt
            from <SOURCE_TABLE> x
           where <DBID>
             AND <INSTANCE_NUMBER> in (<P_INST_ID>)
             AND <SNAP_FILTER>
             AND SAMPLE_TIME BETWEEN :P_START_DT AND :P_END_DT
             AND <FILTER>
             and (sql_id is null or (module is null and action is null))
           group by case when sql_id is null and module is null then 'SQL_ID and MODULE'
                        when sql_id is null and module is not null then 'SQL_ID'
                        when sql_id is not null and module is null then 'MODULE' end,
                    session_type,program, client_id,machine,ecid,user_id) x1)x2
           where cnt/tot>0.005]';
    l_sql varchar2(32765);
    l_crsr sys_refcursor;
  begin
    coremod_log.log('Start calc_unknown_cube','DEBUG');
    if p_unknown_analyze and not p_monitor then
      l_sql := replace(replace(replace(replace(replace(replace(replace(replace(l_sql_unknown_template,
                                                          '<SOURCE_TABLE>',case
                                                                             when p_source = 'V$VIEW' then case when p_dblink = '$LOCAL$' then 'gv$active_session_history'
                                                                                                          else 'gv$active_session_history@'||p_dblink
                                                                                                          end
                                                                             when p_source = 'AWR' then case when p_dblink = '$LOCAL$' then 'dba_hist_active_sess_history'
                                                                                                        else 'dba_hist_active_sess_history@'||p_dblink
                                                                                                        end
                                                                           end),
                                                  '<DBID>',case when p_source = 'V$VIEW' then ':P_DBID is null' else 'DBID = :P_DBID' end),
                                          '<INSTANCE_NUMBER>',case when p_source = 'V$VIEW' then 'INST_ID' else 'INSTANCE_NUMBER' end),
                                  '<SNAP_FILTER>',case when p_source = 'AWR' then 'SNAP_ID BETWEEN :P_MIN_SNAP AND :P_MAX_SNAP' else ':P_MIN_SNAP is null and :P_MAX_SNAP is null' end),
                          '<FILTER>',nvl(p_filter,'1=1')),
                          '<MULT>',case when p_source = 'AWR' then '*10' else null end),'<P_INST_ID>',p_inst_list),
                          '<DBA_USERS>',case when p_dblink = '$LOCAL$' then 'dba_users' else 'dba_users@'||p_dblink end);
      begin
        coremod_log.log('Start unknown loading','DEBUG');
        coremod_log.log(l_sql,'DEBUG');

        execute immediate l_sql using p_sess_id, p_dbid, p_min_snap, p_max_snap, p_start_dt, p_end_dt;

        coremod_log.log('End unknown loading','DEBUG');
      exception
        when others then
          coremod_log.log('Error SQL: '||chr(10)||l_sql);
          raise_application_error(-20000,sqlerrm||chr(10)||sqlerrm);
      end;
    end if;
    coremod_log.log('End calc_unknown_cube','DEBUG');
  end;

  procedure calc_top_sess_cube(p_sess_id number,
                               p_source varchar2,
                               p_dblink varchar2,
                               p_start_dt date,
                               p_end_dt date,
                               p_filter varchar2,
                               p_inst_list varchar2,
                               p_dbid number,
                               p_min_snap number,
                               p_max_snap number,
                               p_monitor boolean,
                               p_top_sess boolean
                               )
  is
    l_sql_topsess_template varchar2(32765):=
    q'[INSERT INTO asha_cube_top_sess (sess_id,session_id,session_serial#,inst_id,module,action,program,client_id,machine,ecid,username,smpls)
      select /*+ driving_site(x) */
                :P_SESS_ID, session_id, session_serial#, <INSTANCE_NUMBER>, module, action, program,client_id,machine,ecid,user_id, cnt<MULT> from(
          select
                 session_id, session_serial#, <INSTANCE_NUMBER>, module, action,program,client_id,machine,ecid,user_id,
                 count(1) cnt
            from <SOURCE_TABLE> x
           where <DBID>
             AND <INSTANCE_NUMBER> in (<P_INST_ID>)
             AND <SNAP_FILTER>
             AND SAMPLE_TIME BETWEEN :P_START_DT AND :P_END_DT
             AND <FILTER>
           group by session_id, session_serial#, <INSTANCE_NUMBER>, module, action,program,client_id,machine,ecid,user_id)]';
    l_sql varchar2(32765);
    l_crsr sys_refcursor;
  begin
    coremod_log.log('Start calc_top_sess_cube','DEBUG');
    if p_top_sess and not p_monitor then
      l_sql := replace(replace(replace(replace(replace(replace(replace(replace(l_sql_topsess_template,
                                                          '<SOURCE_TABLE>',case
                                                                             when p_source = 'V$VIEW' then case when p_dblink = '$LOCAL$' then 'gv$active_session_history'
                                                                                                          else 'gv$active_session_history@'||p_dblink
                                                                                                          end
                                                                             when p_source = 'AWR' then case when p_dblink = '$LOCAL$' then 'dba_hist_active_sess_history'
                                                                                                        else 'dba_hist_active_sess_history@'||p_dblink
                                                                                                        end
                                                                           end),
                                                  '<DBID>',case when p_source = 'V$VIEW' then ':P_DBID is null' else 'DBID = :P_DBID' end),
                                          '<INSTANCE_NUMBER>',case when p_source = 'V$VIEW' then 'INST_ID' else 'INSTANCE_NUMBER' end),
                                  '<SNAP_FILTER>',case when p_source = 'AWR' then 'SNAP_ID BETWEEN :P_MIN_SNAP AND :P_MAX_SNAP' else ':P_MIN_SNAP is null and :P_MAX_SNAP is null' end),
                          '<FILTER>',nvl(p_filter,'1=1')),
                          '<MULT>',case when p_source = 'AWR' then '*10' else null end),'<P_INST_ID>',p_inst_list),
                          '<DBA_USERS>',case when p_dblink = '$LOCAL$' then 'dba_users' else 'dba_users@'||p_dblink end);
      begin
        coremod_log.log('Start top sess loading','DEBUG');
        coremod_log.log(l_sql,'DEBUG');
        execute immediate l_sql using p_sess_id, p_dbid, p_min_snap, p_max_snap, p_start_dt, p_end_dt;
        coremod_log.log('End unknown loading','DEBUG');
      exception
        when others then
          coremod_log.log('Error SQL: '||chr(10)||l_sql);
          raise_application_error(-20000,sqlerrm||chr(10)||sqlerrm);
      end;
    end if;
    coremod_log.log('End calc_top_sess_cube','DEBUG');
  end;

  --============================================================================================================================
  procedure calc_cube    (p_sess_id         asha_cube_sess.sess_id%type)
  is
    l_dbid      number;
    l_min_snap  number;
    l_max_snap  number;
    l_int_size  number;
    l_inst_id   number;
    l_inst_list varchar2(32765);
    l_start_dt  date;
    l_end_dt    date;
    l_interval  number;

    l_crsr sys_refcursor;
  begin
    coremod_log.log('Start calc_cube. p_sess_id: '||p_sess_id,'DEBUG');

    if g_params_t(c_sess)<>p_sess_id then
      raise_application_error(-20000,'There is a mismatch between p_sess_id and g_params_t(c_sess): '||p_sess_id||':'||g_params_t(c_sess));
    end if;

    if g_allpars.pa_monitor and not(g_allpars.pa_dblink <> '$LOCAL$' and g_allpars.pa_source = 'V$VIEW') then
      raise_application_error(-20000, 'Monitor mode is availiable only for remote V$ input.');
    end if;

    ----------------------------------------------------
    COREMOD_LOG.Start_SQL_GATHER_STAT('ASHA_CUBE_PKG.CALC_CUBE');
    COREMOD_LOG.Start_SQL_TRACE('ASHA_CUBE_PKG.CALC_CUBE');
    ----------------------------------------------------

    if g_allpars.pa_monitor then
      select max(sample_time)+0.5/24/3600 into l_start_dt from asha_cube where sess_id=p_sess_id;
      l_interval:=g_allpars.pa_end_dt-g_allpars.pa_start_dt;
      if l_start_dt is null then
        l_start_dt:=g_allpars.pa_start_dt;
        l_end_dt:=g_allpars.pa_end_dt;
      else
        execute immediate 'select systimestamp from dual@'||g_allpars.pa_dblink into l_end_dt;
        l_start_dt:=l_end_dt-l_interval;
      end if;
    else
      l_start_dt:=g_allpars.pa_start_dt;
      l_end_dt:=g_allpars.pa_end_dt;
    end if;

coremod_log.log('g_allpars.pa_dblink: '||g_allpars.pa_dblink,'DEBUG');
    if g_allpars.pa_dblink <> '$LOCAL$' then
      if instr(g_allpars.pa_inst_id,'-1')>0 then
        open l_crsr for 'select inst_id from gv$instance@'||g_allpars.pa_dblink||' order by 1';
        loop
          fetch l_crsr into l_inst_id;
          exit when l_crsr%notfound;
          l_inst_list:=l_inst_list||l_inst_id||',';
        end loop;
        close l_crsr;
        l_inst_list:=rtrim(l_inst_list,',');
      else
        l_inst_list:=replace(replace(g_allpars.pa_inst_id,':',','),';',',');
      end if;
      if g_allpars.pa_source = 'AWR' then
        execute immediate 'select dbid from v$database@'||g_allpars.pa_dblink into l_dbid;
        execute immediate replace('select min(snap_id)
            from dba_hist_snapshot@'||g_allpars.pa_dblink||'
           where end_interval_time>=:P_START_DT
             and dbid=:P_DBID
             and instance_number in (<P_INST_ID>)','<P_INST_ID>',l_inst_list) into l_min_snap using l_start_dt, l_dbid;
        execute immediate replace('select min(snap_id)
            from dba_hist_snapshot@'||g_allpars.pa_dblink||'
           where end_interval_time>=:P_END_DT
             and dbid=:P_DBID
             and instance_number in (<P_INST_ID>)','<P_INST_ID>',l_inst_list) into l_max_snap using l_end_dt, l_dbid;
        if l_max_snap is null then
          execute immediate replace('select max(snap_id)
              from dba_hist_snapshot@'||g_allpars.pa_dblink||'
             where dbid=:P_DBID
               and instance_number in (<P_INST_ID>)','<P_INST_ID>',l_inst_list) into l_max_snap using l_dbid;
        end if;
      end if;
    else
      raise_application_error(-20000,'AWR Warehouse is under construction');
    end if;
    ----------------------------------------------------
    coremod_log.log('l_dbid:     '||l_dbid,'DEBUG');
    coremod_log.log('l_min_snap: '||l_min_snap,'DEBUG');
    coremod_log.log('l_max_snap: '||l_max_snap,'DEBUG');
    coremod_log.log('l_int_size: '||l_int_size,'DEBUG');
    coremod_log.log('l_inst_id:  '||l_inst_id,'DEBUG');
    coremod_log.log('l_inst_list:'||l_inst_list,'DEBUG');
    coremod_log.log('l_start_dt: '||to_char(l_start_dt,c_datetime_fmt),'DEBUG');
    coremod_log.log('l_end_dt:   '||to_char(l_end_dt,c_datetime_fmt),'DEBUG');
    coremod_log.log('l_interval: '||l_interval,'DEBUG');
    ----------------------------------------------------
    calc_main_cube(p_sess_id => p_sess_id,
                   p_source => g_allpars.pa_source,
                   p_dblink => g_allpars.pa_dblink,
                   p_cubeagg => g_allpars.pa_cubeagg,
                   p_start_dt => l_start_dt,
                   p_end_dt => l_end_dt,
                   p_filter => g_allpars.pa_filter,
                   p_inst_list => l_inst_list,
                   p_dbid => l_dbid,
                   p_min_snap => l_min_snap,
                   p_max_snap => l_max_snap,
                   p_monitor => g_allpars.pa_monitor);

    calc_metric_cube
                  (p_sess_id => p_sess_id,
                   p_source => g_allpars.pa_source,
                   p_dblink => g_allpars.pa_dblink,
                   p_cubeagg => g_allpars.pa_cubeagg,
                   p_start_dt => l_start_dt,
                   p_end_dt => l_end_dt,
                   p_filter => g_allpars.pa_filter,
                   p_inst_list => l_inst_list,
                   p_dbid => l_dbid,
                   p_min_snap => l_min_snap,
                   p_max_snap => l_max_snap,
                   p_monitor => g_allpars.pa_monitor,
                   p_metric_id => g_allpars.pa_metric_id,
                   p_metricgroup_id => g_allpars.pa_metricgroup_id,
                   p_metricagg => g_allpars.pa_metricagg);

  calc_block_cube (p_sess_id => p_sess_id,
                   p_source => g_allpars.pa_source,
                   p_dblink => g_allpars.pa_dblink,
                   p_start_dt => l_start_dt,
                   p_end_dt => l_end_dt,
                   p_filter => g_allpars.pa_filter,
                   p_inst_list => l_inst_list,
                   p_dbid => l_dbid,
                   p_min_snap => l_min_snap,
                   p_max_snap => l_max_snap,
                   p_monitor => g_allpars.pa_monitor,
                   p_block_analyze => g_allpars.pa_block_analyze);

  calc_unknown_cube
                  (p_sess_id => p_sess_id,
                   p_source => g_allpars.pa_source,
                   p_dblink => g_allpars.pa_dblink,
                   p_start_dt => l_start_dt,
                   p_end_dt => l_end_dt,
                   p_filter => g_allpars.pa_filter,
                   p_inst_list => l_inst_list,
                   p_dbid => l_dbid,
                   p_min_snap => l_min_snap,
                   p_max_snap => l_max_snap,
                   p_monitor => g_allpars.pa_monitor,
                   p_unknown_analyze => g_allpars.pa_unknown_analyze);

  calc_top_sess_cube
                  (p_sess_id => p_sess_id,
                   p_source => g_allpars.pa_source,
                   p_dblink => g_allpars.pa_dblink,
                   p_start_dt => l_start_dt,
                   p_end_dt => l_end_dt,
                   p_filter => g_allpars.pa_filter,
                   p_inst_list => l_inst_list,
                   p_dbid => l_dbid,
                   p_min_snap => l_min_snap,
                   p_max_snap => l_max_snap,
                   p_monitor => g_allpars.pa_monitor,
                   p_top_sess => g_allpars.pa_top_sess);
    commit;

    COREMOD_LOG.Stop_SQL_GATHER_STAT('ASHA_CUBE_PKG.CALC_CUBE');
    COREMOD_LOG.Stop_SQL_TRACE('ASHA_CUBE_PKG.CALC_CUBE');

    coremod_log.log('End calc_cube. p_sess_id: '||p_sess_id,'DEBUG');
  end;

  procedure init_params(p_sess_id         asha_cube_sess.sess_id%type)
  is
  begin
    g_params_t(c_sess):=p_sess_id;
    for i in (select * from asha_cube_sess_pars where sess_id=p_sess_id) loop
      g_params_t(upper(i.sess_par_nm)):=i.sess_par_val;
    end loop;
  end;

  -- for job call
  procedure load_cube_mon     (p_sess_id asha_cube_sess.sess_id%type)
  is
  begin
    init_params(p_sess_id);
    ----------------------------------------------------
    check_params(p_sess_id);
    ----------------------------------------------------
    for i in 1..to_number(COREMOD_API.getconf('ITERATIONSMONITOR',ASHA_CUBE_API.gMODNAME)) loop
      coremod_log.log('Start load Cube from job, iteration: '||i,'DEBUG');
      calc_cube (p_sess_id);
      dbms_lock.sleep(to_number(COREMOD_API.getconf('PAUSEMONITOR',ASHA_CUBE_API.gMODNAME)));
    end loop;
  end;

  procedure load_cube         (p_sess_id asha_cube_sess.sess_id%type)
  is
    l_cnt number;
    l_job_name varchar2(30):='OPASASHMONITOR';
    l_job_body varchar2(32765);
    pa_monitor boolean;
  begin
    ----------------------------------------------------
    check_params(p_sess_id);
    ----------------------------------------------------

    pa_monitor := to_bool(get_parameter(c_monitor));

    select count(1) into l_cnt from USER_SCHEDULER_RUNNING_JOBS where job_name=l_job_name;
    if pa_monitor then
      if l_cnt>0 then
        begin
          dbms_scheduler.stop_job(job_name => l_job_name);
        exception
          when others then coremod_log.log('Stopping job '||l_job_name||' error: '||chr(10)||sqlerrm);
        end;
      end if;
        l_job_body:=q'[begin ASHA_CUBE_PKG.load_cube_mon(p_sess_id=>]'||p_sess_id||q'[); end;]';
        coremod_log.log(l_job_body,'DEBUG');
        dbms_scheduler.create_job(job_name => l_job_name,
                                  job_type => 'PLSQL_BLOCK',
                                  job_action => l_job_body,
                                  start_date => systimestamp,
                                  enabled => true,
                                  AUTO_DROP => true);
    else
      if l_cnt>0 then
        begin
          dbms_scheduler.stop_job(job_name => l_job_name);
        exception
          when others then coremod_log.log('Stopping job '||l_job_name||' error: '||chr(10)||sqlerrm);
        end;
      end if;
      calc_cube (p_sess_id);
    end if;
  end;

END ASHA_CUBE_PKG;
/
