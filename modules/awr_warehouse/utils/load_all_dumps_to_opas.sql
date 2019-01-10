spool load_all_dumps_to_opas.log
set serveroutput on
variable p_proj_id number                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                          
--create project
declare
  l_name    awrwh_projects.proj_name%type := 'Falcon SVT';
  l_descr   awrwh_projects.PROJ_NOTE%type := q'{Set of Falcon SVT measurement dumps}';
begin
  AWRWH_PROJ_API.create_project(p_proj_name=>l_name,
                                p_owner=>COREMOD_API.gDefaultOwner,
                                p_keep_forever='Y',
                                p_is_public=>'Y',
                                p_proj_id=>:p_proj_id);
  AWRWH_PROJ_API.set_project_crdt(p_proj_id=>:p_proj_id,p_created=>to_date('20171117112827','YYYYMMDDHH24MISS'));
  AWRWH_PROJ_API.set_note(p_proj_id=>:p_proj_id,p_proj_note=>l_descr);
  commit;
  dbms_output.put_line('Project "'||l_name||'" has been created. PROJ_ID='||:p_proj_id);
end;
/                                                                                                                                                                                                                                                              
--                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                      
-- #1                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                   
declare
  l_filename awrwh_dumps.filename%type := 'awrdat_6373_6375.dmp';
  l_dump_description awrwh_dumps.dump_description%type := q'{Nexus build 9.0.8
Duration: Nov  9, 11:23:00 to 12:25:00 EST
\\ftpcn\ftp\Projects\Telus\_General\Performance\Greenfield\Oct_Rel_Result\2017-11-09_20-16-18.tar.gz}';
begin
  AWRWH_FILE_API.load_dump_from_file(p_proj_id=>:p_proj_id,
                                     p_filename=>l_filename,
                                     p_dump_description=>l_dump_description,
                                     p_loaded=>to_date('20171117112829','YYYYMMDDHH24MISS'),
                                     p_dbid=>3781652766,
                                     p_min_snap_id=>6373,
                                     p_max_snap_id=>6375,
                                     p_min_snap_dt=>to_timestamp('20171109111619.099','YYYYMMDDHH24MISS.FF3'),
                                     p_max_snap_dt=>to_timestamp('20171109122345.116','YYYYMMDDHH24MISS.FF3'),
        
p_db_description=>'12.1.0.2.0, devsp095cn.netcracker.com, Linux x86 64-bit',
                                     p_dump_name=>''
                                 );
  commit;
  dbms_output.put_line('Dump "'||l_filename||'" has been loaded into PROJ_ID='||:p_proj_id);
end;
/                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                     
-- #2                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                   
declare
  l_filename awrwh_dumps.filename%type := 'awrdat_6429_6430.dmp';
  l_dump_description awrwh_dumps.dump_description%type := q'{Nexus build 9.0.5
Duration: Nov  7, 09:53:00 to 10:55:00 EST
\\ftpcn\ftp\Projects\Telus\_General\Performance\Greenfield\Oct_Rel_Result\ 2017-11-07_18-53-04.tar.gz}';
begin
  AWRWH_FILE_API.load_dump_from_file(p_proj_id=>:p_proj_id,
                                     p_filename=>l_filename,
                                     p_dump_description=>l_dump_description,
                                     p_loaded=>to_date('20171117112830','YYYYMMDDHH24MISS'),
                                     p_dbid=>3781652766,
                                     p_min_snap_id=>6429,
                                     p_max_snap_id=>6430,
                                     p_min_snap_dt=>to_timestamp('20171107095305.433','YYYYMMDDHH24MISS.FF3'),
                                     p_max_snap_dt=>to_timestamp('20171107105353.435','YYYYMMDDHH24MISS.FF3'),
       
p_db_description=>'12.1.0.2.0, devsp095cn.netcracker.com, Linux x86 64-bit',
                                     p_dump_name=>''
                                 );
  commit;
  dbms_output.put_line('Dump "'||l_filename||'" has been loaded into PROJ_ID='||:p_proj_id);
end;
/                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                     
-- #3                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                   
declare
  l_filename awrwh_dumps.filename%type := 'awrdat_6324_6326.dmp';
  l_dump_description awrwh_dumps.dump_description%type := q'{Results on 8.0.16
Duration: Oct 23 07:01:00 to 08:01:03 EDT
\\Ftp.netcracker.com\ftp\depts\RnD\SystemPerfomance\SVT\Telus\Falcon\2017-10-23_14-55-11.tar.gz}';
begin
  AWRWH_FILE_API.load_dump_from_file(p_proj_id=>:p_proj_id,
                                     p_filename=>l_filename,
                                     p_dump_description=>l_dump_description,
                                     p_loaded=>to_date('20171117112831','YYYYMMDDHH24MISS'),
                                     p_dbid=>3781652766,
                                     p_min_snap_id=>6324,
                                     p_max_snap_id=>6326,
                                     p_min_snap_dt=>to_timestamp('20171023065512.421','YYYYMMDDHH24MISS.FF3'),
                                     p_max_snap_dt=>to_timestamp('20171023080103.512','YYYYMMDDHH24MISS.FF3'),
              
p_db_description=>'12.1.0.2.0, devsp095cn.netcracker.com, Linux x86 64-bit',
                                     p_dump_name=>''
                                 );
  commit;
  dbms_output.put_line('Dump "'||l_filename||'" has been loaded into PROJ_ID='||:p_proj_id);
end;
/                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                     
-- #4                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                   
declare
  l_filename awrwh_dumps.filename%type := 'awrdat_6207_6209.dmp';
  l_dump_description awrwh_dumps.dump_description%type := q'{Nexus build 8.0.6
Oct  6, 08:30:00 to 09:32:00 EDT
\\Ftp.netcracker.com\ftp\depts\RnD\SystemPerfomance\SVT\Telus\Falcon\2017-10-06_16-23-42.tar.gz}';
begin
  AWRWH_FILE_API.load_dump_from_file(p_proj_id=>:p_proj_id,
                                     p_filename=>l_filename,
                                     p_dump_description=>l_dump_description,
                                     p_loaded=>to_date('20171117112833','YYYYMMDDHH24MISS'),
                                     p_dbid=>3781652766,
                                     p_min_snap_id=>6207,
                                     p_max_snap_id=>6209,
                                     p_min_snap_dt=>to_timestamp('20171006082343.760','YYYYMMDDHH24MISS.FF3'),
                                     p_max_snap_dt=>to_timestamp('20171006093030.376','YYYYMMDDHH24MISS.FF3'),
                       
p_db_description=>'12.1.0.2.0,
devsp095cn.netcracker.com, Linux x86 64-bit',
                                     p_dump_name=>''
                                 );
  commit;
  dbms_output.put_line('Dump "'||l_filename||'" has been loaded into PROJ_ID='||:p_proj_id);
end;
/                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                     
-- #5                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                   
declare
  l_filename awrwh_dumps.filename%type := 'awrdat_6086_6087.dmp';
  l_dump_description awrwh_dumps.dump_description%type := q'{From 2017-09-27_11-41-37.tar}';
begin
  AWRWH_FILE_API.load_dump_from_file(p_proj_id=>:p_proj_id,
                                     p_filename=>l_filename,
                                     p_dump_description=>l_dump_description,
                                     p_loaded=>to_date('20171117112834','YYYYMMDDHH24MISS'),
                                     p_dbid=>3781652766,
                                     p_min_snap_id=>6086,
                                     p_max_snap_id=>6087,
                                     p_min_snap_dt=>to_timestamp('20170927034137.560','YYYYMMDDHH24MISS.FF3'),
                                     p_max_snap_dt=>to_timestamp('20170927044810.677','YYYYMMDDHH24MISS.FF3'),
                                     p_db_description=>'12.1.0.2.0, devsp095cn.netcracker.com, Linux x86 64-bit',
                           
p_dump_name=>''
                                 );
  commit;
  dbms_output.put_line('Dump "'||l_filename||'" has been loaded into PROJ_ID='||:p_proj_id);
end;
/                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                       
-- #6                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                   
declare
  l_filename awrwh_dumps.filename%type := 'awrdat_6080_6082.dmp';
  l_dump_description awrwh_dumps.dump_description%type := q'{from 2017-09-21_23-13-02.tar.gz}';
begin
  AWRWH_FILE_API.load_dump_from_file(p_proj_id=>:p_proj_id,
                                     p_filename=>l_filename,
                                     p_dump_description=>l_dump_description,
                                     p_loaded=>to_date('20171117112837','YYYYMMDDHH24MISS'),
                                     p_dbid=>3781652766,
                                     p_min_snap_id=>6080,
                                     p_max_snap_id=>6082,
                                     p_min_snap_dt=>to_timestamp('20170921151303.216','YYYYMMDDHH24MISS.FF3'),
                                     p_max_snap_dt=>to_timestamp('20170921161945.806','YYYYMMDDHH24MISS.FF3'),
                                     p_db_description=>'12.1.0.2.0, devsp095cn.netcracker.com, Linux x86 64-bit',
                        
p_dump_name=>''
                                 );
  commit;
  dbms_output.put_line('Dump "'||l_filename||'" has been loaded into PROJ_ID='||:p_proj_id);
end;
/                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                       
-- #7                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                   
declare
  l_filename awrwh_dumps.filename%type := 'awrdat_6346_6348.dmp';
  l_dump_description awrwh_dumps.dump_description%type := q'{from 2017-10-30_16-03-10.tar.gz}';
begin
  AWRWH_FILE_API.load_dump_from_file(p_proj_id=>:p_proj_id,
                                     p_filename=>l_filename,
                                     p_dump_description=>l_dump_description,
                                     p_loaded=>to_date('20171117130112','YYYYMMDDHH24MISS'),
                                     p_dbid=>3781652766,
                                     p_min_snap_id=>6346,
                                     p_max_snap_id=>6348,
                                     p_min_snap_dt=>to_timestamp('20171030080311.436','YYYYMMDDHH24MISS.FF3'),
                                     p_max_snap_dt=>to_timestamp('20171030091039.196','YYYYMMDDHH24MISS.FF3'),
                                     p_db_description=>'12.1.0.2.0, devsp095cn.netcracker.com, Linux x86 64-bit',
                        
p_dump_name=>''
                                 );
  commit;
  dbms_output.put_line('Dump "'||l_filename||'" has been loaded into PROJ_ID='||:p_proj_id);
end;
/                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                       
-- #8                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                   
declare
  l_filename awrwh_dumps.filename%type := 'awrdat_6550_6552.dmp';
  l_dump_description awrwh_dumps.dump_description%type := q'{build FE: netcracker-2017R9.1.1.FE and MBE: netcracker-2017R9.0.13.BE) Please note that 9.1.1 build is only FE. BE patch is not available
Duration: Nov 22, 06:34:00 to 07:36:00
Results : \\ftpcn\ftp\Projects\Telus\_General\Performance\Greenfield\Oct_Rel_Result\ 2017-11-22_15-26-54.tar.gz}';
begin
  AWRWH_FILE_API.load_dump_from_file(p_proj_id=>:p_proj_id,
                                     p_filename=>l_filename,
                                     p_dump_description=>l_dump_description,
                                     p_loaded=>to_date('20171122174617','YYYYMMDDHH24MISS'),
                                     p_dbid=>3781652766,
                                     p_min_snap_id=>6550,
                                     p_max_snap_id=>6552,
                                                                                                       
p_min_snap_dt=>to_timestamp('20171122062655.118','YYYYMMDDHH24MISS.FF3'),
                                     p_max_snap_dt=>to_timestamp('20171122073457.678','YYYYMMDDHH24MISS.FF3'),
                                     p_db_description=>'12.1.0.2.0, devsp095cn.netcracker.com, Linux x86 64-bit',
                                     p_dump_name=>''
                                 );
  commit;
  dbms_output.put_line('Dump "'||l_filename||'" has been loaded into PROJ_ID='||:p_proj_id);
end;
/                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                       
-- #9                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                   
declare
  l_filename awrwh_dumps.filename%type := 'awrdat_6577_6578.dmp';
  l_dump_description awrwh_dumps.dump_description%type := q'{latest build 9.2.3 and after fix of NCONLPORT-81006
