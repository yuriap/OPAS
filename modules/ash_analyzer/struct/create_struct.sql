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

create table asha_cube_reports(
    proj_id        NUMBER NOT NULL REFERENCES asha_cube_projects ( proj_id )   on delete cascade,
	report_id      NUMBER NOT NULL REFERENCES opas_reports       ( report_id ) on delete cascade
);

create index idx_asha_cube_reports_proj on asha_cube_reports(proj_id);
create index idx_asha_cube_reports_rep  on asha_cube_reports(report_id);

create table asha_cube_sess (
sess_id             number,
sess_proj_id        number references asha_cube_projects(proj_id) on delete cascade,
sess_created        timestamp default systimestamp,
sess_retention_days number,
sess_params         clob,
CONSTRAINT asha_cube_sess_json_chk CHECK (sess_params IS JSON));

rem sess_retention_days: null - default project retention, 0 - keep forever, N - keep days

create unique index xpk_asha_cube_sess on asha_cube_sess(sess_id);
alter table asha_cube_sess add constraint xpk_asha_cube_sess primary key(sess_id);

create table asha_cube_timeline (
sess_id      number references asha_cube_sess(sess_id) on delete cascade,
sample_time  date);

create index idx_asha_cube_timeline_1 on asha_cube_timeline(sess_id);

create table asha_cube (
sess_id      number references asha_cube_sess(sess_id) on delete cascade,
sample_time  date,
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
end_time     date,
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
    CNT              NUMBER
   );

create index IDX_ASHA_CUBE_BLOCK on ASHA_CUBE_BLOCK(sess_id);

create table asha_racnodes_cache (
src_dblink  varchar2(128) references opas_db_links (DB_LINK_NAME) on delete set null,
inst_name   varchar2(256),
inst_id     number,
created     timestamp default systimestamp);

create index idx1_asha_cube_dic on asha_cube_dic(src_db,dic_type);

create table asha_cube_qry_cache (
src_dblink  varchar2(128) references opas_db_links (DB_LINK_NAME) on delete set null,
sql_id      varchar2(128),
sql_text    clob,
ts          timestamp default systimestamp);

create unique index xpk_asha_cube_qry_cache on asha_cube_qry_cache(src_db,sql_id);
alter table asha_cube_qry_cache add constraint xpk_asha_cube_qry_cache primary key(src_db,sql_id);