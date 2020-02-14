CREATE OR REPLACE
PACKAGE BODY DB_GROWTH_API AS

  function  getMODNAME return varchar2 is begin return gMODNAME; end;

  procedure set_parameters (p_proj_id     db_growth_parameters.proj_id%type,
                            p_src_dblink  db_growth_parameters.src_dblink%type,
                            p_scheme_list db_growth_parameters.scheme_list%type,
                            p_schedule    db_growth_parameters.schedule%type,
                            p_start_date  db_growth_parameters.start_date%type,
                            p_minimum_seg_sz db_growth_parameters.minimum_seg_sz%type)
  is
    l_curproj db_growth_projects%rowtype;
  begin
    l_curproj:=DB_GROWTH_PROJ_API.getproject(p_proj_id, true);

    DB_GROWTH_PROJ_LCC.project_exec_action(p_proj_id,DB_GROWTH_PROJ_LCC.c_project_edit);

    merge into db_growth_parameters t
     using (select p_proj_id proj_id, p_src_dblink src_dblink, p_start_date start_date, p_scheme_list scheme_list, p_schedule schedule, p_minimum_seg_sz minimum_seg_sz from dual) s
     on (t.proj_id=s.proj_id)
     when matched then update set
       t.src_dblink=s.src_dblink,
       t.start_date=s.start_date,
       t.scheme_list=s.scheme_list,
       t.schedule=s.schedule,
       t.last_changed = systimestamp,
       t.last_validated = null,
       t.minimum_seg_sz = s.minimum_seg_sz
     when not matched then insert
       (t.proj_id, t.src_dblink, t.start_date, t.scheme_list, t.schedule, t.last_changed, t.last_validated)
       values
       (s.proj_id, s.src_dblink, s.start_date, s.scheme_list, s.schedule, sysdate, null);

    delete from db_growth_par_validation where proj_id=p_proj_id;
  end;

  procedure set_alerts (p_proj_id     db_growth_parameters.proj_id%type,
                        p_delta_alert db_growth_parameters.delta_alert%type,
                        p_size_alert  db_growth_parameters.size_alert%type)
  is
    l_curproj db_growth_projects%rowtype;
  begin
    l_curproj:=DB_GROWTH_PROJ_API.getproject(p_proj_id, true);

    merge into db_growth_parameters t
     using (select p_proj_id proj_id, p_delta_alert delta_alert, p_size_alert size_alert from dual) s
     on (t.proj_id=s.proj_id)
     when matched then update set
       t.delta_alert=s.delta_alert,
       t.size_alert=s.size_alert;
  end;

  procedure suspend_config(p_proj_id db_growth_projects.proj_id%type)is
    l_curproj db_growth_projects%rowtype;
    l_params  db_growth_parameters%rowtype;
  begin
    l_curproj:=DB_GROWTH_PROJ_API.getproject(p_proj_id, true);
    select * into l_params from db_growth_parameters where proj_id=p_proj_id;
    for i in (select job_name from user_scheduler_running_jobs where job_name=l_params.job_name) loop
      begin
        DBMS_SCHEDULER.stop_job(l_params.job_name);
      exception
        when others then
          COREMOD_LOG.log('Suspension: Stopping job '||l_params.job_name||' error: '||sqlerrm);
      end;
    end loop;
    DBMS_SCHEDULER.disable(l_params.job_name);
    DB_GROWTH_PROJ_LCC.project_exec_action(l_curproj,DB_GROWTH_PROJ_LCC.c_project_suspend);
  end;

  procedure activate_config(p_proj_id db_growth_projects.proj_id%type)is
    l_curproj db_growth_projects%rowtype;
    l_params  db_growth_parameters%rowtype;
    l_cnt     number := 0;
  begin
    l_curproj:=DB_GROWTH_PROJ_API.getproject(p_proj_id, true);

    select * into l_params from db_growth_parameters where proj_id=p_proj_id;
    if l_params.last_validated > l_params.last_changed then
      delete from db_growth_par_validation where proj_id=p_proj_id;

      if l_params.job_name is not null then
        select count(1) into l_cnt from user_scheduler_jobs where job_name=l_params.job_name;
        if l_cnt=1 then
          DBMS_SCHEDULER.SET_ATTRIBUTE(name => l_params.job_name,
                                       attribute => 'start_date',
                                       value => l_params.start_date);
          DBMS_SCHEDULER.SET_ATTRIBUTE(name => l_params.job_name,
                                       attribute => 'repeat_interval',
                                       value => l_params.schedule);
          DBMS_SCHEDULER.enable(l_params.job_name);
        end if;
      end if;

      if l_params.job_name is null or l_cnt=0 then
        l_params.job_name := 'OPAS_DBGRWTH_'||DBMS_RANDOM.STRING('X',6);
        dbms_scheduler.create_job(job_name => l_params.job_name,
                                  job_type => 'PLSQL_BLOCK',
                                  job_action => 'begin DB_GROWTH_API.gather_data('||p_proj_id||'); end;',
                                  start_date => l_params.start_date,
                                  repeat_interval => l_params.schedule,
                                  enabled => true,
                                  auto_drop=> false);
      end if;

      update db_growth_parameters set job_name = l_params.job_name where proj_id=p_proj_id;
      DB_GROWTH_PROJ_LCC.project_exec_action(l_curproj,DB_GROWTH_PROJ_LCC.c_project_activate);
    end if;
  end;

  procedure cleanup_config(p_proj_id db_growth_projects.proj_id%type)is
  begin
    for l_params in (select * from db_growth_parameters where proj_id=p_proj_id) loop
      if l_params.job_name is not null then
        for i in (select job_name from user_scheduler_running_jobs where job_name=l_params.job_name) loop
          begin
            DBMS_SCHEDULER.stop_job(l_params.job_name);
          exception
            when others then
              COREMOD_LOG.log('Suspension: Stopping job '||l_params.job_name||' error: '||sqlerrm);
          end;
        end loop;
        DBMS_SCHEDULER.disable(l_params.job_name);
        DBMS_SCHEDULER.drop_job(l_params.job_name);
      end if;
    end loop;
  end;

  procedure gather_data(p_proj_id db_growth_projects.proj_id%type)
  is
    l_params  db_growth_parameters%rowtype;
    l_users     DBMS_UTILITY.uncl_array;
    l_tbln      BINARY_INTEGER;
    l_ts        timestamp(6) := systimestamp;
    l_ts_c      varchar2(100) := to_char(l_ts,'YYYYMMDDHH24MISSff9');
    l_size      number;
    l_size_tot  number := 0;

    l_sql_tab_dict varchar2(4000) := q'[merge into db_growth_tables t using (select * from dba_tables@<DBLINK> where owner='<OWNER>' and table_name not like 'BIN%') s
      on (t.owner=s.owner and t.table_name=s.table_name and t.proj_id=<PROJ_ID>)
    when not matched then insert (
      t.proj_id, t.last_updated, t.owner, t.table_name, t.tablespace_name, t.cluster_name, t.iot_name, t.status, t.partitioned,
      t.iot_type, t.temporary, t.secondary, t.nested, t.cluster_owner, t.compression, t.compress_for, t.segment_created)
    values (
      <PROJ_ID>, to_timestamp('<TS>','YYYYMMDDHH24MISSff9'), s.owner, s.table_name, s.tablespace_name, s.cluster_name, s.iot_name, s.status, s.partitioned,
      s.iot_type, s.temporary, s.secondary, s.nested, s.cluster_owner, s.compression, s.compress_for, s.segment_created)]';

    l_sql_idx_dict varchar2(4000) := q'[merge into db_growth_indexes t using (select * from dba_indexes@<DBLINK> where owner='<OWNER>' and table_name not like 'BIN%' and index_name not like 'BIN%') s
      on (t.owner=s.owner and t.INDEX_NAME=s.INDEX_NAME and t.proj_id=<PROJ_ID>)
    when not matched then insert (
      t.proj_id, t.last_updated, t.owner, t.INDEX_NAME, t.INDEX_TYPE, t.TABLE_OWNER, t.TABLE_NAME, t.TABLE_TYPE, t.COMPRESSION, t.PREFIX_LENGTH, t.TABLESPACE_NAME,
      t.INCLUDE_COLUMN, t.STATUS, t.PARTITIONED, t.TEMPORARY, t.SECONDARY, t.FUNCIDX_STATUS, t.JOIN_INDEX, t.DROPPED, t.SEGMENT_CREATED)
    values (
      <PROJ_ID>, to_timestamp('<TS>','YYYYMMDDHH24MISSff9'), s.owner, s.INDEX_NAME, s.INDEX_TYPE, s.TABLE_OWNER, s.TABLE_NAME, s.TABLE_TYPE, s.COMPRESSION, s.PREFIX_LENGTH, s.TABLESPACE_NAME,
      s.INCLUDE_COLUMN, s.STATUS, s.PARTITIONED, s.TEMPORARY, s.SECONDARY, s.FUNCIDX_STATUS, s.JOIN_INDEX, s.DROPPED, s.SEGMENT_CREATED)]';

    l_sql_lob_dict varchar2(4000) := q'[merge into db_growth_lobs t using (select * from dba_lobs@<DBLINK> where owner='<OWNER>' and table_name not like 'BIN%') s
      on (t.owner=s.owner and t.table_name=s.table_name and t.column_name=s.column_name and t.segment_name=s.segment_name and t.proj_id=<PROJ_ID>)
    when not matched then insert (
      t.proj_id, t.last_updated, t.owner, t.table_name, t.COLUMN_NAME, t.SEGMENT_NAME, t.TABLESPACE_NAME, t.INDEX_NAME, t.CHUNK, t.COMPRESSION,
	  t.DEDUPLICATION, t.IN_ROW, t.PARTITIONED, t.SECUREFILE, t.SEGMENT_CREATED)
    values (
      <PROJ_ID>, to_timestamp('<TS>','YYYYMMDDHH24MISSff9'), s.owner, s.table_name, s.column_name, s.segment_name, s.tablespace_name, s.index_name, s.chunk, s.compression,
	  s.deduplication, s.in_row, s.partitioned, s.securefile, s.segment_created)]';

    l_sql_seg_sizes varchar2(4000) := q'[INSERT INTO db_growth_segs ( proj_id, last_updated, owner, segment_type, segment_name, partition_name, tablespace_name, size_b)
      select <PROJ_ID>, to_timestamp('<TS>','YYYYMMDDHH24MISSff9'), owner, segment_type, segment_name, partition_name, tablespace_name, bytes from dba_segments@<DBLINK>
      where owner='<OWNER>' and bytes >= <MINSZ> and segment_name not like 'BIN%']';

    l_sql_summary varchar2(4000) := q'[select sum(bytes) from dba_segments@<DBLINK> where owner='<OWNER>' and segment_name not like 'BIN%']';

    l_tblsp varchar2(4000) := q'[
