define MODNM=AWR_WAREHOUSE
define MODVER="4.0.0"

--remote scheme setup
conn sys/&remotesys.@&remotedb. as sysdba

@@scheme_setup_remote
@..\modules\awr_warehouse\struct\create_struct_remote
@..\modules\awr_warehouse\source\create_stored_remote

--local scheme setup
conn sys/&localsys.@&localdb. as sysdba

@@scheme_setup.sql
@..\modules\awr_warehouse\struct\create_struct.sql
@..\modules\awr_warehouse\source\create_stored.sql

exec COREMOD.register(p_modname => '&MODNM.', p_moddescr => 'Oracle Performance Analytic Suite AWR WareHouse module', p_modver => '&MODVER.', p_installed => sysdate);

@..\modules\awr_warehouse\data\load.sql

--begin
--  COREMOD_TASKS.create_task (  p_taskname  => 'TRC_PARSEFILE',
--                               p_modname   => '&MODNM.',
--                               p_is_public => 'Y', 
--                               p_task_body => 'begin TRC_FILE_API.parse_file (P_TRC_FILE_ID => <B1>) ; end;');
--end;
--/

begin
  coremod_cleanup.register_cleanup_tasks (  P_TASKNAME => 'CLEANUP_AWRWH',
                                            P_MODNAME => '&MODNM.',
                                            p_task_body => 'begin AWRWH_PROJ_API.cleanup_projects; end;');
end;
/
commit;