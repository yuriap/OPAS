@opas40
set timing off
define COREMODPATH="..\modules\core\source\"

rem "

set heading off
set feedback off
set termout OFF
set trimspool on
set lines 5000
set pages 0
set echo off


spool &COREMODPATH.\COREFILE_API_SPEC.SQL
prompt CREATE OR REPLACE
select text from user_source where name='COREFILE_API' and type='PACKAGE' order by line;
prompt /
spool off
spool &COREMODPATH.\COREFILE_API_BODY.SQL
prompt CREATE OR REPLACE
select text from user_source where name='COREFILE_API' and type='PACKAGE BODY' order by line;
prompt /
spool off

spool &COREMODPATH.\COREMOD_API_SPEC.SQL
prompt CREATE OR REPLACE
select text from user_source where name='COREMOD_API' and type='PACKAGE' order by line;
prompt /
spool off
spool &COREMODPATH.\COREMOD_API_BODY.SQL
prompt CREATE OR REPLACE
select text from user_source where name='COREMOD_API' and type='PACKAGE BODY' order by line;
prompt /
spool off

spool &COREMODPATH.\COREMOD_CLEANUP_SPEC.SQL
prompt CREATE OR REPLACE
select text from user_source where name='COREMOD_CLEANUP' and type='PACKAGE' order by line;
prompt /
spool off
spool &COREMODPATH.\COREMOD_CLEANUP_BODY.SQL
prompt CREATE OR REPLACE
select text from user_source where name='COREMOD_CLEANUP' and type='PACKAGE BODY' order by line;
prompt /
spool off

spool &COREMODPATH.\COREMOD_LOG_SPEC.SQL
prompt CREATE OR REPLACE
select text from user_source where name='COREMOD_LOG' and type='PACKAGE' order by line;
prompt /
spool off
spool &COREMODPATH.\COREMOD_LOG_BODY.SQL
prompt CREATE OR REPLACE
select text from user_source where name='COREMOD_LOG' and type='PACKAGE BODY' order by line;
prompt /
spool off

spool &COREMODPATH.\COREMOD_SPEC.SQL
prompt CREATE OR REPLACE
select text from user_source where name='COREMOD' and type='PACKAGE' order by line;
prompt /
spool off
spool &COREMODPATH.\COREMOD_BODY.SQL
prompt CREATE OR REPLACE
select text from user_source where name='COREMOD' and type='PACKAGE BODY' order by line;
prompt /
spool off

spool &COREMODPATH.\COREMOD_REPORT_UTILS_SPEC.SQL
prompt CREATE OR REPLACE
select text from user_source where name='COREMOD_REPORT_UTILS' and type='PACKAGE' order by line;
prompt /
spool off
spool &COREMODPATH.\COREMOD_REPORT_UTILS_BODY.SQL
prompt CREATE OR REPLACE
select text from user_source where name='COREMOD_REPORT_UTILS' and type='PACKAGE BODY' order by line;
prompt /
spool off

spool &COREMODPATH.\COREMOD_SEC_SPEC.SQL
prompt CREATE OR REPLACE
select text from user_source where name='COREMOD_SEC' and type='PACKAGE' order by line;
prompt /
spool off
spool &COREMODPATH.\COREMOD_SEC_BODY.SQL
prompt CREATE OR REPLACE
select text from user_source where name='COREMOD_SEC' and type='PACKAGE BODY' order by line;
prompt /
spool off

spool &COREMODPATH.\COREMOD_TASKS_SPEC.SQL
prompt CREATE OR REPLACE
select text from user_source where name='COREMOD_TASKS' and type='PACKAGE' order by line;
prompt /
spool off
spool &COREMODPATH.\COREMOD_TASKS_BODY.SQL
prompt CREATE OR REPLACE
select text from user_source where name='COREMOD_TASKS' and type='PACKAGE BODY' order by line;
prompt /
spool off

spool &COREMODPATH.\COREMOD_REPORTS_SPEC.SQL
prompt CREATE OR REPLACE
select text from user_source where name='COREMOD_REPORTS' and type='PACKAGE' order by line;
prompt /
spool off
spool &COREMODPATH.\COREMOD_REPORTS_BODY.SQL
prompt CREATE OR REPLACE
select text from user_source where name='COREMOD_REPORTS' and type='PACKAGE BODY' order by line;
prompt /
spool off

