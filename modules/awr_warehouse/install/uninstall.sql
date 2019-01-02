--AWR WareHouse uninstallation script
define MODNM=AWR_WAREHOUSE

@@install_config

conn &localscheme./&localscheme.@&localdb.

set serveroutput on

drop database link &DBLINK.;

@../modules/core/install/cleanup_common.sql

commit;

declare
  type t_names is table of varchar2(512);
  l_names t_names;
 
  procedure drop_tables is
  begin
    dbms_output.put_line('Dropping tables...');
    select table_name bulk collect
      into l_names
      from user_tables
     where table_name like 'AWRWH%'
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


conn sys/&remotesys.@&remotedb. as sysdba
drop directory &dirname.;
drop user &remotescheme. cascade;
drop tablespace &tblspc_name.;
disc