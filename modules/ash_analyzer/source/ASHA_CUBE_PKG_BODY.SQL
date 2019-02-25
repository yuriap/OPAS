CREATE OR REPLACE
PACKAGE BODY ASHA_CUBE_PKG AS

  type tt_all_params_r is record (
    pa_source varchar2(100),
    pa_dblink varchar2(100),
    pa_cubeagg varchar2(100),
    pa_inst_id varchar2(100),
    pa_start_dt timestamp,
    pa_end_dt timestamp,
    pa_filter varchar2(4000),
    pa_dump_id number,
    pa_metric_id number,
    pa_metricgroup_id number,
    pa_metricagg varchar2(100),
    pa_block_analyze boolean,
    pa_unknown_analyze boolean,
    pa_monitor boolean,
    pa_top_sess boolean,
    pa_snap_ash boolean,
    pa_filtered_separatelly boolean,
    pa_dbid number,
    pa_start_snap number,
    pa_end_snap number
    );

  g_params_t tt_params_t;

  c_sess               constant varchar2(100) := 'SESS_ID';

  g_mon_job_name       constant varchar2(30)  := 'OPASASHMONITOR';

  g_allpars   tt_all_params_r;

  function to_bool(p_val varchar2) return boolean is begin return case upper(p_val) when 'TRUE' then true when 'FALSE' then false when 'T' then true when 'F' then false when 'Y' then true when 'N' then false else false end; end;

  procedure init_params(p_sess_id         asha_cube_sess.sess_id%type)
  is
  begin
    g_params_t(c_sess):=p_sess_id;
    for i in (select * from asha_cube_sess_pars where sess_id=p_sess_id) loop
      g_params_t(upper(i.sess_par_nm)):=i.sess_par_val;
    end loop;
  end;

  function get_sess_pars (p_sess_id asha_cube_sess.sess_id%type) return tt_params_t
  is
  begin
    init_params(p_sess_id);
    return g_params_t;
  end;

  function get_parameter(p_param_name      asha_cube_sess_pars.sess_par_nm%type) return asha_cube_sess_pars.sess_par_val%type
  is
  begin
    coremod_log.log('get param:'||p_param_name||':'||g_params_t(upper(p_param_name)),'DEBUG');
    return g_params_t(upper(p_param_name));
  exception
    when no_data_found then raise_application_error(-20000,'Parameter "'||p_param_name||'" is not specified for session '||g_params_t(c_sess)||chr(10)||DBMS_UTILITY.FORMAT_ERROR_BACKTRACE);
  end;

  function get_parameter_db(p_sess_id         asha_cube_sess.sess_id%type,
                            p_param_name      asha_cube_sess_pars.sess_par_nm%type) return asha_cube_sess_pars.sess_par_val%type result_cache
  is
    l_val asha_cube_sess_pars.sess_par_val%type;
  begin
    select sess_par_val into l_val from asha_cube_sess_pars where sess_id=p_sess_id and sess_par_nm=upper(p_param_name);
    return l_val;
  end;

  procedure check_params(p_sess_id          asha_cube_sess.sess_id%type) is
  begin

    validate_params(p_sess_id);

    g_allpars.pa_snap_ash := to_bool(get_parameter(c_SNAP_ASH));
    g_allpars.pa_monitor := to_bool(get_parameter(c_monitor));
    g_allpars.pa_source := get_parameter(c_source);
    g_allpars.pa_dblink := coremod_api.get_ora_dblink(get_parameter(c_dblink));
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
    g_allpars.pa_top_sess := to_bool(get_parameter(c_top_sess));
    g_allpars.pa_filtered_separatelly := to_bool(get_parameter(c_FILTERED_SEPARATLY));

    g_allpars.pa_dbid := get_parameter(c_DBID);
    g_allpars.pa_start_snap := get_parameter(c_START_SNAP);
    g_allpars.pa_end_snap := get_parameter(c_END_SNAP);

    --g_allpars.pa_snap_duration := get_parameter(c_SNAP_DURATION);
  end;

  procedure validate_params(p_sess_id         asha_cube_sess.sess_id%type)
  is
    l_dt1 timestamp;
    l_dt2 timestamp;
  begin
    if to_bool(get_parameter(c_SNAP_ASH)) then
      add_parameter(p_sess_id,c_monitor,'Y');
      add_parameter(p_sess_id,c_date_interval,'-1');
    end if;

    if get_parameter(c_date_interval) is not null then
      if get_parameter(c_date_interval) = '-1' then
        if to_bool(get_parameter(c_SNAP_ASH)) then
          coremod_log.log('select max(st1), max(st2) from (select min(sample_time) st1, max(sample_time)st2 from asha_cube_snap_ash where sess_id=:p_sess_id group by inst_id)','DEBUG');
          execute immediate 'select max(st1), max(st2) from (select min(sample_time) st1, max(sample_time)st2 from asha_cube_snap_ash where sess_id=:p_sess_id group by inst_id)' into l_dt1,l_dt2 using p_sess_id;
        else
          coremod_log.log('select max(st1), max(st2) from (select min(sample_time) st1, max(sample_time)st2 from gv$active_session_history'||case when get_parameter(c_dblink)<>'$LOCAL$' then '@'||get_parameter(c_dblink) else null end||' group by inst_id)','DEBUG');
          execute immediate 'select max(st1), max(st2) from (select min(sample_time) st1, max(sample_time)st2 from gv$active_session_history'||case when get_parameter(c_dblink)<>'$LOCAL$' then '@'||get_parameter(c_dblink) else null end||' group by inst_id)' into l_dt1,l_dt2;
        end if;
      elsif TO_NUMBER(get_parameter(c_date_interval) DEFAULT -1 ON CONVERSION ERROR)<>-1 then
        coremod_log.log('select systimestamp - '||get_parameter(c_date_interval)||'/60/24, systimestamp from dual'||case when get_parameter(c_dblink)<>'$LOCAL$' then '@'||get_parameter(c_dblink) else null end,'DEBUG');
        execute immediate 'select systimestamp - '||get_parameter(c_date_interval)||'/60/24, systimestamp from dual'||case when get_parameter(c_dblink)<>'$LOCAL$' then '@'||get_parameter(c_dblink) else null end into l_dt1,l_dt2;
      end if;

      add_parameter(p_sess_id,c_start_dt,to_char(l_dt1,c_datetime_fmt));
      add_parameter(p_sess_id,c_end_dt,to_char(l_dt2,c_datetime_fmt));
    end if;
  end;

  procedure load_par_tmpl(p_tmpl_id          asha_cube_sess_tmpl.tmpl_id%type,
                          p_sess_id          asha_cube_sess.sess_id%type)
  is
    l_params_t tt_params_t;
  begin
    coremod_log.log('load_par_tmpl p_sess_id:p_tmpl_id: '||p_sess_id||':'||p_tmpl_id,'DEBUG');

    -- load base parameter list
    for i in (select p.* from asha_cube_sess_tmpl_pars p, asha_cube_sess_tmpl t where t.tmpl_base = 'Y' and t.tmpl_id=p.tmpl_id) loop
      l_params_t(i.tmpl_par_nm):=i.tmpl_par_expr;
    end loop;

    --override by specific template
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

    if l_params_t.exists(c_SNAP_ASH) then add_parameter(p_sess_id,c_SNAP_ASH,l_params_t(c_SNAP_ASH)); end if;
    if l_params_t.exists(c_FILTERED_SEPARATLY) then add_parameter(p_sess_id,c_FILTERED_SEPARATLY,l_params_t(c_FILTERED_SEPARATLY)); end if;

    if l_params_t.exists(c_DBID) then add_parameter(p_sess_id,c_DBID,l_params_t(c_DBID)); end if;
    if l_params_t.exists(c_START_SNAP) then add_parameter(p_sess_id,c_START_SNAP,l_params_t(c_START_SNAP)); end if;
    if l_params_t.exists(c_END_SNAP) then add_parameter(p_sess_id,c_END_SNAP,l_params_t(c_END_SNAP)); end if;

    coremod_log.log('load_par_tmpl finished','DEBUG');
  end;

  procedure init_session(p_proj_id          asha_cube_sess.sess_proj_id%type,
                         p_retention        asha_cube_sess.sess_retention_days%type,
                         p_sess_id   in out asha_cube_sess.sess_id%type,
                         p_parent_sess      asha_cube_sess.parent_id%type default null)
  is
    l_sess_id asha_cube_sess.sess_id%type := p_sess_id;
    l_curproj asha_cube_projects%rowtype;
  begin
    l_curproj:=ASHA_PROJ_API.getproject(p_proj_id, false);
    ASHA_PROJ_LCC.project_exec_action(l_curproj,ASHA_PROJ_LCC.c_project_rwcontent);

    insert into asha_cube_sess (sess_id, sess_proj_id, sess_created, sess_retention_days, sess_status, parent_id)
         values (asha_sq_cube.nextval, p_proj_id, default, p_retention, stNEW, p_parent_sess) returning sess_id into p_sess_id;
    g_params_t.delete;
    g_params_t(c_sess):=p_sess_id;
    if l_sess_id is not null then
      insert into asha_cube_sess_pars (sess_id, sess_par_nm, sess_par_val)
      SELECT p_sess_id, sess_par_nm, sess_par_val FROM asha_cube_sess_pars where sess_id = l_sess_id;

      COREMOD_INTEGRATION.clone_integration (  P_INT_KEY => 'AWRWH2ASH_DUMP2CUBE',
                                               p_modname => 'ASH_ANALYZER',
                                               P_TRG_ENTITY_ID => l_sess_id,
                                               P_TRG_PRNT_ENTITY_ID => p_proj_id,
                                               P_NEW_TRG_ENTITY_ID => p_sess_id) ;
    end if;
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
                               p_start_dt timestamp,
                               p_end_dt timestamp,
                               p_filter varchar2,
                               p_inst_list varchar2,
                               p_dbid number,
                               p_min_snap number,
                               p_max_snap number,
                               p_monitor boolean,
                               p_snap_ash boolean
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
                                                                             when p_snap_ash then '(select * from asha_cube_snap_ash where sess_id='||p_sess_id||')'
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
    if not p_monitor /*and not p_snap_ash*/ then
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
                 trunc(p_start_dt,'mi')+(level-1)/24/60 from dual connect by level <=round((p_end_dt+0-trunc(p_start_dt,'mi'))*24*60)+1;
      end if;
      if p_cubeagg = 'by_hour' then
        insert into asha_cube_timeline
          select p_sess_id,
                 trunc(p_start_dt,'hh')+(level-1)/24 from dual connect by level <=round((p_end_dt+0-trunc(p_start_dt,'hh'))*24)+1;
      end if;
      if p_cubeagg = 'by_day' then
        insert into asha_cube_timeline
          select p_sess_id,
                 trunc(p_start_dt)+(level-1) from dual connect by level <=round(p_end_dt+0-trunc(p_start_dt))+1;
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
                               p_start_dt timestamp,
                               p_end_dt timestamp,
                               p_filter varchar2,
                               p_inst_list varchar2,
                               p_dbid number,
                               p_min_snap number,
                               p_max_snap number,
                               p_monitor boolean,
                               p_metric_id number,
                               p_metricgroup_id number,
                               p_metricagg varchar2,
                               p_snap_ash boolean
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
    coremod_log.log('Start calc_metric_cube, p_metric_id:'||p_metric_id,'DEBUG');
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
        coremod_log.log('p_sess_id, p_dbid, p_min_snap, p_max_snap, p_start_dt, p_end_dt, p_metric_id, p_metricgroup_id:'||
                        p_sess_id||':'||p_dbid||':'||p_min_snap||':'||p_max_snap||':'||p_start_dt||':'||p_end_dt||':'||p_metric_id||':'||p_metricgroup_id,'DEBUG');
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
                               p_start_dt timestamp,
                               p_end_dt timestamp,
                               p_filter varchar2,
                               p_inst_list varchar2,
                               p_dbid number,
                               p_min_snap number,
                               p_max_snap number,
                               p_monitor boolean,
                               p_block_analyze boolean,
                               p_snap_ash boolean
                               )
  is
    l_sql_block_template varchar2(32765):=
   q'[insert into ASHA_CUBE_BLOCK (SESS_ID,SESSION_ID,SESSION_SERIAL#,INST_ID,SQL_ID,MODULE,ACTION,BLOCKING_SESSION,BLOCKING_SESSION_SERIAL#,BLOCKING_INST_ID,CNT,blocker_id)
      select /*+ driving_site(x) */
            :P_SESS_ID, session_id, session_serial#, <INSTANCE_NUMBER>, sql_id, module, action, blocking_session, blocking_session_serial#, blocking_inst_id, cnt<MULT>,