spool &COREMODPATH.\COREMOD_INTEGRATION_SPEC.SQL
prompt CREATE OR REPLACE
select text from user_source where name='COREMOD_INTEGRATION' and type='PACKAGE' order by line;
prompt /
spool off
spool &COREMODPATH.\COREMOD_INTEGRATION_BODY.SQL
prompt CREATE OR REPLACE
select text from user_source where name='COREMOD_INTEGRATION' and type='PACKAGE BODY' order by line;
prompt /
spool off

spool &COREMODPATH.\COREMOD_EXPIMP_SPEC.SQL
prompt CREATE OR REPLACE
select text from user_source where name='COREMOD_EXPIMP' and type='PACKAGE' order by line;
prompt /
spool off
spool &COREMODPATH.\COREMOD_EXPIMP_BODY.SQL
prompt CREATE OR REPLACE
select text from user_source where name='COREMOD_EXPIMP' and type='PACKAGE BODY' order by line;
prompt /
spool off

--=============================================================================================
--=============================================================================================
--=============================================================================================

define COREMODPATH="..\modules\sql_trace\source\"

rem "

spool &COREMODPATH.\TRC_FILE_API_SPEC.SQL
prompt CREATE OR REPLACE
select text from user_source where name='TRC_FILE_API' and type='PACKAGE' order by line;
prompt /
spool off
spool &COREMODPATH.\TRC_FILE_API_BODY.SQL
prompt CREATE OR REPLACE
select text from user_source where name='TRC_FILE_API' and type='PACKAGE BODY' order by line;
prompt /
spool off

spool &COREMODPATH.\TRC_FILE_LCC_SPEC.SQL
prompt CREATE OR REPLACE
select text from user_source where name='TRC_FILE_LCC' and type='PACKAGE' order by line;
prompt /
spool off
spool &COREMODPATH.\TRC_FILE_LCC_BODY.SQL
prompt CREATE OR REPLACE
select text from user_source where name='TRC_FILE_LCC' and type='PACKAGE BODY' order by line;
prompt /
spool off

spool &COREMODPATH.\TRC_PROCESSFILE_SPEC.SQL
prompt CREATE OR REPLACE
select text from user_source where name='TRC_PROCESSFILE' and type='PACKAGE' order by line;
prompt /
spool off
spool &COREMODPATH.\TRC_PROCESSFILE_BODY.SQL
prompt CREATE OR REPLACE
select text from user_source where name='TRC_PROCESSFILE' and type='PACKAGE BODY' order by line;
prompt /
spool off

spool &COREMODPATH.\TRC_PROJ_API_SPEC.SQL
prompt CREATE OR REPLACE
select text from user_source where name='TRC_PROJ_API' and type='PACKAGE' order by line;
prompt /
spool off
spool &COREMODPATH.\TRC_PROJ_API_BODY.SQL
prompt CREATE OR REPLACE
select text from user_source where name='TRC_PROJ_API' and type='PACKAGE BODY' order by line;
prompt /
spool off

spool &COREMODPATH.\TRC_PROJ_LCC_SPEC.SQL
prompt CREATE OR REPLACE
select text from user_source where name='TRC_PROJ_LCC' and type='PACKAGE' order by line;
prompt /
spool off
spool &COREMODPATH.\TRC_PROJ_LCC_BODY.SQL
prompt CREATE OR REPLACE
select text from user_source where name='TRC_PROJ_LCC' and type='PACKAGE BODY' order by line;
prompt /
spool off

spool &COREMODPATH.\TRC_REPORT_SPEC.SQL
prompt CREATE OR REPLACE
select text from user_source where name='TRC_REPORT' and type='PACKAGE' order by line;
prompt /
spool off
spool &COREMODPATH.\TRC_REPORT_BODY.SQL
prompt CREATE OR REPLACE
select text from user_source where name='TRC_REPORT' and type='PACKAGE BODY' order by line;
prompt /

spool &COREMODPATH.\TRC_EXPIMP_SPEC.SQL
prompt CREATE OR REPLACE
select text from user_source where name='TRC_EXPIMP' and type='PACKAGE' order by line;
prompt /
spool off
spool &COREMODPATH.\TRC_EXPIMP_BODY.SQL
prompt CREATE OR REPLACE
select text from user_source where name='TRC_EXPIMP' and type='PACKAGE BODY' order by line;
prompt /

