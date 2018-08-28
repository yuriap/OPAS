define MODNM=OPASCORE
define MODVER="1.1.0"
--Core installation script
conn sys/&localsys.@&localdb. as sysdba

@@scheme_setup.sql

conn &localscheme./&localscheme.@&localdb.

@..\modules\core\struct\create_struct.sql

@..\modules\core\source\create_stored.sql

exec COREMOD.register(p_modname => 'OPASAPP', p_moddescr => 'Oracle Performance Analytic Suite Application', p_modver => '&OPASVER.', p_installed => sysdate);
exec COREMOD.register(p_modname => '&MODNM.', p_moddescr => 'Oracle Performance Analytic Suite Core Module', p_modver => '&MODVER.', p_installed => sysdate);

@..\modules\core\data\load.sql

exec coremod_tasks.create_task_job;
exec coremod_cleanup.create_cleanup_job;


begin
  coremod_cleanup.register_cleanup_tasks (  P_TASKNAME => 'CLEANUPLOGS',
                                            P_MODNAME => '&MODNM.',
                                            p_task_body => 'begin COREMOD_LOG.cleanup_logs; end;');
  coremod_cleanup.register_cleanup_tasks (  P_TASKNAME => 'CLEANUPTASKSDATA',
                                            P_MODNAME => '&MODNM.',
                                            p_task_body => 'begin coremod_tasks.cleanup_tasks; end;');
  coremod_cleanup.register_cleanup_tasks (  P_TASKNAME => 'CLEANUPPROJSDATA',
                                            P_MODNAME => '&MODNM.',
                                            p_task_body => 'begin COREPROJ_API.cleanup_projects; end;');
end;
/