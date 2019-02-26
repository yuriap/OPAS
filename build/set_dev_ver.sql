@opas

define MODNM=OPASAPP
@../install/version.sql 
update opas_modules set modver='&OPASVER.' where modname='&MODNM.';

define MODNM=OPASCORE
@../modules/core/install/version.sql 
update opas_modules set modver='&MODVER.' where modname='&MODNM.';

define MODNM=SQL_TRACE
@../modules/sql_trace/install/version.sql 
update opas_modules set modver='&MODVER.' where modname='&MODNM.';

define MODNM=ASH_ANALYZER
@../modules/ash_analyzer/install/version.sql 
update opas_modules set modver='&MODVER.' where modname='&MODNM.';

define MODNM=AWR_WAREHOUSE
@../modules/awr_warehouse/install/version.sql 
update opas_modules set modver='&MODVER.' where modname='&MODNM.';

commit;