define MODNM=OPASCORE
define MODVER="1.0.0"
--Core installation script
conn sys/&localsys.@&localdb. as sysdba

@@scheme_setup.sql

conn &localscheme./&localscheme.@&localdb.

@..\modules\core\struct\create_struct.sql

@..\modules\core\source\create_stored.sql

exec COREMOD.register(p_modname => 'OPASAPP', p_moddescr => 'Oracle Performance Analytic Suite Application', p_modver => '&OPASVER.', p_installed => sysdate);
exec COREMOD.register(p_modname => '&MODNM.', p_moddescr => 'Oracle Performance Analytic Suite Core Module', p_modver => '&MODVER.', p_installed => sysdate);

@..\modules\core\data\load.sql

exec coremod_purge.create_purge_job;


DECLARE
  L_TASKNAME VARCHAR2(128) := 'CLEANUPLOGS';
begin
  COREMOD_TASKS.create_task (  P_TASKNAME => L_TASKNAME,
                               P_MODNAME => '&MODNM.',
                               P_TASK_TYPE => COREMOD_TASKS.cttPURGE,
                               P_MAX_THREAD => 1,
                               P_ASYNC => 'N') ;  
  COREMOD_TASKS.set_task_body( P_TASKNAME => L_TASKNAME, p_task_body => 'begin COREMOD_LOG.cleanup; end;');
end;
/

DECLARE
  L_TASKNAME VARCHAR2(128) := 'CLEANUPTASKSDATA';
begin
  COREMOD_TASKS.create_task (  P_TASKNAME => L_TASKNAME,
                               P_MODNAME => '&MODNM.',
                               P_TASK_TYPE => COREMOD_TASKS.cttPURGE,
                               P_MAX_THREAD => 1,
                               P_ASYNC => 'N') ;  
  COREMOD_TASKS.set_task_body( P_TASKNAME => L_TASKNAME, p_task_body => 'begin coremod_tasks.purge_old_tasks; end;');
end;
/

