CREATE OR REPLACE
PACKAGE AWRWH_FILE_API AS

  function get_file(p_dump_id awrwh_dumps.dump_id%type, p_lock boolean default false) return awrwh_dumps%rowtype;
  procedure store_file(p_dump_id awrwh_dumps.dump_id%type, p_file blob default null);

  procedure register_dump_file (p_proj_id         awrwh_dumps.proj_id%type,
                                p_owner           awrwh_dumps.owner%type,
                                p_filename        awrwh_dumps.filename%type,
                                p_dump_name       awrwh_dumps.dump_name%type,
                                p_description     awrwh_dumps.dump_description%type,
                                p_dump_id     out awrwh_dumps.dump_id%type);
  procedure set_file_security
                        (p_dump_id             awrwh_dumps.dump_id%type,
                         p_owner               awrwh_dumps.owner%type default null,
                         p_source_retention    awrwh_dumps.source_retention%type,
                         p_parsed_retention    awrwh_dumps.parsed_retention%type);

  procedure set_note(p_dump_id  awrwh_dumps.dump_id%type,
                     p_description     awrwh_dumps.dump_description%type);

  procedure set_awr_dest(p_dump_id  awrwh_dumps.dump_id%type,
                         p_remote_dest varchar2);

  /*
    AWRWH_FILE_LCC.c_dmpfile_awrload,
    AWRWH_FILE_LCC.c_dmpfile_awrunload,
    AWRWH_FILE_LCC.c_dmpfile_compress,
    AWRWH_FILE_LCC.c_dmpfile_archive,
    AWRWH_FILE_LCC.c_dmpfile_dropfile
  */
  procedure exec_file_action_async(p_dump_id awrwh_dumps.dump_id%type, p_action varchar2, p_tq_id out opas_task_queue.tq_id%type);
  procedure exec_file_action      (p_dump_id awrwh_dumps.dump_id%type, p_action varchar2);

  /*import dump utility*/
  procedure load_dump_from_file(p_proj_id          awrwh_dumps.proj_id%type,
                                p_filename         awrwh_dumps.filename%type,
                                p_dump_description awrwh_dumps.dump_description%type,
                                p_loaded           awrwh_dumps.loaded%type default null,
                                p_dbid             awrwh_dumps.dbid%type default null,
                                p_min_snap_id      awrwh_dumps.min_snap_id%type default null,
                                p_max_snap_id      awrwh_dumps.max_snap_id%type default null,
                                p_min_snap_dt      awrwh_dumps.min_snap_dt%type default null,
                                p_max_snap_dt      awrwh_dumps.max_snap_dt%type default null,
                                p_db_description   awrwh_dumps.db_description%type default null,
                                p_dump_name        awrwh_dumps.dump_name%type default null);

END AWRWH_FILE_API;
/
