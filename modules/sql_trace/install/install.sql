define MODNM=SQL_TRACE
@@version.sql
--Extended SQL Trace installation script
conn sys/&localsys.@&localdb. as sysdba

@@scheme_setup.sql

conn &localscheme./&localscheme.@&localdb.

@@uninstall

@../modules/sql_trace/struct/create_struct.sql

@../modules/sql_trace/source/create_stored.sql

exec COREMOD.register(p_modname => '&MODNM.', p_moddescr => 'Extended SQL Trace Module', p_modver => '&MODVER.', p_installed => sysdate);

@../modules/sql_trace/data/load.sql

begin
  COREMOD_TASKS.create_task (  p_taskname  => 'TRC_PARSEFILE',
                               p_modname   => '&MODNM.',
                               p_is_public => 'Y', 
                               p_task_body => 'begin TRC_FILE_API.parse_file (P_TRC_FILE_ID => <B1>) ; end;');
end;
/

begin
  coremod_cleanup.register_cleanup_tasks (  P_TASKNAME => 'CLEANUP_SQL_TRACE',
                                            P_MODNAME => '&MODNM.',
                                            p_task_body => 'begin TRC_PROJ_API.cleanup_projects; end;');
end;
/
commit;

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
                               p_task_body => 'begin TRC_EXPIMP.export_trace (p_trc_ids => coremod_tasks.t_ids(<B1>), p_exp_sess_id => <B2>) ; end;');
end;
/

begin
  COREMOD_TASKS.create_task (  p_taskname  => 'TRC_IMP_PROCESSING',
                               p_modname   => '&MODNM.',
                               p_is_public => 'Y', 
                               p_task_body => 'begin TRC_EXPIMP.import_processing (p_exp_sess_id => <B1>, p_proj_id => <B2>) ; end;');
end;
/

begin
  TRC_EXPIMP.init();
end;
/