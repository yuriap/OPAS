CREATE OR REPLACE
PACKAGE TRC_FILE_API AS

  gMODNAME       constant varchar2(32) := 'SQL_TRACE';

  function getMODNAME return varchar2;


  procedure register_trace_file(p_proj_id         trc_files.proj_id%type,
                                p_owner           trc_files.owner%type,
                                p_filename        trc_files.filename%type,
                                p_file_source     trc_files.file_source%type,
                                p_store_file      boolean,
                                p_trc_file_id out trc_files.trc_file_id%type);

  procedure store_file(p_trc_file_id trc_files.trc_file_id%type, p_file blob default null);

  procedure compress_file(p_trc_file_id trc_files.trc_file_id%type);
  procedure archive_file(p_trc_file_id trc_files.trc_file_id%type);
  procedure drop_file(p_trc_file_id trc_files.trc_file_id%type);

  procedure cleanup_files(p_proj_id trc_projects.proj_id%type, p_mode number, p_use_retention boolean);

  procedure set_note(p_trc_file_id  trc_files.trc_file_id%type,
                     p_note         trc_files.file_note%type);

  function get_file(p_trc_file_id trc_files.trc_file_id%type, p_lock boolean default false) return trc_files%rowtype;

  procedure set_file_security
                        (p_trc_file_id         trc_files.trc_file_id%type,
                         p_owner               trc_files.owner%type default null,
                         p_source_retention    trc_files.source_retention%type,
                         p_parsed_retention    trc_files.parsed_retention%type);

  procedure delete_file (P_TRC_FILE_ID trc_files.trc_file_id%type,
                         P_KEEP_SOURCE boolean,
                         P_KEEP_PARSED boolean,
                         P_KEEP_REPORT boolean);

  procedure parse_file_async(p_trc_file_id trc_files.trc_file_id%type, p_tq_id out opas_task_queue.tq_id%type);
  procedure parse_file(p_trc_file_id trc_files.trc_file_id%type);

  -- for debug only
  procedure recreate_report(p_trc_file_id trc_files.trc_file_id%type);

END TRC_FILE_API;
/
