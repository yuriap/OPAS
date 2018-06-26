insert into opas_db_links (DB_LINK_NAME,OWNER,DDL_TEXT,STATUS) values ('LOCAL', 'PUBLIC', 'N/A', 'CREATED');

INSERT INTO opas_config (modname,cgroup,ckey,cvalue,descr) VALUES ('&MODNM.','RETENTION','TASKRETENTION',8,'Retention time in days for task metadata of USER type tasks.');
INSERT INTO opas_config (modname,cgroup,ckey,cvalue,descr) VALUES ('&MODNM.','RETENTION','LOGS_EXPIRE_TIME',8,'Retention time in days for logs.');

INSERT INTO opas_config (modname,cgroup,ckey,cvalue,descr) VALUES ('&MODNM.','LOGGING','LOGGING_LEVEL','INFO','Current logging level. INFO|DEBUG');

commit;