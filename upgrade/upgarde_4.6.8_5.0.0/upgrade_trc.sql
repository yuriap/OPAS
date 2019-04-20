-------------------------------------------------------------------------------------------------------------
--Extended SQL Trace
-------------------------------------------------------------------------------------------------------------

define MODNM=SQL_TRACE
@../../modules/sql_trace/install/version.sql

INSERT INTO opas_config (modname,cgroup,ckey,cvalue,descr) VALUES ('&MODNM.','RETENTION','EXPIMPSESS',           0.03,'Retention time in days for SQL Trace export/import sessions.');
INSERT INTO opas_expimp_compat ( modname, src_version, trg_version) VALUES ( '&MODNM.',  '&MODVER.',  '&MODVER.');

set define off

@../../modules/sql_trace/source/TRC_EXPIMP_SPEC.SQL
@../../modules/sql_trace/source/TRC_EXPIMP_BODY.SQL
@../../modules/sql_trace/source/TRC_FILE_API_BODY.SQL
@../../modules/sql_trace/source/TRC_FILE_LCC_SPEC.SQL
@../../modules/sql_trace/source/TRC_FILE_LCC_BODY.SQL
@../../modules/sql_trace/source/TRC_PROJ_API_BODY.SQL
@../../modules/sql_trace/source/TRC_PROJ_LCC_BODY.SQL

set define on

begin
  COREMOD_TASKS.create_task (  p_taskname  => 'TRC_EXP_PROJ',
                               p_modname   => '&MODNM.',
                               p_is_public => 'Y', 
                               p_task_body => 'begin TRC_EXPIMP.export_proj (p_proj_ids => coremod_tasks.t_ids(<B1>), p_exp_sess_id => <B2>) ; end;');
end;
/

begin
  COREMOD_TASKS.create_task (  p_taskname  => 'TRC_EXP_TRACE',
                               p_modname   => '&MODNM.',
                               p_is_public => 'Y', 
                               p_task_body => 'begin TRC_EXPIMP.export_trc (p_sess_ids => coremod_tasks.t_ids(<B1>), p_exp_sess_id => <B2>) ; end;');
end;
/

begin
  COREMOD_TASKS.create_task (  p_taskname  => 'TRC_IMP_PROCESSING',
                               p_modname   => '&MODNM.',
                               p_is_public => 'Y', 
                               p_task_body => 'begin TRC_EXPIMP.import_processing (p_exp_sess_id => <B1>, p_proj_id => <B2>) ; end;');
end;
/


exec COREMOD.register(p_modname => '&MODNM.', p_modver => '&MODVER.', p_installed => sysdate);

commit;

begin
  TRC_EXPIMP.init();
end;
/

