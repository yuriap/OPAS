delete from opas_expimp_compat where modname='&MODNM.';
INSERT INTO opas_expimp_compat ( modname, src_version, trg_version) VALUES ( '&MODNM.',  '2.3.0',  '&MODVER.');
INSERT INTO opas_expimp_compat ( modname, src_version, trg_version) VALUES ( '&MODNM.',  '&MODVER.',  '&MODVER.');