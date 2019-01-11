set serveroutput on
set feedback off
set timing off
set lines 1000

spool load_all_dumps_to_opas.sql

declare
  l_cnt number := 1;
  l_header_scr varchar2(32765) := q'[spool load_all_dumps_to_opas.log
set serveroutput on
variable p_proj_id number]';


  l_proj_scr varchar2(32765) := q'[--create project
declare
  l_name    awrwh_projects.proj_name%type := '<Project name>';
  l_descr   awrwh_projects.PROJ_NOTE%type := q'{<Project description>}';
begin
  AWRWH_PROJ_API.create_project(p_proj_name=>l_name,
                                p_owner=>COREMOD_API.gDefaultOwner,
                                p_keep_forever=>'Y',
                                p_is_public=>'Y',
                                p_proj_id=>:p_proj_id);
  AWRWH_PROJ_API.set_project_crdt(p_proj_id=>:p_proj_id,p_created=>to_date('<PROJ_DATE>','YYYYMMDDHH24MISS'));
  AWRWH_PROJ_API.set_note(p_proj_id=>:p_proj_id,p_proj_note=>l_descr);
  commit;
  dbms_output.put_line('Project "'||l_name||'" has been created. PROJ_ID='||:p_proj_id);
end;
/]';

l_dump_scr varchar2(32765) := q'[declare
  l_filename awrwh_dumps.filename%type := '<dump_file_name>';
  l_dump_description awrwh_dumps.dump_description%type := q'{<Dump description>}';
begin
  AWRWH_FILE_API.load_dump_from_file(p_proj_id=>:p_proj_id, 
                                     p_filename=>l_filename, 
                                     p_dump_description=>l_dump_description,
                                     p_loaded=>to_date('<DUMP_DATE>','YYYYMMDDHH24MISS'),
                                     p_dbid=><DBID>,
                                     p_min_snap_id=><MINSN>,
                                     p_max_snap_id=><MAXSN>,
                                     p_min_snap_dt=><MINDT>,
                                     p_max_snap_dt=><MAXDT>,
                                     p_db_description=>'<DBDESCR>',
                                     p_dump_name=>'<DMPNAME>'
                                 );
  commit;
  dbms_output.put_line('Dump "'||l_filename||'" has been loaded into PROJ_ID='||:p_proj_id);
end;
/]';

--                                   p_min_snap_dt=>to_timestamp('<MINDT>','YYYYMMDDHH24MISS.FF3'),
--                                   p_max_snap_dt=>to_timestamp('<MAXDT>','YYYYMMDDHH24MISS.FF3'),

  l_footer_scr varchar2(32765) := q'[spool off
set serveroutput off]';

procedure p(p_msg varchar2) is begin dbms_output.put_line(p_msg); end;

begin
   p(l_header_scr);
   for i in (SELECT PROJ_ID, PROJ_NAME, PROJ_DESCRIPTION,PROJ_DATE FROM AWRTOOLPROJECT order by PROJ_ID) loop
     p(replace(replace(replace(l_proj_scr,'<Project name>',i.PROJ_NAME),'<Project description>',i.PROJ_DESCRIPTION),'<PROJ_DATE>',to_char(i.PROJ_DATE,'YYYYMMDDHH24MISS')));
     p('--');
     for j in (SELECT PROJ_ID, FILENAME, DUMP_DESCRIPTION,loading_date,dbid,min_snap_id,max_snap_id,min_snap_dt,max_snap_dt,db_description, dump_name FROM AWRDUMPS where PROJ_ID=i.PROJ_ID order by dump_id) loop
       p('-- #'||l_cnt);l_cnt:=l_cnt+1;
       p(replace(
         replace(
         replace(
         replace(
         replace(
         replace(
         replace(
         replace(
         replace(
         replace(l_dump_scr,'<dump_file_name>',j.FILENAME),
                            '<Dump description>',j.DUMP_DESCRIPTION),
                            '<DUMP_DATE>',to_char(j.loading_date,'YYYYMMDDHH24MISS')),
                            '<DBID>',nvl(to_char(j.dbid),'null')),
                            '<MINSN>',nvl(to_char(j.min_snap_id),'null')),
                            '<MAXSN>',nvl(to_char(j.max_snap_id),'null')),
                            '<MINDT>',case when j.min_snap_dt is null then 'null' else q'[to_timestamp(']'||to_char(j.min_snap_dt,'YYYYMMDDHH24MISS.FF3')||q'[','YYYYMMDDHH24MISS.FF3')]' end),
                            '<MAXDT>',case when j.max_snap_dt is null then 'null' else q'[to_timestamp(']'||to_char(j.max_snap_dt,'YYYYMMDDHH24MISS.FF3')||q'[','YYYYMMDDHH24MISS.FF3')]' end),
                            '<DBDESCR>',j.db_description),
                            '<DMPNAME>',j.dump_name)
        );
     end loop;
   end loop;
   p(l_footer_scr);
end;
/
spool off