-------------------------------------------------------------------------------------------------------------
-- OPAS Core
-------------------------------------------------------------------------------------------------------------

define MODNM=OPASCORE
@../../modules/core/install/version.sql
@../../modules/core/install/install_config

conn sys/&localsys.@&localdb. as sysdba

create or replace directory &OPASEXPIMP_DIR. as '&OPASEXPIMP_DIRPATH.';
grant read, write on directory &OPASEXPIMP_DIR. to &localscheme.;
grant create table to &localscheme.;

conn &localscheme./&localscheme.@&localdb.

alter table opas_task_pars add list_par    varchar2(4000);

declare
  l_cn varchar2(128);
begin
  select constraint_name into l_cn from user_constraints where table_name='OPAS_REPORTS' and r_constraint_name=(select constraint_name from user_constraints where table_name='OPAS_REPORTS' and constraint_type='P');
  execute immediate 'alter table OPAS_REPORTS drop constraint '||l_cn;
  execute immediate 'alter table OPAS_REPORTS add constraint FK_PARENT_REPORT foreign key (parent_id) references opas_reports(report_id) on delete set null';
end;
/

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

create table opas_expimp_compat (
modname        varchar2(128) references opas_modules(modname) on delete cascade,
src_version    varchar2(100),
trg_version    varchar2(100)
);

create or replace view v$opas_expimp_sessions as
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
	case when m.MODNAME is not null then to_char(x.created + TO_DSINTERVAL(COREMOD_API.getconf('EXPIMPSESS',m.MODNAME)||' 00:00:00'),'YYYY-MON-DD HH24:MI' ) else null end expiration
from opas_expimp_sessions x, opas_expimp_metadata m, opas_files f
where x.owner=decode(x.owner,'PUBLIC',x.owner,nvl(V('APP_USER'),'~^'))
and x.sess_id=m.sess_id and x.expimp_file=f.file_id(+);

INSERT INTO opas_config (modname,cgroup,ckey,cvalue,descr) VALUES ('&MODNM.','EXPIMP','EXPIMPDIR','&OPASEXPIMP_DIR.', 'Directory object for EXP/IMP operation');
INSERT INTO opas_config (modname,cgroup,ckey,cvalue,descr) VALUES ('&MODNM.','EXPIMP','EXPIMPVER','12.2', 'Compatibility level for EXP/IMP dump');
INSERT INTO opas_expimp_compat ( modname, src_version, trg_version) VALUES ( '&MODNM.',  '&MODVER.',  '&MODVER.');
commit;


begin
  COREMOD_TASKS.create_task (  p_taskname  => 'OPAS_UPLOAD_IMP_FILE',
                               p_modname   => '&MODNM.',
                               p_is_public => 'Y', 
                               p_task_body => 'begin COREMOD_EXPIMP.import_file (p_exp_sess_id => <B1>) ; end;');
end;
/

set define off

@../../modules/core/source/COREMOD_REPORT_UTILS_SPEC.SQL
@../../modules/core/source/COREMOD_REPORT_UTILS_BODY.SQL
@../../modules/core/source/COREMOD_EXPIMP_SPEC.SQL
@../../modules/core/source/COREMOD_EXPIMP_BODY.SQL
@../../modules/core/source/COREFILE_API_SPEC.SQL
@../../modules/core/source/COREFILE_API_BODY.SQL
@../../modules/core/source/COREMOD_API_SPEC.SQL
@../../modules/core/source/COREMOD_API_BODY.SQL
@../../modules/core/source/COREMOD_REPORTS_SPEC.SQL
@../../modules/core/source/COREMOD_REPORTS_BODY.SQL
@../../modules/core/source/COREMOD_TASKS_SPEC.SQL
@../../modules/core/source/COREMOD_TASKS_BODY.SQL

set define on

set define ~

/*
declare
  l_script clob;
begin
  l_script := 
q'^
@../../modules/core/scripts/__prn_tbl_html.sql
^';
  delete from opas_scripts where script_id='PROC_PRNHTMLTBL';
  insert into opas_scripts (script_id,modname,script_content) values ('PROC_PRNHTMLTBL','~MODNM.',l_script);  
  COREMOD_REPORT_UTILS.prepare_saved_sql_script (  P_SCRIPT_NAME => 'PROC_PRNHTMLTBL');
end;
/
*/
set define &

--set right mime type (required by ORDS)
update  opas_files set file_mimetype='TEXT/HTML' where file_mimetype='HTML';

exec COREMOD.register(p_modname => '&MODNM.', p_modver => '&MODVER.', p_installed => sysdate);

commit;

begin
  COREMOD_EXPIMP.init();
end;
/