INSERT INTO db_growth_ts_sizes ( proj_id, last_updated, ts_name, free_bytes, free_in_files, free_to_extend, USED_BYTES)
       select <PROJ_ID>, to_timestamp('<TS>','YYYYMMDDHH24MISSff9'),
       nvl(free_sp.tablespace_name, free_au.tablespace_name) ts_name,
       nvl(free_sp.free_bytes, 0) + nvl(free_au.free_bytes, 0) free_bytes,
       free_sp.free_bytes free_in_files,
       free_au.free_bytes free_to_extend,
       (select sum(bytes) from dba_segments@<DBLINK> where TABLESPACE_NAME = nvl(free_sp.tablespace_name, free_au.tablespace_name))
  from (select tablespace_name, sum(bytes) free_bytes
          from dba_free_space@<DBLINK>
         where tablespace_name in (<TSLIST>)
         group by tablespace_name) free_sp
  full outer join (select sum(case when autoextensible = 'YES' then maxbytes - bytes else 0 end) free_bytes, tablespace_name
                     from dba_data_files@<DBLINK> x
                    where tablespace_name in (<TSLIST>)
                    group by tablespace_name) free_au
    on (free_sp.tablespace_name = free_au.tablespace_name)]';

    l_ts_list varchar2(512);

    procedure get_data(p_sql_tmpl varchar2, p_dblink varchar2, p_owner varchar2, p_proj_id number, p_ts varchar2, p_minsz number default null)
    is
    begin
      begin
        execute immediate replace(replace(replace(replace(replace(p_sql_tmpl,'<DBLINK>',p_dblink),'<OWNER>',p_owner),'<PROJ_ID>',p_proj_id),'<TS>',p_ts),'<MINSZ>',p_minsz);
      exception
        when others then
          COREMOD_LOG.log('DB_GROWTH_API.gather_data: DBLINK:'||p_dblink||'; OWNER:'||p_owner||'; error: '||sqlerrm);
          COREMOD_LOG.log('DB_GROWTH_API.gather_data: '||p_sql_tmpl);
      end;
    end;

  begin
    select * into l_params from db_growth_parameters where proj_id=p_proj_id;
    DBMS_UTILITY.COMMA_TO_TABLE (
        list   => l_params.scheme_list,
        tablen => l_tbln,
        tab    => l_users);

    for i in 1..l_tbln loop
      if instr(l_users(i),'"')=0 then l_users(i):=upper(l_users(i)); end if;
      get_data(l_sql_tab_dict,  COREMOD_API.get_ora_dblink ( l_params.src_dblink), l_users(i), p_proj_id, l_ts_c);
      get_data(l_sql_idx_dict,  COREMOD_API.get_ora_dblink ( l_params.src_dblink), l_users(i), p_proj_id, l_ts_c);
      get_data(l_sql_lob_dict,  COREMOD_API.get_ora_dblink ( l_params.src_dblink), l_users(i), p_proj_id, l_ts_c);
      get_data(l_sql_seg_sizes, COREMOD_API.get_ora_dblink ( l_params.src_dblink), l_users(i), p_proj_id, l_ts_c, nvl(l_params.minimum_seg_sz,0));
      execute immediate replace(replace(l_sql_summary,'<DBLINK>',COREMOD_API.get_ora_dblink ( l_params.src_dblink)),'<OWNER>',l_users(i)) into l_size;
      l_size_tot := l_size_tot + l_size;
    end loop;

    begin
      l_tblsp:=replace(replace(replace(l_tblsp,'<DBLINK>',COREMOD_API.get_ora_dblink ( l_params.src_dblink)),'<PROJ_ID>',p_proj_id),'<TS>',l_ts_c);

      select listagg(''''||tablespace_name||'''',',')within group (order by tablespace_name) into l_ts_list
        from (select unique tablespace_name from db_growth_segs
               where proj_id=p_proj_id and trunc(last_updated,'mi') = trunc(l_ts,'mi'));

      l_tblsp := replace(l_tblsp, '<TSLIST>', l_ts_list);
      execute immediate l_tblsp;

      --update DB_GROWTH_TS_SIZES
      --   set USED_BYTES=(select sum(SIZE_B) from db_growth_segs where TABLESPACE_NAME = TS_NAME and proj_id=p_proj_id and trunc(last_updated,'mi') = trunc(l_ts,'mi'))
      -- where PROJ_ID = p_proj_id and trunc(last_updated,'mi') = trunc(l_ts,'mi');
    exception
      when others then COREMOD_LOG.log(sqlerrm); COREMOD_LOG.log(l_tblsp);
    end;

    update db_growth_parameters
       set last_updated = l_ts,
           tot_size = l_size_tot,
           delta = l_size_tot - nvl(l_params.tot_size,l_size_tot)
     where proj_id=p_proj_id;

    INSERT INTO db_growth_sizes ( proj_id, last_updated, size_b, delta )
      values (p_proj_id, trunc(l_ts,'mi'), l_size_tot, l_size_tot - nvl(l_params.tot_size,l_size_tot));

    commit;

    refresh_matviews();

    commit;
  end;

  procedure refresh_matviews
  is
  begin
    --DBMS_MVIEW.REFRESH(list=>'DB_GROWTH_SIZES');
    null;
  end;

  procedure validate_config(p_proj_id db_growth_projects.proj_id%type)
  is
    l_curproj db_growth_projects%rowtype;
    l_params  db_growth_parameters%rowtype;
    l_msg     db_growth_par_validation.message%type;
    l_next_date TIMESTAMP WITH TIME ZONE;
    l_users     DBMS_UTILITY.uncl_array;
    l_tbln      BINARY_INTEGER;
    l_res       varchar2(100);
    l_chk   boolean := false;
  begin
    l_curproj:=DB_GROWTH_PROJ_API.getproject(p_proj_id, true);
    delete from db_growth_par_validation where proj_id=p_proj_id;
    update db_growth_parameters set last_validated = null where proj_id=p_proj_id;

    select * into l_params from db_growth_parameters where proj_id=p_proj_id;

    begin
      l_msg := 'Schedule validation';
      DBMS_SCHEDULER.EVALUATE_CALENDAR_STRING(
        calendar_string    => l_params.schedule,
        start_date         => l_params.start_date,
        return_date_after  => null,
        next_run_date      => l_next_date);
      if l_next_date is not null then
        insert into db_growth_par_validation (proj_id,status,message) values (p_proj_id,'OK',l_msg||': '||to_char(l_next_date,'YYYY-MON-DD HH24:MI:SS.ff3 TZH:TZM'));
      else
        insert into db_growth_par_validation (proj_id,status,message) values (p_proj_id,'ERROR',l_msg||': unable to calculate nect date');
      end if;
    exception
      when others then
        l_chk := true;
        l_msg := substr(l_msg||': '||sqlerrm,1,4000);
        insert into db_growth_par_validation (proj_id,status,message) values (p_proj_id,'ERROR',l_msg);
    end;

    begin
      l_msg := 'DB Link validation';
      COREMOD_API.test_dblink (  P_DB_LINK_NAME => l_params.src_dblink) ;
      insert into db_growth_par_validation (proj_id,status,message) values (p_proj_id,'OK',l_msg);
    exception
      when others then
        l_msg := substr(l_msg||': '||sqlerrm,1,4000);
        insert into db_growth_par_validation (proj_id,status,message) values (p_proj_id,'ERROR',l_msg);
        return;
    end;

    begin
      l_msg := 'Scheme list parsing';
      DBMS_UTILITY.COMMA_TO_TABLE (
        list   => l_params.scheme_list,
        tablen => l_tbln,
        tab    => l_users);
      insert into db_growth_par_validation (proj_id,status,message) values (p_proj_id,'OK',l_msg);
    exception
      when others then
        l_msg := substr(l_msg||': '||sqlerrm,1,4000);
        insert into db_growth_par_validation (proj_id,status,message) values (p_proj_id,'ERROR',l_msg);
        return;
    end;

    for i in 1..l_tbln loop
      begin
        if instr(l_users(i),'"')=0 then l_users(i):=upper(l_users(i)); end if;
        l_msg := 'Scheme existence cheking: '||l_users(i);
        execute immediate 'select 1 from all_users@'||COREMOD_API.get_ora_dblink ( l_params.src_dblink)|| q'[ where username=']'||l_users(i)|| q'[']' into l_res;
        insert into db_growth_par_validation (proj_id,status,message) values (p_proj_id,'OK',l_msg);
      exception
        when others then
          l_chk := true;
          l_msg := substr(l_msg||' '||sqlerrm,1,4000);
          insert into db_growth_par_validation (proj_id,status,message) values (p_proj_id,'ERROR',l_msg);
      end;
    end loop;

    if l_chk then return; end if;

    update db_growth_parameters set last_validated = systimestamp where proj_id=p_proj_id;
  end;

END DB_GROWTH_API;
/
