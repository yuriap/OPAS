define MODNM=AWR_WAREHOUSE
@@version.sql

--remote scheme setup
conn sys/&remotesys.@&remotedb. as sysdba

@@scheme_setup_remote

conn &remotescheme./&remotescheme.@&remotedb.

@../modules/awr_warehouse/struct/create_struct_remote
@../modules/awr_warehouse/source/create_stored_remote

--local scheme setup
conn sys/&localsys.@&localdb. as sysdba

@@scheme_setup.sql

conn &localscheme./&localscheme.@&localdb.

@../modules/awr_warehouse/struct/create_struct.sql
@../modules/awr_warehouse/source/create_stored.sql

@../modules/awr_warehouse/struct/upgrade_struct_4.4.0_4.4.1_mv.sql
@../modules/awr_warehouse/struct/upgrade_struct_4.4.1_4.4.2_mv.sql


exec COREMOD.register(p_modname => '&MODNM.', p_moddescr => 'AWR WareHouse module', p_modver => '&MODVER.', p_installed => sysdate);

@../modules/awr_warehouse/data/load.sql

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

BEGIN
  COREMOD_INTEGRATION.register_integration (  P_INT_KEY => AWRWH_API.gintAWRWH2ASH_DUMP2CUBE,
    P_OWNER_MODNAME => 'AWR_WAREHOUSE',
    P_SRC_MODNAME => 'AWR_WAREHOUSE',
    P_TRG_MODNAME => 'ASH_ANALYZER',
    P_SRC_URL_TMPL => 'f?p=<APP_ID>:404:<SESSION>::::P404_DUMP_ID,P404_PROJ_ID:<SRC_ENTITY>,<SRC_PARENT>:',
    P_TRG_URL_TMPL => 'f?p=<APP_ID>:303:<SESSION>::::P303_SESS_ID,P303_TQ_ID,P303_PROJ_ID:<TRG_ENTITY>,0,<TRG_PARENT>:',
    P_SRC_DESC_TMPL => 'Dump file "<VAR2>" with name "<VAR1>" of "<VAR3>" project',
    P_TRG_DESC_TMPL => 'ASH Cube "Created: <VAR1>; Status: <VAR2>" for dump file "<VAR3>"',
    P_SRC_DESC_DYN_TMPL => 'select dump_name, filename, p.proj_name, null from awrwh_dumps d, awrwh_projects p where dump_id=<SRC_ENTITY> and d.proj_id=p.proj_id',
    P_TRG_DESC_DYN_TMPL => q'[select to_char(sess_created,'YYYY-MON-DD HH24:MI:SS'),sess_status, (select filename from awrwh_dumps where dump_id=<SRC_ENTITY>) dump_name, null from asha_cube_sess where sess_id=<TRG_ENTITY>]');
END;
/

commit;

begin
  AWRWH_EXPIMP.init();
end;
/