--=============================================================================================
--=============================================================================================
--=============================================================================================

define COREMODPATH="..\modules\ash_analyzer\source\"

rem "

spool &COREMODPATH.\ASHA_CUBE_PKG_SPEC.SQL
prompt CREATE OR REPLACE
select text from user_source where name='ASHA_CUBE_PKG' and type='PACKAGE' order by line;
prompt /
spool off
spool &COREMODPATH.\ASHA_CUBE_PKG_BODY.SQL
prompt CREATE OR REPLACE
select text from user_source where name='ASHA_CUBE_PKG' and type='PACKAGE BODY' order by line;
prompt /
spool off

spool &COREMODPATH.\ASHA_CUBE_API_SPEC.SQL
prompt CREATE OR REPLACE
select text from user_source where name='ASHA_CUBE_API' and type='PACKAGE' order by line;
prompt /
spool off
spool &COREMODPATH.\ASHA_CUBE_API_BODY.SQL
prompt CREATE OR REPLACE
select text from user_source where name='ASHA_CUBE_API' and type='PACKAGE BODY' order by line;
prompt /
spool off

spool &COREMODPATH.\ASHA_PROJ_API_SPEC.SQL
prompt CREATE OR REPLACE
select text from user_source where name='ASHA_PROJ_API' and type='PACKAGE' order by line;
prompt /
spool off
spool &COREMODPATH.\ASHA_PROJ_API_BODY.SQL
prompt CREATE OR REPLACE
select text from user_source where name='ASHA_PROJ_API' and type='PACKAGE BODY' order by line;
prompt /
spool off

spool &COREMODPATH.\ASHA_PROJ_LCC_SPEC.SQL
prompt CREATE OR REPLACE
select text from user_source where name='ASHA_PROJ_LCC' and type='PACKAGE' order by line;
prompt /
spool off
spool &COREMODPATH.\ASHA_PROJ_LCC_BODY.SQL
prompt CREATE OR REPLACE
select text from user_source where name='ASHA_PROJ_LCC' and type='PACKAGE BODY' order by line;
prompt /
spool off


spool &COREMODPATH.\ASHA_EXPIMP_SPEC.SQL
prompt CREATE OR REPLACE
select text from user_source where name='ASHA_EXPIMP' and type='PACKAGE' order by line;
prompt /
spool off
spool &COREMODPATH.\ASHA_EXPIMP_BODY.SQL
prompt CREATE OR REPLACE
select text from user_source where name='ASHA_EXPIMP' and type='PACKAGE BODY' order by line;
prompt /
spool off

--=============================================================================================
--=============================================================================================
--=============================================================================================

define COREMODPATH="..\modules\awr_warehouse\source\"

rem "

spool &COREMODPATH.\AWRWH_API_SPEC.SQL
prompt CREATE OR REPLACE
select text from user_source where name='AWRWH_API' and type='PACKAGE' order by line;
prompt /
spool off
spool &COREMODPATH.\AWRWH_API_BODY.SQL
prompt CREATE OR REPLACE
select text from user_source where name='AWRWH_API' and type='PACKAGE BODY' order by line;
prompt /
spool off

spool &COREMODPATH.\AWRWH_FILE_API_SPEC.SQL
prompt CREATE OR REPLACE
select text from user_source where name='AWRWH_FILE_API' and type='PACKAGE' order by line;
prompt /
spool off
spool &COREMODPATH.\AWRWH_FILE_API_BODY.SQL
prompt CREATE OR REPLACE
select text from user_source where name='AWRWH_FILE_API' and type='PACKAGE BODY' order by line;
prompt /
spool off

spool &COREMODPATH.\AWRWH_FILE_LCC_SPEC.SQL
prompt CREATE OR REPLACE
select text from user_source where name='AWRWH_FILE_LCC' and type='PACKAGE' order by line;
prompt /
spool off
spool &COREMODPATH.\AWRWH_FILE_LCC_BODY.SQL
prompt CREATE OR REPLACE
select text from user_source where name='AWRWH_FILE_LCC' and type='PACKAGE BODY' order by line;
prompt /
spool off

