-- Module list installation

--Core
@../modules/core/install/install.sql

--SQL Trace
@../modules/sql_trace/install/install.sql

--ASH Analyzer
@../modules/ash_analyzer/install/install.sql

--AWR WareHouse
@../modules/awr_warehouse/install/install.sql

--DB Growth Tracker
@../modules/db_growth/install/install.sql


conn &localscheme./&localscheme.@&localdb.

set pages 999
set lines 200

select * from user_errors order by 1,2,3,4,5;

begin
  dbms_utility.compile_schema(user);
end;
/

select * from user_errors order by 1,2,3,4,5;

set pages 999
set lines 200
column MODNAME format a32 word_wrapped
column MODDESCR format a100 word_wrapped
select t.modname, t.modver, to_char(t.installed,'YYYY/MON/DD HH24:MI:SS') installed, t.moddescr from opas_modules t order by t.installed;
disc