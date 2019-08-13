@opas

define MODNM=OPASAPP
@../install/version.sql 
update opas_modules set modver='&OPASVER.' where modname='&MODNM.';

define MODNM=OPASCORE
@../modules/core/install/version.sql 
update opas_modules set modver='&MODVER.' where modname='&MODNM.';
@../modules/core/data/expimp_compat.sql 

define MODNM=SQL_TRACE
@../modules/sql_trace/install/version.sql 
update opas_modules set modver='&MODVER.' where modname='&MODNM.';
@../modules/sql_trace/data/expimp_compat.sql 

define MODNM=ASH_ANALYZER
@../modules/ash_analyzer/install/version.sql 
update opas_modules set modver='&MODVER.' where modname='&MODNM.';
@../modules/ash_analyzer/data/expimp_compat.sql 

define MODNM=AWR_WAREHOUSE
@../modules/awr_warehouse/install/version.sql 
update opas_modules set modver='&MODVER.' where modname='&MODNM.';
@../modules/awr_warehouse/data/expimp_compat.sql

define MODNM=DB_GROWTH
@../modules/db_growth/install/version.sql 
update opas_modules set modver='&MODVER.' where modname='&MODNM.';
@../modules/db_growth/data/expimp_compat.sql


commit;