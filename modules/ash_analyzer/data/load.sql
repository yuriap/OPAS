INSERT INTO opas_config (modname,cgroup,ckey,cvalue,descr) VALUES ('&MODNM.','RETENTION','PROJECTRETENTION',    30,'Retention time in days for ASH Analyzer projects.');
INSERT INTO opas_config (modname,cgroup,ckey,cvalue,descr) VALUES ('&MODNM.','RETENTION','CUBERETENTION',        2,'Retention time in hours for ASH Analyzer cude data.');
INSERT INTO opas_config (modname,cgroup,ckey,cvalue,descr) VALUES ('&MODNM.','RETENTION','REPORTRETENTION',     24,'Retention time in hours for ASH Analyzer reports.');

INSERT INTO opas_config (modname,cgroup,ckey,cvalue,descr) VALUES ('&MODNM.','RETENTION','METRICSDICRETENTION', 90,'Time of METRICS dictionary expiration, days');
INSERT INTO opas_config (modname,cgroup,ckey,cvalue,descr) VALUES ('&MODNM.','RETENTION','RACNODEDICRETENTION',  8,'Time of RAC nodes dictionary expiration, days');
INSERT INTO opas_config (modname,cgroup,ckey,cvalue,descr) VALUES ('&MODNM.','MONITOR',  'PAUSEMONITOR',        10,'Seconds between cube refresh in Monitor mode');
INSERT INTO opas_config (modname,cgroup,ckey,cvalue,descr) VALUES ('&MODNM.','MONITOR',  'ITERATIONSMONITOR',  100,'Number of refresh iteration of cube in Monitor mode');

commit;

@@load_stats