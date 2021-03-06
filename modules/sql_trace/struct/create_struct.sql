create table trc_projects (
proj_id             NUMBER GENERATED ALWAYS AS IDENTITY primary key,
proj_name           VARCHAR2(256) not null,
owner               varchar2(128) not null,
created             timestamp     default systimestamp not null,
status              varchar2(10)  default 'NEW' not null,
proj_note           clob,
keep_forever        varchar2(1) default 'N' not null,
is_public           varchar2(1) default 'Y' not null,
priority            number default 10
);

CREATE OR REPLACE FORCE VIEW V$TRC_PROJECTS AS 
select x.*,
case
  when keep_forever = 'Y' 
    then 'Will be kept forever'
  else
    replace('Will be kept till <%p1>','<%p1>',to_char(created + TO_DSINTERVAL(COREMOD_API.getconf('PROJECTRETENTION',TRC_FILE_API.getMODNAME)||' 00:00:00'),'YYYY-MON-DD HH24:MI' ))
end retention
from trc_projects x
where owner=decode(owner,'PUBLIC',owner,decode(is_public,'Y',owner,nvl(V('APP_USER'),'~^')));

create table trc_files (
trc_file_id         NUMBER GENERATED ALWAYS AS IDENTITY primary key,
proj_id             NUMBER NOT NULL REFERENCES trc_projects ( proj_id ) on delete cascade,
filename            varchar2(4000),
file_header         varchar2(4000),
owner               varchar2(128),
db_version          varchar2(32),
created             timestamp default systimestamp,
parsed              timestamp,
status              varchar2(10) default 'NEW',
file_note           clob,
file_source         varchar2(128) REFERENCES opas_db_links ( DB_LINK_NAME ),
file_content        number REFERENCES opas_files ( file_id ),
report_content      number REFERENCES opas_files ( file_id ),
source_keep_forever varchar2(1) default 'N' not null,
parsed_keep_forever varchar2(1) default 'N' not null,
tq_id               number
);

create index idx_trc_file_proj   on trc_files(proj_id);
create index idx_trc_file_dbfsrc on trc_files(file_source);
create index idx_trc_file_fcntn  on trc_files(file_content);
create index idx_trc_file_rcntn  on trc_files(report_content);

CREATE OR REPLACE FORCE VIEW V$TRC_FILES AS 
select x.*,
case
  when source_keep_forever = 'Y' 
    then 'Source file will be kept forever'
  when status in ('COMPRESSED','ARCHIVED')
    then 'N/A'
  else
    replace('Source file will be kept till <%p1>','<%p1>',to_char(created + TO_DSINTERVAL(COREMOD_API.getconf('SOURCERETENTION',TRC_FILE_API.getMODNAME)||' 00:00:00'),'YYYY-MON-DD HH24:MI' ))
end source_retention,
case
  when parsed_keep_forever = 'Y' 
    then 'Parsed data will be kept forever'
  when status in ('ARCHIVED')
    then 'N/A'	
  else
    decode(parsed,null,null,replace('Parsed data  will be kept till <%p1>','<%p1>',to_char(parsed + TO_DSINTERVAL(COREMOD_API.getconf('PARSEDRETENTION',TRC_FILE_API.getMODNAME)||' 00:00:00'),'YYYY-MON-DD HH24:MI' )))
end parsed_retention
from trc_files x;

create table trc_session (
session_id          NUMBER GENERATED ALWAYS AS IDENTITY primary key,
trc_file_id         NUMBER NOT NULL REFERENCES trc_files ( trc_file_id ) on delete cascade,
row_num             number,
sid                 number,
serial#             number,
start_ts            timestamp with time zone,
end_ts              timestamp with time zone
);

create index idx_trc_session_fil on trc_session(trc_file_id);

create table trc_client_identity (
cli_id              NUMBER GENERATED ALWAYS AS IDENTITY primary key,
session_id          NUMBER REFERENCES trc_session ( session_id ) on delete cascade,
trc_file_id         NUMBER NOT NULL REFERENCES trc_files ( trc_file_id ) on delete cascade,
client_id           varchar2(64),
service_name        varchar2(64),
module              varchar2(64),
action              varchar2(64),
client_driver       varchar2(64));

