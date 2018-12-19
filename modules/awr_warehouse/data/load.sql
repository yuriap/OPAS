INSERT INTO opas_config (modname,cgroup,ckey,cvalue,descr) VALUES ('&MODNM.','RETENTION', 'PROJECTRETENTION',     30,'Default retention time in days for AWR WareHouse projects.');
INSERT INTO opas_config (modname,cgroup,ckey,cvalue,descr) VALUES ('&MODNM.','RETENTION', 'DUMPETENTION',         10,'Default retention time in days for AWR WareHouse dump.');
INSERT INTO opas_config (modname,cgroup,ckey,cvalue,descr) VALUES ('&MODNM.','RETENTION', 'AWRPARSEDRETENTION',   30,'Default retention time in days for AWR WareHouse parsed dump.');
INSERT INTO opas_config (modname,cgroup,ckey,cvalue,descr) VALUES ('&MODNM.','RETENTION', 'REPORTRETENTION',      10,'Default retention time in days for AWR WareHouse reports.');
INSERT INTO opas_config (modname,cgroup,ckey,cvalue,descr) VALUES ('&MODNM.','PROCESSING','FILEPROCESSTIMEOUT', 3600,'Default timeout for file processing operations.');

INSERT INTO opas_config (modname,cgroup,ckey,cvalue,descr) VALUES ('&MODNM.','WAREHOUSE','WORKDIR',     upper('&dirname.'),'Oracle directory for loading AWR dumps');
INSERT INTO opas_config (modname,cgroup,ckey,cvalue,descr) VALUES ('&MODNM.','WAREHOUSE','AWRSTGUSER',  '&AWRSTG.','Staging user for AWR Load package');
INSERT INTO opas_config (modname,cgroup,ckey,cvalue,descr) VALUES ('&MODNM.','WAREHOUSE','AWRSTGTBLSPS','&tblspc_name.','Default tablespace for AWR staging user');
INSERT INTO opas_config (modname,cgroup,ckey,cvalue,descr) VALUES ('&MODNM.','WAREHOUSE','AWRSTGTMP',   'TEMP','Temporary tablespace for AWR staging user');
INSERT INTO opas_config (modname,cgroup,ckey,cvalue,descr) VALUES ('&MODNM.','WAREHOUSE','DBLINK',      '&DBLINK.','DB link name for remote AWR repository');


INSERT INTO 
  opas_dictionary (modname,dic_name,val,display_val,sparse1,sparse2,sparse3,dic_ordr)
           VALUES ('&MODNM.','AWRCOMP_SORTORDR','ELAPSED_TIME_DELTA','Sort by Elapsed Time','ela_tot',null,null,1);
           
INSERT INTO 
  opas_dictionary (modname,dic_name,val,display_val,sparse1,sparse2,sparse3,dic_ordr)
           VALUES ('&MODNM.','AWRCOMP_SORTORDR','DISK_READS_DELTA','Sort by Disk Reads','reads_tot',null,null,2);
           
INSERT INTO 
  opas_dictionary (modname,dic_name,val,display_val,sparse1,sparse2,sparse3,dic_ordr)
           VALUES ('&MODNM.','AWRCOMP_SORTORDR','CPU_TIME_DELTA','Sort by CPU time','cpu_tot',null,null,3);
           
INSERT INTO 
  opas_dictionary (modname,dic_name,val,display_val,sparse1,sparse2,sparse3,dic_ordr)
           VALUES ('&MODNM.','AWRCOMP_SORTORDR','BUFFER_GETS_DELTA','Sort by LIO','lio_tot',null,null,4);
		   
commit;

set define off
set serveroutput on

declare
  l_script clob := 
q'^
@@../modules/awr_warehouse/scripts/_getcomph.sql
^';
begin
  delete from opas_scripts where script_id='PROC_GETCOMP';
  insert into opas_scripts (script_id,modname,script_content) values ('PROC_GETCOMP','AWR_WAREHOUSE',l_script||l_script1);  
  COREMOD_REPORT_UTILS.prepare_saved_sql_script (  P_SCRIPT_NAME => 'PROC_GETCOMP');
  dbms_output.put_line('#1: '||dbms_lob.getlength(l_script)||' bytes; #2: '||dbms_lob.getlength(l_script1)||' bytes;');
end;
/  

commit;

set define on


