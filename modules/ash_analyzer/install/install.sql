define MODNM=ASH_ANALYZER
define MODVER="3.4.1"
--Core installation script
conn sys/&localsys.@&localdb. as sysdba

@@scheme_setup.sql

conn &localscheme./&localscheme.@&localdb.

@../modules/ash_analyzer/struct/create_struct.sql

@../modules/ash_analyzer/source/create_stored.sql

exec COREMOD.register(p_modname => '&MODNM.', p_moddescr => 'ASH Analyzer module', p_modver => '&MODVER.', p_installed => sysdate);

@../modules/ash_analyzer/data/load.sql

begin
  COREMOD_TASKS.create_task (  p_taskname  => 'ASHA_CALC_CUBE',
                               p_modname   => '&MODNM.',
                               p_is_public => 'Y', 
                               p_task_body => 'begin ASHA_CUBE_PKG.load_cube_inqueue (p_sess_id => <B1>) ; end;');
end;
/

begin
  COREMOD_TASKS.create_task (  p_taskname  => 'ASHA_SNAP_ASH',
                               p_modname   => '&MODNM.',
                               p_is_public => 'Y', 
                               p_task_body => 'begin ASHA_CUBE_PKG.snap_ash (p_dblink => <B1>, p_sess_id => <B2>) ; end;');
end;
/


begin
  COREMOD_TASKS.create_task (  p_taskname  => 'ASHA_MONITOR',
                               p_modname   => '&MODNM.',
                               p_is_public => 'Y', 
                               p_task_body => 'begin ASHA_CUBE_PKG.load_cube_mon(p_sess_id=><B1>); end;');
end;
/

begin
    dbms_scheduler.create_program(
                              program_name             => 'OPAS_ASHA_DIC_PRG',
                              program_type             => 'PLSQL_BLOCK',
                              program_action           => 'begin ASHA_CUBE_API.refresh_dictionaries; end;',
                              enabled                  => true,
                              comments                 => 'OPAS ASH Analyzer dictionary refresh job program');
    dbms_scheduler.create_job(job_name                 => 'OPAS_ASHA_DIC',
                              program_name             => 'OPAS_ASHA_DIC_PRG',
                              start_date               => trunc(systimestamp,'mi'),
                              repeat_interval          => 'FREQ=SECONDLY; INTERVAL=60',
                              job_style                => 'LIGHTWEIGHT',
                              job_class                => 'OPASLIGHTJOBS',
                              enabled                  => true);
end;
/

begin
  coremod_cleanup.register_cleanup_tasks (  P_TASKNAME => 'CLEANUP_ASH_ANALYZER',
                                            P_MODNAME => '&MODNM.',
                                            p_task_body => 'begin ASHA_PROJ_API.cleanup_projects; end;');
end;
/
commit;