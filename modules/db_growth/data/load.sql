INSERT INTO opas_config (modname,cgroup,ckey,cvalue,descr) VALUES ('&MODNM.','RETENTION','PROJECTRETENTION',    30,'Retention time in days for DB Growth Tracker projects.');

@@expimp_compat.sql

commit;
