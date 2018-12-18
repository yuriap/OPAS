CREATE OR REPLACE
PACKAGE AWRWH_API AS

  gMODNAME       constant varchar2(32) := 'AWR_WAREHOUSE';

  gDUMPFILETYPE  constant varchar2(32) := 'AWR Dump';

  function  getMODNAME return varchar2;

  procedure put_file_to_fs      (p_blob blob,
                                 p_filename varchar2,
                                 p_dir varchar2);

  procedure remove_file_from_fs (p_filename varchar2,
                                 p_dir varchar2);

  procedure local_awr_load      (p_stg_user varchar2,
                                 p_stg_tablespace varchar2,
                                 p_stg_temp varchar2,
                                 p_dir varchar2,
                                 p_dmpfile varchar2,
                                 p_dbid out number,
                                 p_min_snap_id out number,
                                 p_max_snap_id out number,
                                 p_min_snap_dt out timestamp,
                                 p_max_snap_dt out timestamp,
                                 p_db_description out varchar2);

  procedure remote_awr_load     (p_stg_user varchar2,
                                 p_stg_tablespace varchar2,
                                 p_stg_temp varchar2,
                                 p_dir varchar2,
                                 p_dmpfile varchar2,
                                 p_dbid out number,
                                 p_min_snap_id out number,
                                 p_max_snap_id out number,
                                 p_min_snap_dt out timestamp,
                                 p_max_snap_dt out timestamp,
                                 p_db_description out varchar2);

  procedure unload_awr_ranges_for_dump
                                (p_is_remote varchar2,
                                 p_snap_min number,
                                 p_snap_max number,
                                 p_dbid number);

END AWRWH_API;
/
