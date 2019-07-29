INSERT INTO opas_config (modname,cgroup,ckey,cvalue,descr) VALUES ('&MODNM.','RETENTION','PROJECTRETENTION',    30,'Retention time in days for ASH Analyzer projects.');
INSERT INTO opas_config (modname,cgroup,ckey,cvalue,descr) VALUES ('&MODNM.','RETENTION','CUBERETENTION',        2,'Retention time in hours for ASH Analyzer cude data.');
INSERT INTO opas_config (modname,cgroup,ckey,cvalue,descr) VALUES ('&MODNM.','RETENTION','REPORTRETENTION',     24,'Retention time in hours for ASH Analyzer reports.');
INSERT INTO opas_config (modname,cgroup,ckey,cvalue,descr) VALUES ('&MODNM.','RETENTION','DICRETENTION',        30,'Retention time in days for RAC nodes dictionaries.');
INSERT INTO opas_config (modname,cgroup,ckey,cvalue,descr) VALUES ('&MODNM.','RETENTION','EXPIMPSESS',        0.03,'Retention time in days for ASHA export/import sessions.');

INSERT INTO opas_config (modname,cgroup,ckey,cvalue,descr) VALUES ('&MODNM.','RETENTION','METRICSDICRETENTION', 90,'Time of METRICS dictionary expiration, days');
INSERT INTO opas_config (modname,cgroup,ckey,cvalue,descr) VALUES ('&MODNM.','RETENTION','RACNODEDICRETENTION',  8,'Time of RAC nodes dictionary expiration, days');
--INSERT INTO opas_config (modname,cgroup,ckey,cvalue,descr) VALUES ('&MODNM.','MONITOR',  'PAUSEMONITOR',        10,'Seconds between cube refresh in Monitor mode');
--INSERT INTO opas_config (modname,cgroup,ckey,cvalue,descr) VALUES ('&MODNM.','MONITOR',  'ITERATIONSMONITOR',   60,'Number of refresh iteration of cube in Monitor mode');
--INSERT INTO opas_config (modname,cgroup,ckey,cvalue,descr) VALUES ('&MODNM.','MONITOR',  'SNAP_ASH_FREQ',      0.5,'Frequency sec^-1 of snapping V$SESSION in Monitor mode (Standard Edition)');

@@expimp_compat.sql
@@load_tmpls.sql

commit;

@@load_stats