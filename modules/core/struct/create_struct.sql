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

alter table opas_config add constraint opas_config_pk primary key (modname,ckey);
--create unique index idx_opas_config_key on opas_config(decode(cgroup,'PRJRETENTION',null,ckey));

create table opas_dictionary (
modname     varchar2(128) references opas_modules(modname) on delete cascade,
dic_name    varchar2(20) NOT NULL,
val         varchar2(20) NOT NULL,
display_val varchar2(256) not null,
sparse1     varchar2(100),
sparse2     varchar2(100),
sparse3     varchar2(100),
dic_ordr    number);

create index idx_opas_dictionary_mod on opas_dictionary(modname,dic_name);

create table opas_scripts (
script_id      varchar(100) primary key,
modname        varchar2(128) references opas_modules(modname) on delete cascade,
script_content clob
);

create index idx_opas_scripts_mod on opas_scripts(modname);

create table opas_qry_cache (
sql_id      varchar2(128),
sql_text    clob,
created     timestamp default systimestamp,
hit_num     number default 0);

alter table opas_qry_cache add constraint xpk_asha_cube_qry_cache primary key(sql_id);

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

CREATE OR REPLACE FORCE VIEW V$OPAS_DB_LINKS AS 
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
   and l.db_link(+) = case when gn.value is null then upper(o.DB_LINK_NAME) else upper(o.DB_LINK_NAME ||'.'|| gn.value) end;

--Task execution infrasrtucture
create table opas_cleanup_tasks (
taskname    varchar2(128) primary key,
modname     varchar2(128) references opas_modules(modname) on delete cascade,
created     timestamp default systimestamp,
task_body   clob
);

create index idx_opas_cleanup_tasks_mod on opas_cleanup_tasks(modname);

create table opas_task (
taskname    varchar2(128) primary key,
modname     varchar2(128) references opas_modules(modname) on delete cascade,
created     timestamp default systimestamp,
is_public   varchar2(1) default 'Y',
task_body   clob
);

create index idx_opas_task_mod on opas_task(modname);

create table opas_task_queue (
tq_id        NUMBER GENERATED ALWAYS AS IDENTITY primary key,
taskname     varchar2(128) references opas_task(taskname) on delete cascade,
task_subname varchar2(128),
queued       timestamp,
started      timestamp,
finished     timestamp,
cpu_time     number, --seconds
elapsed_time number,
status       varchar2(32) default 'NEW',
owner        varchar2(128),
sid          number,
serial#      number,
inst_id      number,
job_name     varchar2(128)
--result_link  varchar2(4000)
);

create index idx_opas_task_exec_tsk on opas_task_queue(taskname);

create table opas_task_pars (
tq_id       number references opas_task_queue(tq_id) on delete cascade,
PAR_NAME    varchar2(100),
num_par     number,
varchar_par varchar2(4000),
date_par    date,
list_par    varchar2(4000)
);

create index idx_opas_task_parstske on opas_task_pars(tq_id);

create table opas_log (
created     timestamp default systimestamp,
msg         varchar2(4000),
tq_id       number references opas_task_queue(tq_id) on delete cascade,
msg_long    clob
);

create index idx_opas_task_logtske on opas_log(tq_id);
create index idx_opas_task_created on opas_log(created);

CREATE OR REPLACE FORCE VIEW V$OPAS_TASK_QUEUE AS 
select
  t.taskname, t.modname, q.task_subname, t.is_public, q.tq_id, q.queued, q.started, q.finished, q.cpu_time, nvl(q.elapsed_time,round((sysdate-(q.started+0))*3600*24)) elapsed_time, q.status, q.owner, q.sid, q.serial#, q.inst_id , q.job_name
from opas_task t left outer join opas_task_queue q on (t.taskname = q.taskname and q.owner=decode(t.is_public,'Y',q.owner,nvl(V('APP_USER'),'~^')))
where 1=decode(t.is_public,'Y',1, COREMOD_SEC.is_role_assigned_n(t.modname,'Reas-write users'))
;

CREATE OR REPLACE FORCE VIEW V$OPAS_TASK_QUEUE_LONGOPS AS
select tq.*,
       case 
         when message is null then 'N/A' 
         else opname || ':' || message || '; elapsed: ' || elapsed_seconds || '; remaining: ' || nvl(to_char(time_remaining), 'N/A') end msg,
       round(100 * (sofar / totalwork)) pct_done,
       units,opname,module,action
  from V$OPAS_TASK_QUEUE           tq,
       gv$session_longops           lo,
       gv$session                   s
  where tq.sid = lo.sid(+)
    and tq.serial# = lo.serial#(+)
    and tq.inst_id = lo.inst_id(+)
    and tq.sid = s.sid(+)
    and tq.serial# = s.serial#(+)
    and tq.inst_id = s.inst_id(+)
;
--------------------------------

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

create table opas_reports (
report_id      NUMBER GENERATED ALWAYS AS IDENTITY primary key,
parent_id      number references opas_reports(report_id) on delete set null,
modname        varchar2(128) references opas_modules(modname) on delete cascade,
tq_id          number references opas_task_queue(tq_id) on delete set null,
report_content number REFERENCES opas_files ( file_id ),
report_params_displ varchar2(1000),
report_type    varchar2(100));

