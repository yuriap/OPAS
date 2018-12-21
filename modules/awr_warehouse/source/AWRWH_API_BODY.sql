CREATE OR REPLACE
PACKAGE BODY AWRWH_API AS

  function  getMODNAME return varchar2 is begin return gMODNAME; end;

  procedure put_file_to_fs(p_blob blob, p_filename varchar2, p_dir varchar2)
  is
    l_file      UTL_FILE.FILE_TYPE;
    l_buffer    RAW(32767);
    l_amount    BINARY_INTEGER := 32767;
    l_pos       INTEGER := 1;
    l_blob_len  INTEGER;
  BEGIN
    coremod_log.log('AWRWH_API.put_file_to_fs: '||p_filename||';'||p_dir,'DEBUG');
    l_blob_len := DBMS_LOB.getlength(p_blob);

    -- Open the destination file.
    l_file := UTL_FILE.fopen(p_dir,p_filename,'wb', 32767);

    -- Read chunks of the BLOB and write them to the file
    -- until complete.
    WHILE l_pos < l_blob_len LOOP
      DBMS_LOB.read(p_blob, l_amount, l_pos, l_buffer);
      UTL_FILE.put_raw(l_file, l_buffer, TRUE);
      l_pos := l_pos + l_amount;
    END LOOP;

    -- Close the file.
    UTL_FILE.fclose(l_file);

  EXCEPTION
    WHEN OTHERS THEN
      -- Close the file if something goes wrong.
      IF UTL_FILE.is_open(l_file) THEN
        UTL_FILE.fclose(l_file);
      END IF;
      RAISE;
  END;

  procedure remove_file_from_fs(p_filename varchar2,
                                p_dir varchar2)
  is
  begin
    coremod_log.log('AWRWH_API.remove_file_from_fs: '||p_filename||';'||p_dir,'DEBUG');
    UTL_FILE.FREMOVE (
     location => p_dir,
     filename => p_filename);
  end;

  procedure remote_awr_load(p_stg_user varchar2,
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
  begin
    coremod_log.log('AWRWH_API.remote_awr_load','DEBUG');
    delete from awrwh_dumps_rem;
    commit;
    awrwh_remote.awr_load (
        P_STG_USER => P_STG_USER,
        P_STG_TABLESPACE => P_STG_TABLESPACE,
        P_STG_TEMP => P_STG_TEMP,
        P_DIR => P_DIR,
        P_DMPFILE => P_DMPFILE) ;
    select
        DBID,MIN_SNAP_ID,MAX_SNAP_ID,MIN_SNAP_DT,MAX_SNAP_DT,DB_DESCRIPTION
        into p_dbid,p_min_snap_id,p_max_snap_id,p_min_snap_dt,p_max_snap_dt,p_db_description
      from awrwh_dumps_rem;
    delete from awrwh_dumps_rem;
    coremod_log.log('AWRWH_API.remote_awr_load finished','DEBUG');
  end;

  procedure local_awr_load(p_stg_user varchar2,
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
    coremod_log.log('AWRWH_API.local_awr_load','DEBUG');
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
        select unique version || ', ' || host_name || ', ' || platform_name
          from ]'||p_stg_user||q'[.WRM$_DATABASE_INSTANCE i,
               ]'||p_stg_user||q'[.wrm$_snapshot sn
         where i.dbid = sn.dbid]'
         into p_db_description;

      sys.dbms_swrf_internal.move_to_awr(schname => upper(p_stg_user));
      sys.dbms_swrf_internal.clear_awr_dbid;

    end if;

    execute immediate 'drop user '||p_stg_user||' cascade';

    if l_cnt>0 then
      raise_application_error(-20000,'Some snapshots are already loaded for DBID: '||p_dbid||' and snapshot range: '||p_min_snap_id||'-'||p_max_snap_id);
    end if;
    coremod_log.log('AWRWH_API.local_awr_load finished','DEBUG');
  end;

  procedure unload_awr_ranges(p_is_remote varchar2,
                              p_snap_min number,
                              p_snap_max number,
                              p_dbid number)
  is
  begin
    coremod_log.log('AWRWH_API.unload_awr_ranges: '||p_is_remote||':'||p_snap_min||':'||p_snap_max||':'||p_dbid,'DEBUG');
    if p_is_remote='YES' then
      coremod_log.log('AWRWH_API.unload_awr_ranges REMOTE','DEBUG');
      awrwh_remote.drop_snapshot_range(low_snap_id => p_snap_min, high_snap_id => p_snap_max, dbid => p_dbid);
    else
      coremod_log.log('AWRWH_API.unload_awr_ranges LOCAL','DEBUG');
      dbms_workload_repository.drop_snapshot_range(low_snap_id => p_snap_min,high_snap_id => p_snap_max,dbid => p_dbid);
    end if;
    coremod_log.log('AWRWH_API.unload_awr_ranges finished','DEBUG');
  end;

END AWRWH_API;
/
