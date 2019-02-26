-------------------------------------------------------------------------------------------------------------
--AWR Warehouse
-------------------------------------------------------------------------------------------------------------

define MODNM=AWR_WAREHOUSE
@../../modules/awr_warehouse/install/version.sql

alter table awrwh_projects add priority            number default 10;
CREATE OR REPLACE FORCE VIEW V$AWRWH_PROJECTS AS 
select x.*,
case
  when keep_forever = 'Y' 
    then 'Will be kept forever'
  else
    replace('Will be kept till <%p1>','<%p1>',to_char(created + TO_DSINTERVAL(COREMOD_API.getconf('PROJECTRETENTION',AWRWH_API.getMODNAME)||' 00:00:00'),'YYYY-MON-DD HH24:MI' ))
end retention
from awrwh_projects x
where owner=decode(owner,'PUBLIC',owner,decode(is_public,'Y',owner,nvl(V('APP_USER'),'~^')));

set define off

@../../modules/awr_warehouse/source/AWRWH_PROJ_API_SPEC.SQL
@../../modules/awr_warehouse/source/AWRWH_PROJ_API_BODY.SQL

set define on

exec COREMOD.register(p_modname => '&MODNM.', p_modver => '&MODVER.', p_installed => sysdate);

commit;

begin
  AWRWH_EXPIMP.init();
end;
/