Duration: Nov 24, 13:51:00 to 14:53:00 EST
Results :  \\ftpcn\ftp\Projects\Telus\_General\Performance\Greenfield\Oct_Rel_Result\2017-11-24_22-43-54.tar.gz}';
begin
  AWRWH_FILE_API.load_dump_from_file(p_proj_id=>:p_proj_id,
                                     p_filename=>l_filename,
                                     p_dump_description=>l_dump_description,
                                     p_loaded=>to_date('20171127104440','YYYYMMDDHH24MISS'),
                                     p_dbid=>3781652766,
                                     p_min_snap_id=>6577,
                                     p_max_snap_id=>6578,
                                     p_min_snap_dt=>to_timestamp('20171124134355.378','YYYYMMDDHH24MISS.FF3'),
                                                                          
p_max_snap_dt=>to_timestamp('20171124145125.893','YYYYMMDDHH24MISS.FF3'),
                                     p_db_description=>'12.1.0.2.0, devsp095cn.netcracker.com, Linux x86 64-bit',
                                     p_dump_name=>''
                                 );
  commit;
  dbms_output.put_line('Dump "'||l_filename||'" has been loaded into PROJ_ID='||:p_proj_id);
end;
/                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                      
-- #10                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                  
declare
  l_filename awrwh_dumps.filename%type := 'awrdat_6600_6601.dmp';
  l_dump_description awrwh_dumps.dump_description%type := q'{NaaS Test execution is done
Duration: Dec  1, 09:40:00 to 10:43:00 EST
Results: \\ftpcn\ftp\Projects\Telus\_General\Performance\Greenfield\Oct_Rel_Result\2017-12-01_18-33-05.tar.gz}';
begin
  AWRWH_FILE_API.load_dump_from_file(p_proj_id=>:p_proj_id,
                                     p_filename=>l_filename,
                                     p_dump_description=>l_dump_description,
                                     p_loaded=>to_date('20171204122324','YYYYMMDDHH24MISS'),
                                     p_dbid=>3781652766,
                                     p_min_snap_id=>6600,
                                     p_max_snap_id=>6601,
                                     p_min_snap_dt=>to_timestamp('20171201093306.162','YYYYMMDDHH24MISS.FF3'),
                                                                                                    
p_max_snap_dt=>to_timestamp('20171201104005.060','YYYYMMDDHH24MISS.FF3'),
                                     p_db_description=>'12.1.0.2.0, devsp095cn.netcracker.com, Linux x86 64-bit',
                                     p_dump_name=>''
                                 );
  commit;
  dbms_output.put_line('Dump "'||l_filename||'" has been loaded into PROJ_ID='||:p_proj_id);
end;
/                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                      
-- #11                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                  
declare
  l_filename awrwh_dumps.filename%type := 'awrdat_6959_6961.dmp';
  l_dump_description awrwh_dumps.dump_description%type := q'{Duration : Dec 26, 15:20:00 to 16:22:00 EST
Location : \\ftpcn\ftp\Projects\Telus\_General\Performance\Greenfield\Results_2018\2017-12-27_00-11-36.tar.gz}';
begin
  AWRWH_FILE_API.load_dump_from_file(p_proj_id=>:p_proj_id,
                                     p_filename=>l_filename,
                                     p_dump_description=>l_dump_description,
                                     p_loaded=>to_date('20171227122902','YYYYMMDDHH24MISS'),
                                     p_dbid=>3781652766,
                                     p_min_snap_id=>6959,
                                     p_max_snap_id=>6961,
                                     p_min_snap_dt=>to_timestamp('20171226151137.402','YYYYMMDDHH24MISS.FF3'),
                                     p_max_snap_dt=>to_timestamp('20171226162001.454','YYYYMMDDHH24MISS.FF3'),
                
p_db_description=>'12.1.0.2.0, devsp095cn.netcracker.com, Linux x86 64-bit',
                                     p_dump_name=>''
                                 );
  commit;
  dbms_output.put_line('Dump "'||l_filename||'" has been loaded into PROJ_ID='||:p_proj_id);
end;
/                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                     
-- #12                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                  
declare
  l_filename awrwh_dumps.filename%type := 'awrdat_7334_7336.dmp';
  l_dump_description awrwh_dumps.dump_description%type := q'{Test executed on build netcracker-2018R1.0.13
Duration : Jan 12,  06:26:47  to 07:28:47 EST (devsp095cn disk hung for 2 minutes around 06:37:00)
Location : \\ftpcn\ftp\Projects\Telus\_General\Performance\Greenfield\Results_2018\2018-01-12_15-19-14.tar.gz}';
begin
  AWRWH_FILE_API.load_dump_from_file(p_proj_id=>:p_proj_id,
                                     p_filename=>l_filename,
                                     p_dump_description=>l_dump_description,
                                     p_loaded=>to_date('20180115095918','YYYYMMDDHH24MISS'),
                                     p_dbid=>3781652766,
                                     p_min_snap_id=>7334,
                                     p_max_snap_id=>7336,
                                     p_min_snap_dt=>to_timestamp('20180112061915.289','YYYYMMDDHH24MISS.FF3'),
                          
p_max_snap_dt=>to_timestamp('20180112072826.392','YYYYMMDDHH24MISS.FF3'),
                                     p_db_description=>'12.1.0.2.0, devsp095cn.netcracker.com, Linux x86 64-bit',
                                     p_dump_name=>''
                                 );
  commit;
  dbms_output.put_line('Dump "'||l_filename||'" has been loaded into PROJ_ID='||:p_proj_id);
end;
/                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                      
-- #13                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                  
declare
  l_filename awrwh_dumps.filename%type := 'awrdat_7474_7476.dmp';
  l_dump_description awrwh_dumps.dump_description%type := q'{Regression test execution (without adding new themes for Feb release)
Duration : Jan 22 05:11:00 to 06:13:00 EST(devsp095cn disk hanged during 5:51:00)
Location : \\ftpcn\ftp\Projects\Telus\_General\Performance\Greenfield\Results_2018\2018-01-22_14-03-02.tar.gz}';
begin
  AWRWH_FILE_API.load_dump_from_file(p_proj_id=>:p_proj_id,
                                     p_filename=>l_filename,
                                     p_dump_description=>l_dump_description,
                                     p_loaded=>to_date('20180123141644','YYYYMMDDHH24MISS'),
                                     p_dbid=>3781652766,
                                     p_min_snap_id=>7474,
                                     p_max_snap_id=>7476,
                                     p_min_snap_dt=>to_timestamp('20180122050303.904','YYYYMMDDHH24MISS.FF3'),
                   
p_max_snap_dt=>to_timestamp('20180122061154.061','YYYYMMDDHH24MISS.FF3'),
                                     p_db_description=>'12.1.0.2.0, devsp095cn.netcracker.com, Linux x86 64-bit',
                                     p_dump_name=>''
                                 );
  commit;
  dbms_output.put_line('Dump "'||l_filename||'" has been loaded into PROJ_ID='||:p_proj_id);
end;
/                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                      
-- #14                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                  
declare
  l_filename awrwh_dumps.filename%type := 'awrdat_7670_7671.dmp';
  l_dump_description awrwh_dumps.dump_description%type := q'{2.0.13 build
With -server JVM argument (which come with build installation)
• Duration: Feb 6, 04:47:00 to 05:48:00 EST
• Results: \\ftpcn\ftp\Projects\Telus\_General\Performance\Greenfield\Results_2018\\2018-02-06_13-39-08.tar.gz}';
begin
  AWRWH_FILE_API.load_dump_from_file(p_proj_id=>:p_proj_id,
                                     p_filename=>l_filename,
                                     p_dump_description=>l_dump_description,
                                     p_loaded=>to_date('20180207111815','YYYYMMDDHH24MISS'),
                                     p_dbid=>3781652766,
                                     p_min_snap_id=>7670,
                                     p_max_snap_id=>7671,
                                     p_min_snap_dt=>to_timestamp('20180206043909.947','YYYYMMDDHH24MISS.FF3'),
                                                  
p_max_snap_dt=>to_timestamp('20180206054822.807','YYYYMMDDHH24MISS.FF3'),
                                     p_db_description=>'12.1.0.2.0, devsp095cn.netcracker.com, Linux x86 64-bit',
                                     p_dump_name=>''
                                 );
  commit;
  dbms_output.put_line('Dump "'||l_filename||'" has been loaded into PROJ_ID='||:p_proj_id);
end;
/                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                      
-- #15                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                  
declare
  l_filename awrwh_dumps.filename%type := 'awrdat_7669_7671.dmp';
  l_dump_description awrwh_dumps.dump_description%type := q'{2.0.13 build
removed –server from all app servers and executed test
Duration:  Feb 6, 09:06:00 to 10:08:00 EST
Results: \\ftpcn\ftp\Projects\Telus\_General\Performance\Greenfield\Results_2018\2018-02-06_17-57-14.tar.gz}';
begin
  AWRWH_FILE_API.load_dump_from_file(p_proj_id=>:p_proj_id,
                                     p_filename=>l_filename,
                                     p_dump_description=>l_dump_description,
                                     p_loaded=>to_date('20180207120123','YYYYMMDDHH24MISS'),
                                     p_dbid=>3781652766,
                                     p_min_snap_id=>7669,
                                     p_max_snap_id=>7671,
                                     p_min_snap_dt=>to_timestamp('20180206085715.846','YYYYMMDDHH24MISS.FF3'),
                                                              
p_max_snap_dt=>to_timestamp('20180206100649.479','YYYYMMDDHH24MISS.FF3'),
                                     p_db_description=>'12.1.0.2.0, devsp095cn.netcracker.com, Linux x86 64-bit',
                                     p_dump_name=>''
                                 );
  commit;
  dbms_output.put_line('Dump "'||l_filename||'" has been loaded into PROJ_ID='||:p_proj_id);
end;
/                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                      
-- #16                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                  
declare
  l_filename awrwh_dumps.filename%type := 'awrdat_7980_7982.dmp';
  l_dump_description awrwh_dumps.dump_description%type := q'{Test executed on build netcracker-2018R3.0.8 with HF of NCONLPORT-90398
Duration: Mar  2, 07:14:00  to 08:16:00  EST
Results: \\ftpcn\ftp\Projects\Telus\_General\Performance\Greenfield\Results_2018\2018-03-02_16-03-46.tar.gz}';
begin
  AWRWH_FILE_API.load_dump_from_file(p_proj_id=>:p_proj_id,
                                     p_filename=>l_filename,
                                     p_dump_description=>l_dump_description,
                                     p_loaded=>to_date('20180302172606','YYYYMMDDHH24MISS'),
                                     p_dbid=>3781652766,
                                     p_min_snap_id=>7980,
                                     p_max_snap_id=>7982,
                                     p_min_snap_dt=>to_timestamp('20180302070348.337','YYYYMMDDHH24MISS.FF3'),
                                                        
p_max_snap_dt=>to_timestamp('20180302081444.208','YYYYMMDDHH24MISS.FF3'),
                                     p_db_description=>'12.1.0.2.0, devsp095cn.netcracker.com, Linux x86 64-bit',
                                     p_dump_name=>''
                                 );
  commit;
  dbms_output.put_line('Dump "'||l_filename||'" has been loaded into PROJ_ID='||:p_proj_id);
end;
/                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                      
-- #17                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                  
declare
  l_filename awrwh_dumps.filename%type := 'awrdat_8049_8051.dmp';
  l_dump_description awrwh_dumps.dump_description%type := q'{build 3.0.13
Duration: Mar 13, 6:12 to 6:14 EST
Results: \\ftpcn\ftp\Projects\Telus\_General\Performance\Greenfield\Results_2018\2018-03-13_14-01-47.tar.gz}';
begin
  AWRWH_FILE_API.load_dump_from_file(p_proj_id=>:p_proj_id,
                                     p_filename=>l_filename,
                                     p_dump_description=>l_dump_description,
                                     p_loaded=>to_date('20180314120938','YYYYMMDDHH24MISS'),
                                     p_dbid=>3781652766,
                                     p_min_snap_id=>8049,
                                     p_max_snap_id=>8051,
                                     p_min_snap_dt=>to_timestamp('20180313060148.552','YYYYMMDDHH24MISS.FF3'),
                                     p_max_snap_dt=>to_timestamp('20180313071304.804','YYYYMMDDHH24MISS.FF3'),
              
p_db_description=>'12.1.0.2.0, devsp095cn.netcracker.com, Linux x86 64-bit',
                                     p_dump_name=>''
                                 );
  commit;
  dbms_output.put_line('Dump "'||l_filename||'" has been loaded into PROJ_ID='||:p_proj_id);
