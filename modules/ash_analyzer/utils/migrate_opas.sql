spool migrate_opas.log
define source_schema=opas421
define target_schema=opas45
set verify off
set serveroutput on

declare
  l_proj_id &target_schema..asha_cube_projects.proj_id%type;
  l_sess_id &target_schema..asha_cube_sess.sess_id%type;
  type t_ids is table of number index by pls_integer;
  l_sess_ids t_ids;
  l_file_ids t_ids;
  l_rpt_ids t_ids;
  l_proj_ids t_ids;
  id number;
  l_cnt number;
  l_tim number;
begin
   l_cnt:=0;
   l_tim:=DBMS_UTILITY.GET_TIME;
   for i in (select * from &source_schema..opas_files where file_id in (select report_content from &source_schema..opas_reports where report_id in (select report_id from &source_schema..asha_cube_reports/* where report_id<>13*/))) loop
     INSERT INTO &target_schema..opas_files (modname,file_type,file_name,file_mimetype,file_contentb,file_contentc,created,owner) 
           VALUES (i.modname,i.file_type,i.file_name,i.file_mimetype,i.file_contentb,i.file_contentc,i.created,i.owner) returning file_id into l_file_ids(i.file_id);
     l_cnt:=l_cnt+1;
   end loop;
   dbms_output.put_line('Loaded opas_files: '||l_cnt||' in '||to_char((DBMS_UTILITY.GET_TIME-l_tim)/100)||' sec.');
   l_cnt:=0;
   l_tim:=DBMS_UTILITY.GET_TIME;
   for i in (select * from &source_schema..opas_reports where report_id in (select report_id from &source_schema..asha_cube_reports /* where report_id<>13*/) order by report_id, parent_id nulls first) loop
     if i.parent_id is null then id := null; else id:=l_rpt_ids(i.parent_id); end if;
     INSERT INTO &target_schema..opas_reports (parent_id,modname,tq_id,report_content,report_params_displ,report_type) 
           VALUES (id,i.modname,i.tq_id,l_file_ids(i.report_content),i.report_params_displ,i.report_type) returning report_id into l_rpt_ids(i.report_id);
     l_cnt:=l_cnt+1;
   end loop;
   dbms_output.put_line('Loaded opas_reports: '||l_cnt||' in '||to_char((DBMS_UTILITY.GET_TIME-l_tim)/100)||' sec.');
   l_cnt:=0;
   l_tim:=DBMS_UTILITY.GET_TIME;
   for i in (select * from &source_schema..opas_reports_pars where report_id in (select report_id from &source_schema..asha_cube_reports /* where report_id<>13*/)) loop
     INSERT INTO &target_schema..opas_reports_pars (report_id,par_name,num_par,varchar_par,date_par) 
           VALUES (l_rpt_ids(i.report_id),i.par_name,i.num_par,i.varchar_par,i.date_par);
     l_cnt:=l_cnt+1;
   end loop;
   dbms_output.put_line('Loaded opas_reports_pars: '||l_cnt||' in '||to_char((DBMS_UTILITY.GET_TIME-l_tim)/100)||' sec.');
   l_cnt:=0;
   l_tim:=DBMS_UTILITY.GET_TIME;
   for i in (select * from &source_schema..asha_cube_projects) loop
     INSERT INTO &target_schema..asha_cube_projects (proj_name,owner,created,status,proj_note,keep_forever,is_public) 
           VALUES (i.proj_name,i.owner,i.created,i.status,i.proj_note,i.keep_forever,i.is_public) returning proj_id into l_proj_ids(i.proj_id);
     l_cnt:=l_cnt+1;
   end loop;
   dbms_output.put_line('Loaded asha_cube_projects: '||l_cnt||' in '||to_char((DBMS_UTILITY.GET_TIME-l_tim)/100)||' sec.');
   l_cnt:=0;
   l_tim:=DBMS_UTILITY.GET_TIME;
   for i in (select * from &source_schema..asha_cube_sess order by sess_id, parent_id nulls first) loop
     if i.parent_id is null then id := null; else id:=l_sess_ids(i.parent_id); end if;
     INSERT INTO &target_schema..asha_cube_sess (sess_id,sess_proj_id,sess_created,sess_retention_days,sess_status,sess_tq_id,sess_tq_id_snap,sess_description,parent_id) 
           VALUES (&target_schema..asha_sq_cube.nextval,l_proj_ids(i.sess_proj_id),i.sess_created,i.sess_retention_days,i.sess_status,i.sess_tq_id,i.sess_tq_id_snap,i.sess_description,id) returning sess_id into l_sess_ids(i.sess_id);     
     l_cnt:=l_cnt+1;
   end loop;
   dbms_output.put_line('Loaded asha_cube_sess: '||l_cnt||' in '||to_char((DBMS_UTILITY.GET_TIME-l_tim)/100)||' sec.');
   l_cnt:=0;
   l_tim:=DBMS_UTILITY.GET_TIME;
   for i in (select * from &source_schema..asha_cube_reports /* where report_id<>13*/) loop
     INSERT INTO &target_schema..asha_cube_reports (proj_id,report_id,sess_id,report_retention,report_note,created) 
           VALUES (l_proj_ids(i.proj_id),l_rpt_ids(i.report_id),l_sess_ids(i.sess_id),i.report_retention,i.report_note,i.created);
     l_cnt:=l_cnt+1;
   end loop;
   dbms_output.put_line('Loaded asha_cube_reports: '||l_cnt||' in '||to_char((DBMS_UTILITY.GET_TIME-l_tim)/100)||' sec.');
   l_cnt:=0;
   l_tim:=DBMS_UTILITY.GET_TIME;
   for i in (select * from &source_schema..asha_cube_sess_pars) loop
     INSERT INTO &target_schema..asha_cube_sess_pars (sess_id,sess_par_nm,sess_par_val) 
           VALUES (l_sess_ids(i.sess_id),i.sess_par_nm,i.sess_par_val);
     l_cnt:=l_cnt+1;
   end loop;
   dbms_output.put_line('Loaded asha_cube_sess_pars: '||l_cnt||' in '||to_char((DBMS_UTILITY.GET_TIME-l_tim)/100)||' sec.');
   l_cnt:=0;
   l_tim:=DBMS_UTILITY.GET_TIME;
   for i in (select * from &source_schema..asha_cube) loop
     INSERT INTO &target_schema..asha_cube (sess_id,sample_time,wait_class,sql_id,event,event_id,module,action,sql_id1,sql_plan_hash_value,segment_id,
                                   g1,g2,g3,g4,g5,g6,smpls) 
           VALUES (l_sess_ids(i.sess_id),i.sample_time,i.wait_class,i.sql_id,i.event,i.event_id,i.module,i.action,i.sql_id1,i.sql_plan_hash_value,i.segment_id,
                                   i.g1,i.g2,i.g3,i.g4,i.g5,i.g6,i.smpls);
     l_cnt:=l_cnt+1;
   end loop;
   dbms_output.put_line('Loaded asha_cube: '||l_cnt||' in '||to_char((DBMS_UTILITY.GET_TIME-l_tim)/100)||' sec.');
   l_cnt:=0;
   l_tim:=DBMS_UTILITY.GET_TIME;
   for i in (select * from &source_schema..asha_cube_block) loop
     INSERT INTO &target_schema..asha_cube_block (sess_id,session_id,session_serial#,inst_id,sql_id,module,action,blocking_session,blocking_session_serial#,blocking_inst_id,cnt)
           VALUES (l_sess_ids(i.sess_id),i.session_id,i.session_serial#,i.inst_id,i.sql_id,i.module,i.action,i.blocking_session,i.blocking_session_serial#,i.blocking_inst_id,i.cnt);
     l_cnt:=l_cnt+1;
   end loop;
   dbms_output.put_line('Loaded asha_cube_block: '||l_cnt||' in '||to_char((DBMS_UTILITY.GET_TIME-l_tim)/100)||' sec.');
   l_cnt:=0;
   l_tim:=DBMS_UTILITY.GET_TIME;
   for i in (select * from &source_schema..asha_cube_metrics) loop
     INSERT INTO &target_schema..asha_cube_metrics (sess_id,metric_id,end_time,value)
           VALUES (l_sess_ids(i.sess_id),i.metric_id,i.end_time,i.value);
     l_cnt:=l_cnt+1;
   end loop;
   dbms_output.put_line('Loaded asha_cube_metrics: '||l_cnt||' in '||to_char((DBMS_UTILITY.GET_TIME-l_tim)/100)||' sec.');
   l_cnt:=0;
   l_tim:=DBMS_UTILITY.GET_TIME;
   for i in (select * from &source_schema..asha_cube_seg) loop
     INSERT INTO &target_schema..asha_cube_seg (sess_id,segment_id,segment_name)
           VALUES (l_sess_ids(i.sess_id),i.segment_id,i.segment_name);
     l_cnt:=l_cnt+1;
   end loop;
   dbms_output.put_line('Loaded asha_cube_seg: '||l_cnt||' in '||to_char((DBMS_UTILITY.GET_TIME-l_tim)/100)||' sec.');
   l_cnt:=0;
   l_tim:=DBMS_UTILITY.GET_TIME;
   for i in (select * from &source_schema..asha_cube_snap_ash) loop
     INSERT INTO &target_schema..asha_cube_snap_ash (sess_id,inst_id,sample_id,sample_time,sample_time_utc,usecs_per_row,is_awr_sample,session_id,session_serial#,
                                             session_type,flags,user_id,sql_id,is_sqlid_current,sql_child_number,sql_opcode,force_matching_signature,top_level_sql_id,
                                             top_level_sql_opcode,sql_opname,sql_adaptive_plan_resolved,sql_full_plan_hash_value,sql_plan_hash_value,sql_plan_line_id,
                                             sql_plan_operation,sql_plan_options,sql_exec_id,sql_exec_start,plsql_entry_object_id,plsql_entry_subprogram_id,plsql_object_id,
                                             plsql_subprogram_id,qc_instance_id,qc_session_id,qc_session_serial#,px_flags,event,event_id,event#,seq#,p1text,p1,p2text,p2,
                                             p3text,p3,wait_class,wait_class_id,wait_time,session_state,time_waited,blocking_session_status,blocking_session,blocking_session_serial#,
                                             blocking_inst_id,blocking_hangchain_info,current_obj#,current_file#,current_block#,current_row#,top_level_call#,top_level_call_name,
                                             consumer_group_id,xid,remote_instance#,time_model,in_connection_mgmt,in_parse,in_hard_parse,in_sql_execution,in_plsql_execution,
                                             in_plsql_rpc,in_plsql_compilation,in_java_execution,in_bind,in_cursor_close,in_sequence_load,in_inmemory_query,in_inmemory_populate,
                                             in_inmemory_prepopulate,in_inmemory_repopulate,in_inmemory_trepopulate,in_tablespace_encryption,capture_overhead,replay_overhead,
                                             is_captured,is_replayed,is_replay_sync_token_holder,service_hash,program,module,action,client_id,machine,port,ecid,dbreplay_file_id,
                                             dbreplay_call_counter,tm_delta_time,tm_delta_cpu_time,tm_delta_db_time,delta_time,delta_read_io_requests,delta_write_io_requests,
                                             delta_read_io_bytes,delta_write_io_bytes,delta_interconnect_io_bytes,delta_read_mem_bytes,pga_allocated,temp_space_allocated,
                                             con_dbid,con_id,dbop_name,dbop_exec_id)
                                             VALUES 
                                            (l_sess_ids(i.sess_id),i.inst_id,&target_schema..asha_snap_ash.nextval,i.sample_time,i.sample_time_utc,i.usecs_per_row,i.is_awr_sample,i.session_id,i.session_serial#,
                                             i.session_type,i.flags,i.user_id,i.sql_id,i.is_sqlid_current,i.sql_child_number,i.sql_opcode,i.force_matching_signature,i.top_level_sql_id,
                                             i.top_level_sql_opcode,i.sql_opname,i.sql_adaptive_plan_resolved,i.sql_full_plan_hash_value,i.sql_plan_hash_value,i.sql_plan_line_id,
                                             i.sql_plan_operation,i.sql_plan_options,i.sql_exec_id,i.sql_exec_start,i.plsql_entry_object_id,i.plsql_entry_subprogram_id,i.plsql_object_id,
                                             i.plsql_subprogram_id,i.qc_instance_id,i.qc_session_id,i.qc_session_serial#,i.px_flags,i.event,i.event_id,i.event#,i.seq#,i.p1text,i.p1,i.p2text,i.p2,
                                             i.p3text,i.p3,i.wait_class,i.wait_class_id,i.wait_time,i.session_state,i.time_waited,i.blocking_session_status,i.blocking_session,i.blocking_session_serial#,
                                             i.blocking_inst_id,i.blocking_hangchain_info,i.current_obj#,i.current_file#,i.current_block#,i.current_row#,i.top_level_call#,i.top_level_call_name,
                                             i.consumer_group_id,i.xid,i.remote_instance#,i.time_model,i.in_connection_mgmt,i.in_parse,i.in_hard_parse,i.in_sql_execution,i.in_plsql_execution,
                                             i.in_plsql_rpc,i.in_plsql_compilation,i.in_java_execution,i.in_bind,i.in_cursor_close,i.in_sequence_load,i.in_inmemory_query,i.in_inmemory_populate,
                                             i.in_inmemory_prepopulate,i.in_inmemory_repopulate,i.in_inmemory_trepopulate,i.in_tablespace_encryption,i.capture_overhead,i.replay_overhead,
                                             i.is_captured,i.is_replayed,i.is_replay_sync_token_holder,i.service_hash,i.program,i.module,i.action,i.client_id,i.machine,i.port,i.ecid,i.dbreplay_file_id,
                                             i.dbreplay_call_counter,i.tm_delta_time,i.tm_delta_cpu_time,i.tm_delta_db_time,i.delta_time,i.delta_read_io_requests,i.delta_write_io_requests,
                                             i.delta_read_io_bytes,i.delta_write_io_bytes,i.delta_interconnect_io_bytes,i.delta_read_mem_bytes,i.pga_allocated,i.temp_space_allocated,
                                             i.con_dbid,i.con_id,i.dbop_name,i.dbop_exec_id
     );
     l_cnt:=l_cnt+1;
   end loop;
   dbms_output.put_line('Loaded asha_cube_snap_ash: '||l_cnt||' in '||to_char((DBMS_UTILITY.GET_TIME-l_tim)/100)||' sec.');
   l_cnt:=0;
   l_tim:=DBMS_UTILITY.GET_TIME;
   for i in (select * from &source_schema..asha_cube_timeline) loop
     INSERT INTO &target_schema..asha_cube_timeline (sess_id,sample_time)
           VALUES (l_sess_ids(i.sess_id),i.sample_time);
     l_cnt:=l_cnt+1;
   end loop;
   dbms_output.put_line('Loaded asha_cube_timeline: '||l_cnt||' in '||to_char((DBMS_UTILITY.GET_TIME-l_tim)/100)||' sec.');
   l_cnt:=0;
   l_tim:=DBMS_UTILITY.GET_TIME;
   for i in (select * from &source_schema..asha_cube_top_sess) loop
     INSERT INTO &target_schema..asha_cube_top_sess (sess_id,session_id,session_serial#,inst_id,module,action,program,client_id,machine,ecid,username,smpls)
           VALUES (l_sess_ids(i.sess_id),i.session_id,i.session_serial#,i.inst_id,i.module,i.action,i.program,i.client_id,i.machine,i.ecid,i.username,i.smpls);
     l_cnt:=l_cnt+1;
   end loop;
   dbms_output.put_line('Loaded asha_cube_top_sess: '||l_cnt||' in '||to_char((DBMS_UTILITY.GET_TIME-l_tim)/100)||' sec.');
   l_cnt:=0;
   l_tim:=DBMS_UTILITY.GET_TIME;
   for i in (select * from &source_schema..asha_cube_unknown) loop
     INSERT INTO &target_schema..asha_cube_unknown (sess_id,unknown_type,session_type,program,client_id,machine,ecid,username,smpls)
           VALUES (l_sess_ids(i.sess_id),i.unknown_type,i.session_type,i.program,i.client_id,i.machine,i.ecid,i.username,i.smpls);
     l_cnt:=l_cnt+1;
   end loop;
   dbms_output.put_line('Loaded asha_cube_unknown: '||l_cnt||' in '||to_char((DBMS_UTILITY.GET_TIME-l_tim)/100)||' sec.');
   commit;
end;
/

spool off