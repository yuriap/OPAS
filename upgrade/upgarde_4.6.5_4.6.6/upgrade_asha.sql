-------------------------------------------------------------------------------------------------------------
--ASH Analyzer
-------------------------------------------------------------------------------------------------------------

define MODNM=ASH_ANALYZER
@../../modules/ash_analyzer/install/version.sql

alter table asha_cube_projects add priority            number default 10;
CREATE OR REPLACE FORCE VIEW V$ASHA_CUBE_PROJECTS AS 
select x.*,
case
  when keep_forever = 'Y' 
    then 'Will be kept forever'
  else
    replace('Will be kept till <%p1>','<%p1>',to_char(created + TO_DSINTERVAL(COREMOD_API.getconf('PROJECTRETENTION',ASHA_CUBE_API.getMODNAME)||' 00:00:00'),'YYYY-MON-DD HH24:MI' ))
end retention
from asha_cube_projects x
where owner=decode(owner,'PUBLIC',owner,decode(is_public,'Y',owner,nvl(V('APP_USER'),'~^')));

INSERT INTO opas_expimp_compat ( modname, src_version, trg_version) VALUES ( '&MODNM.',  '&MODVER.',  '&MODVER.');
commit;

set define off

@../../modules/ash_analyzer/source/ASHA_EXPIMP_BODY.SQL
@../../modules/ash_analyzer/source/ASHA_PROJ_API_SPEC.SQL
@../../modules/ash_analyzer/source/ASHA_PROJ_API_BODY.SQL

set define on

exec COREMOD.register(p_modname => '&MODNM.', p_modver => '&MODVER.', p_installed => sysdate);

commit;

begin
  ASHA_EXPIMP.init();
end;
/