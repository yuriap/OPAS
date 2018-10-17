create or replace package awrwh_remote as

  procedure awr_load(p_stg_user varchar2, p_stg_tablespace varchar2, p_stg_temp varchar2, p_dir varchar2, p_dmpfile varchar2);
  
  procedure awr_load_i(p_stg_user varchar2, p_stg_tablespace varchar2, p_stg_temp varchar2, p_dir varchar2, p_dmpfile varchar2,
                       p_dbid out number,p_min_snap_id out number,p_max_snap_id out number,p_min_snap_dt out timestamp,p_max_snap_dt out timestamp,p_db_description out varchar2);
  procedure drop_snapshot_range(low_snap_id number, high_snap_id number, dbid number);
end;
/