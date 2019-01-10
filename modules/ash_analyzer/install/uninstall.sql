--ASH Analyzer uninstallation script
define MODNM=ASH_ANALYZER

conn &localscheme./&localscheme.@&localdb.

set serveroutput on
@../modules/core/install/cleanup_common.sql ASHA_CUBE

drop sequence asha_sq_cube;
drop sequence asha_snap_ash;

begin
  dbms_scheduler.drop_job(job_name         => 'OPAS_ASHA_DIC');
  dbms_scheduler.drop_program(program_name => 'OPAS_ASHA_DIC_PRG');
end;
/