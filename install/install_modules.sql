-- Module list installation

--Core
@..\modules\core\install\install.sql

--SQL Trace
@..\modules\sql_trace\install\install.sql

conn &localscheme./&localscheme.@&localdb.
set pages 999
set lines 200
column MODNAME format a32 word_wrapped
column MODDESCR format a100 word_wrapped
select t.modname, t.modver, to_char(t.installed,'YYYY/MON/DD HH24:MI:SS') installed, t.moddescr from opas_modules t order by t.installed;
disc