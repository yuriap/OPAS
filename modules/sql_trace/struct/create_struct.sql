create table trc_projects (
trcproj_id  NUMBER GENERATED ALWAYS AS IDENTITY primary key,
proj_name   VARCHAR2(256),
owner       varchar2(128),
created     timestamp default systimestamp,
status      varchar2(10) default 'NEW',
description varchar2(4000),
retention   varchar2(20) default 'DEFAULT'
is_public   varchar2(1) default 'Y'
);

create global temporary table trc$tmp_file_content (
line_number number,
payload     varchar2(4000))
on commit delete rows;


create table trc_file (
trc_file_id NUMBER GENERATED ALWAYS AS IDENTITY primary key,
trcproj_id  NUMBER NOT NULL REFERENCES trc_projects ( trcproj_id ) on delete cascade,
filename    varchar2(4000),
file_header varchar2(4000),
owner       varchar2(128),
db_version  varchar2(32),
created     timestamp default systimestamp,
status      varchar2(10) default 'NEW'
);

create index idx_trc_file_proj on trc_file(trcproj_id);

create table trc_file_source (
trc_file_id    NUMBER REFERENCES trc_file ( trc_file_id ),
file_db_source varchar2(128) REFERENCES opas_db_links ( DB_LINK_NAME ),
trcproj_id     NUMBER REFERENCES trc_projects ( trcproj_id ) on delete cascade,
file_content   number REFERENCES opas_files ( file_id ));

create index idx_trc_file_source_dbfsrc on trc_file_source(file_db_source);
create index idx_trc_file_source_proj on trc_file_source(trcproj_id);
create index idx_trc_file_source_fcntn on trc_file_source(file_content);

alter table trc_file_source add constraint trc_file_source_pk primary key(trc_file_id);

create table trc_notes (
trcproj_id  NUMBER NOT NULL REFERENCES trc_projects ( trcproj_id ) on delete cascade,
trc_file_id NUMBER REFERENCES trc_file ( trc_file_id ) on delete cascade,
note        clob)
lob (note) store as (enable storage in row)
;

create index idx_trc_notes_fil on trc_notes(trc_file_id);
create unique index idx_trc_notes_proj on trc_notes(trcproj_id,trc_file_id);

create table trc_session (
session_id  NUMBER GENERATED ALWAYS AS IDENTITY primary key,
trc_file_id NUMBER NOT NULL REFERENCES trc_file ( trc_file_id ) on delete cascade,
row_num     number,
sid         number,
serial#     number,
start_ts    timestamp with time zone,
end_ts      timestamp with time zone
);

create index idx_trc_session_fil on trc_session(trc_file_id);

create table trc_trans (
trans_id   NUMBER GENERATED ALWAYS AS IDENTITY primary key,
session_id NUMBER REFERENCES trc_session ( session_id ) on delete cascade,
trc_file_id NUMBER NOT NULL REFERENCES trc_file ( trc_file_id ) on delete cascade,
row_num    number,
rlbk       number,
rd_only    number,
tim        number);

create index idx_trc_trans_sess on trc_trans(session_id);
create index idx_trc_trans_file on trc_trans(trc_file_id);

create table trc_client_identity (
cli_id     NUMBER GENERATED ALWAYS AS IDENTITY primary key,
session_id NUMBER REFERENCES trc_session ( session_id ) on delete cascade,
trc_file_id NUMBER NOT NULL REFERENCES trc_file ( trc_file_id ) on delete cascade,
client_id  varchar2(64),
service_name varchar2(64),
module     varchar2(64),
action     varchar2(64),
client_driver varchar2(64));

create index idx_trc_client_identity_sess on trc_client_identity(session_id);
create index idx_trc_client_identity_file on trc_client_identity(trc_file_id);

create table trc_statement (
stmt_id    NUMBER GENERATED ALWAYS AS IDENTITY primary key,
session_id NUMBER REFERENCES trc_session ( session_id ) on delete cascade,
trc_file_id NUMBER NOT NULL REFERENCES trc_file ( trc_file_id ) on delete cascade,
row_num    number,
trc_slot   number,
len        number,
dep        number,
uid#       number,
oct        number,
lid        number,
tim        number,
hv         number,
ad         varchar2(100),
sqlid      varchar2(100),
sql_text   clob,
cli_ident  NUMBER REFERENCES trc_client_identity ( cli_id ) on delete cascade
);

