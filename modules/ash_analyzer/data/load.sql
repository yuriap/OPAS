INSERT INTO opas_config (modname,cgroup,ckey,cvalue,descr) VALUES ('&MODNM.','RETENTION','PROJECTRETENTION',    30,'Retention time in days for ASH Analyzer projects.');
INSERT INTO opas_config (modname,cgroup,ckey,cvalue,descr) VALUES ('&MODNM.','RETENTION','CUBERETENTION',        2,'Retention time in hours for ASH Analyzer cude data.');
INSERT INTO opas_config (modname,cgroup,ckey,cvalue,descr) VALUES ('&MODNM.','RETENTION','REPORTRETENTION',     24,'Retention time in hours for ASH Analyzer reports.');
INSERT INTO opas_config (modname,cgroup,ckey,cvalue,descr) VALUES ('&MODNM.','RETENTION','DICRETENTION',        30,'Retention time in days for ASH Analyzer sql texts and RAC nodes dictionaries.');

INSERT INTO opas_config (modname,cgroup,ckey,cvalue,descr) VALUES ('&MODNM.','RETENTION','METRICSDICRETENTION', 90,'Time of METRICS dictionary expiration, days');
INSERT INTO opas_config (modname,cgroup,ckey,cvalue,descr) VALUES ('&MODNM.','RETENTION','RACNODEDICRETENTION',  8,'Time of RAC nodes dictionary expiration, days');
INSERT INTO opas_config (modname,cgroup,ckey,cvalue,descr) VALUES ('&MODNM.','MONITOR',  'PAUSEMONITOR',        10,'Seconds between cube refresh in Monitor mode');
INSERT INTO opas_config (modname,cgroup,ckey,cvalue,descr) VALUES ('&MODNM.','MONITOR',  'ITERATIONSMONITOR',  100,'Number of refresh iteration of cube in Monitor mode');

declare
 l_tmpl asha_cube_sess_tmpl.tmpl_id%type;
