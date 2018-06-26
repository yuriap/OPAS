INSERT INTO opas_config (modname,cgroup,ckey,cvalue,descr) VALUES ('&MODNM.','RETENTION','TRACEPROJRETENTION',30,'Retention time in days for trace projects.');
INSERT INTO opas_config (modname,cgroup,ckey,cvalue,descr) VALUES ('&MODNM.','RETENTION','TRACEFILERETENTION',8,'Retention time in days for trace files.');
--INSERT INTO opas_config (modname,cgroup,ckey,cvalue,descr) VALUES ('&MODNM.','RETENTION','LOGS_EXPIRE_TIME',8,'Retention time for logs.');

--INSERT INTO opas_config (modname,cgroup,ckey,cvalue,descr) VALUES ('&MODNM.','LOGGING','LOGGING_LEVEL','INFO','Current logging level. INFO|DEBUG');

insert into opas_groups (group_name,modname,group_descr,access_level) values ('Administrators','&MODNM.','Full set of rights',0);
insert into opas_groups (group_name,modname,group_descr,access_level) values ('Reas-write users','&MODNM.','All application functions',1);
insert into opas_groups (group_name,modname,group_descr,access_level) values ('Read-only users','&MODNM.','Read-only functions',2);

commit;