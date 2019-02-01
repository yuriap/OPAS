set echo on

spool upgrade.log

@../../install/install_global_config

conn &localscheme./&localscheme.@&localdb.

-------------------------------------------------------------------------------------------------------------
--ASH Analyzer
-------------------------------------------------------------------------------------------------------------

define MODNM=ASH_ANALYZER
define MODVER="3.4.4"

exec COREMOD.register(p_modname => '&MODNM.', p_modver => '&MODVER.', p_installed => sysdate);

commit;

-------------------------------------------------------------------------------------------------------------
--AWR Warehouse
-------------------------------------------------------------------------------------------------------------

define MODNM=AWR_WAREHOUSE
define MODVER="4.3.4"


exec COREMOD.register(p_modname => '&MODNM.', p_modver => '&MODVER.', p_installed => sysdate);

commit;


-------------------------------------------------------------------------------------------------------------
--Extended SQL Trace
-------------------------------------------------------------------------------------------------------------

define MODNM=SQL_TRACE
define MODVER="2.2.2"

alter table trc_files add tq_id number;

CREATE OR REPLACE FORCE VIEW V$TRC_FILES AS 
select x.*,
case
  when source_keep_forever = 'Y' 
    then 'Source file will be kept forever'
  when status in ('COMPRESSED','ARCHIVED')
    then 'N/A'
  else
    replace('Source file will be kept till <%p1>','<%p1>',to_char(created + TO_DSINTERVAL(COREMOD_API.getconf('SOURCERETENTION',TRC_FILE_API.getMODNAME)||' 00:00:00'),'YYYY-MON-DD HH24:MI' ))
end source_retention,
case
  when parsed_keep_forever = 'Y' 
    then 'Parsed data will be kept forever'
  when status in ('ARCHIVED')
    then 'N/A'	
  else
    decode(parsed,null,null,replace('Parsed data  will be kept till <%p1>','<%p1>',to_char(parsed + TO_DSINTERVAL(COREMOD_API.getconf('PARSEDRETENTION',TRC_FILE_API.getMODNAME)||' 00:00:00'),'YYYY-MON-DD HH24:MI' )))
end parsed_retention
from trc_files x;

set define off

@../../modules/sql_trace/source/TRC_FILE_API_BODY.SQL

set define on

exec COREMOD.register(p_modname => '&MODNM.', p_modver => '&MODVER.', p_installed => sysdate);

commit;

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