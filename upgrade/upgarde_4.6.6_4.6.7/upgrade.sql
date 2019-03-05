set echo on

spool upgrade.log

@../../install/install_global_config

conn &localscheme./&localscheme.@&localdb.

@upgrade_core.sql
rem @upgrade_trc.sql
@upgrade_asha.sql
rem @upgrade_awrwh.sql

-------------------------------------------------------------------------------------------------------------
-------------------------------------------------------------------------------------------------------------
-------------------------------------------------------------------------------------------------------------

set pages 999
set lines 200

select * from user_errors order by 1,2,3,4,5;

begin
  dbms_utility.compile_schema(user);
end;
/

select * from user_errors order by 1,2,3,4,5;


exec COREMOD.register(p_modname => 'OPASAPP', p_modver => '&OPASVER.', p_installed => sysdate);
commit;

set pages 999
set lines 200
column MODNAME format a32 word_wrapped
column MODDESCR format a100 word_wrapped
select t.modname, t.modver, to_char(t.installed,'YYYY/MON/DD HH24:MI:SS') installed, t.moddescr from opas_modules t order by t.installed;
disc

spool off