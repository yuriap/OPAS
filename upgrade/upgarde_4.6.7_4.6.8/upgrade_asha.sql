-------------------------------------------------------------------------------------------------------------
--ASH Analyzer
-------------------------------------------------------------------------------------------------------------

define MODNM=ASH_ANALYZER
@../../modules/ash_analyzer/install/version.sql

delete from opas_expimp_compat where modname='&MODNM.';
INSERT INTO opas_expimp_compat ( modname, src_version, trg_version) VALUES ( '&MODNM.',  '3.4.6',  '&MODVER.');
INSERT INTO opas_expimp_compat ( modname, src_version, trg_version) VALUES ( '&MODNM.',  '3.4.7',  '&MODVER.');
INSERT INTO opas_expimp_compat ( modname, src_version, trg_version) VALUES ( '&MODNM.',  '&MODVER.',  '&MODVER.');
commit;

set define off

@../../modules/ash_analyzer/source/ASHA_PROJ_API_BODY.SQL

set define on

exec COREMOD.register(p_modname => '&MODNM.', p_modver => '&MODVER.', p_installed => sysdate);

commit;

begin
  ASHA_EXPIMP.init();
end;
/