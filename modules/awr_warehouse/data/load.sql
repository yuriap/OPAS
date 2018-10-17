INSERT INTO opas_config (modname,cgroup,ckey,cvalue,descr) VALUES ('&MODNM.','RETENTION','PROJECTRETENTION',    30,'Retention time in days for AWR WareHouse projects.');
INSERT INTO opas_config (modname,cgroup,ckey,cvalue,descr) VALUES ('&MODNM.','RETENTION','REPORTRETENTION',     10,'Retention time in days for AWR WareHouse reports.');

INSERT INTO opas_config (modname,cgroup,ckey,cvalue,descr) VALUES ('&MODNM.','WAREHOUSE','WORKDIR',     upper('&dirname.'),'Oracle directory for loading AWR dumps');
INSERT INTO opas_config (modname,cgroup,ckey,cvalue,descr) VALUES ('&MODNM.','WAREHOUSE','AWRSTGUSER',  '&AWRSTG.','Staging user for AWR Load package');
INSERT INTO opas_config (modname,cgroup,ckey,cvalue,descr) VALUES ('&MODNM.','WAREHOUSE','AWRSTGTBLSPS','&tblspc_name.','Default tablespace for AWR staging user');
INSERT INTO opas_config (modname,cgroup,ckey,cvalue,descr) VALUES ('&MODNM.','WAREHOUSE','AWRSTGTMP',   'TEMP','Temporary tablespace for AWR staging user');
INSERT INTO opas_config (modname,cgroup,ckey,cvalue,descr) VALUES ('&MODNM.','WAREHOUSE','DBLINK',      '&DBLINK.','DB link name for remote AWR repository');

commit;

set define off
set serveroutput on

declare
  l_script clob := 
q'^
@@../scripts/_getplanawrh
^';
begin
  delete from opas_scripts where script_id='GETAWRSQLREPORT';
  insert into opas_scripts (script_id,script_content) values ('GETAWRSQLREPORT','&MODNM.',l_script);
end;
/

declare
  l_script clob := 
q'^
@@../scripts/_getcomph.sql
^';
begin
  delete from opas_scripts where script_id='GETCOMPREPORT';
  insert into opas_scripts (script_id,script_content) values ('GETCOMPREPORT','&MODNM.',l_script||l_script1);
  dbms_output.put_line('#1: '||dbms_lob.getlength(l_script)||' bytes; #2: '||dbms_lob.getlength(l_script1)||' bytes;');
end;
/

declare
  l_script clob;
begin
  l_script := 
q'^
@@../scripts/__prn_tbl_html.sql
^';
  delete from opas_scripts where script_id='PROC_PRNHTMLTBL';
  insert into opas_scripts (script_id,script_content) values ('PROC_PRNHTMLTBL','&MODNM.',l_script);

  l_script := 
q'^
@@../scripts/__getftxt.sql
^';
  delete from opas_scripts where script_id='PROC_GETGTXT';
  insert into opas_scripts (script_id,script_content) values ('PROC_GETGTXT','&MODNM.',l_script);

  l_script := 
q'^
@@../scripts/__nonshared1.sql
^';
  delete from opas_scripts where script_id='PROC_NON_SHARED';
  insert into opas_scripts (script_id,script_content) values ('PROC_NON_SHARED','&MODNM.',l_script);

  l_script := 
q'^
@@../scripts/__vsql_stat.sql
^';
  delete from opas_scripts where script_id='PROC_VSQL_STAT';
  insert into opas_scripts (script_id,script_content) values ('PROC_VSQL_STAT','&MODNM.',l_script);

  l_script := 
q'^
@@../scripts/__offload_percent1.sql
^';
  delete from opas_scripts where script_id='PROC_OFFLOAD_PCT1';
  insert into opas_scripts (script_id,script_content) values ('PROC_OFFLOAD_PCT1','&MODNM.',l_script);
  
  l_script := 
q'^
@@../scripts/__offload_percent2.sql
^';
  delete from opas_scripts where script_id='PROC_OFFLOAD_PCT2';
  insert into opas_scripts (script_id,script_content) values ('PROC_OFFLOAD_PCT2','&MODNM.',l_script);
  
  l_script := 
q'^
@@../scripts/__sqlmon1.sql
^';
  delete from opas_scripts where script_id='PROC_SQLMON';
  insert into opas_scripts (script_id,script_content) values ('PROC_SQLMON','&MODNM.',l_script);

  l_script := 
q'^
@@../scripts/__sqlwarea.sql
^';
  delete from opas_scripts where script_id='PROC_SQLWORKAREA';
  insert into opas_scripts (script_id,script_content) values ('PROC_SQLWORKAREA','&MODNM.',l_script);

  l_script := 
q'^
@@../scripts/__optenv.sql
^';
  delete from opas_scripts where script_id='PROC_OPTENV';
  insert into opas_scripts (script_id,script_content) values ('PROC_OPTENV','&MODNM.',l_script);

  l_script := 
q'^
@@../scripts/__rac_plans.sql
^';
  delete from opas_scripts where script_id='PROC_RACPLAN';
  insert into opas_scripts (script_id,script_content) values ('PROC_RACPLAN','&MODNM.',l_script);

  l_script := 
q'^
@@../scripts/__sqlmon_hist.sql
^';
  delete from opas_scripts where script_id='PROC_SQLMON_HIST';
  insert into opas_scripts (script_id,script_content) values ('PROC_SQLMON_HIST','&MODNM.',l_script);
end;
/

declare
  l_script clob;
begin
  l_script :=
q'{
@@../scripts/__sqlstat.sql
}';
  delete from opas_scripts where script_id='PROC_AWRSQLSTAT';
  insert into opas_scripts (script_id,script_content) values ('PROC_AWRSQLSTAT','&MODNM.',l_script);
  
  l_script := 
q'[
@@../scripts/__ash_summ
]';
  delete from opas_scripts where script_id='PROC_AWRASHSUMM';
  insert into opas_scripts (script_id,script_content) values ('PROC_AWRASHSUMM','&MODNM.',l_script);

  l_script := 
q'[
@@../scripts/__ash_p1
]';
  delete from opas_scripts where script_id='PROC_AWRASHP1';
  insert into opas_scripts (script_id,script_content) values ('PROC_AWRASHP1','&MODNM.',l_script);

  l_script := 
q'[
@@../scripts/__ash_p1_1
]';
  delete from opas_scripts where script_id='PROC_AWRASHP1_1';
  insert into opas_scripts (script_id,script_content) values ('PROC_AWRASHP1_1','&MODNM.',l_script);

  l_script := 
q'[
@@../scripts/__ash_p2
]';
  delete from opas_scripts where script_id='PROC_AWRASHP2';
  insert into opas_scripts (script_id,script_content) values ('PROC_AWRASHP2','&MODNM.',l_script);

  l_script := 
q'[
@@../scripts/__ash_p3
]';
  delete from opas_scripts where script_id='PROC_AWRASHP3';
  insert into opas_scripts (script_id,script_content) values ('PROC_AWRASHP3','&MODNM.',l_script);
  l_script := 
q'[
@@../scripts/awr.css
]';
  delete from opas_scripts where script_id='PROC_AWRCSS';
  insert into opas_scripts (script_id,script_content) values ('PROC_AWRCSS','&MODNM.',l_script);  
end;
/

set define on
commit;
