define MODNM=AWR_WAREHOUSE
define MODVER="4.0.0"

--remote scheme setup
conn sys/&remotesys.@&remotedb. as sysdba

@@scheme_setup_remote

conn &remotescheme./&remotescheme.@&remotedb.

@..\modules\awr_warehouse\struct\create_struct_remote
@..\modules\awr_warehouse\source\create_stored_remote

--local scheme setup
conn sys/&localsys.@&localdb. as sysdba

@@scheme_setup.sql

conn &localscheme./&localscheme.@&localdb.

@..\modules\awr_warehouse\struct\create_struct.sql
@..\modules\awr_warehouse\source\create_stored.sql



exec COREMOD.register(p_modname => '&MODNM.', p_moddescr => 'Oracle Performance Analytic Suite AWR WareHouse module', p_modver => '&MODVER.', p_installed => sysdate);

@..\modules\awr_warehouse\data\load.sql

begin
  COREMOD_TASKS.create_task (  p_taskname  => 'AWRWH_EXECFILEACTION',
                               p_modname   => '&MODNM.',
                               p_is_public => 'Y', 
                               p_task_body => 'begin AWRWH_FILE_API.exec_file_action (p_dump_id => <B1>, p_action => <B2>, p_start_state => <B3>) ; end;');
end;
/

begin
  COREMOD_TASKS.create_task (  p_taskname  => 'AWRWH_AWRCOMPRPT',
                               p_modname   => '&MODNM.',
                               p_is_public => 'Y', 
                               p_task_body => 'begin AWRWH_REPORT_API.report_awrcomp (p_report_id => <B1>) ; end;');
end;
/

begin
  coremod_cleanup.register_cleanup_tasks (  P_TASKNAME => 'CLEANUP_AWRWH',
                                            P_MODNAME => '&MODNM.',
                                            p_task_body => 'begin AWRWH_PROJ_API.cleanup_projects; end;');
end;
/
commit;