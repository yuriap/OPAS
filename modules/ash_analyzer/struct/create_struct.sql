--Online ASH Dashboard V3
create sequence asha_sq_cube;

create table asha_cube_projects (
proj_id             NUMBER GENERATED ALWAYS AS IDENTITY primary key,
proj_name           VARCHAR2(256) not null,
owner               varchar2(128) not null,
created             timestamp     default systimestamp not null,
status              varchar2(10)  default 'NEW' not null,
proj_note           clob,
keep_forever        varchar2(1) default 'N' not null,
is_public           varchar2(1) default 'Y' not null
);

create table asha_cube_srcdblink2projects (
proj_id         number references asha_cube_projects(proj_id) on delete cascade,
src_dblink      varchar2(128) references opas_db_links (DB_LINK_NAME) on delete cascade);

create index idx_asha_cube_src2proj_proj on asha_cube_srcdblink2projects(proj_id);
create index idx_asha_cube_src2proj_src  on asha_cube_srcdblink2projects(src_dblink);

CREATE OR REPLACE FORCE VIEW V$ASHA_CUBE_PROJECTS AS 
select x.*,
case
  when keep_forever = 'Y' 
    then 'Will be kept forever'
  else
    replace('Will be kept till <%p1>','<%p1>',to_char(created + TO_DSINTERVAL(COREMOD_API.getconf('PROJECTRETENTION',ASHA_CUBE_API.getMODNAME)||' 00:00:00'),'YYYY-MON-DD HH24:MI' ))
end retention
from asha_cube_projects x
where owner=decode(owner,'PUBLIC',owner,decode(is_public,'Y',owner,nvl(V('APP_USER'),'~^')));

create table asha_cube_sess_tmpl (
tmpl_id             NUMBER GENERATED ALWAYS AS IDENTITY primary key,
tmpl_proj_id        number references asha_cube_projects(proj_id) on delete cascade,
tmpl_name           varchar2(100),
tmpl_description    varchar2(4000),
tmpl_created        timestamp default systimestamp not null,
tmpl_base           varchar2(1) default 'N');

create index idx_asha_cube_tmpl_prj on asha_cube_sess_tmpl(tmpl_proj_id);

create table asha_cube_sess_tmpl_pars (
tmpl_id             number references asha_cube_sess_tmpl(tmpl_id) on delete cascade,
tmpl_par_nm         varchar2(100),
tmpl_par_expr       varchar2(4000));

create index idx_asha_cube_tmpl_fk on asha_cube_sess_tmpl_pars(tmpl_id);

--=====================================================================================
--=====================================================================================
--=====================================================================================

create table asha_cube_metrics_dic as
select group_id, group_name, metric_id, metric_name||' ('||metric_unit||')' metric_name, 'N' is_manual, systimestamp created
from v$metricname where metric_name in (
'Average Synchronous Single-Block Read Latency',
'Physical Reads Per Sec',
'Physical Writes Per Sec',   
'Redo Generated Per Sec',  
'I/O Requests per Second',
'I/O Megabytes per Second',
'CPU Usage Per Sec',
'Host CPU Usage Per Sec',
'Executions Per Sec',
'Network Traffic Volume Per Sec',
'User Calls Per Sec');

create unique index asha_cube_metrics_dic_id on asha_cube_metrics_dic(group_id,metric_id);

--=====================================================================================
--=====================================================================================
--=====================================================================================

create table asha_cube_racnodes_cache (
src_dblink  varchar2(128) references opas_db_links (DB_LINK_NAME) on delete cascade,
inst_name   varchar2(256),
inst_id     number,
created     timestamp default systimestamp);

create index idx_asha_cube_rac_cache_src on asha_cube_racnodes_cache(src_dblink);

--=====================================================================================
--=====================================================================================
--=====================================================================================

create table asha_cube_sess (
sess_id             number,
sess_proj_id        number references asha_cube_projects(proj_id) on delete cascade,
sess_created        timestamp default systimestamp,
sess_retention_days number,
sess_status         varchar2(30),
sess_tq_id          number,
sess_tq_id_snap     number,
sess_description    varchar2(4000),
parent_id           number);

rem sess_retention_days: null - default project retention, 0 - keep forever, N - keep days

create unique index xpk_asha_cube_sess on asha_cube_sess(sess_id);
alter table asha_cube_sess add constraint xpk_asha_cube_sess primary key(sess_id);
create unique index xpk_asha_cube_parsess on asha_cube_sess(parent_id);
alter table asha_cube_sess add constraint fk_asha_cube_sess_prnt foreign key(parent_id) references asha_cube_sess(sess_id) on delete cascade;

create table asha_cube_sess_pars (
sess_id      number references asha_cube_sess(sess_id) on delete cascade,
sess_par_nm  varchar2(100),
sess_par_val varchar2(4000));

create unique index idx_asha_cube_see_pars_s on asha_cube_sess_pars(sess_id,sess_par_nm);

create table asha_cube_timeline (
sess_id      number references asha_cube_sess(sess_id) on delete cascade,
sample_time  timestamp);

