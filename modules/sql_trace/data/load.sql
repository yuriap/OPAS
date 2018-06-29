INSERT INTO opas_config (modname,cgroup,ckey,cvalue,descr) VALUES ('&MODNM.','RETENTION','TRACEPROJRETENTION',30,'Retention time in days for trace projects.');
INSERT INTO opas_config (modname,cgroup,ckey,cvalue,descr) VALUES ('&MODNM.','RETENTION','TRACEFILERETENTION',8,'Retention time in days for trace files.');
--INSERT INTO opas_config (modname,cgroup,ckey,cvalue,descr) VALUES ('&MODNM.','RETENTION','LOGS_EXPIRE_TIME',8,'Retention time for logs.');

--INSERT INTO opas_config (modname,cgroup,ckey,cvalue,descr) VALUES ('&MODNM.','LOGGING','LOGGING_LEVEL','INFO','Current logging level. INFO|DEBUG');

insert into opas_groups (group_name,modname,group_descr,access_level) values ('Administrators','&MODNM.','Full set of rights',0);
insert into opas_groups (group_name,modname,group_descr,access_level) values ('Reas-write users','&MODNM.','All application functions',1);
insert into opas_groups (group_name,modname,group_descr,access_level) values ('Read-only users','&MODNM.','Read-only functions',2);

--Dictionatiries
insert into trc_dic_retention (ret_code, ret_display_name) values ('DEFAULT', 'Default');
insert into trc_dic_retention (ret_code, ret_display_name) values ('KEEPFOREVER', 'Keep forever');
insert into trc_dic_retention (ret_code, ret_display_name) values ('KEEPFILESONLY', 'Keep files only');
insert into trc_dic_retention (ret_code, ret_display_name) values ('KEEPPARSEDONLY', 'Keep parsed only');
insert into trc_dic_retention (ret_code, ret_display_name) values ('CLEANUPOLD', 'Cleanup old parsed/files');

insert into opas_db_links (DB_LINK_NAME,DISPLAY_NAME,OWNER,DDL_TEXT,STATUS,is_public) values ('NEIGHBOR', 'NEIGHBOR', 'PUBLIC', q'[CREATE DATABASE LINK NEIGHBOR CONNECT TO AWRTOOLS21 IDENTIFIED BY awrtools21 USING 'localhost:1521/db12c22.localdomain']', 'NEW', 'Y');
commit;