create index idx_opas_reports_mod   on opas_reports(modname);
create index idx_opas_reports_fcntn on opas_reports(report_content);

create table opas_reports_pars (
report_id   number references opas_reports(report_id) on delete cascade,
par_name    varchar2(100),
num_par     number,
varchar_par varchar2(4000),
date_par    date
);

create index idx_opas_reports_parstske on opas_reports_pars(report_id);

--Clob2row representation
--https://jonathanlewis.wordpress.com/2008/11/19/lateral-lobs/
create or replace type clob_line as object (
    line_number number,
    payload varchar2(4000)
)
/
 
create or replace type clob_page as table of clob_line
/

--Authorisation group_id - is an access level
-- 0 - admin; 1 - rw; 2 - RO; 3 - noaccess;
create table opas_groups (
group_id      number primary key check (group_id in (0,1,2,3)),
group_name    varchar2(100) not null,
group_descr   varchar2(1000));

create table opas_groups2apexusr (
group_id       number not null references opas_groups(group_id),
modname        varchar2(128) references opas_modules(modname) on delete cascade,
apex_user      varchar2(100));

create index opas_groups2apexusr_usr on opas_groups2apexusr(apex_user);
create unique index opas_groups2apexusr_usr2grp on opas_groups2apexusr(modname,apex_user,group_id);

--V4.6
--Module integration
create table opas_integration_tmpl (
int_key              varchar2(30) primary key,
owner_modname        varchar2(128) references opas_modules(modname) on delete cascade,
src_modname          varchar2(128) references opas_modules(modname) on delete cascade,
trg_modname          varchar2(128) references opas_modules(modname) on delete cascade,
src_url_tmpl         varchar2(1000),
trg_url_tmpl         varchar2(1000),
src_desc_tmpl        varchar2(1000),
trg_desc_tmpl        varchar2(1000),
src_desc_dyn_tmpl    varchar2(1000),
trg_desc_dyn_tmpl    varchar2(1000)
);

create index idx_opas_int_tmpl_modo   on opas_integration_tmpl(owner_modname);
create index idx_opas_int_tmpl_mods   on opas_integration_tmpl(src_modname);
create index idx_opas_int_tmpl_modt   on opas_integration_tmpl(trg_modname);

create table opas_integration (
int_id               NUMBER GENERATED ALWAYS AS IDENTITY primary key,
int_key              varchar2(30)  references opas_integration_tmpl(int_key) on delete cascade,
src_entity_id        number,
src_prnt_entity_id   number,
trg_entity_id        number,
trg_prnt_entity_id   number
);

create index idx_opas_integration_src on opas_integration(int_key,src_prnt_entity_id,src_entity_id);
create index idx_opas_integration_trg on opas_integration(int_key,trg_prnt_entity_id,trg_entity_id);


---------------------------------------------------------------------------------------------
--Export/Import
---------------------------------------------------------------------------------------------
create table opas_expimp_sessions (
sess_id        NUMBER GENERATED ALWAYS AS IDENTITY primary key,
tq_id          number references opas_task_queue(tq_id) on delete set null,
expimp_file    number REFERENCES opas_files ( file_id ),
created        timestamp default systimestamp,
owner          varchar2(128) default 'PUBLIC' not null,
sess_type      varchar2(3) check (sess_type in ('IMP','EXP')),
status         varchar2(32) default 'NEW'
)
;
create index idx_opas_expimp_sessions_tq   on opas_expimp_sessions(tq_id);

create table opas_expimp_metadata (
sess_id        NUMBER references opas_expimp_sessions(sess_id) on delete cascade,
modname        varchar2(128) references opas_modules(modname) on delete cascade,
import_prc     varchar2(128),
file_descr     varchar2(4000),
src_version    varchar2(128),
src_core_version varchar2(128)
);

create index idx_opas_expimp_metadata_mod   on opas_expimp_metadata(modname);
create index idx_opas_expimp_metadata_sess   on opas_expimp_metadata(sess_id);

create table opas_expimp_params (
sess_id        NUMBER references opas_expimp_sessions(sess_id) on delete cascade,
par_name       varchar2(128),
par_value      varchar2(4000)
);

create index idx_opas_expimp_params_sess   on opas_expimp_params(sess_id);

create table opas_expimp_compat (
modname        varchar2(128) references opas_modules(modname) on delete cascade,
src_version    varchar2(100),
trg_version    varchar2(100)
);

create or replace force view v$opas_expimp_sessions as
select 
    x.sess_id,
    x.tq_id,
    x.expimp_file file_id,
    x.created,
    x.owner,
    decode(x.sess_type,'EXP','Export','IMP','Import','Unknown: '||x.sess_type) sess_type,
    x.status,
    m.modname,
    m.import_prc,
    m.file_descr,
    m.src_version,
    m.src_core_version,
    dbms_lob.getlength(f.file_contentb) fsize,
    f.file_name,
	case when m.MODNAME is not null then to_char(x.created + to_number(COREMOD_API.getconf('EXPIMPSESS',m.MODNAME)),'YYYY-MON-DD HH24:MI' ) else null end expiration
from opas_expimp_sessions x, opas_expimp_metadata m, opas_files f
where x.owner=decode(x.owner,'PUBLIC',x.owner,nvl(V('APP_USER'),'~^'))
and x.sess_id=m.sess_id and x.expimp_file=f.file_id(+);
