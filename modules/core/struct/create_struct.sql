--Module register
create table opas_modules (
MODNAME    varchar2(128) primary key,
MODDESCR   varchar2(4000),
MODVER     varchar2(32) not null,
INSTALLED  date not null
);

--Module Metadata
create table opas_config (
modname varchar2(128) references opas_modules(modname) on delete cascade,
cgroup  varchar2(128),
ckey    varchar2(100),
cvalue  varchar2(4000),
descr   varchar2(200)
);

--alter table opas_config add constraint opas_config_pk primary key (ckey);
create unique index idx_opas_config_key on opas_config(decode(cgroup,'PRJRETENTION',null,ckey));


create table opas_scripts (
script_id      varchar(100) primary key,
modname        varchar2(128) references opas_modules(modname) on delete cascade,
script_content clob
);

--Logging
create table opas_log (
ts timestamp default systimestamp,
msg clob)
;
create index idx_log_ts on opas_log(ts);

--Database link dictionary
create table opas_db_links (
DB_LINK_NAME    varchar2(128) primary key,
DISPLAY_NAME    varchar2(128),
OWNER           varchar2(128),
username        varchar2(128),
password        varchar2(128),
connstr         varchar2(1000),
STATUS          varchar2(32) default 'NEW',
is_public       varchar2(1) default 'Y');

CREATE OR REPLACE FORCE EDITIONABLE VIEW V$OPAS_DB_LINKS AS 
with gn as (select value from v$parameter where name like '%domain%')
select DB_LINK_NAME,
       case
         when DB_LINK_NAME = '$LOCAL$' then DB_LINK_NAME
         else l.db_link
       end ORA_DB_LINK,
       case
         when DB_LINK_NAME = '$LOCAL$' then DISPLAY_NAME
         else DISPLAY_NAME||' ('||l.username||'@'||l.host||')'
         end DISPLAY_NAME,
       OWNER,
       STATUS,
       IS_PUBLIC
  from OPAS_DB_LINKS o, user_db_links l, gn
 where owner =
       decode(owner,
              'PUBLIC',
              owner,
              decode(is_public, 'Y', owner, nvl(V('APP_USER'), '~^')))
   and l.db_link(+) = upper(o.DB_LINK_NAME ||'.'|| gn.value);

--Task execution infrasrtucture
create table opas_task (
taskname    varchar2(128) primary key,
modname     varchar2(128) references opas_modules(modname) on delete cascade,
owner       varchar2(128) default 'PUBLIC' not null,
task_type   varchar2(32) default 'SYSTEM', --SYSTEM, USER
created     timestamp default systimestamp,
status      varchar2(32) default 'NEW',
task_body   clob,
max_thread  number default 1,
async       varchar2(1) default 'Y' not null,
schedule    varchar2(256)
);

create index idx_opas_task_mod on opas_task(modname);

create table opas_task_exec (
texec_id    NUMBER GENERATED ALWAYS AS IDENTITY primary key,
taskname    varchar2(128) references opas_task(taskname) on delete cascade,
started     timestamp,
finished    timestamp,
cpu_time    number, --seconds
elapsed_time number,
status      varchar2(32) default 'NEW',
owner       varchar2(128),
sid         number,
serial#     number
);

create index idx_opas_task_exec_tsk on opas_task_exec(taskname);

create table opas_task_pars (
texec_id    number references opas_task_exec(texec_id) on delete cascade,
PAR_NAME    varchar2(100),
num_par     number,
varchar_par varchar2(4000),
date_par    date
);

create index idx_opas_task_parstske on opas_task_pars(texec_id);

create table opas_task_log (
taskname    varchar2(128) references opas_task(taskname) on delete cascade,
texec_id    number references opas_task_exec(texec_id) on delete cascade,
created     timestamp default systimestamp,
msg         varchar2(4000)
);

create index idx_opas_task_logtsk on opas_task_log(taskname);
create index idx_opas_task_logtske on opas_task_log(texec_id);

--File storage
create table opas_files (
file_id       NUMBER GENERATED ALWAYS AS IDENTITY primary key,
modname       varchar2(128) references opas_modules(modname) on delete cascade,
file_type     varchar2(100) not null,
file_name     varchar2(1000) not null,
FILE_MIMETYPE varchar2(30),
file_contentb blob,
file_contentc clob,
created       timestamp default systimestamp,
owner         varchar2(128) default 'PUBLIC' not null
);

alter table opas_files move lob (file_contentb) store as (compress high);
alter table opas_files move lob (file_contentc) store as (compress high);

create index idx_opas_files_mod on opas_files(modname);

--Clob2row representation
--https://jonathanlewis.wordpress.com/2008/11/19/lateral-lobs/
create or replace type clob_line as object (
    line_number number,
    payload varchar2(4000)
)
/
 
