create or replace package body awrwh_remote as

  procedure drop_snapshot_range(low_snap_id number, high_snap_id number, dbid number)
  is
  begin
    dbms_workload_repository.drop_snapshot_range(low_snap_id => low_snap_id, high_snap_id => high_snap_id, dbid => dbid);    
  end;

  procedure awr_load(p_stg_user varchar2, p_stg_tablespace varchar2, p_stg_temp varchar2, p_dir varchar2, p_dmpfile varchar2)
  is
    l_dbid number;
    l_min_snap_id number;
    l_max_snap_id number;
    l_min_snap_dt timestamp(3);
    l_max_snap_dt timestamp(3);
    l_db_description awrwh_dumps.db_description%type;
  begin
    awrwh_remote.awr_load_i(p_stg_user => p_stg_user,
        p_stg_tablespace => p_stg_tablespace,
        p_stg_temp => p_stg_temp,
        p_dir => p_dir,
        p_dmpfile => p_dmpfile,
        p_dbid=>l_dbid,
        p_min_snap_id=>l_min_snap_id,
        p_max_snap_id=>l_max_snap_id,
        p_min_snap_dt=>l_min_snap_dt,
        p_max_snap_dt=>l_max_snap_dt,
        p_db_description=>l_db_description);
    insert into awrwh_dumps values(l_dbid,l_min_snap_id,l_max_snap_id,l_min_snap_dt,l_max_snap_dt,l_db_description);
    commit;
  end;

  procedure awr_load_i(p_stg_user varchar2,
                       p_stg_tablespace varchar2,
                       p_stg_temp varchar2,
                       p_dir varchar2,
                       p_dmpfile varchar2,
                       p_dbid out number,
                       p_min_snap_id out number,
                       p_max_snap_id out number,
                       p_min_snap_dt out timestamp,
                       p_max_snap_dt out timestamp,
                       p_db_description out varchar2)
  is
    --awr staging
    l_user number;
    l_cnt number;
  begin
    select count(1) into l_user from dba_users where username=upper(p_stg_user);
    if l_user=1 then execute immediate 'drop user '||p_stg_user||' cascade'; end if;

    execute immediate
        'create user '||p_stg_user||'
          identified by '||p_stg_user||'
          default tablespace '||p_stg_tablespace||'
          temporary tablespace '||p_stg_temp;

    execute immediate 'alter user '||p_stg_user||' quota unlimited on '||p_stg_tablespace;
    /* call PL/SQL routine to load the data into the staging schema */
    sys.dbms_swrf_internal.awr_load(schname  => upper(p_stg_user),
                                    dmpfile  => p_dmpfile,
                                    dmpdir   => p_dir);

    execute immediate 'SELECT
        min(snap_id),max(snap_id),
        min(end_interval_time),max(end_interval_time),
        min(dbid)
        FROM '||p_stg_user||'.wrm$_snapshot'
        into
        p_min_snap_id,p_max_snap_id,
        p_min_snap_dt,p_max_snap_dt,p_dbid;

    --check already loaded snapshots
    with rng as (select p_min_snap_id+level-1 snaps from dual connect by level <=p_max_snap_id-p_min_snap_id+1)
      select count(1) into l_cnt from DBA_HIST_SNAPSHOT where dbid=p_dbid and snap_id in (select snaps from rng);

    if l_cnt=0 then

      execute immediate q'[   
        select unique db_name|| ', ' || version || ', ' || platform_name || ', ' || listagg(instance_name||':'||host_name,',') within group (order by host_name) from
        (select unique db_name,version,platform_name,host_name,instance_name
          from ]'||p_stg_user||q'[.WRM$_DATABASE_INSTANCE i,
               ]'||p_stg_user||q'[.wrm$_snapshot sn
         where i.dbid = sn.dbid  and i.instance_number=sn.instance_number)
         group by db_name,version,platform_name]'
         into p_db_description; 

      sys.dbms_swrf_internal.move_to_awr(schname => upper(p_stg_user));
      sys.dbms_swrf_internal.clear_awr_dbid;

    end if;

    execute immediate 'drop user '||p_stg_user||' cascade';

    if l_cnt>0 then
      raise_application_error(-20000,'Some snapshots are already loaded remotely for DBID: '||p_dbid||' and snapshot range: '||p_min_snap_id||'-'||p_max_snap_id);
    end if;
  end;
end;
/