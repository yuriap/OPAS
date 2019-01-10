define MODNM=SQL_TRACE
define MODVER="2.2.0"
--Core installation script
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