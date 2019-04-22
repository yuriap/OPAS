-------------------------------------------------------------------------------------------------------------
--AWR Warehouse
-------------------------------------------------------------------------------------------------------------

define MODNM=AWR_WAREHOUSE
@../../modules/awr_warehouse/install/version.sql

INSERT INTO opas_config (modname,cgroup,ckey,cvalue,descr) VALUES ('&MODNM.','RETENTION','EXPIMPSESS',           0.03,'Retention time in days for AWRWH export/import sessions.');
INSERT INTO opas_expimp_compat ( modname, src_version, trg_version) VALUES ( '&MODNM.',  '&MODVER.',  '&MODVER.');

set define off

@../../modules/awr_warehouse/source/AWRWH_EXPIMP_SPEC.SQL
@../../modules/awr_warehouse/source/AWRWH_EXPIMP_BODY.SQL
@../../modules/awr_warehouse/source/AWRWH_PROJ_API_BODY.SQL
@../../modules/awr_warehouse/source/AWRWH_REPORT_API_BODY.SQL

set define on


begin
  COREMOD_TASKS.create_task (  p_taskname  => 'AWRWH_EXP_PROJ',
                               p_modname   => '&MODNM.',
                               p_is_public => 'Y', 
                               p_task_body => 'begin AWRWH_EXPIMP.export_proj (p_proj_ids => coremod_tasks.t_ids(<B1>), p_exp_sess_id => <B2>) ; end;');
end;
/

begin
  COREMOD_TASKS.create_task (  p_taskname  => 'AWRWH_EXP_DUMP',
                               p_modname   => '&MODNM.',
                               p_is_public => 'Y', 
                               p_task_body => 'begin AWRWH_EXPIMP.export_dump (p_dump_ids => coremod_tasks.t_ids(<B1>), p_exp_sess_id => <B2>) ; end;');
end;
/

begin
  COREMOD_TASKS.create_task (  p_taskname  => 'AWRWH_IMP_PROCESSING',
                               p_modname   => '&MODNM.',
                               p_is_public => 'Y', 
                               p_task_body => 'begin AWRWH_EXPIMP.import_processing (p_exp_sess_id => <B1>, p_proj_id => <B2>) ; end;');
end;
/



exec COREMOD.register(p_modname => '&MODNM.', p_modver => '&MODVER.', p_installed => sysdate);

commit;

begin
  AWRWH_EXPIMP.init();
end;
/