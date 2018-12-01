--AWR DataWarehous V4
create database link &DBLINK. connect to &remotescheme. identified by &remotescheme. using '&dblinkstr.';

--Create tables

create table awrwh_projects (
proj_id             NUMBER GENERATED ALWAYS AS IDENTITY primary key,
proj_name           VARCHAR2(256) not null,
owner               varchar2(128) not null,
created             timestamp     default systimestamp not null,
status              varchar2(10)  default 'NEW' not null,
proj_note           clob,
keep_forever        varchar2(1) default 'N' not null,
is_public           varchar2(1) default 'Y' not null
);

CREATE OR REPLACE FORCE VIEW V$AWRWH_PROJECTS AS 
select x.*,
case
  when keep_forever = 'Y' 
    then 'Will be kept forever'
  else
    replace('Will be kept till <%p1>','<%p1>',to_char(created + TO_DSINTERVAL(COREMOD_API.getconf('PROJECTRETENTION',AWRWH_API.getMODNAME)||' 00:00:00'),'YYYY-MON-DD HH24:MI' ))
end retention
from awrwh_projects x
where owner=decode(owner,'PUBLIC',owner,decode(is_public,'Y',owner,nvl(V('APP_USER'),'~^')));


create table awrwh_dumps (
    dump_id NUMBER GENERATED ALWAYS AS IDENTITY primary key,
    proj_id NUMBER NOT NULL REFERENCES awrwh_projects ( proj_id ) on delete cascade,
    loading_date date default sysdate,
    filename varchar2(512),
    status varchar2(30), /* default 'NEW' check (status in ('NEW','LOADED','UNLOADED','COMPRESSED')), */
    dbid number,
    min_snap_id number,
    max_snap_id number,
    min_snap_dt timestamp(3),
    max_snap_dt timestamp(3),
    is_remote varchar2(10) default 'NO' NOT NULL check (is_remote in ('YES','NO')),
    db_description varchar2(1000),
    dump_description varchar2(4000),
    dump_name varchar2(100),
    filebody number REFERENCES opas_files ( file_id )
);

create index idx1_awrwh_dumps_proj on awrwh_dumps(proj_id);


create table awrwh_reports(
    proj_id        NUMBER NOT NULL REFERENCES awrwh_projects ( proj_id )   on delete cascade,
    report_id      NUMBER NOT NULL REFERENCES opas_reports   ( report_id ) on delete cascade
);

create index idx_awrwh_reports_proj on awrwh_reports(proj_id);
create index idx_awrwh_reports_rep  on awrwh_reports(report_id);
  
create or replace synonym awrwh_dumps_rem for awrwh_dumps@&DBLINK.;

create or replace synonym awrwh_remote for awrwh_remote@&DBLINK.;

create or replace synonym dba_hist_snapshot_rem for dba_hist_snapshot@&DBLINK.;
create or replace synonym v$database_rem for v$database@&DBLINK.;
   

CREATE OR REPLACE FORCE EDITIONABLE VIEW AWRCOMP_REMOTE_DATA as
select x1.snap_id, 
       x1.dbid, 
       x1.instance_number, 
       x1.startup_time, 
       x1.begin_interval_time, 
       x1.end_interval_time, 
       x1.snap_level,x1.error_count, 
       decode(loc.proj_name,null,'<UNKNOWN PROJECT>',loc.proj_name) project, loc.proj_id
 from dba_hist_snapshot_rem x1,
     (select dbid, min_snap_id, max_snap_id, proj_name, d.proj_id 
        from awrwh_dumps d, awrwh_projects p 
       where d.status='AWRLOADED' and d.proj_id=p.proj_id and d.IS_REMOTE='YES') loc
where x1.dbid<>(select dbid from v$database_rem) 
  and x1.dbid=loc.dbid(+) and x1.snap_id between loc.min_snap_id(+) and loc.max_snap_id(+)
order by x1.dbid,x1.snap_id;