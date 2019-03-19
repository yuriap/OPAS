-------------------------------------------------------------------------------------------------------------
-- OPAS Core
-------------------------------------------------------------------------------------------------------------

define MODNM=OPASCORE
@../../modules/core/install/version.sql
@../../modules/core/install/install_config

conn &localscheme./&localscheme.@&localdb.

create table opas_expimp_params (
sess_id        NUMBER references opas_expimp_sessions(sess_id) on delete cascade,
par_name       varchar2(128),
par_value      varchar2(4000)
);

create index idx_opas_expimp_params_sess   on opas_expimp_params(sess_id);

delete from opas_expimp_compat where modname='&MODNM.';
INSERT INTO opas_expimp_compat ( modname, src_version, trg_version) VALUES ( '&MODNM.',  '1.3.5',  '&MODVER.');
INSERT INTO opas_expimp_compat ( modname, src_version, trg_version) VALUES ( '&MODNM.',  '&MODVER.',  '&MODVER.');
commit;

set define off

@../../modules/core/source/COREMOD_EXPIMP_SPEC.SQL
@../../modules/core/source/COREMOD_EXPIMP_BODY.SQL

set define on

set define ~

declare
  l_script clob;
begin
  l_script := 
q'^
@../../modules/core/scripts/__sqlmon_hist.sql
^';
  delete from opas_scripts where script_id='PROC_SQLMON_HIST';
  insert into opas_scripts (script_id,modname,script_content) values ('PROC_SQLMON_HIST','~MODNM.',l_script);  
  COREMOD_REPORT_UTILS.prepare_saved_sql_script (  P_SCRIPT_NAME => 'PROC_SQLMON_HIST');
end;
/

set define &

exec COREMOD.register(p_modname => '&MODNM.', p_modver => '&MODVER.', p_installed => sysdate);

commit;

begin
  COREMOD_EXPIMP.init();
end;
/
