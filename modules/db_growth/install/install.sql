--DB Growth Tracker installation script

define MODNM=DB_GROWTH
@@version.sql

--Scheme setup script
conn sys/&localsys.@&localdb. as sysdba

@@scheme_setup.sql

conn &localscheme./&localscheme.@&localdb.

@../modules/db_growth/struct/create_struct.sql

@../modules/db_growth/source/create_stored.sql


exec COREMOD.register(p_modname => '&MODNM.', p_moddescr => 'DB Growth Tracker module', p_modver => '&MODVER.', p_installed => sysdate);

@../modules/db_growth/data/load.sql

begin
  coremod_cleanup.register_cleanup_tasks (  P_TASKNAME => 'CLEANUP_DB_GROWTH',
                                            P_MODNAME => '&MODNM.',
                                            p_task_body => 'begin DB_GROWTH_PROJ_API.cleanup_projects; end;');
end;
/


begin
  COREMOD_TASKS.create_task (  p_taskname  => 'DB_GROWTH_EXP_PROJ',
                               p_modname   => '&MODNM.',
                               p_is_public => 'Y', 
                               p_task_body => 'begin DB_GROWTH_EXPIMP.export_proj (p_proj_ids => coremod_tasks.t_ids(<B1>), p_exp_sess_id => <B2>) ; end;');
end;
/

begin
  COREMOD_TASKS.create_task (  p_taskname  => 'DB_GROWTH_IMP_PROCESSING',
                               p_modname   => '&MODNM.',
                               p_is_public => 'Y', 
                               p_task_body => 'begin DB_GROWTH_EXPIMP.import_processing (p_exp_sess_id => <B1>, p_proj_id => <B2>) ; end;');
end;
/

commit;

begin
  DB_GROWTH_EXPIMP.init();
end;
/