delete from opas_config where modname='&MODNM.';
delete from OPAS_CLEANUP_TASKS where modname='&MODNM.';
delete from opas_dictionary where modname='&MODNM.';
delete from opas_scripts where modname='&MODNM.';
delete from opas_files where modname='&MODNM.';
delete from opas_reports where modname='&MODNM.';
delete from opas_modules where modname='&MODNM.';

commit;