end;
/                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                     
-- #18                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                  
declare
  l_filename awrwh_dumps.filename%type := 'awrdat_8050_8051.dmp';
  l_dump_description awrwh_dumps.dump_description%type := q'{after applying HF for NCONLPORT-91981.
Duration: Mar 14, 05:50:00 to 06:52:00 EDT
Results: \\ftpcn\ftp\Projects\Telus\_General\Performance\Greenfield\Results_2018\2018-03-14_13-39-03.tar.gz}';
begin
  AWRWH_FILE_API.load_dump_from_file(p_proj_id=>:p_proj_id,
                                     p_filename=>l_filename,
                                     p_dump_description=>l_dump_description,
                                     p_loaded=>to_date('20180314182247','YYYYMMDDHH24MISS'),
                                     p_dbid=>3781652766,
                                     p_min_snap_id=>8050,
                                     p_max_snap_id=>8051,
                                     p_min_snap_dt=>to_timestamp('20180314053905.108','YYYYMMDDHH24MISS.FF3'),
                                                                                           
p_max_snap_dt=>to_timestamp('20180314065013.461','YYYYMMDDHH24MISS.FF3'),
                                     p_db_description=>'12.1.0.2.0, devsp095cn.netcracker.com, Linux x86 64-bit',
                                     p_dump_name=>''
                                 );
  commit;
  dbms_output.put_line('Dump "'||l_filename||'" has been loaded into PROJ_ID='||:p_proj_id);
end;
/                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                      
-- #19                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                  
declare
  l_filename awrwh_dumps.filename%type := 'awrdat_8095_8097.dmp';
  l_dump_description awrwh_dumps.dump_description%type := q'{Test executed after DB (devsp095cn)  and APP (devsp094cn) servers are moved to  new storage.
Duration: Mar 19, 06:02:00 to 07:04:00  EDT
Results: \\ftpcn\ftp\Projects\Telus\_General\Performance\Greenfield\Results_2018\2018-03-19_14-00-15.tar.gz}';
begin
  AWRWH_FILE_API.load_dump_from_file(p_proj_id=>:p_proj_id,
                                     p_filename=>l_filename,
                                     p_dump_description=>l_dump_description,
                                     p_loaded=>to_date('20180319142854','YYYYMMDDHH24MISS'),
                                     p_dbid=>3781652766,
                                     p_min_snap_id=>8095,
                                     p_max_snap_id=>8097,
                                     p_min_snap_dt=>to_timestamp('20180319060016.645','YYYYMMDDHH24MISS.FF3'),
                                    
p_max_snap_dt=>to_timestamp('20180319070259.434','YYYYMMDDHH24MISS.FF3'),
                                     p_db_description=>'12.1.0.2.0, devsp095cn.netcracker.com, Linux x86 64-bit',
                                     p_dump_name=>''
                                 );
  commit;
  dbms_output.put_line('Dump "'||l_filename||'" has been loaded into PROJ_ID='||:p_proj_id);
end;
/                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                      
-- #20                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                  
declare
  l_filename awrwh_dumps.filename%type := 'awrdat_8051_8052.dmp';
  l_dump_description awrwh_dumps.dump_description%type := q'{Test executed after hardware fix but did not help.
Duration: Mar 21 07:52:00 to 08:54:00 EDT
Results: \\ftpcn\ftp\Projects\Telus\_General\Performance\Greenfield\Results_2018\2018-03-21_15-50-14.tar.gz
After 20 minutes of test, IO Queue length was about 85 and High IOW too. Please see below graphs}';
begin
  AWRWH_FILE_API.load_dump_from_file(p_proj_id=>:p_proj_id,
                                     p_filename=>l_filename,
                                     p_dump_description=>l_dump_description,
                                     p_loaded=>to_date('20180321205512','YYYYMMDDHH24MISS'),
                                     p_dbid=>3781652766,
                                     p_min_snap_id=>8051,
                                     p_max_snap_id=>8052,
                                                                                              
p_min_snap_dt=>to_timestamp('20180321075015.711','YYYYMMDDHH24MISS.FF3'),
                                     p_max_snap_dt=>to_timestamp('20180321085253.358','YYYYMMDDHH24MISS.FF3'),
                                     p_db_description=>'12.1.0.2.0, devsp095cn.netcracker.com, Linux x86 64-bit',
                                     p_dump_name=>''
                                 );
  commit;
  dbms_output.put_line('Dump "'||l_filename||'" has been loaded into PROJ_ID='||:p_proj_id);
end;
/                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                       
-- #21                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                  
declare
  l_filename awrwh_dumps.filename%type := 'awrdat_8050_8052.dmp';
  l_dump_description awrwh_dumps.dump_description%type := q'{after fiber cable was temporary fixed
Duration: Mar 21 16:27:00 to 17:29:00 EDT}';
begin
  AWRWH_FILE_API.load_dump_from_file(p_proj_id=>:p_proj_id,
                                     p_filename=>l_filename,
                                     p_dump_description=>l_dump_description,
                                     p_loaded=>to_date('20180322012218','YYYYMMDDHH24MISS'),
                                     p_dbid=>3781652766,
                                     p_min_snap_id=>8050,
                                     p_max_snap_id=>8052,
                                     p_min_snap_dt=>to_timestamp('20180321162601.528','YYYYMMDDHH24MISS.FF3'),
                                     p_max_snap_dt=>to_timestamp('20180321172728.293','YYYYMMDDHH24MISS.FF3'),
                                     p_db_description=>'12.1.0.2.0,                       
devsp095cn.netcracker.com, Linux x86 64-bit',
                                     p_dump_name=>''
                                 );
  commit;
  dbms_output.put_line('Dump "'||l_filename||'" has been loaded into PROJ_ID='||:p_proj_id);
end;
/                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                    
-- #22                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                  
declare
  l_filename awrwh_dumps.filename%type := 'awrdat_8051_8053.dmp';
  l_dump_description awrwh_dumps.dump_description%type := q'{Duration: Mar 23, 08:06:50 to 09:09:00 EDT
Results: \\ftpcn\ftp\Projects\Telus\_General\Performance\Greenfield\Results_2018\2018-03-23_16-05-20.tar.gz}';
begin
  AWRWH_FILE_API.load_dump_from_file(p_proj_id=>:p_proj_id,
                                     p_filename=>l_filename,
                                     p_dump_description=>l_dump_description,
                                     p_loaded=>to_date('20180323225050','YYYYMMDDHH24MISS'),
                                     p_dbid=>3781652766,
                                     p_min_snap_id=>8051,
                                     p_max_snap_id=>8053,
                                     p_min_snap_dt=>to_timestamp('20180323080521.245','YYYYMMDDHH24MISS.FF3'),
                                     p_max_snap_dt=>to_timestamp('20180323090654.087','YYYYMMDDHH24MISS.FF3'),
                   
p_db_description=>'12.1.0.2.0, devsp095cn.netcracker.com, Linux x86 64-bit',
                                     p_dump_name=>''
                                 );
  commit;
  dbms_output.put_line('Dump "'||l_filename||'" has been loaded into PROJ_ID='||:p_proj_id);
end;
/                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                     
-- #23                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                  
declare
  l_filename awrwh_dumps.filename%type := 'awrdat_8122_8123.dmp';
  l_dump_description awrwh_dumps.dump_description%type := q'{April 2018 release
Duration: Mar 29, 11:40:00 to 12:42:00  EDT
Results: \\ftpcn\ftp\Projects\Telus\_General\Performance\Greenfield\Results_2018\2018-03-29_19-24-44.tar.gz}';
begin
  AWRWH_FILE_API.load_dump_from_file(p_proj_id=>:p_proj_id,
                                     p_filename=>l_filename,
                                     p_dump_description=>l_dump_description,
                                     p_loaded=>to_date('20180329230405','YYYYMMDDHH24MISS'),
                                     p_dbid=>3781652766,
                                     p_min_snap_id=>8122,
                                     p_max_snap_id=>8123,
                                     p_min_snap_dt=>to_timestamp('20180329113919.320','YYYYMMDDHH24MISS.FF3'),
                                                                                                              
p_max_snap_dt=>to_timestamp('20180329124029.571','YYYYMMDDHH24MISS.FF3'),
                                     p_db_description=>'12.1.0.2.0, devsp095cn.netcracker.com, Linux x86 64-bit',
                                     p_dump_name=>''
                                 );
  commit;
  dbms_output.put_line('Dump "'||l_filename||'" has been loaded into PROJ_ID='||:p_proj_id);
end;
/                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                      
-- #24                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                  
declare
  l_filename awrwh_dumps.filename%type := 'awrdat_8145_8146.dmp';
  l_dump_description awrwh_dumps.dump_description%type := q'{DJ only  SVT test
Duration: Apr  5, 08:36:00 to 09:38:00  EDT
Results:   \\ftpcn\ftp\Projects\Telus\_General\Performance\Greenfield\Results_2018\22018-04-05_16-34-55.tar.gz}';
begin
  AWRWH_FILE_API.load_dump_from_file(p_proj_id=>:p_proj_id,
                                     p_filename=>l_filename,
                                     p_dump_description=>l_dump_description,
                                     p_loaded=>to_date('20180406003110','YYYYMMDDHH24MISS'),
                                     p_dbid=>3781652766,
                                     p_min_snap_id=>8145,
                                     p_max_snap_id=>8146,
                                     p_min_snap_dt=>to_timestamp('20180405083456.198','YYYYMMDDHH24MISS.FF3'),
                                                                                                            
p_max_snap_dt=>to_timestamp('20180405093617.722','YYYYMMDDHH24MISS.FF3'),
                                     p_db_description=>'12.1.0.2.0, devsp095cn.netcracker.com, Linux x86 64-bit',
                                     p_dump_name=>''
                                 );
  commit;
  dbms_output.put_line('Dump "'||l_filename||'" has been loaded into PROJ_ID='||:p_proj_id);
end;
/                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                      
-- #25                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                  
declare
  l_filename awrwh_dumps.filename%type := 'awrdat_8142_8143.dmp';
  l_dump_description awrwh_dumps.dump_description%type := q'{DJ+ 50% Workload  test after above adding suggested class file and your log level changes in tbapi and graphql
Duration: Apr  6, 04:51:00 to 05:53:00 EDT
Results: \\ftpcn\ftp\Projects\Telus\_General\Performance\Greenfield\Results_2018\2018-04-06_12-34-51.tar.gz}';
begin
  AWRWH_FILE_API.load_dump_from_file(p_proj_id=>:p_proj_id,
                                     p_filename=>l_filename,
                                     p_dump_description=>l_dump_description,
                                     p_loaded=>to_date('20180406194152','YYYYMMDDHH24MISS'),
                                     p_dbid=>3781652766,
                                     p_min_snap_id=>8142,
                                     p_max_snap_id=>8143,
                                     p_min_snap_dt=>to_timestamp('20180406044954.759','YYYYMMDDHH24MISS.FF3'),
                   
p_max_snap_dt=>to_timestamp('20180406055116.612','YYYYMMDDHH24MISS.FF3'),
                                     p_db_description=>'12.1.0.2.0, devsp095cn.netcracker.com, Linux x86 64-bit',
                                     p_dump_name=>''
                                 );
  commit;
  dbms_output.put_line('Dump "'||l_filename||'" has been loaded into PROJ_ID='||:p_proj_id);
end;
/                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                      
-- #26                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                  
declare
  l_filename awrwh_dumps.filename%type := 'awrdat_8168_8169.dmp';
  l_dump_description awrwh_dumps.dump_description%type := q'{Test (50WL without DJ) after 4.0.17 build installation.
