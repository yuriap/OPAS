--DB Growth Tracker uninstallation script
define MODNM=DB_GROWTH

conn &localscheme./&localscheme.@&localdb.

set serveroutput on
@../modules/core/install/cleanup_common.sql DB_GROWTH


rem begin
rem   dbms_scheduler.drop_job(job_name         => 'OPAS_ASHA_DIC');
rem   dbms_scheduler.drop_program(program_name => 'OPAS_ASHA_DIC_PRG');
rem end;
rem /