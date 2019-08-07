create table db_growth_projects (
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

create table db_growth_parameters (
proj_id         number not null references db_growth_projects(proj_id) on delete cascade,
src_dblink      varchar2(128) not null references opas_db_links (DB_LINK_NAME) on delete cascade,
scheme_list     varchar2(4000) not null,
schedule        varchar2(512) not null,
start_date      date not null,
last_changed    timestamp(6),
last_validated  timestamp(6),
job_name        varchar2(100),
last_updated    timestamp,
tot_size        number,
delta           number,
delta_alert     number,
size_alert      number
);

create unique index idx_db_growth_params_proj on db_growth_parameters(proj_id);
create index idx_db_growth_param_src  on db_growth_parameters(src_dblink);

CREATE OR REPLACE FORCE VIEW V$DB_GROWTH_PROJECTS AS 
select
  proj_id,
  proj_name,
  owner,
  created,
  status,
  proj_note,
  keep_forever,
  is_public,
  priority,
  retention,
  sizes,
  case when trim(proj_warnings) is null then null else 'Warning! '||proj_warnings end proj_warnings
from (
select x.*,
case
  when keep_forever = 'Y' 
    then 'Will be kept forever'
  else
    replace('Will be kept till <%p1>','<%p1>',to_char(created + TO_DSINTERVAL(COREMOD_API.getconf('PROJECTRETENTION',DB_GROWTH_API.getMODNAME)||' 00:00:00'),'YYYY-MON-DD HH24:MI' ))
end retention,
'Schema size: '||case when pars.tot_size is not null then case when pars.tot_size>=0 then dbms_xplan.format_size(pars.tot_size) else '-'||dbms_xplan.format_size(abs(pars.tot_size)) end else 'N/A' end || 
'; Delta: ' ||   case when pars.delta is not null then case when pars.delta>=0 then dbms_xplan.format_size(pars.delta) else '-'||dbms_xplan.format_size(abs(pars.delta)) end else 'N/A' end sizes,
case when keep_forever = 'N' and created + COREMOD_API.getconf('PROJECTRETENTION',DB_GROWTH_API.getMODNAME) < (sysdate + COREMOD_API.getconf('SHOWEXPBEFORE',COREMOD_API.getMODNAME)) then ' Project is expiring.' else null end ||
case when tot_size > nvl(size_alert,1e50) then ' DB Size Alert!' else null end ||
case when delta > nvl(delta_alert,1e50) then ' DB Delta Alert!' else null end
 proj_warnings
from db_growth_projects x, db_growth_parameters pars
where x.proj_id=pars.proj_id(+)
  and owner=decode(owner,'PUBLIC',owner,decode(is_public,'Y',owner,nvl(V('APP_USER'),'~^'))));

create table db_growth_par_validation (
proj_id         number not null references db_growth_projects(proj_id) on delete cascade,
status          varchar2(100),
message         varchar2(4000)
);

create index idx_db_growth_par_val on db_growth_par_validation(proj_id);

create table db_growth_tables (
proj_id          number not null references db_growth_projects(proj_id) on delete cascade,
last_updated     timestamp,
owner            VARCHAR2(128 BYTE),
table_name       VARCHAR2(128 BYTE),
tablespace_name  VARCHAR2(30 BYTE),
cluster_name     VARCHAR2(128 BYTE),
iot_name         VARCHAR2(128 BYTE),
status           VARCHAR2(8 BYTE),
partitioned      VARCHAR2(3 BYTE),
iot_type         VARCHAR2(12 BYTE),
temporary        VARCHAR2(1 BYTE),
secondary        VARCHAR2(1 BYTE),
nested           VARCHAR2(3 BYTE),
cluster_owner    VARCHAR2(128 BYTE),
compression      VARCHAR2(8 BYTE),
compress_for     VARCHAR2(30 BYTE),
segment_created  VARCHAR2(3 BYTE)
);

alter table db_growth_tables ROW STORE COMPRESS ADVANCED;

create index idx_db_growth_tabs on db_growth_tables(proj_id,table_name);

create table db_growth_indexes (
proj_id         number not null references db_growth_projects(proj_id) on delete cascade,
last_updated    timestamp,
OWNER           VARCHAR2(128 BYTE), 
INDEX_NAME      VARCHAR2(128 BYTE), 
INDEX_TYPE      VARCHAR2(27 BYTE), 
TABLE_OWNER     VARCHAR2(128 BYTE), 
TABLE_NAME      VARCHAR2(128 BYTE), 
TABLE_TYPE      VARCHAR2(11 BYTE), 
COMPRESSION     VARCHAR2(13 BYTE), 
PREFIX_LENGTH   NUMBER, 
TABLESPACE_NAME VARCHAR2(30 BYTE), 
INCLUDE_COLUMN  NUMBER, 
STATUS          VARCHAR2(8 BYTE), 
PARTITIONED     VARCHAR2(3 BYTE), 
TEMPORARY       VARCHAR2(1 BYTE), 
SECONDARY       VARCHAR2(1 BYTE), 
FUNCIDX_STATUS  VARCHAR2(8 BYTE), 
JOIN_INDEX      VARCHAR2(3 BYTE), 
DROPPED         VARCHAR2(3 BYTE), 
SEGMENT_CREATED VARCHAR2(3 BYTE) 
);

alter table db_growth_indexes ROW STORE COMPRESS ADVANCED;

create index idx_db_growth_idxs on db_growth_indexes(proj_id,INDEX_NAME);

create table db_growth_lobs (
proj_id         number not null references db_growth_projects(proj_id) on delete cascade,
last_updated    timestamp,
OWNER           VARCHAR2(128 BYTE), 
TABLE_NAME      VARCHAR2(128 BYTE), 
COLUMN_NAME     VARCHAR2(4000 BYTE), 
SEGMENT_NAME    VARCHAR2(128 BYTE), 
TABLESPACE_NAME VARCHAR2(30 BYTE), 
INDEX_NAME      VARCHAR2(128 BYTE), 
CHUNK           NUMBER, 
COMPRESSION     VARCHAR2(6 BYTE), 
DEDUPLICATION   VARCHAR2(15 BYTE), 
IN_ROW          VARCHAR2(3 BYTE), 
PARTITIONED     VARCHAR2(3 BYTE), 
SECUREFILE      VARCHAR2(3 BYTE), 
SEGMENT_CREATED VARCHAR2(3 BYTE)
);

alter table db_growth_lobs ROW STORE COMPRESS ADVANCED;

create index idx_db_growth_lobs on db_growth_lobs(proj_id,TABLE_NAME,COLUMN_NAME,SEGMENT_NAME);

create table db_growth_segs (
proj_id         number not null references db_growth_projects(proj_id) on delete cascade,
last_updated    timestamp,
OWNER           VARCHAR2(128 BYTE),
SEGMENT_TYPE    VARCHAR2(18 BYTE), 
SEGMENT_NAME    VARCHAR2(128 BYTE), 
PARTITION_NAME  VARCHAR2(128 BYTE), 
TABLESPACE_NAME VARCHAR2(30 BYTE), 
SIZE_B NUMBER
);

alter table DB_GROWTH_SEGS ROW STORE COMPRESS ADVANCED;

create index idx_db_growth_segs on db_growth_segs(proj_id);


create materialized view DB_GROWTH_SIZES 
build immediate
refresh on demand
as
select proj_id,
       LAST_UPDATED,
       size_b,
       size_b - lag(size_b) over(partition by proj_id order by LAST_UPDATED) delta
  from (select proj_id,trunc(LAST_UPDATED,'mi') LAST_UPDATED, sum(size_b) size_b
          from DB_GROWTH_SEGS
         group by proj_id, trunc(LAST_UPDATED,'mi'))
;

create index idx_DB_GROWTH_SIZES_proj on DB_GROWTH_SIZES(proj_id);