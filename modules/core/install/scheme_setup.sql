create tablespace &tblspc_name.;

create user &localscheme. identified by &localscheme.
default tablespace &tblspc_name.
temporary tablespace temp;
alter user &localscheme. quota unlimited on &tblspc_name.;

grant connect, resource to &localscheme.;
grant select_catalog_role to &localscheme.;
grant select any table to &localscheme.;
grant execute on dbms_lock to &localscheme.;
grant create view to &localscheme.;
grant create synonym to &localscheme.;
grant create job to &localscheme.;
grant execute on dbms_xplan to &localscheme.;
