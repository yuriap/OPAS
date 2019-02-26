CREATE OR REPLACE
PACKAGE COREMOD_EXPIMP AS

  type t_object_names is table of varchar2(128);
  type t_id_mapping   is table of number index by pls_integer;

  gTabPref     constant varchar2(10):='EI$';
  gTableList   constant t_object_names := t_object_names('OPAS_REPORTS','OPAS_REPORTS_PARS','OPAS_FILES','OPAS_EXPIMP_METADATA','OPAS_QRY_CACHE');

  gstNEW       constant varchar2(32) := 'NEW';
  gstINQUEUE   constant varchar2(32) := 'INQUEUE';
  gstEXECUTING constant varchar2(32) := 'EXECUTING';
  gstFINISHED  constant varchar2(32) := 'FINISHED';
  gstFAILED    constant varchar2(32) := 'FAILED';
  gstNEXTSTAGE constant varchar2(32) := 'NEXTSTAGE';

  procedure init;
  procedure init(p_prefix varchar2, p_table_lst t_object_names);
  procedure create_ei_table(p_table varchar2, p_prefix varchar2);
  procedure drop_ei_table  (p_table varchar2, p_prefix varchar2);

  -- called from UI
  -- create exp/imp session descriptor
  procedure create_exp_session(p_owner        opas_expimp_sessions.owner%type,
                               p_modname      opas_expimp_metadata.modname%type,
                               p_import_prc   opas_expimp_metadata.import_prc%type,
                               p_file_descr   opas_expimp_metadata.file_descr%type,
                               p_sess_id  out opas_expimp_sessions.sess_id%type);

  procedure create_imp_session(p_owner        opas_expimp_sessions.owner%type,
                               p_expimp_file  opas_expimp_sessions.expimp_file%type,
                               p_sess_id  out opas_expimp_sessions.sess_id%type);

  procedure queue_import_file(p_expimp_file opas_expimp_sessions.expimp_file%type,
                              p_tq_id   out opas_task_queue.tq_id%type,
                              p_exp_sess_id out opas_expimp_sessions.sess_id%type);

  procedure queue_execution_session(p_exp_sess_id opas_expimp_sessions.sess_id%type,
                                    p_tq_id       opas_expimp_sessions.tq_id%type);
  procedure discard_staged_session(p_exp_sess_id opas_expimp_sessions.sess_id%type);

  --called from task
  --step 1 of execution exp/imp session
  procedure start_execution_session(p_exp_sess_id opas_expimp_sessions.sess_id%type);
  procedure continue_execution_session(p_exp_sess_id opas_expimp_sessions.sess_id%type);
  procedure execute_export_session(p_exp_sess_id opas_expimp_sessions.sess_id%type);
  procedure finish_export_session(p_exp_sess_id opas_expimp_sessions.sess_id%type, p_status varchar2);

  procedure import_file       (p_exp_sess_id opas_expimp_sessions.sess_id%type);
  procedure execute_import_session(p_exp_sess_id opas_expimp_sessions.sess_id%type);
  procedure finish_import_file_session(p_exp_sess_id opas_expimp_sessions.sess_id%type, p_status varchar2);
  procedure finish_import_session(p_exp_sess_id opas_expimp_sessions.sess_id%type, p_status varchar2);

  --cleanup
  procedure cleanup_expimp_sess(p_modname        opas_expimp_metadata.modname%type,
                                p_retention_days number);
  procedure cleanup_expimp_session(p_exp_sess_id opas_expimp_sessions.sess_id%type,
                                   p_inlcuding_metadata boolean default true);
END COREMOD_EXPIMP;
/
