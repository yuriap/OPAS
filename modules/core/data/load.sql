insert into opas_db_links (DB_LINK_NAME,DISPLAY_NAME,OWNER,DDL_TEXT,STATUS,is_public) values ('$LOCAL$', 'Local', 'PUBLIC', 'N/A', 'CREATED','Y');

INSERT INTO opas_config (modname,cgroup,ckey,cvalue,descr) VALUES ('&MODNM.','RETENTION','TASKRETENTION',8,'Retention time in days for task metadata of USER type tasks.');
INSERT INTO opas_config (modname,cgroup,ckey,cvalue,descr) VALUES ('&MODNM.','RETENTION','LOGS_EXPIRE_TIME',8,'Retention time in days for logs.');

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

commit;