begin
  INSERT INTO asha_cube_sess_tmpl (tmpl_id,tmpl_proj_id,tmpl_name,tmpl_description,tmpl_created) 
       VALUES (default,null,'Last 30 minutes','Set parameters to show last 30 minutes of ASH',default) returning tmpl_id into l_tmpl;
  insert into ASHA_CUBE_SESS_TMPL_PARS (TMPL_ID,TMPL_PAR_NM,TMPL_PAR_EXPR) values (l_tmpl,'SOURCE','V$VIEW');
  insert into ASHA_CUBE_SESS_TMPL_PARS (TMPL_ID,TMPL_PAR_NM,TMPL_PAR_EXPR) values (l_tmpl,'CUBEAGG','by_mi');
  insert into ASHA_CUBE_SESS_TMPL_PARS (TMPL_ID,TMPL_PAR_NM,TMPL_PAR_EXPR) values (l_tmpl,'INST_ID','-1');
  insert into ASHA_CUBE_SESS_TMPL_PARS (TMPL_ID,TMPL_PAR_NM,TMPL_PAR_EXPR) values (l_tmpl,'START_DT',null);
  insert into ASHA_CUBE_SESS_TMPL_PARS (TMPL_ID,TMPL_PAR_NM,TMPL_PAR_EXPR) values (l_tmpl,'END_DT',null);
  insert into ASHA_CUBE_SESS_TMPL_PARS (TMPL_ID,TMPL_PAR_NM,TMPL_PAR_EXPR) values (l_tmpl,'METRIC_ID','2144');
  insert into ASHA_CUBE_SESS_TMPL_PARS (TMPL_ID,TMPL_PAR_NM,TMPL_PAR_EXPR) values (l_tmpl,'METRICGROUP_ID','2');
  insert into ASHA_CUBE_SESS_TMPL_PARS (TMPL_ID,TMPL_PAR_NM,TMPL_PAR_EXPR) values (l_tmpl,'METRICAGG','AVG');
  insert into ASHA_CUBE_SESS_TMPL_PARS (TMPL_ID,TMPL_PAR_NM,TMPL_PAR_EXPR) values (l_tmpl,'FILTER',null);
  insert into ASHA_CUBE_SESS_TMPL_PARS (TMPL_ID,TMPL_PAR_NM,TMPL_PAR_EXPR) values (l_tmpl,'DUMP_ID',null);
  insert into ASHA_CUBE_SESS_TMPL_PARS (TMPL_ID,TMPL_PAR_NM,TMPL_PAR_EXPR) values (l_tmpl,'BLOCKANALYZE','N');
  insert into ASHA_CUBE_SESS_TMPL_PARS (TMPL_ID,TMPL_PAR_NM,TMPL_PAR_EXPR) values (l_tmpl,'UNKNOWNANALYZE','N');
  insert into ASHA_CUBE_SESS_TMPL_PARS (TMPL_ID,TMPL_PAR_NM,TMPL_PAR_EXPR) values (l_tmpl,'MONITOR','N');
  insert into ASHA_CUBE_SESS_TMPL_PARS (TMPL_ID,TMPL_PAR_NM,TMPL_PAR_EXPR) values (l_tmpl,'TOP_SESS','N');
  insert into ASHA_CUBE_SESS_TMPL_PARS (TMPL_ID,TMPL_PAR_NM,TMPL_PAR_EXPR) values (l_tmpl,'DATE_INTERVAL','30');

  INSERT INTO asha_cube_sess_tmpl (tmpl_id,tmpl_proj_id,tmpl_name,tmpl_description,tmpl_created) 
       VALUES (default,null,'Last 60 minutes','Set parameters to show last 60 minutes of ASH',default) returning tmpl_id into l_tmpl;
  insert into ASHA_CUBE_SESS_TMPL_PARS (TMPL_ID,TMPL_PAR_NM,TMPL_PAR_EXPR) values (l_tmpl,'SOURCE','V$VIEW');
  insert into ASHA_CUBE_SESS_TMPL_PARS (TMPL_ID,TMPL_PAR_NM,TMPL_PAR_EXPR) values (l_tmpl,'CUBEAGG','by_mi');
  insert into ASHA_CUBE_SESS_TMPL_PARS (TMPL_ID,TMPL_PAR_NM,TMPL_PAR_EXPR) values (l_tmpl,'INST_ID','-1');
  insert into ASHA_CUBE_SESS_TMPL_PARS (TMPL_ID,TMPL_PAR_NM,TMPL_PAR_EXPR) values (l_tmpl,'START_DT',null);
  insert into ASHA_CUBE_SESS_TMPL_PARS (TMPL_ID,TMPL_PAR_NM,TMPL_PAR_EXPR) values (l_tmpl,'END_DT',null);
  insert into ASHA_CUBE_SESS_TMPL_PARS (TMPL_ID,TMPL_PAR_NM,TMPL_PAR_EXPR) values (l_tmpl,'METRIC_ID','2144');
  insert into ASHA_CUBE_SESS_TMPL_PARS (TMPL_ID,TMPL_PAR_NM,TMPL_PAR_EXPR) values (l_tmpl,'METRICGROUP_ID','2');
  insert into ASHA_CUBE_SESS_TMPL_PARS (TMPL_ID,TMPL_PAR_NM,TMPL_PAR_EXPR) values (l_tmpl,'METRICAGG','AVG');
  insert into ASHA_CUBE_SESS_TMPL_PARS (TMPL_ID,TMPL_PAR_NM,TMPL_PAR_EXPR) values (l_tmpl,'FILTER',null);
  insert into ASHA_CUBE_SESS_TMPL_PARS (TMPL_ID,TMPL_PAR_NM,TMPL_PAR_EXPR) values (l_tmpl,'DUMP_ID',null);
  insert into ASHA_CUBE_SESS_TMPL_PARS (TMPL_ID,TMPL_PAR_NM,TMPL_PAR_EXPR) values (l_tmpl,'BLOCKANALYZE','N');
  insert into ASHA_CUBE_SESS_TMPL_PARS (TMPL_ID,TMPL_PAR_NM,TMPL_PAR_EXPR) values (l_tmpl,'UNKNOWNANALYZE','N');
  insert into ASHA_CUBE_SESS_TMPL_PARS (TMPL_ID,TMPL_PAR_NM,TMPL_PAR_EXPR) values (l_tmpl,'MONITOR','N');
  insert into ASHA_CUBE_SESS_TMPL_PARS (TMPL_ID,TMPL_PAR_NM,TMPL_PAR_EXPR) values (l_tmpl,'TOP_SESS','N');
  insert into ASHA_CUBE_SESS_TMPL_PARS (TMPL_ID,TMPL_PAR_NM,TMPL_PAR_EXPR) values (l_tmpl,'DATE_INTERVAL','60');
  
  INSERT INTO asha_cube_sess_tmpl (tmpl_id,tmpl_proj_id,tmpl_name,tmpl_description,tmpl_created) 
       VALUES (default,null,'All ASH available','Set parameters to show all ASH available',default) returning tmpl_id into l_tmpl;
  insert into ASHA_CUBE_SESS_TMPL_PARS (TMPL_ID,TMPL_PAR_NM,TMPL_PAR_EXPR) values (l_tmpl,'SOURCE','V$VIEW');
  insert into ASHA_CUBE_SESS_TMPL_PARS (TMPL_ID,TMPL_PAR_NM,TMPL_PAR_EXPR) values (l_tmpl,'CUBEAGG','by_mi');
  insert into ASHA_CUBE_SESS_TMPL_PARS (TMPL_ID,TMPL_PAR_NM,TMPL_PAR_EXPR) values (l_tmpl,'INST_ID','-1');
  insert into ASHA_CUBE_SESS_TMPL_PARS (TMPL_ID,TMPL_PAR_NM,TMPL_PAR_EXPR) values (l_tmpl,'START_DT',null);
  insert into ASHA_CUBE_SESS_TMPL_PARS (TMPL_ID,TMPL_PAR_NM,TMPL_PAR_EXPR) values (l_tmpl,'END_DT',null);
  insert into ASHA_CUBE_SESS_TMPL_PARS (TMPL_ID,TMPL_PAR_NM,TMPL_PAR_EXPR) values (l_tmpl,'METRIC_ID','2144');
  insert into ASHA_CUBE_SESS_TMPL_PARS (TMPL_ID,TMPL_PAR_NM,TMPL_PAR_EXPR) values (l_tmpl,'METRICGROUP_ID','2');
  insert into ASHA_CUBE_SESS_TMPL_PARS (TMPL_ID,TMPL_PAR_NM,TMPL_PAR_EXPR) values (l_tmpl,'METRICAGG','AVG');
  insert into ASHA_CUBE_SESS_TMPL_PARS (TMPL_ID,TMPL_PAR_NM,TMPL_PAR_EXPR) values (l_tmpl,'FILTER',null);
  insert into ASHA_CUBE_SESS_TMPL_PARS (TMPL_ID,TMPL_PAR_NM,TMPL_PAR_EXPR) values (l_tmpl,'DUMP_ID',null);
  insert into ASHA_CUBE_SESS_TMPL_PARS (TMPL_ID,TMPL_PAR_NM,TMPL_PAR_EXPR) values (l_tmpl,'BLOCKANALYZE','N');
  insert into ASHA_CUBE_SESS_TMPL_PARS (TMPL_ID,TMPL_PAR_NM,TMPL_PAR_EXPR) values (l_tmpl,'UNKNOWNANALYZE','N');
  insert into ASHA_CUBE_SESS_TMPL_PARS (TMPL_ID,TMPL_PAR_NM,TMPL_PAR_EXPR) values (l_tmpl,'MONITOR','N');
  insert into ASHA_CUBE_SESS_TMPL_PARS (TMPL_ID,TMPL_PAR_NM,TMPL_PAR_EXPR) values (l_tmpl,'TOP_SESS','N');
  insert into ASHA_CUBE_SESS_TMPL_PARS (TMPL_ID,TMPL_PAR_NM,TMPL_PAR_EXPR) values (l_tmpl,'DATE_INTERVAL','-1');
end;
/
commit;

@@load_stats