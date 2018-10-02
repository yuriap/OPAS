define COREMODPATH="..\modules\core\source\"

set heading off
set feedback off
set termout OFF
set trimspool on
set lines 5000
set pages 0
set echo off

spool &COREMODPATH.\COREFILE_API_SPEC.SQL
select text from user_source where name='COREFILE_API' and type='PACKAGE' order by line;
prompt /
spool off
spool &COREMODPATH.\COREFILE_API_BODY.SQL
select text from user_source where name='COREFILE_API' and type='PACKAGE BODY' order by line;
prompt /
spool off

spool &COREMODPATH.\COREMOD_API_SPEC.SQL
select text from user_source where name='COREMOD_API' and type='PACKAGE' order by line;
prompt /
spool off
spool &COREMODPATH.\COREMOD_API_BODY.SQL
select text from user_source where name='COREMOD_API' and type='PACKAGE BODY' order by line;
prompt /
spool off

spool &COREMODPATH.\COREMOD_CLEANUP_SPEC.SQL
select text from user_source where name='COREMOD_CLEANUP' and type='PACKAGE' order by line;
prompt /
spool off
spool &COREMODPATH.\COREMOD_CLEANUP_BODY.SQL
select text from user_source where name='COREMOD_CLEANUP' and type='PACKAGE BODY' order by line;
prompt /
spool off

spool &COREMODPATH.\COREMOD_LOG_SPEC.SQL
select text from user_source where name='COREMOD_LOG' and type='PACKAGE' order by line;
prompt /
spool off
spool &COREMODPATH.\COREMOD_LOG_BODY.SQL
select text from user_source where name='COREMOD_LOG' and type='PACKAGE BODY' order by line;
prompt /
spool off

spool &COREMODPATH.\COREMOD_SPEC.SQL
select text from user_source where name='COREMOD' and type='PACKAGE' order by line;
prompt /
spool off
spool &COREMODPATH.\COREMOD_BODY.SQL
select text from user_source where name='COREMOD' and type='PACKAGE BODY' order by line;
prompt /
spool off

spool &COREMODPATH.\COREMOD_REPORT_UTILS_SPEC.SQL
select text from user_source where name='COREMOD_REPORT_UTILS' and type='PACKAGE' order by line;
prompt /
spool off
spool &COREMODPATH.\COREMOD_REPORT_UTILS_BODY.SQL
select text from user_source where name='COREMOD_REPORT_UTILS' and type='PACKAGE BODY' order by line;
prompt /
spool off

spool &COREMODPATH.\COREMOD_SEC_SPEC.SQL
select text from user_source where name='COREMOD_SEC' and type='PACKAGE' order by line;
prompt /
spool off
spool &COREMODPATH.\COREMOD_SEC_BODY.SQL
select text from user_source where name='COREMOD_SEC' and type='PACKAGE BODY' order by line;
prompt /
spool off

spool &COREMODPATH.\COREMOD_TASKS_SPEC.SQL
select text from user_source where name='COREMOD_TASKS' and type='PACKAGE' order by line;
prompt /
spool off
spool &COREMODPATH.\COREMOD_TASKS_BODY.SQL
select text from user_source where name='COREMOD_TASKS' and type='PACKAGE BODY' order by line;
prompt /
spool off

--=============================================================================================
--=============================================================================================
--=============================================================================================

define COREMODPATH="..\modules\sql_trace\source\"

spool &COREMODPATH.\TRC_FILE_API_SPEC.SQL
select text from user_source where name='TRC_FILE_API' and type='PACKAGE' order by line;
prompt /
spool off
spool &COREMODPATH.\TRC_FILE_API_BODY.SQL
select text from user_source where name='TRC_FILE_API' and type='PACKAGE BODY' order by line;
prompt /
spool off

spool &COREMODPATH.\TRC_FILE_LCC_SPEC.SQL
select text from user_source where name='TRC_FILE_LCC' and type='PACKAGE' order by line;
prompt /
spool off
spool &COREMODPATH.\TRC_FILE_LCC_BODY.SQL
select text from user_source where name='TRC_FILE_LCC' and type='PACKAGE BODY' order by line;
prompt /
spool off

spool &COREMODPATH.\TRC_PROCESSFILE_SPEC.SQL
select text from user_source where name='TRC_PROCESSFILE' and type='PACKAGE' order by line;
prompt /
spool off
spool &COREMODPATH.\TRC_PROCESSFILE_BODY.SQL
select text from user_source where name='TRC_PROCESSFILE' and type='PACKAGE BODY' order by line;
prompt /
spool off

spool &COREMODPATH.\TRC_PROJ_API_SPEC.SQL
select text from user_source where name='TRC_PROJ_API' and type='PACKAGE' order by line;
prompt /
spool off
spool &COREMODPATH.\TRC_PROJ_API_BODY.SQL
select text from user_source where name='TRC_PROJ_API' and type='PACKAGE BODY' order by line;
prompt /
spool off

spool &COREMODPATH.\TRC_PROJ_LCC_SPEC.SQL
select text from user_source where name='TRC_PROJ_LCC' and type='PACKAGE' order by line;
prompt /
spool off
spool &COREMODPATH.\TRC_PROJ_LCC_BODY.SQL
select text from user_source where name='TRC_PROJ_LCC' and type='PACKAGE BODY' order by line;
prompt /
spool off

spool &COREMODPATH.\TRC_REPORT_SPEC.SQL
select text from user_source where name='TRC_REPORT' and type='PACKAGE' order by line;
prompt /
spool off
spool &COREMODPATH.\TRC_REPORT_BODY.SQL
select text from user_source where name='TRC_REPORT' and type='PACKAGE BODY' order by line;
prompt /
spool off