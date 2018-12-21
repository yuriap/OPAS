insert into opas_db_links (DB_LINK_NAME,DISPLAY_NAME,OWNER,STATUS,is_public) values ('$LOCAL$', 'Local', 'PUBLIC', 'CREATED','Y');

INSERT INTO opas_config (modname,cgroup,ckey,cvalue,descr) VALUES ('&MODNM.','RETENTION','TASKRETENTION',3,'Retention time in days for task queue metadata.');
INSERT INTO opas_config (modname,cgroup,ckey,cvalue,descr) VALUES ('&MODNM.','RETENTION','LOGRETENTION', 3,'Retention time in days for logs.');
INSERT INTO opas_config (modname,cgroup,ckey,cvalue,descr) VALUES ('&MODNM.','INSTRUMENTATION','INSTR_SQL_GATHER_STAT',null,'Start to gather SQL rowsource statistic for a given code.');
INSERT INTO opas_config (modname,cgroup,ckey,cvalue,descr) VALUES ('&MODNM.','INSTRUMENTATION','INSTR_SQL_TRACE',null,'Start Extended SQL Trace for a given code.');

INSERT INTO opas_config (modname,cgroup,ckey,cvalue,descr) VALUES ('&MODNM.','LOGGING','LOGGING_LEVEL','INFO','Current logging level. INFO|DEBUG');
INSERT INTO opas_config (modname,cgroup,ckey,cvalue,descr) VALUES ('&MODNM.','TASKEXEC','MAXTHREADS',4,'Max number of simultaneously running tasks');

INSERT INTO opas_config (modname,cgroup,ckey,cvalue,descr) VALUES ('&MODNM.','RETENTION','SQLCACHERETENTION', 30,'Retention time in days for SQL Cache.');

insert into opas_groups (group_id,group_name,group_descr) values (0, 'Administrators','Full set of rights');
insert into opas_groups (group_id,group_name,group_descr) values (1, 'Reas-write users','All application functions');
insert into opas_groups (group_id,group_name,group_descr) values (2, 'Read-only users','Read-only functions');
insert into opas_groups (group_id,group_name,group_descr) values (3, 'No access users','No access to any functionality');

		   
INSERT INTO 
  opas_dictionary (modname,dic_name,val,display_val,sparse1,sparse2,sparse3,dic_ordr)
           VALUES ('&MODNM.','REPORT_TYPES','CUST_SQL_AWR_REPORT'    ,'AWR SQL report (custom)'                  ,151,null,null,10);
INSERT INTO 
  opas_dictionary (modname,dic_name,val,display_val,sparse1,sparse2,sparse3,dic_ordr)
           VALUES ('&MODNM.','REPORT_TYPES','CUST_SQL_MEM_REPORT'    ,'SQL memory report (custom)'               ,152,null,null,20);		   
INSERT INTO 
  opas_dictionary (modname,dic_name,val,display_val,sparse1,sparse2,sparse3,dic_ordr)
           VALUES ('&MODNM.','REPORT_TYPES','AWR_REPORT'             ,'AWR report (standard)'                    ,153,null,null,30);
INSERT INTO 
  opas_dictionary (modname,dic_name,val,display_val,sparse1,sparse2,sparse3,dic_ordr)
           VALUES ('&MODNM.','REPORT_TYPES','AWR_SQL_REPORT'         ,'AWR SQL report (standard)'                ,154,null,null,40);
INSERT INTO  
  opas_dictionary (modname,dic_name,val,display_val,sparse1,sparse2,sparse3,dic_ordr)
           VALUES ('&MODNM.','REPORT_TYPES','AWR_DIFF'               ,'AWR diff (standard)'                      ,155,null,null,50);
INSERT INTO     
  opas_dictionary (modname,dic_name,val,display_val,sparse1,sparse2,sparse3,dic_ordr)
           VALUES ('&MODNM.','REPORT_TYPES','ASH_REPORT'             ,'ASH report (standard)'                    ,156,null,null,60);

set define ~

declare
  l_script clob;
