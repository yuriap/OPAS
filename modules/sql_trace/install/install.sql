define MODNM=SQL_TRACE
define MODVER="2.0.0"
--Core installation script
conn sys/&localsys.@&localdb. as sysdba

@@scheme_setup.sql

conn &localscheme./&localscheme.@&localdb.

@@uninstall

@..\modules\sql_trace\struct\create_struct.sql

@..\modules\sql_trace\source\create_stored.sql

exec COREMOD.register(p_modname => '&MODNM.', p_moddescr => 'Oracle Performance Analytic Suite SQL Trace Module', p_modver => '&MODVER.', p_installed => sysdate);

@..\modules\sql_trace\data\load.sql

DECLARE
  L_TASKNAME VARCHAR2(128) := 'CLEANUPSQL_TRACE';
begin
  COREMOD_TASKS.create_task (  P_TASKNAME => L_TASKNAME,
                               P_MODNAME => '&MODNM.',
                               P_TASK_TYPE => COREMOD_TASKS.cttPURGE,
                               P_MAX_THREAD => 1,
                               P_ASYNC => 'N') ;  
  COREMOD_TASKS.set_task_body( P_TASKNAME => L_TASKNAME, p_task_body => 'begin TRC_UTILS.purge_trc_projects; end;');
end;
/