create index idx_asha_cube_timeline_1 on asha_cube_timeline(sess_id);

create table asha_cube (
sess_id      number references asha_cube_sess(sess_id) on delete cascade,
sample_time  timestamp,
wait_class   VARCHAR2(64),
sql_id       VARCHAR2(13),
event        VARCHAR2(64),
event_id     number,
module       VARCHAR2(64),
action       VARCHAR2(64),
sql_id1      VARCHAR2(13),
SQL_PLAN_HASH_VALUE number,
segment_id   number,
g1           number,
g2           number,
g3           number,
g4           number,
g5           number,
g6           number,
smpls        number);

create bitmap index idx_asha_cube_1 on asha_cube(sess_id);
create bitmap index idx_asha_cube_2 on asha_cube(g1);
create bitmap index idx_asha_cube_3 on asha_cube(g2);
create bitmap index idx_asha_cube_4 on asha_cube(g3);
create bitmap index idx_asha_cube_5 on asha_cube(g4);
create bitmap index idx_asha_cube_6 on asha_cube(g5);
create bitmap index idx_asha_cube_7 on asha_cube(g6);
create bitmap index idx_asha_cube_8 on asha_cube(wait_class);

create table asha_cube_unknown (
sess_id      number references asha_cube_sess(sess_id) on delete cascade,
unknown_type varchar2(100),
session_type varchar2(10),
program      VARCHAR2(48),
client_id    VARCHAR2(64),
machine      VARCHAR2(64),
ecid         VARCHAR2(64),
username     varchar2(128),
smpls        number);

create index idx_asha_cube_unkn_1 on asha_cube_unknown(sess_id);

create table asha_cube_seg (
sess_id      number references asha_cube_sess(sess_id) on delete cascade,
segment_id   number,
segment_name varchar2(260));

create index idx_asha_cube_seg on asha_cube_seg(sess_id);

create table asha_cube_metrics (
sess_id      number references asha_cube_sess(sess_id) on delete cascade,
metric_id    number,
end_time     timestamp,
value        number
);

create index idx_asha_cube_metrics on asha_cube_metrics(sess_id);

CREATE TABLE ASHA_CUBE_BLOCK (
    SESS_ID          NUMBER references asha_cube_sess(sess_id) on delete cascade,
    SESSION_ID       NUMBER, 
    SESSION_SERIAL#  NUMBER, 
    INST_ID          NUMBER, 
    SQL_ID           VARCHAR2(13 BYTE), 
    MODULE           VARCHAR2(64 BYTE), 
    ACTION           VARCHAR2(64 BYTE), 
    BLOCKING_SESSION NUMBER, 
    BLOCKING_SESSION_SERIAL# NUMBER, 
    BLOCKING_INST_ID NUMBER, 
    CNT              NUMBER,
	blocker_id       varchar2(4000)
   );

create index IDX_ASHA_CUBE_BLOCK on ASHA_CUBE_BLOCK(sess_id);

create table asha_cube_top_sess (
sess_id          number references asha_cube_sess(sess_id) on delete cascade,
session_id       number, 
session_serial#  number, 
inst_id          number, 
module           varchar2(64 byte), 
action           varchar2(64 byte), 	
program          varchar2(48),
client_id        varchar2(64),
machine          varchar2(64),
ecid             varchar2(64),
username         varchar2(128),
smpls            number);

create index idx_asha_cube_top_sess_ss on asha_cube_top_sess(sess_id);

create sequence asha_snap_ash;
create table asha_cube_snap_ash as select 1 sess_id, x.* from gv$active_session_history x where 1=2;
create index idx_asha_cube_snap_ash_ix1 on asha_cube_snap_ash(sess_id);
alter table asha_cube_snap_ash add constraint fk_snap_sess foreign key (sess_id) references asha_cube_sess(sess_id) on delete cascade;


--create table asha_cube_statistics (
--sess_id          number references asha_cube_sess(sess_id) on delete cascade,
--sample_id        number,
--sample_time      timestamp,
--statistic#       number, 
--value            number);

--create index idx_asha_statistics_ss on asha_cube_statistics(sess_id);

--create global temporary table asha_cube$tmp_statistics (
--sample_id        number,
--sample_time      timestamp,
--statistic#       number, 
--value            number)
--on commit preserve rows;

create table asha_cube_reports(
    proj_id          NUMBER NOT NULL REFERENCES asha_cube_projects ( proj_id )   on delete cascade,
	report_id        NUMBER NOT NULL REFERENCES opas_reports       ( report_id ) on delete cascade,
	sess_id          number references asha_cube_sess(sess_id) on delete set null,
	report_retention number,
	report_note      varchar2(4000),
	created          timestamp default systimestamp
);

rem report_retention: null - default project retention, 0 - keep forever, N - keep days

create unique index idx_asha_cube_reports_proj on asha_cube_reports(proj_id, report_id);
create index idx_asha_cube_reports_rep  on asha_cube_reports(report_id);
create index idx_asha_cube_reports_sess  on asha_cube_reports(sess_id);