(select program||'; '||machine||'; '||module||'; '||action
  from <SOURCE_TABLE> b
 where <DBID> and b.session_id=x2.blocking_session and b.session_serial#=x2.blocking_session_serial# and b.<INSTANCE_NUMBER>=x2.blocking_inst_id
   and <SNAP_FILTER_BLOCKER> and rownum=1) blocker_id
            from(
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
           group by session_id, session_serial#, <INSTANCE_NUMBER>, sql_id, module, action, blocking_session, blocking_session_serial#, blocking_inst_id) x1)x2
           where cnt/tot>0.001]';
    l_sql varchar2(32765);
    l_crsr sys_refcursor;
  begin
    coremod_log.log('Start calc_block_cube','DEBUG');
    if p_block_analyze /*and not p_monitor*/ then
      l_sql := replace(replace(replace(replace(replace(replace(replace(replace(l_sql_block_template,
                                                          '<SOURCE_TABLE>',case
                                                                             when p_snap_ash then '(select * from asha_cube_snap_ash where sess_id='||p_sess_id||')'
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
                                  '<SNAP_FILTER_BLOCKER>',case when p_source = 'AWR' then 'SNAP_ID BETWEEN :P_MIN_SNAP - 1000 AND :P_MAX_SNAP' else ':P_MIN_SNAP is null and :P_MAX_SNAP is null' end),
                          '<FILTER>',nvl(p_filter,'1=1')),
                          '<MULT>',case when p_source = 'AWR' then '*10' else null end),'<P_INST_ID>',p_inst_list);
      begin
        coremod_log.log('Start block loading','DEBUG');
        coremod_log.log(l_sql,'DEBUG');

        execute immediate l_sql using p_sess_id, p_dbid, p_min_snap, p_max_snap, p_dbid, p_min_snap, p_max_snap, p_start_dt, p_end_dt;

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
                               p_start_dt timestamp,
                               p_end_dt timestamp,
                               p_filter varchar2,
                               p_inst_list varchar2,
                               p_dbid number,
                               p_min_snap number,
                               p_max_snap number,
                               p_monitor boolean,
                               p_unknown_analyze boolean,
                               p_snap_ash boolean
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
    if p_unknown_analyze /*and not p_monitor*/ then
      l_sql := replace(replace(replace(replace(replace(replace(replace(replace(l_sql_unknown_template,
                                                          '<SOURCE_TABLE>',case
                                                                             when p_snap_ash then '(select * from asha_cube_snap_ash where sess_id='||p_sess_id||')'
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
          raise_application_error(-20000,sqlerrm);
      end;
    end if;
    coremod_log.log('End calc_unknown_cube','DEBUG');
  end;

  procedure calc_top_sess_cube(p_sess_id number,
                               p_source varchar2,
                               p_dblink varchar2,
                               p_start_dt timestamp,
                               p_end_dt timestamp,
                               p_filter varchar2,
                               p_inst_list varchar2,
                               p_dbid number,
                               p_min_snap number,
                               p_max_snap number,
                               p_monitor boolean,
                               p_top_sess boolean,
                               p_snap_ash boolean
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
    if p_top_sess /*and not p_monitor*/ then
      l_sql := replace(replace(replace(replace(replace(replace(replace(replace(l_sql_topsess_template,
                                                          '<SOURCE_TABLE>',case
                                                                             when p_snap_ash then '(select * from asha_cube_snap_ash where sess_id='||p_sess_id||')'
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
          raise_application_error(-20000,sqlerrm);
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
    l_start_dt  timestamp;
    l_end_dt    timestamp;
    l_interval  number;

    l_crsr sys_refcursor;
    l_lops_ind number;
    l_module varchar2(100) := 'ASHA Cube calculating';
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

    COREMOD_API.init_longops(l_module,'section','sections',6,l_lops_ind);
    COREMOD_API.start_longops_section ( l_module, 'Preparing');

    l_start_dt:=g_allpars.pa_start_dt;
    l_end_dt:=g_allpars.pa_end_dt;

    if g_allpars.pa_dblink <> '$LOCAL$' then
      if instr(g_allpars.pa_inst_id,'-1')>0 then
        open l_crsr for select inst_id from asha_cube_racnodes_cache where src_dblink=g_allpars.pa_dblink and inst_id<>-1 order by 1;
        loop
          fetch l_crsr into l_inst_id;
          exit when l_crsr%notfound;
          l_inst_list:=l_inst_list||l_inst_id||',';
        end loop;
        close l_crsr;
        l_inst_list:=rtrim(l_inst_list,',');
        if l_inst_list is null then l_inst_list:='1'; end if;
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

        add_parameter(p_sess_id,c_DBID,l_dbid);
        add_parameter(p_sess_id,c_START_SNAP,l_min_snap);
        add_parameter(p_sess_id,c_END_SNAP,l_max_snap);
      end if;
    else
      if g_allpars.pa_source = 'AWR' then
        l_dbid     := g_allpars.pa_DBID;
        l_min_snap := g_allpars.pa_START_SNAP;
        l_max_snap := g_allpars.pa_END_SNAP;
        l_start_dt := g_allpars.pa_start_dt;
        l_end_dt   := g_allpars.pa_end_dt;

        if instr(g_allpars.pa_inst_id,'-1')>0 then
          open l_crsr for select unique instance_number inst_id from dba_hist_snapshot where dbid=l_dbid and snap_id between l_min_snap and l_max_snap order by 1;
          loop
            fetch l_crsr into l_inst_id;
            exit when l_crsr%notfound;
            l_inst_list:=l_inst_list||l_inst_id||',';
          end loop;
          close l_crsr;
          l_inst_list:=rtrim(l_inst_list,',');
          if l_inst_list is null then l_inst_list:='1'; end if;
        else
          l_inst_list:=replace(replace(g_allpars.pa_inst_id,':',','),';',',');
        end if;
      elsif g_allpars.pa_source = 'V$VIEW' then
        if instr(g_allpars.pa_inst_id,'-1')>0 then
          open l_crsr for select unique inst_id from gv$instance order by 1;
          loop
            fetch l_crsr into l_inst_id;
            exit when l_crsr%notfound;
            l_inst_list:=l_inst_list||l_inst_id||',';
          end loop;
          close l_crsr;
          l_inst_list:=rtrim(l_inst_list,',');
          if l_inst_list is null then l_inst_list:='1'; end if;
        else
          l_inst_list:=replace(replace(g_allpars.pa_inst_id,':',','),';',',');
        end if;
      end if;
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
    --=====================================================================
    COREMOD_API.end_longops_section(1,l_lops_ind);
    COREMOD_API.start_longops_section ( l_module, 'Calcualting main cube');
    --=====================================================================
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
                   p_monitor => g_allpars.pa_monitor,
                   p_snap_ash => g_allpars.pa_snap_ash);
    --=====================================================================
    COREMOD_API.end_longops_section(1,l_lops_ind);
    COREMOD_API.start_longops_section ( l_module, 'Calcualting metrics cube');
    --=====================================================================
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
                   p_metricagg => g_allpars.pa_metricagg,
                   p_snap_ash => g_allpars.pa_snap_ash);
    --=====================================================================
    COREMOD_API.end_longops_section(1,l_lops_ind);
    COREMOD_API.start_longops_section ( l_module, 'Calcualting blockers cube');
    --=====================================================================
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
                   p_block_analyze => g_allpars.pa_block_analyze,
                   p_snap_ash => g_allpars.pa_snap_ash);
    --=====================================================================
    COREMOD_API.end_longops_section(1,l_lops_ind);
    COREMOD_API.start_longops_section ( l_module, 'Calcualting unknown cube');
    --=====================================================================
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
                   p_unknown_analyze => g_allpars.pa_unknown_analyze,
                   p_snap_ash => g_allpars.pa_snap_ash);
    --=====================================================================
    COREMOD_API.end_longops_section(1,l_lops_ind);
    COREMOD_API.start_longops_section ( l_module, 'Calcualting top sessions cube');
    --=====================================================================
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
                   p_top_sess => g_allpars.pa_top_sess,
                   p_snap_ash => g_allpars.pa_snap_ash);
    commit;
    --==================================================
    COREMOD_API.end_longops_section(1,l_lops_ind);
    --==================================================

    COREMOD_LOG.Stop_SQL_GATHER_STAT('ASHA_CUBE_PKG.CALC_CUBE');
    COREMOD_LOG.Stop_SQL_TRACE('ASHA_CUBE_PKG.CALC_CUBE');

    coremod_log.log('End calc_cube. p_sess_id: '||p_sess_id,'DEBUG');
  end;

  procedure set_cube_sess_status(p_sess_id asha_cube_sess.sess_id%type, p_status varchar2, p_tq_id opas_task_queue.tq_id%type default null)
  is
    pragma autonomous_transaction;
    l_status varchar2(100);
  begin
    update asha_cube_sess set sess_status = p_status, sess_tq_id=nvl(p_tq_id,sess_tq_id) where sess_id=p_sess_id returning sess_status into l_status;
    coremod_log.log('Set status: '||l_status||'; p_sess_id: '||p_sess_id||'; rows: '||sql%rowcount, 'DEBUG');
    commit;
  end;
  -- for job call
  procedure load_cube_mon     (p_sess_id asha_cube_sess.sess_id%type)
  is
    l_duration number;
    l_end_time date;
  begin
    coremod_log.log('load_cube_mon p_sess_id: '||p_sess_id,'DEBUG');
    ----------------------------------------------------
    for i in (select sess_id from asha_cube_sess where sess_id=p_sess_id and sess_status=stINQUEUE) loop
      ----------------------------------------------------
      set_cube_sess_status(p_sess_id,stMONITOR,coremod_tasks.get_curr_tq_id);
      ----------------------------------------------------
      init_params(p_sess_id);
      --for i in 1..to_number(COREMOD_API.getconf('ITERATIONSMONITOR',ASHA_CUBE_API.gMODNAME))
      l_duration:=to_number(COREMOD_API.getconf('ITERATIONSMONITOR',ASHA_CUBE_API.gMODNAME))*to_number(COREMOD_API.getconf('PAUSEMONITOR',ASHA_CUBE_API.gMODNAME)); --seconds
      l_end_time:=sysdate+(l_duration/3600/24);
      coremod_log.log('load_cube_mon.l_end_time: '||to_char(l_end_time,'YYYY-MON-DD HH24:MI:SS')||':'||to_char(sysdate,'YYYY-MON-DD HH24:MI:SS'),'DEBUG');
      loop
        --coremod_log.log('Start load Cube from job, iteration: '||i,'DEBUG');
        check_params(p_sess_id);
        calc_cube (p_sess_id);
        exit when sysdate>l_end_time;
        dbms_lock.sleep(to_number(COREMOD_API.getconf('PAUSEMONITOR',ASHA_CUBE_API.gMODNAME)));
      end loop;
      ----------------------------------------------------
      set_cube_sess_status(p_sess_id,stREADY);
    end loop;
  exception
    when others then
      set_cube_sess_status(p_sess_id,stFAILED);
      coremod_log.log('ASHA_CUBE_PKG.load_cube_mon'||chr(10)||sqlerrm||chr(10)||DBMS_UTILITY.FORMAT_ERROR_BACKTRACE);
      raise_application_error(-20000,'ASHA_CUBE_PKG.load_cube_mon'||chr(10)||sqlerrm);
  end;

  procedure load_cube_inqueue (p_sess_id asha_cube_sess.sess_id%type)
  is
  begin
    coremod_log.log('load_cube_inqueue p_sess_id: '||p_sess_id,'DEBUG');
    for i in (select sess_id from asha_cube_sess where sess_id=p_sess_id and sess_status=stINQUEUE) loop
      set_cube_sess_status(p_sess_id,stCALC,coremod_tasks.get_curr_tq_id);
      init_params(i.sess_id);
      check_params(i.sess_id);
      calc_cube (i.sess_id);
      set_cube_sess_status(p_sess_id,stREADY);
    end loop;
  exception
    when others then
      set_cube_sess_status(p_sess_id,stFAILED);
      coremod_log.log('ASHA_CUBE_PKG.load_cube_inqueue'||chr(10)||sqlerrm||chr(10)||DBMS_UTILITY.FORMAT_ERROR_BACKTRACE);
      raise_application_error(-20000,'ASHA_CUBE_PKG.load_cube_inqueue'||chr(10)||sqlerrm);
  end;

  procedure queue_load_cube(p_sess_id asha_cube_sess.sess_id%type, p_tq_id out opas_task_queue.tq_id%type)
  is
    l_tq_id           opas_task_queue.tq_id%type;
    pa_monitor        boolean;
    l_parent_sess     asha_cube_sess.parent_id%type;
  begin
    ----------------------------------------------------
    init_params(p_sess_id);
    check_params(p_sess_id);
    validate_params(p_sess_id);
    ----------------------------------------------------

    pa_monitor := to_bool(get_parameter(c_monitor));

    set_cube_sess_status(p_sess_id,stINQUEUE);


--    select parent_id into l_parent_sess from asha_cube_sess where sess_id=p_sess_id;
--    if l_parent_sess is null then
--      coremod_tasks.stop_previous_user_task(P_TASKNAME => 'ASHA_SNAP_ASH');
--    end if;
    coremod_tasks.stop_previous_user_task(P_TASKNAME => 'ASHA_MONITOR');

    if pa_monitor then
      if to_bool(get_parameter(c_SNAP_ASH)) then
        l_tq_id:=COREMOD_TASKS.prep_execute_task (  P_TASKNAME => 'ASHA_SNAP_ASH') ;
        COREMOD_TASKS.set_task_param( p_tq_id => l_tq_id, p_name => 'B1', p_varchar_par => get_parameter(c_dblink));
        COREMOD_TASKS.set_task_param( p_tq_id => l_tq_id, p_name => 'B2', p_num_par => p_sess_id);
        COREMOD_TASKS.queue_task ( p_tq_id => l_tq_id ) ;
      end if;
      p_tq_id:=COREMOD_TASKS.prep_execute_task (  P_TASKNAME => 'ASHA_MONITOR') ;
      COREMOD_TASKS.set_task_param( p_tq_id => p_tq_id, p_name => 'B1', p_num_par => p_sess_id);
      COREMOD_TASKS.queue_task ( p_tq_id => p_tq_id ) ;
    else
      p_tq_id:=COREMOD_TASKS.prep_execute_task (  P_TASKNAME => 'ASHA_CALC_CUBE') ;
      COREMOD_TASKS.set_task_param( p_tq_id => p_tq_id, p_name => 'B1', p_num_par => p_sess_id);
      COREMOD_TASKS.queue_task ( p_tq_id => p_tq_id ) ;
--      coremod_log.log('MAIN CUBE SESS: '||p_sess_id);
--      coremod_log.log('MAIN CUBE TQ: '||p_tq_id);
      begin
        select sess_id into l_parent_sess from asha_cube_sess where parent_id=p_sess_id;
--        coremod_log.log('FILTERED CUBE SESS: '||l_parent_sess);
        queue_load_cube(l_parent_sess,l_tq_id);
--        coremod_log.log('FILTERED CUBE TQ: '||l_tq_id);
      exception
        when no_data_found then null;
      end;
    end if;
    commit;
  exception
    when others then
      coremod_log.log('ASHA_CUBE_PKG.queue_load_cube'||chr(10)||sqlerrm||chr(10)||DBMS_UTILITY.FORMAT_ERROR_BACKTRACE);
      raise_application_error(-20000,'ASHA_CUBE_PKG.queue_load_cube'||chr(10)||sqlerrm);
  end;

  procedure snap_ash (p_dblink opas_db_links.db_link_name%type, p_sess_id number)
  is
    l_frequency number;
    l_duration number;
    l_end_time date;
    l_cnt number; l_iter number := 0;
    l_sample_time timestamp;

    l_sql_tmpl_ash varchar2(32765) := q'[INSERT INTO asha_cube_snap_ash (sess_id,
    inst_id,    sample_id,    sample_time,    sample_time_utc,    usecs_per_row,    is_awr_sample,    session_id,
    session_serial#,    session_type,    flags,    user_id,    sql_id,    is_sqlid_current,    sql_child_number,
    sql_opcode,    sql_opname,    force_matching_signature,    top_level_sql_id,    top_level_sql_opcode,    sql_adaptive_plan_resolved,    sql_full_plan_hash_value,
    sql_plan_hash_value,    sql_plan_line_id,    sql_plan_operation,    sql_plan_options,    sql_exec_id,    sql_exec_start,    plsql_entry_object_id,
    ---
    plsql_entry_subprogram_id,    plsql_object_id,    plsql_subprogram_id,    qc_instance_id,    qc_session_id,    qc_session_serial#,    px_flags,
    event,    event_id,    event#,    seq#,    p1text,    p1,    p2text,
    p2,    p3text,    p3,    wait_class,    wait_class_id,    wait_time,    session_state,
    time_waited,    blocking_session_status,    blocking_session,    blocking_session_serial#,    blocking_inst_id,    blocking_hangchain_info,    current_obj#,
    ---
    current_file#,    current_block#,    current_row#,    top_level_call#,    top_level_call_name,    consumer_group_id,    xid,
    remote_instance#,    time_model,    in_connection_mgmt,    in_parse,    in_hard_parse,    in_sql_execution,    in_plsql_execution,
    in_plsql_rpc,    in_plsql_compilation,    in_java_execution,    in_bind,    in_cursor_close,    in_sequence_load,    in_inmemory_query,
    in_inmemory_populate,    in_inmemory_prepopulate,    in_inmemory_repopulate,    in_inmemory_trepopulate,    in_tablespace_encryption,    capture_overhead,
    ---
    replay_overhead,    is_captured,    is_replayed,    is_replay_sync_token_holder,    service_hash,    program,    module,
    action,    client_id,    machine,    port,    ecid,    dbreplay_file_id,    dbreplay_call_counter,
    tm_delta_time,    tm_delta_cpu_time,    tm_delta_db_time,    delta_time,    delta_read_io_requests,    delta_write_io_requests,    delta_read_io_bytes,
    delta_write_io_bytes,    delta_interconnect_io_bytes,    delta_read_mem_bytes,    pga_allocated,    temp_space_allocated,    con_dbid,    con_id,
    dbop_name,    dbop_exec_id)
SELECT :p_sess_id,
    inst_id, :sample_id, :p_timestamp, null, null,'N', sid,
    serial#,    type, null, user#, sql_id, null, sql_child_number,
    null, null, null, null, null, null, null,
    sql_hash_value,null,null,null, sql_exec_id, sql_exec_start,    plsql_entry_object_id,
    ---
    plsql_entry_subprogram_id,    plsql_object_id,   plsql_subprogram_id,null,null,null,null,
    decode(state,'WAITING',event,null),null,decode(state,'WAITING',event#,null),seq#,p1text, p1,p2text,
    p2, p3text,p3,  decode(state,'WAITING',wait_class,null),  decode(state,'WAITING',wait_class_id,null), wait_time, decode(state,'WAITING',state,'ON CPU'),
    seconds_in_wait, blocking_session_status,    blocking_session, null, blocking_instance, null,row_wait_obj#,
    ---
    row_wait_file#,  row_wait_block#,  row_wait_row#, top_level_call#, null, null, taddr,
    null,  null, null, null, null, null, null,
    null,  null, null, null, null, null, null,
    null,  null, null, null, null, null,
    ---
    null,  null, null, null, null,program,module,
    action,client_info,machine, port,ecid,null,null,
    null,  null, null, null, null, null, null,
    null,  null, null, null, null, null, con_id,
    null,  null
from gv$session@<dblink> where (type='USER' and status='ACTIVE' and wait_class<>'Idle') or (type='BACKGROUND' and wait_class<>'Idle') <FILTER>]';

    l_sql_stat_flt_tmpl varchar2(32765) := q'[
INSERT INTO asha_cube$tmp_statistics ( sample_id, sample_time, statistic#, value )
select sample_id, sample_time, statistic#, sum(value) from
(select :sample_id sample_id, :p_timestamp sample_time, sst.statistic#, sst.value
  from gv$sesstat@<dblink> sst, gv$session@<dblink> s
 where sst.inst_id = s.inst_id
   and sst.sid = s.sid
   and sst.value > 0
   <FILTER>)
   group by sess_id, sample_id, sample_time, /*sid, serial#, inst_id,*/ statistic#]';

    l_sql_stat_tmpl varchar2(32765) := q'[
INSERT INTO asha_cube$tmp_statistics ( sample_id, sample_time, statistic#, value )
select :sample_id sample_id, :p_timestamp sample_time, sst.statistic#, sst.value
  from gv$sysstat@<dblink> sst
 where sst.value > 0]';

   l_sql_sysdt_tmpl varchar2(32765) := q'[select systimestamp from dual@<dblink>]';
   l_filter varchar2(4000);

   l_sql_dt varchar2(32765);
   l_sql_ash varchar2(32765);
   l_sql_stat varchar2(32765);
  begin
    l_filter:=get_parameter_db(p_sess_id, c_filter);
    l_frequency:=to_number(COREMOD_API.getconf('SNAP_ASH_FREQ',ASHA_CUBE_API.gMODNAME));
    l_duration:=to_number(COREMOD_API.getconf('ITERATIONSMONITOR',ASHA_CUBE_API.gMODNAME))*to_number(COREMOD_API.getconf('PAUSEMONITOR',ASHA_CUBE_API.gMODNAME)); --seconds

    l_sql_dt  := replace(l_sql_sysdt_tmpl,'<dblink>',COREMOD_API.get_ora_dblink(p_dblink));
    l_sql_ash := replace(replace(l_sql_tmpl_ash,'<dblink>',     COREMOD_API.get_ora_dblink(p_dblink)),'<FILTER>',case when l_filter is not null then ' and ('||l_filter||')' else null end);
    --if l_filter is not null then
    --  l_sql_stat := replace(replace(l_sql_stat_flt_tmpl,'<dblink>',COREMOD_API.get_ora_dblink(p_dblink)),'<FILTER>',' and ('||l_filter||')');
    --else
    --  l_sql_stat := replace(l_sql_stat_tmpl,'<dblink>',COREMOD_API.get_ora_dblink(p_dblink));
    --end if;

    --delete from asha_cube_snap_ash where sess_id=p_sess_id;
    update asha_cube_sess set sess_tq_id_snap=nvl(coremod_tasks.get_curr_tq_id,sess_tq_id_snap) where sess_id=p_sess_id;
    commit;

    l_end_time:=sysdate+(l_duration/3600/24);
    coremod_log.log('snap_ash.l_end_time: '||to_char(l_end_time,'YYYY-MON-DD HH24:MI:SS')||':'||to_char(sysdate,'YYYY-MON-DD HH24:MI:SS'),'DEBUG');
    --for i in 1..round(p_duration*60*l_frequency)
    loop
      execute immediate l_sql_dt   into l_sample_time;
      execute immediate l_sql_ash  using p_sess_id, asha_snap_ash.nextval, l_sample_time;
      --execute immediate l_sql_stat using asha_snap_ash.nextval, l_sample_time;

      --if mod(l_iter,20)=0 then
      --  delete from asha_cube_statistics where sess_id = p_sess_id;
      --  insert into asha_cube_statistics (sess_id, sample_id, sample_time, statistic#, value)
      --    select * from (
      --      select p_sess_id,sample_id,sample_time,statistic#, value - first_value(value)over(partition by statistic# order by sample_id) d
      --        from asha_cube$tmp_statistics)
      --     where d > 0;
      --end if;
      commit;

      exit when sysdate>l_end_time;

      --select count(1) into l_cnt from user_scheduler_running_jobs where job_name=g_mon_job_name;
      --if l_cnt=0 then l_iter:=l_iter+1; end if;
      --exit when l_iter>3;

      dbms_lock.sleep(1/l_frequency);
      l_iter:=l_iter+1;
    end loop;

    --delete from asha_cube_statistics where sess_id = p_sess_id;
    --insert into asha_cube_statistics (sess_id, sample_id, sample_time, statistic#, value)
    --    select * from (
    --      select p_sess_id,sample_id,sample_time,statistic#, value - first_value(value)over(partition by statistic# order by sample_id) d
    --        from asha_cube$tmp_statistics)
    --     where d > 0;
    --commit;
  end;

END ASHA_CUBE_PKG;
/
