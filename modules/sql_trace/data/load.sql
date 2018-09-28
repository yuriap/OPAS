INSERT INTO opas_config (modname,cgroup,ckey,cvalue,descr) VALUES ('&MODNM.','RETENTION','PROJECTRETENTION',30,'Retention time in days for trace projects.');
INSERT INTO opas_config (modname,cgroup,ckey,cvalue,descr) VALUES ('&MODNM.','RETENTION','SOURCERETENTION',10,'Retention time in days for trace files.');
INSERT INTO opas_config (modname,cgroup,ckey,cvalue,descr) VALUES ('&MODNM.','RETENTION','PARSEDRETENTION',20,'Retention time in days for parsed representation.');
INSERT INTO opas_config (modname,cgroup,ckey,cvalue,descr) VALUES ('&MODNM.','REPORT','TOPSQL',50,'Default value for number of Top SQL to show.');

commit;