Duration: Apr 19, 10:50:00 to 11:52:00 EDT
Results: \\ftpcn\ftp\Projects\Telus\_General\Performance\Greenfield\Results_2018\2018-04-19_18-34-27.tar.gz}';
begin
  AWRWH_FILE_API.load_dump_from_file(p_proj_id=>:p_proj_id,
                                     p_filename=>l_filename,
                                     p_dump_description=>l_dump_description,
                                     p_loaded=>to_date('20180420154934','YYYYMMDDHH24MISS'),
                                     p_dbid=>3781652766,
                                     p_min_snap_id=>8168,
                                     p_max_snap_id=>8169,
                                     p_min_snap_dt=>to_timestamp('20180419104939.445','YYYYMMDDHH24MISS.FF3'),
                                                                          
p_max_snap_dt=>to_timestamp('20180419115031.252','YYYYMMDDHH24MISS.FF3'),
                                     p_db_description=>'12.1.0.2.0, devsp095cn.netcracker.com, Linux x86 64-bit',
                                     p_dump_name=>''
                                 );
  commit;
  dbms_output.put_line('Dump "'||l_filename||'" has been loaded into PROJ_ID='||:p_proj_id);
end;
/                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                      
-- #27                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                  
declare
  l_filename awrwh_dumps.filename%type := 'awrdat_8168_8170.dmp';
  l_dump_description awrwh_dumps.dump_description%type := q'{2018R4.0.17
Duration: Apr 26, 10:13:0  to 11:15:00 EDT
Results: \\ftpcn\ftp\Projects\Telus_General\Performance\Greenfield\Results_2018\2018-04-26_17-57-27.tar.gz}';
begin
  AWRWH_FILE_API.load_dump_from_file(p_proj_id=>:p_proj_id,
                                     p_filename=>l_filename,
                                     p_dump_description=>l_dump_description,
                                     p_loaded=>to_date('20180430111702','YYYYMMDDHH24MISS'),
                                     p_dbid=>3781652766,
                                     p_min_snap_id=>8168,
                                     p_max_snap_id=>8170,
                                     p_min_snap_dt=>to_timestamp('20180426101245.203','YYYYMMDDHH24MISS.FF3'),
                                     p_max_snap_dt=>to_timestamp('20180426111339.966','YYYYMMDDHH24MISS.FF3'),
        
p_db_description=>'12.1.0.2.0, devsp095cn.netcracker.com, Linux x86 64-bit',
                                     p_dump_name=>''
                                 );
  commit;
  dbms_output.put_line('Dump "'||l_filename||'" has been loaded into PROJ_ID='||:p_proj_id);
end;
/                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                     
-- #28                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                  
declare
  l_filename awrwh_dumps.filename%type := 'awrdat_8231_8232.dmp';
  l_dump_description awrwh_dumps.dump_description%type := q'{Executed test (DJ+50WL) on 4.0.23 build
Duration: Apr 25, 03:16:00 to 4:18:00 EDT
Results: \\ftpcn\ftp\Projects\Telus_General\Performance\Greenfield\Results_2018\2018-04-30_16-44-13.tar.gz}';
begin
  AWRWH_FILE_API.load_dump_from_file(p_proj_id=>:p_proj_id,
                                     p_filename=>l_filename,
                                     p_dump_description=>l_dump_description,
                                     p_loaded=>to_date('20180502115320','YYYYMMDDHH24MISS'),
                                     p_dbid=>3781652766,
                                     p_min_snap_id=>8231,
                                     p_max_snap_id=>8232,
                                     p_min_snap_dt=>to_timestamp('20180430085918.792','YYYYMMDDHH24MISS.FF3'),
                                                                                            
p_max_snap_dt=>to_timestamp('20180430100041.002','YYYYMMDDHH24MISS.FF3'),
                                     p_db_description=>'12.1.0.2.0, devsp095cn.netcracker.com, Linux x86 64-bit',
                                     p_dump_name=>''
                                 );
  commit;
  dbms_output.put_line('Dump "'||l_filename||'" has been loaded into PROJ_ID='||:p_proj_id);
end;
/                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                      
-- #29                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                  
declare
  l_filename awrwh_dumps.filename%type := 'awrdat_8404_8405.dmp';
  l_dump_description awrwh_dumps.dump_description%type := q'{Duration: May 21, 11:58:00 to 13:00:00 EDT
Results: \\ftpcn\ftp\Projects\Telus_General\Performance\Greenfield\Results_2018\2018-05-21_19-41-29.tar.gz}';
begin
  AWRWH_FILE_API.load_dump_from_file(p_proj_id=>:p_proj_id,
                                     p_filename=>l_filename,
                                     p_dump_description=>l_dump_description,
                                     p_loaded=>to_date('20180522104748','YYYYMMDDHH24MISS'),
                                     p_dbid=>3781652766,
                                     p_min_snap_id=>8404,
                                     p_max_snap_id=>8405,
                                     p_min_snap_dt=>to_timestamp('20180521115709.457','YYYYMMDDHH24MISS.FF3'),
                                     p_max_snap_dt=>to_timestamp('20180521125830.172','YYYYMMDDHH24MISS.FF3'),
                    
p_db_description=>'12.1.0.2.0, devsp095cn.netcracker.com, Linux x86 64-bit',
                                     p_dump_name=>''
                                 );
  commit;
  dbms_output.put_line('Dump "'||l_filename||'" has been loaded into PROJ_ID='||:p_proj_id);
end;
/                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                     
-- #30                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                  
declare
  l_filename awrwh_dumps.filename%type := 'awrdat_8404_8406.dmp';
  l_dump_description awrwh_dumps.dump_description%type := q'{applied HF •	https://tms.netcracker.com/browse/NCONLPORT-100560.
Duration: May 22, 11:05:00 to 12:06:00 EDT
Results: \\ftpcn\ftp\Projects\Telus_General\Performance\Greenfield\Results_2018\2018-05-22_18-50-12.tar.gz}';
begin
  AWRWH_FILE_API.load_dump_from_file(p_proj_id=>:p_proj_id,
                                     p_filename=>l_filename,
                                     p_dump_description=>l_dump_description,
                                     p_loaded=>to_date('20180523092945','YYYYMMDDHH24MISS'),
                                     p_dbid=>3781652766,
                                     p_min_snap_id=>8404,
                                     p_max_snap_id=>8406,
                                     p_min_snap_dt=>to_timestamp('20180522110546.346','YYYYMMDDHH24MISS.FF3'),
                                                                  
p_max_snap_dt=>to_timestamp('20180522120707.537','YYYYMMDDHH24MISS.FF3'),
                                     p_db_description=>'12.1.0.2.0, devsp095cn.netcracker.com, Linux x86 64-bit',
                                     p_dump_name=>''
                                 );
  commit;
  dbms_output.put_line('Dump "'||l_filename||'" has been loaded into PROJ_ID='||:p_proj_id);
end;
/                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                      
-- #31                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                  
declare
  l_filename awrwh_dumps.filename%type := 'awrdat_8432_8433.dmp';
  l_dump_description awrwh_dumps.dump_description%type := q'{build 5.0.23 (HF for NCONLPORT-100560 was part of build)
Duration: May 29, 10:40:00 to 11:42:00 EDT
Results: \\ftpcn\ftp\Projects\Telus_General\Performance\Greenfield\Results_2018\2018-05-29_18-22-16.tar.gz}';
begin
  AWRWH_FILE_API.load_dump_from_file(p_proj_id=>:p_proj_id,
                                     p_filename=>l_filename,
                                     p_dump_description=>l_dump_description,
                                     p_loaded=>to_date('20180530105555','YYYYMMDDHH24MISS'),
                                     p_dbid=>3781652766,
                                     p_min_snap_id=>8432,
                                     p_max_snap_id=>8433,
                                     p_min_snap_dt=>to_timestamp('20180529103759.787','YYYYMMDDHH24MISS.FF3'),
                                                                          
p_max_snap_dt=>to_timestamp('20180529113927.286','YYYYMMDDHH24MISS.FF3'),
                                     p_db_description=>'12.1.0.2.0, devsp095cn.netcracker.com, Linux x86 64-bit',
                                     p_dump_name=>''
                                 );
  commit;
  dbms_output.put_line('Dump "'||l_filename||'" has been loaded into PROJ_ID='||:p_proj_id);
end;
/                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                      
-- #32                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                  
declare
  l_filename awrwh_dumps.filename%type := 'awrdat_8436_8438.dmp';
  l_dump_description awrwh_dumps.dump_description%type := q'{Test with 30% WL on build 5.0.23
Duration: May 31, 11:30:00 to 12:032:00  EDT
Results: \\ftpcn\ftp\Projects\Telus\_General\Performance\Greenfield\Results_2018\2018-05-31_19-14-03.tar.gz}';
begin
  AWRWH_FILE_API.load_dump_from_file(p_proj_id=>:p_proj_id,
                                     p_filename=>l_filename,
                                     p_dump_description=>l_dump_description,
                                     p_loaded=>to_date('20180601133032','YYYYMMDDHH24MISS'),
                                     p_dbid=>null,
                                     p_min_snap_id=>null,
                                     p_max_snap_id=>null,
                                     p_min_snap_dt=>null,
                                     p_max_snap_dt=>null,
                                     p_db_description=>'',
                                     
p_dump_name=>''
                                 );
  commit;
  dbms_output.put_line('Dump "'||l_filename||'" has been loaded into PROJ_ID='||:p_proj_id);
end;
/                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                       
-- #33                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                  
declare
  l_filename awrwh_dumps.filename%type := 'awrdat_8463_8465.dmp';
  l_dump_description awrwh_dumps.dump_description%type := q'{Test with 50% WL on build 7.0.4 .
Duration: Jun  8, 10:16:00 to 11:18:00 EDT
Results: \\ftpcn\ftp\Projects\Telus\_General\Performance\Greenfield\Results_2018\2018-06-08_17-58-50.tar.gz}';
begin
  AWRWH_FILE_API.load_dump_from_file(p_proj_id=>:p_proj_id,
                                     p_filename=>l_filename,
                                     p_dump_description=>l_dump_description,
                                     p_loaded=>to_date('20180618164844','YYYYMMDDHH24MISS'),
                                     p_dbid=>3781652766,
                                     p_min_snap_id=>8463,
                                     p_max_snap_id=>8465,
                                     p_min_snap_dt=>to_timestamp('20180608101423.880','YYYYMMDDHH24MISS.FF3'),
                                                                                                
p_max_snap_dt=>to_timestamp('20180608111536.858','YYYYMMDDHH24MISS.FF3'),
                                     p_db_description=>'12.1.0.2.0, devsp095cn.netcracker.com, Linux x86 64-bit',
                                     p_dump_name=>''
                                 );
  commit;
  dbms_output.put_line('Dump "'||l_filename||'" has been loaded into PROJ_ID='||:p_proj_id);
end;
/                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                      
-- #34                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                  
declare
  l_filename awrwh_dumps.filename%type := 'awrdat_8465_8467.dmp';
  l_dump_description awrwh_dumps.dump_description%type := q'{Test with 100% WL on build 7.0.4 and RDB calcs ON
Duration. Jun 18, 06:29:00 to 07:31:00  EDT
Results: \\ftpcn\ftp\Projects\Telus\_General\Performance\Greenfield\Results_2018\2018-06-18_14-10-38.tar.gz}';
begin
  AWRWH_FILE_API.load_dump_from_file(p_proj_id=>:p_proj_id,
                                     p_filename=>l_filename,
                                     p_dump_description=>l_dump_description,
                                     p_loaded=>to_date('20180618170445','YYYYMMDDHH24MISS'),
                                     p_dbid=>3781652766,
                                     p_min_snap_id=>8465,
                                     p_max_snap_id=>8467,
                                     p_min_snap_dt=>to_timestamp('20180618062814.767','YYYYMMDDHH24MISS.FF3'),
                                                                               
p_max_snap_dt=>to_timestamp('20180618072949.506','YYYYMMDDHH24MISS.FF3'),
                                     p_db_description=>'12.1.0.2.0, devsp095cn.netcracker.com, Linux x86 64-bit',
                                     p_dump_name=>''
                                 );
  commit;
  dbms_output.put_line('Dump "'||l_filename||'" has been loaded into PROJ_ID='||:p_proj_id);
end;
/                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                      
-- #35                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                  
declare
  l_filename awrwh_dumps.filename%type := 'awrdat_8465_8467_1.dmp';
  l_dump_description awrwh_dumps.dump_description%type := q'{Todays test results (100%WL)