begin
  l_script := 
q'[
@../modules/core/scripts/opasawr.css
]';
  delete from opas_scripts where script_id='PROC_AWRCSS';
  insert into opas_scripts (script_id,modname,script_content) values ('PROC_AWRCSS','~MODNM.',l_script);  
  
  l_script := 
q'^
@../modules/core/scripts/__prn_tbl_html.sql
^';
  delete from opas_scripts where script_id='PROC_PRNHTMLTBL';
  insert into opas_scripts (script_id,modname,script_content) values ('PROC_PRNHTMLTBL','~MODNM.',l_script);  
  COREMOD_REPORT_UTILS.prepare_saved_sql_script (  P_SCRIPT_NAME => 'PROC_PRNHTMLTBL');
  
  l_script := 
q'^
@../modules/core/scripts/__getftxt.sql
^';
  delete from opas_scripts where script_id='PROC_GETGTXT';
  insert into opas_scripts (script_id,modname,script_content) values ('PROC_GETGTXT','~MODNM.',l_script);
  COREMOD_REPORT_UTILS.prepare_saved_sql_script (  P_SCRIPT_NAME => 'PROC_GETGTXT');
  
  l_script := 
q'^
@../modules/core/scripts/__nonshared1.sql
^';
  delete from opas_scripts where script_id='PROC_NON_SHARED';
  insert into opas_scripts (script_id,modname,script_content) values ('PROC_NON_SHARED','~MODNM.',l_script);
  COREMOD_REPORT_UTILS.prepare_saved_sql_script (  P_SCRIPT_NAME => 'PROC_NON_SHARED');

  l_script := 
q'^
@../modules/core/scripts/__vsql_stat.sql
^';
  delete from opas_scripts where script_id='PROC_VSQL_STAT';
  insert into opas_scripts (script_id,modname,script_content) values ('PROC_VSQL_STAT','~MODNM.',l_script);
  COREMOD_REPORT_UTILS.prepare_saved_sql_script (  P_SCRIPT_NAME => 'PROC_VSQL_STAT');

  l_script := 
q'^
@../modules/core/scripts/__offload_percent1.sql
^';
  delete from opas_scripts where script_id='PROC_OFFLOAD_PCT1';
  insert into opas_scripts (script_id,modname,script_content) values ('PROC_OFFLOAD_PCT1','~MODNM.',l_script);
  COREMOD_REPORT_UTILS.prepare_saved_sql_script (  P_SCRIPT_NAME => 'PROC_OFFLOAD_PCT1');
  
  l_script := 
q'^
@../modules/core/scripts/__offload_percent2.sql
^';
  delete from opas_scripts where script_id='PROC_OFFLOAD_PCT2';
  insert into opas_scripts (script_id,modname,script_content) values ('PROC_OFFLOAD_PCT2','~MODNM.',l_script);
  COREMOD_REPORT_UTILS.prepare_saved_sql_script (  P_SCRIPT_NAME => 'PROC_OFFLOAD_PCT2');
  
  l_script := 
q'^
@../modules/core/scripts/__sqlmon1.sql
^';
  delete from opas_scripts where script_id='PROC_SQLMON';
  insert into opas_scripts (script_id,modname,script_content) values ('PROC_SQLMON','~MODNM.',l_script);
  COREMOD_REPORT_UTILS.prepare_saved_sql_script (  P_SCRIPT_NAME => 'PROC_SQLMON');
  
  l_script := 
q'^
@../modules/core/scripts/__sqlwarea.sql
^';
  delete from opas_scripts where script_id='PROC_SQLWORKAREA';
  insert into opas_scripts (script_id,modname,script_content) values ('PROC_SQLWORKAREA','~MODNM.',l_script);
  COREMOD_REPORT_UTILS.prepare_saved_sql_script (  P_SCRIPT_NAME => 'PROC_SQLWORKAREA');

  l_script := 
