--ASH Analyzer uninstallation script
define MODNM=ASH_ANALYZER

conn &localscheme./&localscheme.@&localdb.

set serveroutput on
@../modules/core/install/cleanup_common.sql

declare
  type t_names is table of varchar2(512);
  l_names t_names;
 
  procedure drop_tables is
  begin
    dbms_output.put_line('Dropping tables...');
    select table_name bulk collect
      into l_names
      from user_tables
     where table_name like 'ASHA_CUBE%'
     order by 1;
    for i in 1 .. l_names.count loop
      begin
        execute immediate 'drop table ' || l_names(i);
		dbms_output.put_line('Dropped ' || l_names(i));
      exception
        when others then
          dbms_output.put_line('Dropping error of ' || l_names(i) || ': ' || sqlerrm);
      end;
    end loop;
  end;
begin
  drop_tables();
  drop_tables();
  drop_tables();
end;
/

drop sequence asha_sq_cube;
drop sequence asha_snap_ash;

begin
  dbms_scheduler.drop_job(job_name         => 'OPAS_ASHA_DIC');
  dbms_scheduler.drop_program(program_name => 'OPAS_ASHA_DIC_PRG');
end;
/