Duration: 4:11:00 to 5:13:00 EDT
2018-06-19_11-54-35.tar.gz}';
begin
  AWRWH_FILE_API.load_dump_from_file(p_proj_id=>:p_proj_id,
                                     p_filename=>l_filename,
                                     p_dump_description=>l_dump_description,
                                     p_loaded=>to_date('20180619185453','YYYYMMDDHH24MISS'),
                                     p_dbid=>3781652766,
                                     p_min_snap_id=>8465,
                                     p_max_snap_id=>8467,
                                     p_min_snap_dt=>to_timestamp('20180619040953.401','YYYYMMDDHH24MISS.FF3'),
                                     p_max_snap_dt=>to_timestamp('20180619051128.109','YYYYMMDDHH24MISS.FF3'),
                                     p_db_description=>'12.1.0.2.0,            
devsp095cn.netcracker.com, Linux x86
64-bit',
                                     p_dump_name=>''
                                 );
  commit;
  dbms_output.put_line('Dump "'||l_filename||'" has been loaded into PROJ_ID='||:p_proj_id);
end;
/                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                    
-- #36                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                  
declare
  l_filename awrwh_dumps.filename%type := 'awrdat_8492_8494.dmp';
  l_dump_description awrwh_dumps.dump_description%type := q'{2018R7.0.10 Baseline test with 100% WL without RDB jobs
Duration: Jun 21, 10:21:00 11:23:00 EDT
Results: \\ftpcn\ftp\Projects\Telus\_General\Performance\Greenfield\Results_2018\2018-06-21_18-04-06.tar.gz}';
begin
  AWRWH_FILE_API.load_dump_from_file(p_proj_id=>:p_proj_id,
                                     p_filename=>l_filename,
                                     p_dump_description=>l_dump_description,
                                     p_loaded=>to_date('20180622102821','YYYYMMDDHH24MISS'),
                                     p_dbid=>3781652766,
                                     p_min_snap_id=>8492,
                                     p_max_snap_id=>8494,
                                     p_min_snap_dt=>to_timestamp('20180621101934.096','YYYYMMDDHH24MISS.FF3'),
                                                                             
p_max_snap_dt=>to_timestamp('20180621112038.188','YYYYMMDDHH24MISS.FF3'),
                                     p_db_description=>'12.1.0.2.0, devsp095cn.netcracker.com, Linux x86 64-bit',
                                     p_dump_name=>''
                                 );
  commit;
  dbms_output.put_line('Dump "'||l_filename||'" has been loaded into PROJ_ID='||:p_proj_id);
end;
/                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                      
-- #37                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                  
declare
  l_filename awrwh_dumps.filename%type := 'awrdat_8492_8493.dmp';
  l_dump_description awrwh_dumps.dump_description%type := q'{2018R7.0.10 Baseline test with 100% WL without RDB jobs
GraphQL/TBAPI conf changed by NCONLPORT-103076
Duration: Jun 22, 06:40:00 to 07:42:00 EDT
Results: \\ftpcn\ftp\Projects\Telus\_General\Performance\Greenfield\Results_2018\2018-06-22_14-23-44.tar.gz}';
begin
  AWRWH_FILE_API.load_dump_from_file(p_proj_id=>:p_proj_id,
                                     p_filename=>l_filename,
                                     p_dump_description=>l_dump_description,
                                     p_loaded=>to_date('20180622163852','YYYYMMDDHH24MISS'),
                                     p_dbid=>3781652766,
                                     p_min_snap_id=>8492,
                                     p_max_snap_id=>8493,
                                     p_min_snap_dt=>to_timestamp('20180622063910.373','YYYYMMDDHH24MISS.FF3'),
                           
p_max_snap_dt=>to_timestamp('20180622074030.681','YYYYMMDDHH24MISS.FF3'),
                                     p_db_description=>'12.1.0.2.0, devsp095cn.netcracker.com, Linux x86 64-bit',
                                     p_dump_name=>''
                                 );
  commit;
  dbms_output.put_line('Dump "'||l_filename||'" has been loaded into PROJ_ID='||:p_proj_id);
end;
/                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                      
-- #38                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                  
declare
  l_filename awrwh_dumps.filename%type := 'awrdat_8492_8494_1.dmp';
  l_dump_description awrwh_dumps.dump_description%type := q'{Executed 50% WL without RDB jobs on build 7.0.10
Duration: Jun 22 09:10:00 to 10:12:00 EDT
Results: \\ftpcn\ftp\Projects\Telus\_General\Performance\Greenfield\Results_2018\2018-06-22_16-53-41.tar.gz}';
begin
  AWRWH_FILE_API.load_dump_from_file(p_proj_id=>:p_proj_id,
                                     p_filename=>l_filename,
                                     p_dump_description=>l_dump_description,
                                     p_loaded=>to_date('20180625104533','YYYYMMDDHH24MISS'),
                                     p_dbid=>3781652766,
                                     p_min_snap_id=>8492,
                                     p_max_snap_id=>8494,
                                     p_min_snap_dt=>to_timestamp('20180622090912.923','YYYYMMDDHH24MISS.FF3'),
                                                                                
p_max_snap_dt=>to_timestamp('20180622101033.220','YYYYMMDDHH24MISS.FF3'),
                                     p_db_description=>'12.1.0.2.0, devsp095cn.netcracker.com, Linux x86 64-bit',
                                     p_dump_name=>''
                                 );
  commit;
  dbms_output.put_line('Dump "'||l_filename||'" has been loaded into PROJ_ID='||:p_proj_id);
end;
/                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                      
-- #39                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                  
declare
  l_filename awrwh_dumps.filename%type := 'awrdat_8492_8493_1.dmp';
  l_dump_description awrwh_dumps.dump_description%type := q'{Executed 50% WL without RDB jobs on build 7.0.10 with exactly same workload as 7.0.4 (i.e. excluded D2D and NEWT business test cases )
Duration: Jun 26 09:36:01 to 20:38:00 EDT
Results: \\ftpcn\ftp\Projects\Telus\_General\Performance\Greenfield\Results_2018\2018-06-26_17-19-01.tar.gz}';
begin
  AWRWH_FILE_API.load_dump_from_file(p_proj_id=>:p_proj_id,
                                     p_filename=>l_filename,
                                     p_dump_description=>l_dump_description,
                                     p_loaded=>to_date('20180627103752','YYYYMMDDHH24MISS'),
                                     p_dbid=>3781652766,
                                     p_min_snap_id=>8492,
                                     p_max_snap_id=>8493,
                                                                                                         
p_min_snap_dt=>to_timestamp('20180626093422.447','YYYYMMDDHH24MISS.FF3'),
                                     p_max_snap_dt=>to_timestamp('20180626103543.334','YYYYMMDDHH24MISS.FF3'),
                                     p_db_description=>'12.1.0.2.0, devsp095cn.netcracker.com, Linux x86 64-bit',
                                     p_dump_name=>''
                                 );
  commit;
  dbms_output.put_line('Dump "'||l_filename||'" has been loaded into PROJ_ID='||:p_proj_id);
end;
/                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                       
-- #40                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                  
declare
  l_filename awrwh_dumps.filename%type := 'awrdat_8523_8524.dmp';
  l_dump_description awrwh_dumps.dump_description%type := q'{test with 20% WL after changing log level on CSR and SSP (BE log level was already optimum)
Duration:  Jul 30, 07:49:00 to 08:51:00 EDT
SVT results: \\ftpcn\ftp\Projects\Telus_General\Performance\Greenfield\Results_2018\2018-07-30_15-32-42.tar.gz}';
begin
  AWRWH_FILE_API.load_dump_from_file(p_proj_id=>:p_proj_id,
                                     p_filename=>l_filename,
                                     p_dump_description=>l_dump_description,
                                     p_loaded=>to_date('20180803121108','YYYYMMDDHH24MISS'),
                                     p_dbid=>3781652766,
                                     p_min_snap_id=>8523,
                                     p_max_snap_id=>8524,
                                     p_min_snap_dt=>to_timestamp('20180730074825.043','YYYYMMDDHH24MISS.FF3'),
                                
p_max_snap_dt=>to_timestamp('20180730084954.069','YYYYMMDDHH24MISS.FF3'),
                                     p_db_description=>'12.1.0.2.0, devsp095cn.netcracker.com, Linux x86 64-bit',
                                     p_dump_name=>''
                                 );
  commit;
  dbms_output.put_line('Dump "'||l_filename||'" has been loaded into PROJ_ID='||:p_proj_id);
end;
/                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                      
-- #41                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                  
declare
  l_filename awrwh_dumps.filename%type := 'awrdat_8887_8888.dmp';
  l_dump_description awrwh_dumps.dump_description%type := q'{Duration: Oct 23,, 06:52:00 to 07:54:00 EDT
Location:\\ftpcn\ftp\Projects\Telus_General\Performance\Greenfield\Results_2018\2018-10-23_14-34-51.tar.gz
Description: Executed 20WL SVT test on Oct Release Build 11.0.19 with NEW production logging without RDB cal jobs}';
begin
  AWRWH_FILE_API.load_dump_from_file(p_proj_id=>:p_proj_id,
                                     p_filename=>l_filename,
                                     p_dump_description=>l_dump_description,
                                     p_loaded=>to_date('20181105210409','YYYYMMDDHH24MISS'),
                                     p_dbid=>3781652766,
                                     p_min_snap_id=>8887,
                                     p_max_snap_id=>8888,
                                     p_min_snap_dt=>to_timestamp('20181023065135.514','YYYYMMDDHH24MISS.FF3'),
              
p_max_snap_dt=>to_timestamp('20181023075323.047','YYYYMMDDHH24MISS.FF3'),
                                     p_db_description=>'12.1.0.2.0, devsp095cn.netcracker.com, Linux x86 64-bit',
                                     p_dump_name=>'Oct_11.0.19'
                                 );
  commit;
  dbms_output.put_line('Dump "'||l_filename||'" has been loaded into PROJ_ID='||:p_proj_id);
end;
/                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                           
-- #42                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                  
declare
  l_filename awrwh_dumps.filename%type := 'awrdat_8919_8920.dmp';
  l_dump_description awrwh_dumps.dump_description%type := q'{Duration: Nov 2, 8:42:00 to 9:44:00 EDT
Location:\\ftpcn\ftp\Projects\Telus_General\Performance\Greenfield\Results_2018\2018-11-02_16-24-47.tar.gz
Description: Executed 20WL SVT test on Nov Release Build 12.0.8 with NEW production logging without RDB cal jobs}';
begin
  AWRWH_FILE_API.load_dump_from_file(p_proj_id=>:p_proj_id,
                                     p_filename=>l_filename,
                                     p_dump_description=>l_dump_description,
                                     p_loaded=>to_date('20181105211230','YYYYMMDDHH24MISS'),
                                     p_dbid=>3781652766,
                                     p_min_snap_id=>8919,
                                     p_max_snap_id=>8920,
                                     p_min_snap_dt=>to_timestamp('20181102084109.318','YYYYMMDDHH24MISS.FF3'),
                   
p_max_snap_dt=>to_timestamp('20181102094320.573','YYYYMMDDHH24MISS.FF3'),
                                     p_db_description=>'12.1.0.2.0, devsp095cn.netcracker.com, Linux x86 64-bit',
                                     p_dump_name=>'Nov12.0.8'
                                 );
  commit;
  dbms_output.put_line('Dump "'||l_filename||'" has been loaded into PROJ_ID='||:p_proj_id);
end;
/                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                             
-- #43                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                  
declare
  l_filename awrwh_dumps.filename%type := 'awrdat_8852_8854.dmp';
  l_dump_description awrwh_dumps.dump_description%type := q'{Executed 20WL SVT test  (build 9.0.16) with production logging
Duration: Sep  21, 11:05:00 to 11:07:00  EDT
Results: \\ftpcn\ftp\Projects\Telus_General\Performance\Greenfield\Results_2018\2018-09-21_18-47-35.tar.gz}';
begin
  AWRWH_FILE_API.load_dump_from_file(p_proj_id=>:p_proj_id,
                                     p_filename=>l_filename,
                                     p_dump_description=>l_dump_description,
                                     p_loaded=>to_date('20181113105129','YYYYMMDDHH24MISS'),
                                     p_dbid=>3781652766,
                                     p_min_snap_id=>8852,
                                     p_max_snap_id=>8854,
                                     p_min_snap_dt=>to_timestamp('20180921110347.276','YYYYMMDDHH24MISS.FF3'),
                                                                
p_max_snap_dt=>to_timestamp('20180921120556.014','YYYYMMDDHH24MISS.FF3'),
                                     p_db_description=>'12.1.0.2.0, devsp095cn.netcracker.com, Linux x86 64-bit',
                                     p_dump_name=>'Sep_9.0.16_Baseline'
                                 );
  commit;
  dbms_output.put_line('Dump "'||l_filename||'" has been loaded into PROJ_ID='||:p_proj_id);
