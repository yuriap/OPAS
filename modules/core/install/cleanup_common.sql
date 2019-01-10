delete from opas_config where modname='&MODNM.';
delete from OPAS_CLEANUP_TASKS where modname='&MODNM.';
delete from opas_dictionary where modname='&MODNM.';
delete from opas_scripts where modname='&MODNM.';
delete from opas_files where modname='&MODNM.';
delete from opas_reports where modname='&MODNM.';
delete from opas_modules where modname='&MODNM.';

commit;
set verify off
prompt Removing tables with the prefix "&1."

declare
  type t_names is table of varchar2(512);
  l_names t_names;
 
  procedure drop_tables is
  begin
    dbms_output.put_line('Dropping tables...');
    select table_name bulk collect
      into l_names
      from user_tables
     where table_name like '&1.%'
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
set verify on