q'^
@../modules/core/scripts/__optenv.sql
^';
  delete from opas_scripts where script_id='PROC_OPTENV';
  insert into opas_scripts (script_id,modname,script_content) values ('PROC_OPTENV','~MODNM.',l_script);
  COREMOD_REPORT_UTILS.prepare_saved_sql_script (  P_SCRIPT_NAME => 'PROC_OPTENV');
  
  l_script := 
q'^
@../modules/core/scripts/__rac_plans.sql
^';
  delete from opas_scripts where script_id='PROC_RACPLAN';
  insert into opas_scripts (script_id,modname,script_content) values ('PROC_RACPLAN','~MODNM.',l_script);
  COREMOD_REPORT_UTILS.prepare_saved_sql_script (  P_SCRIPT_NAME => 'PROC_RACPLAN');
  
  l_script := 
q'^
@../modules/core/scripts/__sqlmon_hist.sql
^';
  delete from opas_scripts where script_id='PROC_SQLMON_HIST';
  insert into opas_scripts (script_id,modname,script_content) values ('PROC_SQLMON_HIST','~MODNM.',l_script);
  COREMOD_REPORT_UTILS.prepare_saved_sql_script (  P_SCRIPT_NAME => 'PROC_SQLMON_HIST');
  
  l_script := 
q'[
@../modules/core/scripts/__ash_p3
]';
  delete from opas_scripts where script_id='PROC_AWRASHP3';
  insert into opas_scripts (script_id,modname,script_content) values ('PROC_AWRASHP3','~MODNM.',l_script);
  COREMOD_REPORT_UTILS.prepare_saved_sql_script (  P_SCRIPT_NAME => 'PROC_AWRASHP3');

end;
/

declare
  l_script clob;
begin
  l_script :=
q'{
@../modules/core/scripts/__sqlstat.sql
}';
  delete from opas_scripts where script_id='PROC_AWRSQLSTAT';
  insert into opas_scripts (script_id,modname,script_content) values ('PROC_AWRSQLSTAT','~MODNM.',l_script);
  COREMOD_REPORT_UTILS.prepare_saved_sql_script (  P_SCRIPT_NAME => 'PROC_AWRSQLSTAT');
  
  l_script := 
q'[
@../modules/core/scripts/__ash_summ
]';
  delete from opas_scripts where script_id='PROC_AWRASHSUMM';
  insert into opas_scripts (script_id,modname,script_content) values ('PROC_AWRASHSUMM','~MODNM.',l_script);
  COREMOD_REPORT_UTILS.prepare_saved_sql_script (  P_SCRIPT_NAME => 'PROC_AWRASHSUMM');
  
  l_script := 
q'[
@../modules/core/scripts/__ash_p1
]';
  delete from opas_scripts where script_id='PROC_AWRASHP1';
  insert into opas_scripts (script_id,modname,script_content) values ('PROC_AWRASHP1','~MODNM.',l_script);
  COREMOD_REPORT_UTILS.prepare_saved_sql_script (  P_SCRIPT_NAME => 'PROC_AWRASHP1');
  
  l_script := 
q'[
@../modules/core/scripts/__ash_p1_1
]';
  delete from opas_scripts where script_id='PROC_AWRASHP1_1';
  insert into opas_scripts (script_id,modname,script_content) values ('PROC_AWRASHP1_1','~MODNM.',l_script);
  COREMOD_REPORT_UTILS.prepare_saved_sql_script (  P_SCRIPT_NAME => 'PROC_AWRASHP1_1');
  
  l_script := 
q'[
@../modules/core/scripts/__ash_p2
]';
  delete from opas_scripts where script_id='PROC_AWRASHP2';
  insert into opas_scripts (script_id,modname,script_content) values ('PROC_AWRASHP2','~MODNM.',l_script);
  COREMOD_REPORT_UTILS.prepare_saved_sql_script (  P_SCRIPT_NAME => 'PROC_AWRASHP2');
  
end;
/



set define &

INSERT INTO opas_groups2apexusr ( group_id, modname, apex_user) VALUES ( 0, 'OPASCORE', 'OPAS40ADM');

commit;