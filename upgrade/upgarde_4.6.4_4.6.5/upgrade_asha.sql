-------------------------------------------------------------------------------------------------------------
--ASH Analyzer
-------------------------------------------------------------------------------------------------------------

define MODNM=ASH_ANALYZER
@../../modules/ash_analyzer/install/version.sql

INSERT INTO opas_config (modname,cgroup,ckey,cvalue,descr) VALUES ('&MODNM.','RETENTION','EXPIMPSESS',           1,'Retention time in days for ASHA export/import sessions.');

INSERT INTO opas_expimp_compat ( modname, src_version, trg_version) VALUES ( '&MODNM.',  '&MODVER.',  '&MODVER.');

commit;

set define off

@../../modules/ash_analyzer/source/ASHA_EXPIMP_SPEC.SQL
@../../modules/ash_analyzer/source/ASHA_EXPIMP_BODY.SQL
@../../modules/ash_analyzer/source/ASHA_CUBE_API_SPEC.SQL
@../../modules/ash_analyzer/source/ASHA_CUBE_API_BODY.SQL
@../../modules/ash_analyzer/source/ASHA_CUBE_PKG_BODY.SQL
@../../modules/ash_analyzer/source/ASHA_PROJ_API_BODY.SQL

set define on

begin
  COREMOD_TASKS.create_task (  p_taskname  => 'ASHA_EXP_PROJ',
                               p_modname   => '&MODNM.',
                               p_is_public => 'Y', 
                               p_task_body => 'begin ASHA_EXPIMP.export_proj (p_proj_ids => coremod_tasks.t_ids(<B1>), p_exp_sess_id => <B2>) ; end;');
end;
/

begin
  COREMOD_TASKS.create_task (  p_taskname  => 'ASHA_EXP_CUBE',
                               p_modname   => '&MODNM.',
                               p_is_public => 'Y', 
                               p_task_body => 'begin ASHA_EXPIMP.export_cube (p_sess_ids => coremod_tasks.t_ids(<B1>), p_exp_sess_id => <B2>) ; end;');
end;
/

begin
  COREMOD_TASKS.create_task (  p_taskname  => 'ASHA_IMP_PROCESSING',
                               p_modname   => '&MODNM.',
                               p_is_public => 'Y', 
                               p_task_body => 'begin ASHA_EXPIMP.import_processing (p_exp_sess_id => <B1>, p_proj_id => <B2>) ; end;');
end;
/

exec COREMOD.register(p_modname => '&MODNM.', p_modver => '&MODVER.', p_installed => sysdate);

commit;

begin
  ASHA_EXPIMP.init();
end;
/