create index idx_trc_client_identity_sess on trc_client_identity(session_id);
create index idx_trc_client_identity_file on trc_client_identity(trc_file_id);

create table trc_statement (
stmt_id             NUMBER GENERATED ALWAYS AS IDENTITY primary key,
session_id          NUMBER REFERENCES trc_session ( session_id ) on delete cascade,
trc_file_id         NUMBER NOT NULL REFERENCES trc_files ( trc_file_id ) on delete cascade,
row_num             number,
trc_slot            number,
len                 number,
dep                 number,
uid#                number,
oct                 number,
lid                 number,
tim                 number,
hv                  number,
ad                  varchar2(100),
sqlid               varchar2(100),
sql_text            clob,
cli_ident           NUMBER REFERENCES trc_client_identity ( cli_id ) on delete cascade,
err                 number
);

create index idx_trc_statement_sess on trc_statement(session_id);
create index idx_trc_statement_file on trc_statement(trc_file_id,sqlid);

create table trc_trans (
trans_id            NUMBER GENERATED ALWAYS AS IDENTITY primary key,
session_id          NUMBER REFERENCES trc_session ( session_id ) on delete cascade,
trc_file_id         NUMBER NOT NULL REFERENCES trc_files ( trc_file_id ) on delete cascade,
stmt_id             NUMBER REFERENCES trc_statement ( stmt_id ) on delete cascade,
row_num             number,
rlbk                number,
rd_only             number,
tim                 number);

create index idx_trc_trans_sess on trc_trans(session_id);
create index idx_trc_trans_file on trc_trans(trc_file_id);
create index idx_trc_trans_stmt on trc_trans(stmt_id);

create table trc_call (
call_id             NUMBER GENERATED ALWAYS AS IDENTITY primary key,
stmt_id             NUMBER NOT NULL REFERENCES trc_statement ( stmt_id ) on delete cascade,
trc_file_id         NUMBER NOT NULL REFERENCES trc_files ( trc_file_id ) on delete cascade,
parent_id           NUMBER REFERENCES trc_call ( call_id ) on delete cascade,
call_type           varchar2(100),
row_num             number,
trc_slot            number,
c                   number,
e                   number,
p                   number,
cr                  number,
cu                  number,
mis                 number,
r                   number,
dep                 number,
og                  number,
plh                 number,
tim                 number,
typ                 number --CLOSE call type field
);

create index idx_trc_call_sess on trc_call(stmt_id,trc_file_id);
create index idx_trc_call_prnt on trc_call(parent_id);
create index idx_trc_call_file on trc_call(trc_file_id,parent_id);

create table trc_call_self (
call_id             NUMBER NOT NULL REFERENCES trc_call ( call_id ) on delete cascade,
c                   number,
e                   number,
p                   number,
cr                  number,
cu                  number);

create index idx_trc_call_self_cll on trc_call_self(call_id);

create table trc_binds (
stmt_id             NUMBER NOT NULL REFERENCES trc_statement ( stmt_id ) on delete cascade,
trc_file_id         NUMBER NOT NULL REFERENCES trc_files ( trc_file_id ) on delete cascade,
call_id             NUMBER REFERENCES trc_call ( call_id ) on delete cascade,
row_num             number,
trc_slot            number,
bind#               number,
value               varchar2(4000)
);

create index idx_trc_binds_cll on trc_binds(call_id);
create index idx_trc_binds_file on trc_binds(trc_file_id);

create table trc_wait (
stmt_id             NUMBER NOT NULL REFERENCES trc_statement ( stmt_id ) on delete cascade,
trc_file_id         NUMBER NOT NULL REFERENCES trc_files ( trc_file_id ) on delete cascade,
row_num             number,
trc_slot            number,
nam                 varchar2(100),
ela                 number,
p1_name             varchar2(256),
p1                  number,
p2_name             varchar2(256),
p2                  number,
p3_name             varchar2(256),
p3                  number,
pars                varchar2(4000),
obj#                number,
tim                 number
);

create index idx_trc_wait_stmt on trc_wait(stmt_id,trc_file_id);
create index idx_trc_wait_file on trc_wait(trc_file_id);

