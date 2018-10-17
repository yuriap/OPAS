CREATE OR REPLACE CONTEXT rem_&remotescheme._ctx USING remote_awr_xplan_init;
create or replace procedure remote_awr_xplan_init(p_sql_id varchar2, p_plan_hash varchar2, p_dbid varchar2)
is
begin
  DBMS_SESSION.set_context('rem_&remotescheme._ctx', 'sql_id' , p_sql_id);          
  DBMS_SESSION.set_context('rem_&remotescheme._ctx', 'plan_hash' , p_plan_hash);   
  DBMS_SESSION.set_context('rem_&remotescheme._ctx', 'dbid' , p_dbid);   
end;
/
show errors

rem R12
create or replace view remote_awr_plan as
select plan_table_output 
from table(dbms_xplan.display_awr(SYS_CONTEXT('rem_&remotescheme._ctx', 'sql_id'), 
                                  SYS_CONTEXT('rem_&remotescheme._ctx', 'plan_hash'), 
                                  SYS_CONTEXT('rem_&remotescheme._ctx', 'dbid'), 'ADVANCED -ALIAS'));
show errors

rem R18 single tenant
create or replace view remote_awr_plan as
select plan_table_output 
from table(dbms_xplan.display_workload_repository(sql_id          => SYS_CONTEXT('rem_&remotescheme._ctx', 'sql_id'), 
                                                  plan_hash_value => SYS_CONTEXT('rem_&remotescheme._ctx', 'plan_hash'), 
                                                  dbid            => SYS_CONTEXT('rem_&remotescheme._ctx', 'dbid'), 
                                                  con_dbid        => SYS_CONTEXT('rem_&remotescheme._ctx', 'dbid'), 
                                                  format          => 'ADVANCED -ALIAS',
                                                  awr_location=>'AWR_PDB')
                                                  );
show errors


create table awrwh_dumps (
  dbid number,
  min_snap_id number,
  max_snap_id number,
  min_snap_dt timestamp(3),
  max_snap_dt timestamp(3),
  db_description varchar2(1000)
);

