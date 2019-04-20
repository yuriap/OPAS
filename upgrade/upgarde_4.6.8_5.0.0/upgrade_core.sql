-------------------------------------------------------------------------------------------------------------
-- OPAS Core
-------------------------------------------------------------------------------------------------------------

define MODNM=OPASCORE
@../../modules/core/install/version.sql
@../../modules/core/install/install_config

conn &localscheme./&localscheme.@&localdb.

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
	case when m.MODNAME is not null then to_char(x.created + to_number(COREMOD_API.getconf('EXPIMPSESS',m.MODNAME)),'YYYY-MON-DD HH24:MI' ) else null end expiration
from opas_expimp_sessions x, opas_expimp_metadata m, opas_files f
where x.owner=decode(x.owner,'PUBLIC',x.owner,nvl(V('APP_USER'),'~^'))
and x.sess_id=m.sess_id and x.expimp_file=f.file_id(+);

delete from opas_expimp_compat where modname='&MODNM.';
INSERT INTO opas_expimp_compat ( modname, src_version, trg_version) VALUES ( '&MODNM.',  '1.3.5',  '&MODVER.');
INSERT INTO opas_expimp_compat ( modname, src_version, trg_version) VALUES ( '&MODNM.',  '1.3.6',  '&MODVER.');
INSERT INTO opas_expimp_compat ( modname, src_version, trg_version) VALUES ( '&MODNM.',  '&MODVER.',  '&MODVER.');
commit;

set define off

@../../modules/core/source/COREMOD_EXPIMP_SPEC.SQL
@../../modules/core/source/COREMOD_EXPIMP_BODY.SQL
@../../modules/core/source/COREMOD_LOG_SPEC.SQL
@../../modules/core/source/COREMOD_LOG_BODY.SQL
@../../modules/core/source/COREMOD_REPORT_UTILS_BODY.SQL
@../../modules/core/source/COREMOD_REPORTS_BODY.SQL

set define on

set define ~

--declare
--  l_script clob;
--begin
--  l_script := 
--q'^
--@../../modules/core/scripts/__sqlmon_hist.sql
--^';
--  delete from opas_scripts where script_id='PROC_SQLMON_HIST';
--  insert into opas_scripts (script_id,modname,script_content) values ('PROC_SQLMON_HIST','~MODNM.',l_script);  
--  COREMOD_REPORT_UTILS.prepare_saved_sql_script (  P_SCRIPT_NAME => 'PROC_SQLMON_HIST');
--end;
--/

set define &

exec COREMOD.register(p_modname => '&MODNM.', p_modver => '&MODVER.', p_installed => sysdate);

commit;

begin
  COREMOD_EXPIMP.init();
end;
/