create index idx_trc_statement_sess on trc_statement(session_id);
create index idx_trc_statement_file on trc_statement(trc_file_id);

create table trc_call (
call_id    NUMBER GENERATED ALWAYS AS IDENTITY primary key,
stmt_id    NUMBER NOT NULL REFERENCES trc_statement ( stmt_id ) on delete cascade,
trc_file_id NUMBER NOT NULL REFERENCES trc_file ( trc_file_id ) on delete cascade,
parent_id  NUMBER REFERENCES trc_call ( call_id ) on delete cascade,
call_type  varchar2(100),
row_num    number,
trc_slot   number,
c          number,
e          number,
p          number,
cr         number,
cu         number,
mis        number,
r          number,
dep        number,
og         number,
plh        number,
tim        number,
typ        number --CLOSE call type field
);

create index idx_trc_call_sess on trc_call(stmt_id);
create index idx_trc_call_prnt on trc_call(parent_id);
create index idx_trc_call_file on trc_call(trc_file_id);

create table trc_binds (
stmt_id    NUMBER NOT NULL REFERENCES trc_statement ( stmt_id ) on delete cascade,
trc_file_id NUMBER NOT NULL REFERENCES trc_file ( trc_file_id ) on delete cascade,
call_id    NUMBER REFERENCES trc_call ( call_id ) on delete cascade,
row_num    number,
trc_slot   number,
bind#      number,
value      varchar2(4000)
);

create index idx_trc_binds_cll on trc_binds(call_id);
create index idx_trc_binds_file on trc_binds(trc_file_id);

create table trc_wait (
stmt_id    NUMBER NOT NULL REFERENCES trc_statement ( stmt_id ) on delete cascade,
trc_file_id NUMBER NOT NULL REFERENCES trc_file ( trc_file_id ) on delete cascade,
row_num    number,
trc_slot   number,
nam        varchar2(100),
ela        number,
p1_name    varchar2(256),
p1         number,
p2_name    varchar2(256),
p2         number,
p3_name    varchar2(256),
p3         number,
pars       varchar2(4000),
obj#       number,
tim        number
);

create index idx_trc_wait_stmt on trc_wait(stmt_id);
create index idx_trc_wait_file on trc_wait(trc_file_id);

create table trc_stat (
stmt_id    NUMBER NOT NULL REFERENCES trc_statement ( stmt_id ) on delete cascade,
trc_file_id NUMBER NOT NULL REFERENCES trc_file ( trc_file_id ) on delete cascade,
row_num    number,
trc_slot   number,
id         number,
cnt        number,
pid        number,
pos        number,
obj        number,
op         varchar2(1000),
cr         number,
pr         number,
pw         number,
str        number,
tim        number,
cost       number,
sz         number,
card       number);

create index idx_trc_stat_stmt on trc_stat(stmt_id);
create index idx_trc_stat_file on trc_stat(trc_file_id);

--Dictionaries
create table trc_dic_retention (
ret_code varchar2(32) primary key,
ret_display_name varchar2(100));

alter table trc_projects add constraint fk_proj_retention foreign key (retention) references trc_dic_retention;

create or replace view v$trc_projects as
select x.*,
case 
  when RETENTION = 'KEEPFOREVER' then 'Will be kept forever' 
  else
    case
      when RETENTION = 'DEFAULT' then 'Project will be removed after '|| to_char(created + TO_DSINTERVAL(COREMOD_API.getconf('TRACEPROJRETENTION')||' 00:00:00'),'YYYY-MON-DD HH24:MI' )
      else
        case
          when RETENTION = 'KEEPFILESONLY' then 'Parsed data will be removed in '
          when RETENTION = 'KEEPPARSEDONLY' then 'Trace files will be removed in '
          when RETENTION = 'CLEANUPOLD' then 'Old data will be removed in '
          else null
        end || COREMOD_API.getconf('TRACEFILERETENTION')|| ' days' 
    end
end factual_retention
from trc_projects x
where owner=decode(owner,'PUBLIC',owner,decode(is_public,'Y',owner,nvl(V('APP_USER'),'~^')))
;