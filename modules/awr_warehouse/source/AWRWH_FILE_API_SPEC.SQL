CREATE OR REPLACE
PACKAGE AWRWH_FILE_API AS

  procedure register_dump_file (p_proj_id         awrwh_dumps.proj_id%type,
                                p_owner           awrwh_dumps.owner%type,
                                p_filename        awrwh_dumps.filename%type,
                                p_store_file      boolean,
                                p_dump_id     out awrwh_dumps.dump_id%type);

  procedure store_file(p_dump_id awrwh_dumps.dump_id%type, p_file blob default null);

  procedure compress_file(p_dump_id awrwh_dumps.dump_id%type);
  procedure archive_file (p_dump_id awrwh_dumps.dump_id%type);
  procedure drop_file    (p_dump_id awrwh_dumps.dump_id%type);

  procedure cleanup_files(p_proj_id awrwh_projects.proj_id%type, p_mode number, p_use_retention boolean);

  --procedure set_note(p_dump_id  awrwh_dumps.dump_id%type,
  --                   p_note     awrwh_dumps.file_note%type);

  function get_file(p_dump_id awrwh_dumps.dump_id%type, p_lock boolean default false) return awrwh_dumps%rowtype;

  procedure set_file_security
                        (p_dump_id             awrwh_dumps.dump_id%type,
                         p_owner               awrwh_dumps.owner%type default null,
                         p_source_keep_forever awrwh_dumps.source_keep_forever%type,
                         p_parsed_keep_forever awrwh_dumps.parsed_keep_forever%type);

  procedure delete_file (p_dump_id awrwh_dumps.dump_id%type,
                         P_KEEP_SOURCE boolean,
                         P_KEEP_PARSED boolean,
                         P_KEEP_REPORT boolean);

  procedure parse_file_async(p_dump_id awrwh_dumps.dump_id%type, p_tq_id out opas_task_queue.tq_id%type);
  procedure parse_file(p_dump_id awrwh_dumps.dump_id%type);

  /*import dump utility*/
  procedure load_dump_from_file(p_proj_id          awrwh_dumps.proj_id%type,
                                p_filename         awrwh_dumps.filename%type,
                                p_dump_description awrwh_dumps.dump_description%type,
                                p_loading_date     awrwh_dumps.loading_date%type default null,
                                p_dbid             awrwh_dumps.dbid%type default null,
                                p_min_snap_id      awrwh_dumps.min_snap_id%type default null,
                                p_max_snap_id      awrwh_dumps.max_snap_id%type default null,
                                p_min_snap_dt      awrwh_dumps.min_snap_dt%type default null,
                                p_max_snap_dt      awrwh_dumps.max_snap_dt%type default null,
                                p_db_description   awrwh_dumps.db_description%type default null,
                                p_dump_name        awrwh_dumps.dump_name%type default null);

END AWRWH_FILE_API;
/
