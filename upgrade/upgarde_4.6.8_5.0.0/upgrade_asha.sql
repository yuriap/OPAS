-------------------------------------------------------------------------------------------------------------
--ASH Analyzer
-------------------------------------------------------------------------------------------------------------

define MODNM=ASH_ANALYZER
@../../modules/ash_analyzer/install/version.sql

delete from opas_config where modname='&MODNM.' and cgroup='RETENTION' and ckey='EXPIMPSESS';
INSERT INTO opas_config (modname,cgroup,ckey,cvalue,descr) VALUES ('&MODNM.','RETENTION','EXPIMPSESS',        0.03,'Retention time in days for ASHA export/import sessions.');

delete from opas_expimp_compat where modname='&MODNM.';
INSERT INTO opas_expimp_compat ( modname, src_version, trg_version) VALUES ( '&MODNM.',  '3.4.6',  '&MODVER.');
INSERT INTO opas_expimp_compat ( modname, src_version, trg_version) VALUES ( '&MODNM.',  '3.4.7',  '&MODVER.');
INSERT INTO opas_expimp_compat ( modname, src_version, trg_version) VALUES ( '&MODNM.',  '3.4.8',  '&MODVER.');
INSERT INTO opas_expimp_compat ( modname, src_version, trg_version) VALUES ( '&MODNM.',  '&MODVER.',  '&MODVER.');
commit;

set define off

@../../modules/ash_analyzer/source/ASHA_CUBE_API_BODY.SQL
@../../modules/ash_analyzer/source/ASHA_EXPIMP_BODY.SQL

set define on

exec COREMOD.register(p_modname => '&MODNM.', p_modver => '&MODVER.', p_installed => sysdate);

commit;

begin
  ASHA_EXPIMP.init();
end;
/