create or replace type clob_page as table of clob_line
/

--Authorisation 
-- 0 - admin; 1 - rw; 2 - RO; 3 - noaccess;
create table opas_groups (
group_id      NUMBER GENERATED ALWAYS AS IDENTITY primary key,
group_name    varchar2(100) not null,
access_level  number not null check (access_level in (0,1,2,3)), 
modname       varchar2(128) references opas_modules(modname) on delete cascade,
group_descr   varchar2(1000));

create unique index idx_opas_groups_modgr on opas_groups(modname,group_name);

create table opas_groups2apexusr (
group_id       number not null references opas_groups(group_id) on delete cascade,
apex_user      varchar2(100));

create index opas_groups2apexusr_gr on opas_groups2apexusr(group_id);
create index opas_groups2apexusr_usr on opas_groups2apexusr(apex_user);

--OPAS Projects infrastrucutre
create table opas_project_types (
proj_type   varchar2(100) primary key,
modname     varchar2(128) not null references opas_modules(modname) on delete cascade,
page_title  varchar2(1000),
region_title  varchar2(1000));

create index idx_opas_projects_tp_mod on opas_project_types(modname);

create table opas_projects (
proj_id     NUMBER GENERATED ALWAYS AS IDENTITY primary key,
modname     varchar2(128) not null references opas_modules(modname) on delete cascade,
proj_name   VARCHAR2(256) not null references opas_project_types(proj_type),
proj_type   varchar2(100) not null,
owner       varchar2(128) not null,
created     timestamp default systimestamp not null,
status      varchar2(10) default 'NEW' not null,
description varchar2(4000),
retention   varchar2(20) default 'DEFAULT' not null check (retention in ('DEFAULT','KEEPSOURCEDATAONLY','KEEPPARSEDDATAONLY','KEEPALLFOREVER')),
is_public   varchar2(1) default 'Y' not null
);
create index idx_opas_projects_mod on opas_projects(modname);
create index idx_opas_projects_tpmod on opas_projects(proj_type,modname);

create table opas_notes (
note_id      NUMBER GENERATED ALWAYS AS IDENTITY primary key,
proj_id      NUMBER NOT NULL REFERENCES opas_projects ( proj_id ) on delete cascade,
is_proj_note varchar2(1) default 'Y' not null,
note         clob)
lob (note) store as (enable storage in row)
;

create index idx_opas_notes_proj on opas_notes(proj_id);
--only a single note can exist for a given project all other can be non-project notes
create unique index idx_opas_notes_projnt on opas_notes(decode(is_proj_note,'Y',proj_id,null));

create table opas_project_cleanup (
modname       varchar2(128) not null references opas_modules(modname) on delete cascade,
cleanup_mode  varchar2(10)  not null check (cleanup_mode in ('SOURCEDATA','PARSEDDATA')), 
cleanup_prc   varchar2(512) not null,
ordr          number not null
);

create index idx_opas_project_cleanup_mod on opas_project_cleanup(modname);

--Dictionaries
create table opas_dic_retention (
ret_code varchar2(32) primary key,
ret_display_name varchar2(100),
ret_display_descr varchar2(1000)
);

alter table opas_projects add constraint fk_opasproj_retention foreign key (retention) references opas_dic_retention;

CREATE OR REPLACE VIEW V$OPAS_PROJECTS (PROJ_ID, MODNAME, PROJ_NAME, proj_type, OWNER, CREATED, STATUS, DESCRIPTION, RETENTION, IS_PUBLIC, FACTUAL_RETENTION) AS 
  select x.PROJ_ID, x.MODNAME, x.PROJ_NAME, x.proj_type, x.OWNER, x.CREATED, x.STATUS, x.DESCRIPTION, x.RETENTION, x.IS_PUBLIC,
case
  when RETENTION = 'KEEPALLFOREVER' then d.ret_display_descr
  else
    case
      when RETENTION = 'DEFAULT' then replace(d.ret_display_descr,'<%p1>',to_char(created + TO_DSINTERVAL(COREMOD_API.getconf('PROJECTRETENTION',x.MODNAME)||' 00:00:00'),'YYYY-MON-DD HH24:MI' ))
      else
        case when RETENTION in ('KEEPFILESONLY', 'KEEPPARSEDONLY')
             then replace(d.ret_display_descr,'<%p1>',COREMOD_API.getconf('PROJECTRETENTION',x.MODNAME))
        end
    end
end factual_retention
from opas_projects x, opas_dic_retention d
where owner=decode(owner,'PUBLIC',owner,decode(is_public,'Y',owner,nvl(V('APP_USER'),'~^')))
and x.RETENTION=d.ret_code
;