end;
/                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                   
-- #44                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                  
declare
  l_filename awrwh_dumps.filename%type := 'awrdat_8919_8920_1.dmp';
  l_dump_description awrwh_dumps.dump_description%type := q'{Executed test(20WL)  with  RDB calc jobs running. Please find attached comparison report between 12.0.8 without RDB and with RDB.
2018-11-09_12-30-59.tar.gz}';
begin
  AWRWH_FILE_API.load_dump_from_file(p_proj_id=>:p_proj_id,
                                     p_filename=>l_filename,
                                     p_dump_description=>l_dump_description,
                                     p_loaded=>to_date('20181113105600','YYYYMMDDHH24MISS'),
                                     p_dbid=>3781652766,
                                     p_min_snap_id=>8919,
                                     p_max_snap_id=>8920,
                                     p_min_snap_dt=>to_timestamp('20181109034718.406','YYYYMMDDHH24MISS.FF3'),
                                     p_max_snap_dt=>to_timestamp('20181109044925.326','YYYYMMDDHH24MISS.FF3'),
          
p_db_description=>'12.1.0.2.0, devsp095cn.netcracker.com, Linux x86 64-bit',
                                     p_dump_name=>'Nov_12.0.8_Run2'
                                 );
  commit;
  dbms_output.put_line('Dump "'||l_filename||'" has been loaded into PROJ_ID='||:p_proj_id);
end;
/                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                      
--create project
declare
  l_name    awrwh_projects.proj_name%type := 'Falcon migration 11g-12c';
  l_descr   awrwh_projects.PROJ_NOTE%type := q'{Set of Falcon SVT dumps to evaluate migration from Oracle 11g to 12c}';
begin
  AWRWH_PROJ_API.create_project(p_proj_name=>l_name,
                                p_owner=>COREMOD_API.gDefaultOwner,
                                p_keep_forever='Y',
                                p_is_public=>'Y',
                                p_proj_id=>:p_proj_id);
  AWRWH_PROJ_API.set_project_crdt(p_proj_id=>:p_proj_id,p_created=>to_date('20171117112838','YYYYMMDDHH24MISS'));
  AWRWH_PROJ_API.set_note(p_proj_id=>:p_proj_id,p_proj_note=>l_descr);
  commit;
  dbms_output.put_line('Project "'||l_name||'" has been created. PROJ_ID='||:p_proj_id);
end;
/                                                                                                                                                                                                               
--                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                      
-- #45                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                  
declare
  l_filename awrwh_dumps.filename%type := 'awr_rep_11c_20160722.dmp';
  l_dump_description awrwh_dumps.dump_description%type := q'{11g measurement 2016/07/22}';
begin
  AWRWH_FILE_API.load_dump_from_file(p_proj_id=>:p_proj_id,
                                     p_filename=>l_filename,
                                     p_dump_description=>l_dump_description,
                                     p_loaded=>to_date('20171117112838','YYYYMMDDHH24MISS'),
                                     p_dbid=>3781652766,
                                     p_min_snap_id=>2545,
                                     p_max_snap_id=>2546,
                                     p_min_snap_dt=>to_timestamp('20160722073752.221','YYYYMMDDHH24MISS.FF3'),
                                     p_max_snap_dt=>to_timestamp('20160722083758.027','YYYYMMDDHH24MISS.FF3'),
                                     p_db_description=>'11.2.0.4.0, devsp095cn.netcracker.com, Linux x86 64-bit',
                         
p_dump_name=>''
                                 );
  commit;
  dbms_output.put_line('Dump "'||l_filename||'" has been loaded into PROJ_ID='||:p_proj_id);
end;
/                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                       
-- #46                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                  
declare
  l_filename awrwh_dumps.filename%type := 'awrdat_2504_2506.dmp';
  l_dump_description awrwh_dumps.dump_description%type := q'{12c measurement #1 2016/07/29}';