spool &COREMODPATH.\AWRWH_PROJ_API_SPEC.SQL
prompt CREATE OR REPLACE
select text from user_source where name='AWRWH_PROJ_API' and type='PACKAGE' order by line;
prompt /
spool off
spool &COREMODPATH.\AWRWH_PROJ_API_BODY.SQL
prompt CREATE OR REPLACE
select text from user_source where name='AWRWH_PROJ_API' and type='PACKAGE BODY' order by line;
prompt /
spool off

spool &COREMODPATH.\AWRWH_PROJ_LCC_SPEC.SQL
prompt CREATE OR REPLACE
select text from user_source where name='AWRWH_PROJ_LCC' and type='PACKAGE' order by line;
prompt /
spool off
spool &COREMODPATH.\AWRWH_PROJ_LCC_BODY.SQL
prompt CREATE OR REPLACE
select text from user_source where name='AWRWH_PROJ_LCC' and type='PACKAGE BODY' order by line;
prompt /
spool off


spool &COREMODPATH.\AWRWH_REPORT_API_SPEC.SQL
prompt CREATE OR REPLACE
select text from user_source where name='AWRWH_REPORT_API' and type='PACKAGE' order by line;
prompt /
spool off
spool &COREMODPATH.\AWRWH_REPORT_API_BODY.SQL
prompt CREATE OR REPLACE
select text from user_source where name='AWRWH_REPORT_API' and type='PACKAGE BODY' order by line;
prompt /
spool off


spool &COREMODPATH.\AWRWH_CALC_ASH_CUBE_FNC.SQL
prompt CREATE OR REPLACE
select text from user_source where name='AWRWH_CALC_ASH_CUBE' and type='FUNCTION' order by line;
prompt /
spool off

spool &COREMODPATH.\AWRWH_EXPIMP_SPEC.SQL
prompt CREATE OR REPLACE
select text from user_source where name='AWRWH_EXPIMP' and type='PACKAGE' order by line;
prompt /
spool off
spool &COREMODPATH.\AWRWH_EXPIMP_BODY.SQL
prompt CREATE OR REPLACE
select text from user_source where name='AWRWH_EXPIMP' and type='PACKAGE BODY' order by line;
prompt /
spool off

--=============================================================================================
--=============================================================================================
--=============================================================================================

define COREMODPATH="..\modules\db_growth\source\"

rem "

spool &COREMODPATH.\DB_GROWTH_API_SPEC.SQL
prompt CREATE OR REPLACE
select text from user_source where name='DB_GROWTH_API' and type='PACKAGE' order by line;
prompt /
spool off
spool &COREMODPATH.\DB_GROWTH_API_BODY.SQL
prompt CREATE OR REPLACE
select text from user_source where name='DB_GROWTH_API' and type='PACKAGE BODY' order by line;
prompt /
spool off

spool &COREMODPATH.\DB_GROWTH_EXPIMP_SPEC.SQL
prompt CREATE OR REPLACE
select text from user_source where name='DB_GROWTH_EXPIMP' and type='PACKAGE' order by line;
prompt /
spool off
spool &COREMODPATH.\DB_GROWTH_EXPIMP_BODY.SQL
prompt CREATE OR REPLACE
select text from user_source where name='DB_GROWTH_EXPIMP' and type='PACKAGE BODY' order by line;
prompt /
spool off

spool &COREMODPATH.\DB_GROWTH_PROJ_API_SPEC.SQL
prompt CREATE OR REPLACE
select text from user_source where name='DB_GROWTH_PROJ_API' and type='PACKAGE' order by line;
prompt /
spool off
spool &COREMODPATH.\DB_GROWTH_PROJ_API_BODY.SQL
prompt CREATE OR REPLACE
select text from user_source where name='DB_GROWTH_PROJ_API' and type='PACKAGE BODY' order by line;
prompt /
spool off

spool &COREMODPATH.\DB_GROWTH_PROJ_LCC_SPEC.SQL
prompt CREATE OR REPLACE
select text from user_source where name='DB_GROWTH_PROJ_LCC' and type='PACKAGE' order by line;
prompt /
spool off
spool &COREMODPATH.\DB_GROWTH_PROJ_LCC_BODY.SQL
prompt CREATE OR REPLACE
select text from user_source where name='DB_GROWTH_PROJ_LCC' and type='PACKAGE BODY' order by line;
prompt /
spool off

--=============================================================================================
--=============================================================================================
--=============================================================================================