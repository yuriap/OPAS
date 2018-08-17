INSERT INTO opas_config (modname,cgroup,ckey,cvalue,descr) VALUES ('&MODNM.','RETENTION','PROJECTRETENTION',30,'Retention time in days for trace projects.');
INSERT INTO opas_config (modname,cgroup,ckey,cvalue,descr) VALUES ('&MODNM.','RETENTION','TRACEFILERETENTION',8,'Retention time in days for trace files.');

INSERT INTO opas_config (modname,cgroup,ckey,cvalue,descr) VALUES ('&MODNM.','PRJRETENTION','PROJECTRETENTION',30,'Retention time in days for trace projects.');

--INSERT INTO opas_config (modname,cgroup,ckey,cvalue,descr) VALUES ('&MODNM.','RETENTION','LOGS_EXPIRE_TIME',8,'Retention time for logs.');

--INSERT INTO opas_config (modname,cgroup,ckey,cvalue,descr) VALUES ('&MODNM.','LOGGING','LOGGING_LEVEL','INFO','Current logging level. INFO|DEBUG');

INSERT INTO opas_config (modname,cgroup,ckey,cvalue,descr) VALUES ('&MODNM.','REPORT','TOPSQL',50,'Default value for number of Top SQL to show.');

insert into opas_groups (group_name,modname,group_descr,access_level) values ('Administrators','&MODNM.','Full set of rights',0);
insert into opas_groups (group_name,modname,group_descr,access_level) values ('Reas-write users','&MODNM.','All application functions',1);
insert into opas_groups (group_name,modname,group_descr,access_level) values ('Read-only users','&MODNM.','Read-only functions',2);

--Dictionatiries
insert into trc_dic_retention (ret_code, ret_display_name) values ('DEFAULT', 'Default');
insert into trc_dic_retention (ret_code, ret_display_name) values ('KEEPFOREVER', 'Keep forever');
insert into trc_dic_retention (ret_code, ret_display_name) values ('KEEPFILESONLY', 'Keep files only');
insert into trc_dic_retention (ret_code, ret_display_name) values ('KEEPPARSEDONLY', 'Keep parsed only');
insert into trc_dic_retention (ret_code, ret_display_name) values ('CLEANUPOLD', 'Cleanup old parsed/files');

insert into opas_project_types (proj_type, modname, page_title, region_title) values ('EXTSQLTRACE','&MODNM.','Extended SQL Trace Projects','Projects');

commit;