begin
  AWRWH_FILE_API.load_dump_from_file(p_proj_id=>:p_proj_id,
                                     p_filename=>l_filename,
                                     p_dump_description=>l_dump_description,
                                     p_loaded=>to_date('20171117112839','YYYYMMDDHH24MISS'),
                                     p_dbid=>null,
                                     p_min_snap_id=>null,
                                     p_max_snap_id=>null,
                                     p_min_snap_dt=>null,
                                     p_max_snap_dt=>null,
                                     p_db_description=>'',
                                     p_dump_name=>''
                                 );
  commit;
  dbms_output.put_line('Dump "'||l_filename||'" has been loaded into                          
PROJ_ID='||:p_proj_id);
end;
/                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                          
-- #47                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                  
declare
  l_filename awrwh_dumps.filename%type := '12c_1htest_20160108_2504_2506.dmp';
  l_dump_description awrwh_dumps.dump_description%type := q'{12c measurement #2 2016/08/01}';
begin
  AWRWH_FILE_API.load_dump_from_file(p_proj_id=>:p_proj_id,
                                     p_filename=>l_filename,
                                     p_dump_description=>l_dump_description,
                                     p_loaded=>to_date('20171117112840','YYYYMMDDHH24MISS'),
                                     p_dbid=>3781652766,
                                     p_min_snap_id=>2504,
                                     p_max_snap_id=>2506,
                                     p_min_snap_dt=>to_timestamp('20160801102635.061','YYYYMMDDHH24MISS.FF3'),
                                     p_max_snap_dt=>to_timestamp('20160801112640.312','YYYYMMDDHH24MISS.FF3'),
                                     p_db_description=>'12.1.0.2.0, devsp095cn.netcracker.com, Linux x86 64-bit',
             
p_dump_name=>''
                                 );
  commit;
  dbms_output.put_line('Dump "'||l_filename||'" has been loaded into PROJ_ID='||:p_proj_id);
end;
/                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                       
-- #48                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                  
declare
  l_filename awrwh_dumps.filename%type := 'rdb_11g_1h_backlog_2588_2589.dmp';
  l_dump_description awrwh_dumps.dump_description%type := q'{11g 1 hour RDB backlog}';
begin
  AWRWH_FILE_API.load_dump_from_file(p_proj_id=>:p_proj_id,
                                     p_filename=>l_filename,
                                     p_dump_description=>l_dump_description,
                                     p_loaded=>to_date('20171218095334','YYYYMMDDHH24MISS'),
                                     p_dbid=>null,
                                     p_min_snap_id=>null,
                                     p_max_snap_id=>null,
                                     p_min_snap_dt=>null,
                                     p_max_snap_dt=>null,
                                     p_db_description=>'',
                                     p_dump_name=>''
                                 );
  commit;
  dbms_output.put_line('Dump "'||l_filename||'" has been loaded into                     
PROJ_ID='||:p_proj_id);
end;
/                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                          
-- #49                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                  
declare
  l_filename awrwh_dumps.filename%type := 'rdb_12c_1h_backlog_2504_2505.dmp';
  l_dump_description awrwh_dumps.dump_description%type := q'{12c 1 hour RDB backlog}';
begin
  AWRWH_FILE_API.load_dump_from_file(p_proj_id=>:p_proj_id,
                                     p_filename=>l_filename,
                                     p_dump_description=>l_dump_description,
                                     p_loaded=>to_date('20171218095415','YYYYMMDDHH24MISS'),
                                     p_dbid=>null,
                                     p_min_snap_id=>null,
                                     p_max_snap_id=>null,
                                     p_min_snap_dt=>null,
                                     p_max_snap_dt=>null,
                                     p_db_description=>'',
                                     p_dump_name=>''
                                 );
  commit;
  dbms_output.put_line('Dump "'||l_filename||'" has been loaded into                     
PROJ_ID='||:p_proj_id);
end;
/                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                          
-- #50                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                  
declare
  l_filename awrwh_dumps.filename%type := '11g_full_refill_RDB_2608_2609.dmp';
  l_dump_description awrwh_dumps.dump_description%type := q'{11g full RDB refill run #1}';
begin
  AWRWH_FILE_API.load_dump_from_file(p_proj_id=>:p_proj_id,
                                     p_filename=>l_filename,
                                     p_dump_description=>l_dump_description,
                                     p_loaded=>to_date('20171218095510','YYYYMMDDHH24MISS'),
                                     p_dbid=>null,
                                     p_min_snap_id=>null,
                                     p_max_snap_id=>null,
                                     p_min_snap_dt=>null,
                                     p_max_snap_dt=>null,
                                     p_db_description=>'',
                                     p_dump_name=>''
                                 );
  commit;
  dbms_output.put_line('Dump "'||l_filename||'" has been loaded into                
PROJ_ID='||:p_proj_id);
end;
/                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                          
-- #51                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                  
declare
  l_filename awrwh_dumps.filename%type := '11g_frefill_RDB_v2_2580_2582.dmp';
  l_dump_description awrwh_dumps.dump_description%type := q'{11g full RDB refill run #2}';
begin
  AWRWH_FILE_API.load_dump_from_file(p_proj_id=>:p_proj_id,
                                     p_filename=>l_filename,
                                     p_dump_description=>l_dump_description,
                                     p_loaded=>to_date('20171218095548','YYYYMMDDHH24MISS'),
                                     p_dbid=>null,
                                     p_min_snap_id=>null,
                                     p_max_snap_id=>null,
                                     p_min_snap_dt=>null,
                                     p_max_snap_dt=>null,
                                     p_db_description=>'',
                                     p_dump_name=>''
                                 );
  commit;
  dbms_output.put_line('Dump "'||l_filename||'" has been loaded into                 
PROJ_ID='||:p_proj_id);
end;
/                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                          
-- #52                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                  
declare
  l_filename awrwh_dumps.filename%type := '11g_RDB_CA_jobs_17h_2670_2687.dmp';
  l_dump_description awrwh_dumps.dump_description%type := q'{11g RDB CA jobs}';
begin
  AWRWH_FILE_API.load_dump_from_file(p_proj_id=>:p_proj_id,
                                     p_filename=>l_filename,
                                     p_dump_description=>l_dump_description,
                                     p_loaded=>to_date('20171218095623','YYYYMMDDHH24MISS'),
                                     p_dbid=>null,
                                     p_min_snap_id=>null,
                                     p_max_snap_id=>null,
                                     p_min_snap_dt=>null,
                                     p_max_snap_dt=>null,
                                     p_db_description=>'',
                                     p_dump_name=>''
                                 );
  commit;
  dbms_output.put_line('Dump "'||l_filename||'" has been loaded into                           
PROJ_ID='||:p_proj_id);
end;
/                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                          
-- #53                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                  
declare
  l_filename awrwh_dumps.filename%type := '12c_full_refill_RDB_2498_2499.dmp';
  l_dump_description awrwh_dumps.dump_description%type := q'{12c full RDB refill run #1}';
begin
  AWRWH_FILE_API.load_dump_from_file(p_proj_id=>:p_proj_id,
                                     p_filename=>l_filename,
                                     p_dump_description=>l_dump_description,
                                     p_loaded=>to_date('20171218095704','YYYYMMDDHH24MISS'),
                                     p_dbid=>null,
                                     p_min_snap_id=>null,
                                     p_max_snap_id=>null,
                                     p_min_snap_dt=>null,
                                     p_max_snap_dt=>null,
                                     p_db_description=>'',
                                     p_dump_name=>''
                                 );
  commit;
  dbms_output.put_line('Dump "'||l_filename||'" has been loaded into                
PROJ_ID='||:p_proj_id);
end;
/                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                          
-- #54                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                  
declare
  l_filename awrwh_dumps.filename%type := '12g_frefill_RDB_v2_2583_2585.dmp';
  l_dump_description awrwh_dumps.dump_description%type := q'{12c full RDB refill run #2}';
begin
  AWRWH_FILE_API.load_dump_from_file(p_proj_id=>:p_proj_id,
                                     p_filename=>l_filename,
                                     p_dump_description=>l_dump_description,
                                     p_loaded=>to_date('20171218095749','YYYYMMDDHH24MISS'),
                                     p_dbid=>null,
                                     p_min_snap_id=>null,
                                     p_max_snap_id=>null,
                                     p_min_snap_dt=>null,
                                     p_max_snap_dt=>null,
                                     p_db_description=>'',
                                     p_dump_name=>''
                                 );
  commit;
  dbms_output.put_line('Dump "'||l_filename||'" has been loaded into                 
PROJ_ID='||:p_proj_id);
end;
/                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                          
-- #55                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                  
declare
  l_filename awrwh_dumps.filename%type := '12c_RDB_CA_jobs_17h_2507_2524.dmp';
  l_dump_description awrwh_dumps.dump_description%type := q'{12c RDB CA jobs}';
begin
  AWRWH_FILE_API.load_dump_from_file(p_proj_id=>:p_proj_id,
                                     p_filename=>l_filename,
                                     p_dump_description=>l_dump_description,
                                     p_loaded=>to_date('20171218095814','YYYYMMDDHH24MISS'),
                                     p_dbid=>null,
                                     p_min_snap_id=>null,
                                     p_max_snap_id=>null,
                                     p_min_snap_dt=>null,
                                     p_max_snap_dt=>null,
                                     p_db_description=>'',
                                     p_dump_name=>''
                                 );
  commit;
  dbms_output.put_line('Dump "'||l_filename||'" has been loaded into                           
PROJ_ID='||:p_proj_id);
end;
/                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                          
--create project
declare
  l_name    awrwh_projects.proj_name%type := 'Demo';
  l_descr   awrwh_projects.PROJ_NOTE%type := q'{Two runs of demo workload test to test all reports}';
begin
  AWRWH_PROJ_API.create_project(p_proj_name=>l_name,
                                p_owner=>COREMOD_API.gDefaultOwner,
                                p_keep_forever='Y',
                                p_is_public=>'Y',
                                p_proj_id=>:p_proj_id);
  AWRWH_PROJ_API.set_project_crdt(p_proj_id=>:p_proj_id,p_created=>to_date('20171117112840','YYYYMMDDHH24MISS'));
  AWRWH_PROJ_API.set_note(p_proj_id=>:p_proj_id,p_proj_note=>l_descr);
  commit;
  dbms_output.put_line('Project "'||l_name||'" has been created. PROJ_ID='||:p_proj_id);
end;
/                                                                                                                                                                                                                                                     
--                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                      
-- #56                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                  
declare
  l_filename awrwh_dumps.filename%type := 'awrdat_1987_1988.dmp';
  l_dump_description awrwh_dumps.dump_description%type := q'{Run #1}';
begin
  AWRWH_FILE_API.load_dump_from_file(p_proj_id=>:p_proj_id,
                                     p_filename=>l_filename,
                                     p_dump_description=>l_dump_description,
                                     p_loaded=>to_date('20171117112841','YYYYMMDDHH24MISS'),
                                     p_dbid=>3353856749,
                                     p_min_snap_id=>1987,
                                     p_max_snap_id=>1988,
                                     p_min_snap_dt=>to_timestamp('20171005111745.679','YYYYMMDDHH24MISS.FF3'),
                                     p_max_snap_dt=>to_timestamp('20171005112133.839','YYYYMMDDHH24MISS.FF3'),
                                     p_db_description=>'11.2.0.4.0, dbhost64.local, Linux x86 64-bit',
                                     p_dump_name=>''
       
);
  commit;
  dbms_output.put_line('Dump "'||l_filename||'" has been loaded into PROJ_ID='||:p_proj_id);
end;
/                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                        
-- #57                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                  
declare
  l_filename awrwh_dumps.filename%type := 'awrdat_1989_1990.dmp';
  l_dump_description awrwh_dumps.dump_description%type := q'{Run #2}';
begin
  AWRWH_FILE_API.load_dump_from_file(p_proj_id=>:p_proj_id,
                                     p_filename=>l_filename,
                                     p_dump_description=>l_dump_description,
                                     p_loaded=>to_date('20171117112841','YYYYMMDDHH24MISS'),
                                     p_dbid=>3353856749,
                                     p_min_snap_id=>1989,
                                     p_max_snap_id=>1990,
                                     p_min_snap_dt=>to_timestamp('20171005112213.413','YYYYMMDDHH24MISS.FF3'),
                                     p_max_snap_dt=>to_timestamp('20171005112559.400','YYYYMMDDHH24MISS.FF3'),
                                     p_db_description=>'11.2.0.4.0, dbhost64.local, Linux x86 64-bit',
                                     p_dump_name=>''
       
);
  commit;
  dbms_output.put_line('Dump "'||l_filename||'" has been loaded into PROJ_ID='||:p_proj_id);
end;
/                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                        
--create project
declare
  l_name    awrwh_projects.proj_name%type := 'DHL';
  l_descr   awrwh_projects.PROJ_NOTE%type := q'{Data migration}';
begin
  AWRWH_PROJ_API.create_project(p_proj_name=>l_name,
                                p_owner=>COREMOD_API.gDefaultOwner,
                                p_keep_forever='Y',
                                p_is_public=>'Y',
                                p_proj_id=>:p_proj_id);
  AWRWH_PROJ_API.set_project_crdt(p_proj_id=>:p_proj_id,p_created=>to_date('20171215153248','YYYYMMDDHH24MISS'));
  AWRWH_PROJ_API.set_note(p_proj_id=>:p_proj_id,p_proj_note=>l_descr);
  commit;
  dbms_output.put_line('Project "'||l_name||'" has been created. PROJ_ID='||:p_proj_id);
end;
/                                                                                                                                                                                                                                                                                          
--                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                      
-- #58                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                  
declare
  l_filename awrwh_dumps.filename%type := 'awrdat_142353_142453.dmp';
  l_dump_description awrwh_dumps.dump_description%type := q'{US run #1}';
begin
  AWRWH_FILE_API.load_dump_from_file(p_proj_id=>:p_proj_id,
                                     p_filename=>l_filename,
                                     p_dump_description=>l_dump_description,
                                     p_loaded=>to_date('20171215153739','YYYYMMDDHH24MISS'),
                                     p_dbid=>null,
                                     p_min_snap_id=>null,
                                     p_max_snap_id=>null,
                                     p_min_snap_dt=>null,
                                     p_max_snap_dt=>null,
                                     p_db_description=>'',
                                     p_dump_name=>''
                                 );
  commit;
  dbms_output.put_line('Dump "'||l_filename||'" has been loaded into PROJ_ID='||:p_proj_id);
end;
/           
-- #59                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                  
declare
  l_filename awrwh_dumps.filename%type := 'awrdat_145184_145259.dmp';
  l_dump_description awrwh_dumps.dump_description%type := q'{US run #2}';
begin
  AWRWH_FILE_API.load_dump_from_file(p_proj_id=>:p_proj_id,
                                     p_filename=>l_filename,
                                     p_dump_description=>l_dump_description,
                                     p_loaded=>to_date('20171215154802','YYYYMMDDHH24MISS'),
                                     p_dbid=>null,
                                     p_min_snap_id=>null,
                                     p_max_snap_id=>null,
                                     p_min_snap_dt=>null,
                                     p_max_snap_dt=>null,
                                     p_db_description=>'',
                                     p_dump_name=>''
                                 );
  commit;
  dbms_output.put_line('Dump "'||l_filename||'" has been loaded into PROJ_ID='||:p_proj_id);
end;
/           
--create project
declare
  l_name    awrwh_projects.proj_name%type := 'Falcon build installation';
  l_descr   awrwh_projects.PROJ_NOTE%type := q'{Captured builds installation performance}';
begin
  AWRWH_PROJ_API.create_project(p_proj_name=>l_name,
                                p_owner=>COREMOD_API.gDefaultOwner,
                                p_keep_forever='Y',
                                p_is_public=>'Y',
                                p_proj_id=>:p_proj_id);
  AWRWH_PROJ_API.set_project_crdt(p_proj_id=>:p_proj_id,p_created=>to_date('20171218094445','YYYYMMDDHH24MISS'));
  AWRWH_PROJ_API.set_note(p_proj_id=>:p_proj_id,p_proj_note=>l_descr);
  commit;
  dbms_output.put_line('Project "'||l_name||'" has been created. PROJ_ID='||:p_proj_id);
end;
/                                                                                                                                                                                                                                          
--                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                      
-- #60                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                  
declare
  l_filename awrwh_dumps.filename%type := 'awrdat_4892_4896_april2017.dmp';
  l_dump_description awrwh_dumps.dump_description%type := q'{April 2017 build}';
begin
  AWRWH_FILE_API.load_dump_from_file(p_proj_id=>:p_proj_id,
                                     p_filename=>l_filename,
                                     p_dump_description=>l_dump_description,
                                     p_loaded=>to_date('20171218094742','YYYYMMDDHH24MISS'),
                                     p_dbid=>null,
                                     p_min_snap_id=>null,
                                     p_max_snap_id=>null,
                                     p_min_snap_dt=>null,
                                     p_max_snap_dt=>null,
                                     p_db_description=>'',
                                     p_dump_name=>''
                                 );
  commit;
  dbms_output.put_line('Dump "'||l_filename||'" has been loaded into                             
PROJ_ID='||:p_proj_id);
end;
/                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                          
-- #61                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                  
declare
  l_filename awrwh_dumps.filename%type := 'awrdat_4944_4949_may2017.dmp';
  l_dump_description awrwh_dumps.dump_description%type := q'{May 2017 build}';
begin
  AWRWH_FILE_API.load_dump_from_file(p_proj_id=>:p_proj_id,
                                     p_filename=>l_filename,
                                     p_dump_description=>l_dump_description,
                                     p_loaded=>to_date('20171218094807','YYYYMMDDHH24MISS'),
                                     p_dbid=>null,
                                     p_min_snap_id=>null,
                                     p_max_snap_id=>null,
                                     p_min_snap_dt=>null,
                                     p_max_snap_dt=>null,
                                     p_db_description=>'',
                                     p_dump_name=>''
                                 );
  commit;
  dbms_output.put_line('Dump "'||l_filename||'" has been loaded into PROJ_ID='||:p_proj_id);
end;
/  
--create project
declare
  l_name    awrwh_projects.proj_name%type := 'HDS Falcon';
  l_descr   awrwh_projects.PROJ_NOTE%type := q'{Falcon HDS SVT}';
begin
  AWRWH_PROJ_API.create_project(p_proj_name=>l_name,
                                p_owner=>COREMOD_API.gDefaultOwner,
                                p_keep_forever='Y',
                                p_is_public=>'Y',
                                p_proj_id=>:p_proj_id);
  AWRWH_PROJ_API.set_project_crdt(p_proj_id=>:p_proj_id,p_created=>to_date('20180903163200','YYYYMMDDHH24MISS'));
  AWRWH_PROJ_API.set_note(p_proj_id=>:p_proj_id,p_proj_note=>l_descr);
  commit;
  dbms_output.put_line('Project "'||l_name||'" has been created. PROJ_ID='||:p_proj_id);
end;
/                                                                                                                                                                                                                                                                                   
--                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                      
-- #62                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                  
declare
  l_filename awrwh_dumps.filename%type := 'awrdat_8749_8750_baseline.dmp';
  l_dump_description awrwh_dumps.dump_description%type := q'{HDS baseline 2018R9.0.6 20% workload, RDB calcs on
2018-09-03_15-24-01.tar.gz}';
begin
  AWRWH_FILE_API.load_dump_from_file(p_proj_id=>:p_proj_id,
                                     p_filename=>l_filename,
                                     p_dump_description=>l_dump_description,
                                     p_loaded=>to_date('20180903173007','YYYYMMDDHH24MISS'),
                                     p_dbid=>3781652766,
                                     p_min_snap_id=>8749,
                                     p_max_snap_id=>8750,
                                     p_min_snap_dt=>to_timestamp('20180903074009.303','YYYYMMDDHH24MISS.FF3'),
                                     p_max_snap_dt=>to_timestamp('20180903084240.570','YYYYMMDDHH24MISS.FF3'),
                                     p_db_description=>'12.1.0.2.0,               
devsp095cn.netcracker.com, Linux x86 64-bit',
                                     p_dump_name=>'NC_HISTORY moving baseline'
                                 );
  commit;
  dbms_output.put_line('Dump "'||l_filename||'" has been loaded into PROJ_ID='||:p_proj_id);
end;
/                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                          
-- #63                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                  
declare
  l_filename awrwh_dumps.filename%type := 'awrdat_8749_8750.dmp';
  l_dump_description awrwh_dumps.dump_description%type := q'{HDS Job ON, 2018R9.0.6 20% workload, RDB calcs ON
2018-09-03_11-23-43.tar.gz}';
begin
  AWRWH_FILE_API.load_dump_from_file(p_proj_id=>:p_proj_id,
                                     p_filename=>l_filename,
                                     p_dump_description=>l_dump_description,
                                     p_loaded=>to_date('20180903173140','YYYYMMDDHH24MISS'),
                                     p_dbid=>3781652766,
                                     p_min_snap_id=>8749,
                                     p_max_snap_id=>8750,
                                     p_min_snap_dt=>to_timestamp('20180903034115.411','YYYYMMDDHH24MISS.FF3'),
                                     p_max_snap_dt=>to_timestamp('20180903044452.094','YYYYMMDDHH24MISS.FF3'),
                                     p_db_description=>'12.1.0.2.0,                         
devsp095cn.netcracker.com, Linux x86 64-bit',
                                     p_dump_name=>'NC_HISTORY moving run#1'
                                 );
  commit;
  dbms_output.put_line('Dump "'||l_filename||'" has been loaded into PROJ_ID='||:p_proj_id);
end;
/                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                             
-- #64                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                  
declare
  l_filename awrwh_dumps.filename%type := 'awrdat_8823_8824.dmp';
  l_dump_description awrwh_dumps.dump_description%type := q'{20% WL test on build 9.0.10. RDB calcs ON. All HDS jobs #1, #2 and #3 were running one after another during test. 2018-09-11_15-14-14.tar.gz}';
begin
  AWRWH_FILE_API.load_dump_from_file(p_proj_id=>:p_proj_id,
                                     p_filename=>l_filename,
                                     p_dump_description=>l_dump_description,
                                     p_loaded=>to_date('20180912133506','YYYYMMDDHH24MISS'),
                                     p_dbid=>3781652766,
                                     p_min_snap_id=>8823,
                                     p_max_snap_id=>8824,
                                     p_min_snap_dt=>to_timestamp('20180911073300.938','YYYYMMDDHH24MISS.FF3'),
                                     p_max_snap_dt=>to_timestamp('20180911083717.762','YYYYMMDDHH24MISS.FF3'),
                             
p_db_description=>'12.1.0.2.0, devsp095cn.netcracker.com, Linux x86 64-bit',
                                     p_dump_name=>'Run #1 (SVT duration)'
                                 );
  commit;
  dbms_output.put_line('Dump "'||l_filename||'" has been loaded into PROJ_ID='||:p_proj_id);
end;
/                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                
-- #65                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                  
declare
  l_filename awrwh_dumps.filename%type := 'awrdat_8823_8825_full.dmp';
  l_dump_description awrwh_dumps.dump_description%type := q'{20% WL test on build 9.0.10. RDB calcs ON. All HDS jobs #1, #2 and #3 were running one after another during test. 2018-09-11_15-14-14.tar.gz}';
begin
  AWRWH_FILE_API.load_dump_from_file(p_proj_id=>:p_proj_id,
                                     p_filename=>l_filename,
                                     p_dump_description=>l_dump_description,
                                     p_loaded=>to_date('20180912143132','YYYYMMDDHH24MISS'),
                                     p_dbid=>3781652766,
                                     p_min_snap_id=>8823,
                                     p_max_snap_id=>8825,
                                     p_min_snap_dt=>to_timestamp('20180911073300.938','YYYYMMDDHH24MISS.FF3'),
                                     p_max_snap_dt=>to_timestamp('20180911091606.628','YYYYMMDDHH24MISS.FF3'),
                        
p_db_description=>'12.1.0.2.0, devsp095cn.netcracker.com, Linux x86 64-bit',
                                     p_dump_name=>'Run #1 (full duration)'
                                 );
  commit;
  dbms_output.put_line('Dump "'||l_filename||'" has been loaded into PROJ_ID='||:p_proj_id);
end;
/                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                               
-- #66                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                  
declare
  l_filename awrwh_dumps.filename%type := 'awrdat_8822_8824.dmp';
  l_dump_description awrwh_dumps.dump_description%type := q'{Baseline for runs: #1, #2, #4; 
20% WL test on build 9.0.10. RDB calcs ON. 2018-09-12_10-44-36.tar.gz}';
begin
  AWRWH_FILE_API.load_dump_from_file(p_proj_id=>:p_proj_id,
                                     p_filename=>l_filename,
                                     p_dump_description=>l_dump_description,
                                     p_loaded=>to_date('20180912143527','YYYYMMDDHH24MISS'),
                                     p_dbid=>3781652766,
                                     p_min_snap_id=>8822,
                                     p_max_snap_id=>8824,
                                     p_min_snap_dt=>to_timestamp('20180912030437.051','YYYYMMDDHH24MISS.FF3'),
                                     p_max_snap_dt=>to_timestamp('20180912040856.478','YYYYMMDDHH24MISS.FF3'),
                                     p_db_description=>'12.1.0.2.0, 
devsp095cn.netcracker.com, Linux x86 64-bit',
                                     p_dump_name=>'Baseline
 #1'
                                 );
  commit;
  dbms_output.put_line('Dump "'||l_filename||'" has been loaded into PROJ_ID='||:p_proj_id);
end;
/                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                        
-- #67                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                  
declare
  l_filename awrwh_dumps.filename%type := 'awrdat_8822_8824_1.dmp';
  l_dump_description awrwh_dumps.dump_description%type := q'{20% WL test on build 9.0.10. RDB calcs ON. HDS jobs #1 and #2 finished before test, Job #3 was running entirely during SVT workload. 2018-09-12_13-53-46.tar.gz}';
begin
  AWRWH_FILE_API.load_dump_from_file(p_proj_id=>:p_proj_id,
                                     p_filename=>l_filename,
                                     p_dump_description=>l_dump_description,
                                     p_loaded=>to_date('20180912151527','YYYYMMDDHH24MISS'),
                                     p_dbid=>3781652766,
                                     p_min_snap_id=>8822,
                                     p_max_snap_id=>8824,
                                     p_min_snap_dt=>to_timestamp('20180912061457.026','YYYYMMDDHH24MISS.FF3'),
                                     p_max_snap_dt=>to_timestamp('20180912071911.331','YYYYMMDDHH24MISS.FF3'),
        
p_db_description=>'12.1.0.2.0, devsp095cn.netcracker.com, Linux x86 64-bit',
                                     p_dump_name=>'Run #2'
                                 );
  commit;
  dbms_output.put_line('Dump "'||l_filename||'" has been loaded into PROJ_ID='||:p_proj_id);
end;
/                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                               
-- #68                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                  
declare
  l_filename awrwh_dumps.filename%type := 'awrdat_8830_8831.dmp';
  l_dump_description awrwh_dumps.dump_description%type := q'{20% WL test on build 9.0.10. RDB calcs ON. HDS jobs #1, #2 and #3 "TELUS Customer Account Config " were skipped.  Job #3 part "TELUS Process Config" was running entirely during SVT workload. 2018-09-14_11-32-51.tar.gz}';
begin
  AWRWH_FILE_API.load_dump_from_file(p_proj_id=>:p_proj_id,
                                     p_filename=>l_filename,
                                     p_dump_description=>l_dump_description,
                                     p_loaded=>to_date('20180917122136','YYYYMMDDHH24MISS'),
                                     p_dbid=>3781652766,
                                     p_min_snap_id=>8830,
                                     p_max_snap_id=>8831,
                                     p_min_snap_dt=>to_timestamp('20180914035228.084','YYYYMMDDHH24MISS.FF3'),
                                                               
p_max_snap_dt=>to_timestamp('20180914045700.811','YYYYMMDDHH24MISS.FF3'),
                                     p_db_description=>'12.1.0.2.0, devsp095cn.netcracker.com, Linux x86 64-bit',
                                     p_dump_name=>'Run #4'
                                 );
  commit;
  dbms_output.put_line('Dump "'||l_filename||'" has been loaded into PROJ_ID='||:p_proj_id);
end;
/                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                
-- #69                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                  
declare
  l_filename awrwh_dumps.filename%type := 'awrdat_8830_8831_1.dmp';
  l_dump_description awrwh_dumps.dump_description%type := q'{20% WL test on build 9.0.10. RDB calcs ON. HDS jobs #1, #2 were skipped. Job #3 "TELUS Customer Account Config " was running entirely during SVT workload.. 2018-09-14_15-32-49.tar.gz}';
begin
  AWRWH_FILE_API.load_dump_from_file(p_proj_id=>:p_proj_id,
                                     p_filename=>l_filename,
                                     p_dump_description=>l_dump_description,
                                     p_loaded=>to_date('20180917123324','YYYYMMDDHH24MISS'),
                                     p_dbid=>3781652766,
                                     p_min_snap_id=>8830,
                                     p_max_snap_id=>8831,
                                     p_min_snap_dt=>to_timestamp('20180914075220.962','YYYYMMDDHH24MISS.FF3'),
                                                                                                
p_max_snap_dt=>to_timestamp('20180914085738.449','YYYYMMDDHH24MISS.FF3'),
                                     p_db_description=>'12.1.0.2.0, devsp095cn.netcracker.com, Linux x86 64-bit',
                                     p_dump_name=>'Run #5'
                                 );
  commit;
  dbms_output.put_line('Dump "'||l_filename||'" has been loaded into PROJ_ID='||:p_proj_id);
end;
/                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                
-- #70                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                  
declare
  l_filename awrwh_dumps.filename%type := 'awrdat_8830_8832.dmp';
  l_dump_description awrwh_dumps.dump_description%type := q'{Baseline for Run #5: 20% WL test on build 9.0.10. RDB calcs ON. 2018-09-14_18-42-19.tar.gz}';
begin
  AWRWH_FILE_API.load_dump_from_file(p_proj_id=>:p_proj_id,
                                     p_filename=>l_filename,
                                     p_dump_description=>l_dump_description,
                                     p_loaded=>to_date('20180917124217','YYYYMMDDHH24MISS'),
                                     p_dbid=>3781652766,
                                     p_min_snap_id=>8830,
                                     p_max_snap_id=>8832,
                                     p_min_snap_dt=>to_timestamp('20180914110029.662','YYYYMMDDHH24MISS.FF3'),
                                     p_max_snap_dt=>to_timestamp('20180914120448.653','YYYYMMDDHH24MISS.FF3'),
                                     p_db_description=>'12.1.0.2.0,            
devsp095cn.netcracker.com, Linux x86 64-bit',
                                     p_dump_name=>'Run #6 Baseline #2'
                                 );
  commit;
  dbms_output.put_line('Dump "'||l_filename||'" has been loaded into PROJ_ID='||:p_proj_id);
end;
/                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                  
-- #71                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                  
declare
  l_filename awrwh_dumps.filename%type := 'awrdat_8821_8832.dmp';
  l_dump_description awrwh_dumps.dump_description%type := q'{RDB calcs ON. HDS jobs #1, #2, #3 are run to process entirly available data, i.e. 8% of 470K of customers and all 940K processes.}';
begin
  AWRWH_FILE_API.load_dump_from_file(p_proj_id=>:p_proj_id,
                                     p_filename=>l_filename,
                                     p_dump_description=>l_dump_description,
                                     p_loaded=>to_date('20180917124606','YYYYMMDDHH24MISS'),
                                     p_dbid=>3781652766,
                                     p_min_snap_id=>8821,
                                     p_max_snap_id=>8832,
                                     p_min_snap_dt=>to_timestamp('20180913042527.072','YYYYMMDDHH24MISS.FF3'),
                                     p_max_snap_dt=>to_timestamp('20180913111325.457','YYYYMMDDHH24MISS.FF3'),
                                        
p_db_description=>'12.1.0.2.0, devsp095cn.netcracker.com, Linux x86 64-bit',
                                     p_dump_name=>'Run #3'
                                 );
  commit;
  dbms_output.put_line('Dump "'||l_filename||'" has been loaded into PROJ_ID='||:p_proj_id);
end;
/                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                               
spool off
set serveroutput off                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                          
