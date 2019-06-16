declare
 l_tmpl asha_cube_sess_tmpl.tmpl_id%type;
begin
  delete from asha_cube_sess_tmpl;

  INSERT INTO asha_cube_sess_tmpl (tmpl_id,tmpl_proj_id,tmpl_name,tmpl_description,tmpl_created, tmpl_base) 
       VALUES (default,null,'Base template','All parameters with default values',default, 'Y') returning tmpl_id into l_tmpl;
  insert into ASHA_CUBE_SESS_TMPL_PARS (TMPL_ID,TMPL_PAR_NM,TMPL_PAR_EXPR) values (l_tmpl,'SOURCE','V$VIEW');
  insert into ASHA_CUBE_SESS_TMPL_PARS (TMPL_ID,TMPL_PAR_NM,TMPL_PAR_EXPR) values (l_tmpl,'CUBEAGG','by_mi');
  insert into ASHA_CUBE_SESS_TMPL_PARS (TMPL_ID,TMPL_PAR_NM,TMPL_PAR_EXPR) values (l_tmpl,'INST_ID','-1');
  insert into ASHA_CUBE_SESS_TMPL_PARS (TMPL_ID,TMPL_PAR_NM,TMPL_PAR_EXPR) values (l_tmpl,'START_DT',null);
  insert into ASHA_CUBE_SESS_TMPL_PARS (TMPL_ID,TMPL_PAR_NM,TMPL_PAR_EXPR) values (l_tmpl,'END_DT',null);
  insert into ASHA_CUBE_SESS_TMPL_PARS (TMPL_ID,TMPL_PAR_NM,TMPL_PAR_EXPR) values (l_tmpl,'METRIC_ID','2144');
  insert into ASHA_CUBE_SESS_TMPL_PARS (TMPL_ID,TMPL_PAR_NM,TMPL_PAR_EXPR) values (l_tmpl,'METRICGROUP_ID','2');
  insert into ASHA_CUBE_SESS_TMPL_PARS (TMPL_ID,TMPL_PAR_NM,TMPL_PAR_EXPR) values (l_tmpl,'METRICAGG','AVG');
  insert into ASHA_CUBE_SESS_TMPL_PARS (TMPL_ID,TMPL_PAR_NM,TMPL_PAR_EXPR) values (l_tmpl,'METRIC_TAB',null);   
  insert into ASHA_CUBE_SESS_TMPL_PARS (TMPL_ID,TMPL_PAR_NM,TMPL_PAR_EXPR) values (l_tmpl,'FILTER',null);
  insert into ASHA_CUBE_SESS_TMPL_PARS (TMPL_ID,TMPL_PAR_NM,TMPL_PAR_EXPR) values (l_tmpl,'DUMP_ID',null);
  insert into ASHA_CUBE_SESS_TMPL_PARS (TMPL_ID,TMPL_PAR_NM,TMPL_PAR_EXPR) values (l_tmpl,'BLOCKANALYZE','N');
  insert into ASHA_CUBE_SESS_TMPL_PARS (TMPL_ID,TMPL_PAR_NM,TMPL_PAR_EXPR) values (l_tmpl,'UNKNOWNANALYZE','N');
  insert into ASHA_CUBE_SESS_TMPL_PARS (TMPL_ID,TMPL_PAR_NM,TMPL_PAR_EXPR) values (l_tmpl,'MONITOR','N');
  insert into ASHA_CUBE_SESS_TMPL_PARS (TMPL_ID,TMPL_PAR_NM,TMPL_PAR_EXPR) values (l_tmpl,'TOP_SESS','Y');
  insert into ASHA_CUBE_SESS_TMPL_PARS (TMPL_ID,TMPL_PAR_NM,TMPL_PAR_EXPR) values (l_tmpl,'DATE_INTERVAL',null);
  insert into ASHA_CUBE_SESS_TMPL_PARS (TMPL_ID,TMPL_PAR_NM,TMPL_PAR_EXPR) values (l_tmpl,'SNAP_ASH','N'); 
  insert into ASHA_CUBE_SESS_TMPL_PARS (TMPL_ID,TMPL_PAR_NM,TMPL_PAR_EXPR) values (l_tmpl,'FILTERED_SEPARATLY','N'); 

  insert into ASHA_CUBE_SESS_TMPL_PARS (TMPL_ID,TMPL_PAR_NM,TMPL_PAR_EXPR) values (l_tmpl,'DBID',null); 
  insert into ASHA_CUBE_SESS_TMPL_PARS (TMPL_ID,TMPL_PAR_NM,TMPL_PAR_EXPR) values (l_tmpl,'START_SNAP',null); 
  insert into ASHA_CUBE_SESS_TMPL_PARS (TMPL_ID,TMPL_PAR_NM,TMPL_PAR_EXPR) values (l_tmpl,'END_SNAP',null); 
  
  
  INSERT INTO asha_cube_sess_tmpl (tmpl_id,tmpl_proj_id,tmpl_name,tmpl_description,tmpl_created) 
       VALUES (default,null,'Last 30 minutes','Set parameters to show last 30 minutes of ASH',default) returning tmpl_id into l_tmpl;
  insert into ASHA_CUBE_SESS_TMPL_PARS (TMPL_ID,TMPL_PAR_NM,TMPL_PAR_EXPR) values (l_tmpl,'DATE_INTERVAL','30');
  insert into ASHA_CUBE_SESS_TMPL_PARS (TMPL_ID,TMPL_PAR_NM,TMPL_PAR_EXPR) values (l_tmpl,'METRIC_TAB','2144,2,AVG;2146,2,AVG;');    

  INSERT INTO asha_cube_sess_tmpl (tmpl_id,tmpl_proj_id,tmpl_name,tmpl_description,tmpl_created) 
       VALUES (default,null,'Last 60 minutes','Set parameters to show last 60 minutes of ASH',default) returning tmpl_id into l_tmpl;
  insert into ASHA_CUBE_SESS_TMPL_PARS (TMPL_ID,TMPL_PAR_NM,TMPL_PAR_EXPR) values (l_tmpl,'DATE_INTERVAL','60');
  insert into ASHA_CUBE_SESS_TMPL_PARS (TMPL_ID,TMPL_PAR_NM,TMPL_PAR_EXPR) values (l_tmpl,'METRIC_TAB','2144,2,AVG;2146,2,AVG;'); 

  
  INSERT INTO asha_cube_sess_tmpl (tmpl_id,tmpl_proj_id,tmpl_name,tmpl_description,tmpl_created) 
       VALUES (default,null,'All ASH available','Set parameters to show all ASH available',default) returning tmpl_id into l_tmpl;
  insert into ASHA_CUBE_SESS_TMPL_PARS (TMPL_ID,TMPL_PAR_NM,TMPL_PAR_EXPR) values (l_tmpl,'DATE_INTERVAL','-1');
  
  INSERT INTO asha_cube_sess_tmpl (tmpl_id,tmpl_proj_id,tmpl_name,tmpl_description,tmpl_created) 
       VALUES (default,null,'Snap V$SESS','Makes snaphots of V$SESSION (SE)',default) returning tmpl_id into l_tmpl;
  insert into ASHA_CUBE_SESS_TMPL_PARS (TMPL_ID,TMPL_PAR_NM,TMPL_PAR_EXPR) values (l_tmpl,'MONITOR','Y');
  insert into ASHA_CUBE_SESS_TMPL_PARS (TMPL_ID,TMPL_PAR_NM,TMPL_PAR_EXPR) values (l_tmpl,'DATE_INTERVAL','-1');
  insert into ASHA_CUBE_SESS_TMPL_PARS (TMPL_ID,TMPL_PAR_NM,TMPL_PAR_EXPR) values (l_tmpl,'SNAP_ASH','Y');    
  
  INSERT INTO asha_cube_sess_tmpl (tmpl_id,tmpl_proj_id,tmpl_name,tmpl_description,tmpl_created) 
       VALUES (default,null,'Monitor ASH','Auto refreshed ASH statistics',default) returning tmpl_id into l_tmpl;
  insert into ASHA_CUBE_SESS_TMPL_PARS (TMPL_ID,TMPL_PAR_NM,TMPL_PAR_EXPR) values (l_tmpl,'MONITOR','Y');
  insert into ASHA_CUBE_SESS_TMPL_PARS (TMPL_ID,TMPL_PAR_NM,TMPL_PAR_EXPR) values (l_tmpl,'DATE_INTERVAL','-1');
  
  INSERT INTO asha_cube_sess_tmpl (tmpl_id,tmpl_proj_id,tmpl_name,tmpl_description,tmpl_created) 
       VALUES (default,null,'AWR ASH','AWR ASH statistics for the recent 24 hours',default) returning tmpl_id into l_tmpl;
  insert into ASHA_CUBE_SESS_TMPL_PARS (TMPL_ID,TMPL_PAR_NM,TMPL_PAR_EXPR) values (l_tmpl,'SOURCE','AWR');
  insert into ASHA_CUBE_SESS_TMPL_PARS (TMPL_ID,TMPL_PAR_NM,TMPL_PAR_EXPR) values (l_tmpl,'CUBEAGG','by_hour');
  insert into ASHA_CUBE_SESS_TMPL_PARS (TMPL_ID,TMPL_PAR_NM,TMPL_PAR_EXPR) values (l_tmpl,'DATE_INTERVAL','1440');
  insert into ASHA_CUBE_SESS_TMPL_PARS (TMPL_ID,TMPL_PAR_NM,TMPL_PAR_EXPR) values (l_tmpl,'METRIC_TAB','2144,2,AVG;2146,2,AVG;'); 
end;
/