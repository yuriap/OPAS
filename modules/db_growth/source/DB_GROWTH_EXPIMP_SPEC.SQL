CREATE OR REPLACE
PACKAGE DB_GROWTH_EXPIMP AS

  procedure init;

  --UI calls
  procedure queue_export_proj (p_proj_ids    coremod_tasks.t_ids,
                               p_descr       opas_expimp_metadata.file_descr%type,
                               p_tq_id       out opas_task_queue.tq_id%type,
                               p_exp_sess_id out opas_expimp_sessions.sess_id%type);
--============================================================================================
  procedure queue_import_processing ( p_exp_sess_id      opas_expimp_sessions.sess_id%type,
                                      p_tq_id            out opas_task_queue.tq_id%type);
--============================================================================================
  --tasks
  procedure export_proj (p_proj_ids    coremod_tasks.t_ids,     p_exp_sess_id opas_expimp_sessions.sess_id%type);

  procedure import_processing (p_exp_sess_id    opas_expimp_sessions.sess_id%type,
                               p_proj_id        db_growth_projects.proj_id%type);

END DB_GROWTH_EXPIMP;
/
