insert into opas_db_links (DB_LINK_NAME,DISPLAY_NAME,OWNER,DDL_TEXT,STATUS,is_public) values ('$LOCAL$', 'Local', 'PUBLIC', 'N/A', 'CREATED','Y');

INSERT INTO opas_config (modname,cgroup,ckey,cvalue,descr) VALUES ('&MODNM.','RETENTION','TASKRETENTION',8,'Retention time in days for task metadata of USER type tasks.');
INSERT INTO opas_config (modname,cgroup,ckey,cvalue,descr) VALUES ('&MODNM.','RETENTION','LOGS_EXPIRE_TIME',8,'Retention time in days for logs.');
INSERT INTO opas_config (modname,cgroup,ckey,cvalue,descr) VALUES ('&MODNM.','PRJRETENTION','PROJECTRETENTION',30,'Retention time in days for projects (default).');
INSERT INTO opas_config (modname,cgroup,ckey,cvalue,descr) VALUES ('&MODNM.','INSTRUMENTATION','INSTR_SQL_GATHER_STAT',null,'Start to gather SQL rowsource statistic for a given code.');
INSERT INTO opas_config (modname,cgroup,ckey,cvalue,descr) VALUES ('&MODNM.','INSTRUMENTATION','INSTR_SQL_TRACE',null,'Start Extended SQL Trace for a given code.');

INSERT INTO opas_config (modname,cgroup,ckey,cvalue,descr) VALUES ('&MODNM.','LOGGING','LOGGING_LEVEL','INFO','Current logging level. INFO|DEBUG');

insert into opas_groups (group_name,modname,group_descr,access_level) values ('Administrators','&MODNM.','Full set of rights',0);
insert into opas_groups (group_name,modname,group_descr,access_level) values ('Reas-write users','&MODNM.','All application functions',1);
insert into opas_groups (group_name,modname,group_descr,access_level) values ('Read-only users','&MODNM.','Read-only functions',2);

declare
  l_script clob;
begin
  l_script := 
q'[
@@../scripts/awr.css
]';
  delete from opas_scripts where script_id='PROC_AWRCSS';
  insert into opas_scripts (script_id,modname,script_content) values ('PROC_AWRCSS','&MODNM.',l_script);  
end;
/

insert into opas_project_cleanup (modname,cleanup_mode,cleanup_prc,ordr) values ('&MODNM.','SOURCEDATA','COREPROJ_API.cleanup_project_source_data',1);
insert into opas_project_cleanup (modname,cleanup_mode,cleanup_prc,ordr) values ('&MODNM.','PARSEDDATA','COREPROJ_API.cleanup_project_parsed_data',1);

insert into opas_project_types (proj_type, modname, page_title, region_title) values ('DEFAULT','&MODNM.','Default projects','Default projects');

--Dictionatiries
insert into opas_dic_retention (ret_code, ret_display_name, ret_display_descr) values ('DEFAULT', 'Default retention applied', 'Project will be removed after <%p1>');
insert into opas_dic_retention (ret_code, ret_display_name, ret_display_descr) values ('KEEPALLFOREVER', 'Keep forever', 'Will be kept forever');
insert into opas_dic_retention (ret_code, ret_display_name, ret_display_descr) values ('KEEPSOURCEDATAONLY', 'Keep source files only', 'Parsed data will be removed in <%p1> days');
insert into opas_dic_retention (ret_code, ret_display_name, ret_display_descr) values ('KEEPPARSEDDATAONLY', 'Keep parsed data only', 'Trace files will be removed in <%p1> days');

commit;