create table trc_stat (
stmt_id             NUMBER NOT NULL REFERENCES trc_statement ( stmt_id ) on delete cascade,
trc_file_id         NUMBER NOT NULL REFERENCES trc_files ( trc_file_id ) on delete cascade,
row_num             number,
trc_slot            number,
id                  number,
cnt                 number,
pid                 number,
pos                 number,
obj                 number,
op                  varchar2(1000),
cr                  number,
pr                  number,
pw                  number,
str                 number,
tim                 number,
cost                number,
sz                  number,
card                number);

create index idx_trc_stat_stmt on trc_stat(stmt_id);
create index idx_trc_stat_file on trc_stat(trc_file_id);
--create index idx_trc_stat_id on trc_stat(id);
--create index idx_trc_stat_pid on trc_stat(pid);

create table trc_obj_dic (
trc_file_id         NUMBER NOT NULL REFERENCES trc_files ( trc_file_id ) on delete cascade,
object_id           number,
object_name         varchar2(128));

create index idx_trc_obj_dic_file on trc_obj_dic(trc_file_id);


CREATE GLOBAL TEMPORARY TABLE TRC$TMP_CALL_STATS(
SQLID               VARCHAR2(100 BYTE), 
CALL_TYPE           VARCHAR2(100 BYTE), 
CNT                 NUMBER, 
C                   NUMBER, 
E                   NUMBER, 
P                   NUMBER, 
CR                  NUMBER, 
CU                  NUMBER, 
R                   NUMBER, 
MIS                 NUMBER
) ON COMMIT DELETE ROWS ;
   
create index TRC$TMP_CALL_STATS_SQLID on TRC$TMP_CALL_STATS(SQLID);

CREATE GLOBAL TEMPORARY TABLE TRC$TMP_CALL_SELF_STATS(
SQLID               VARCHAR2(100 BYTE), 
CALL_TYPE           VARCHAR2(100 BYTE), 
CNT                 NUMBER, 
C                   NUMBER, 
E                   NUMBER, 
P                   NUMBER, 
CR                  NUMBER, 
CU                  NUMBER
) ON COMMIT DELETE ROWS ;

create index TRC$TMP_CALL_SELF_STATS_SQLID on TRC$TMP_CALL_SELF_STATS(SQLID);
   
CREATE GLOBAL TEMPORARY TABLE TRC$TMP_WAIT_STATS(
SQLID               VARCHAR2(100 BYTE), 
WAIT_CLASS          VARCHAR2(64 BYTE), 
NAM                 VARCHAR2(100 BYTE), 
CNT                 NUMBER, 
ELA                 NUMBER, 
AVG_ELA             NUMBER, 
MAX_ELA             NUMBER, 
ELA_95              NUMBER
) ON COMMIT DELETE ROWS ;
   
create index TRC$TMP_WAIT_STATS_SQLID on TRC$TMP_WAIT_STATS(SQLID);
   
CREATE GLOBAL TEMPORARY TABLE TRC$TMP_PLAN_STATS(
SQLID               VARCHAR2(100 BYTE), 
PLH                 NUMBER, 
ID                  NUMBER, 
CNT                 NUMBER, 
PID                 NUMBER, 
POS                 NUMBER, 
OBJ                 NUMBER, 
OP                  VARCHAR2(1000 BYTE), 
CR                  NUMBER, 
PR                  NUMBER, 
PW                  NUMBER, 
TIM                 NUMBER, 
COST                NUMBER, 
SZ                  NUMBER, 
CARD                NUMBER,
STR                 NUMBER
) ON COMMIT DELETE ROWS ;
   
create index TRC$TMP_PLAN_STATS_SQLID on TRC$TMP_PLAN_STATS(SQLID);


create global temporary table trc$tmp_file_content (
line_number number,
payload     varchar2(4000))
on commit delete rows;

@@upgrade_structure_2.3.0-2.3.1.sql
@@upgrade_structure_2.3.0-2.3.1_p2.sql
@@upgrade_structure_2.3.1-2.4.0.sql
@@upgrade_structure_2.4.1-2.4.2.sql
@@upgrade_structure_2.4.2-2.4.3.sql

@@upgrade_structure_2.4.3-2.4.4.sql
@@upgrade_structure_2.4.4-2.4.5.sql