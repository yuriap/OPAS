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
DDL_TEXT        varchar2(4000),
STATUS          varchar2(32) default 'NEW',
is_public       varchar2(1) default 'Y');

create or replace view v$opas_db_links as
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
  from OPAS_DB_LINKS o, user_db_links l
 where owner =
       decode(owner,
              'PUBLIC',
              owner,
              decode(is_public, 'Y', owner, nvl(V('APP_USER'), '~^')))
   and l.db_link(+) like o.DB_LINK_NAME || '%';

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
async       varchar2(1) default 'Y' not null
);

create index idx_opas_task_mod on opas_task(modname);

create table opas_task_log (
taskname    varchar2(128) references opas_task(taskname) on delete cascade,
created     timestamp default systimestamp,
msg         varchar2(4000)
);

create index idx_opas_task_logsk on opas_task_log(taskname);

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
create table opas_groups (
group_id      NUMBER GENERATED ALWAYS AS IDENTITY primary key,
group_name    varchar2(100) not null,
access_level  number not null check (access_level in (0,1,2,3)), -- 0 - admin; 1 - rw; 2 - RO; 3 - noaccess;
modname       varchar2(128) references opas_modules(modname) on delete cascade,
group_descr   varchar2(1000));

create unique index idx_opas_groups_modgr on opas_groups(modname,group_name);

create table opas_groups2apexusr (
group_id       number not null references opas_groups(group_id) on delete cascade,
apex_user      varchar2(100));

create index opas_groups2apexusr_gr on opas_groups2apexusr(group_id);
create index opas_groups2apexusr_usr on opas_groups2apexusr(apex_user);

