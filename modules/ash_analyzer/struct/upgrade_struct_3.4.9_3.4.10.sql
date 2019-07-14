CREATE OR REPLACE FORCE VIEW V$ASHA_CUBE_PROJECTS AS 
select x.*,
case
  when keep_forever = 'Y' 
    then 'Will be kept forever.'
  else
    replace('Will be kept till <%p1>','<%p1>',to_char(created + TO_DSINTERVAL(COREMOD_API.getconf('PROJECTRETENTION',ASHA_CUBE_API.getMODNAME)||' 00:00:00'),'YYYY-MON-DD HH24:MI' ))||'.'
end retention,
case when keep_forever = 'N' and created + COREMOD_API.getconf('PROJECTRETENTION',ASHA_CUBE_API.getMODNAME) < (sysdate + COREMOD_API.getconf('SHOWEXPBEFORE',COREMOD_API.getMODNAME)) then 'Project is expiring.' else null end
|| (select case when expiring>0 then ' '||expiring||' cube(s) is(are) expiring.' else null end from ASHA_MV_CUBE_RETENTIONS i where i.PROJ_ID=x.PROJ_ID) 
|| (select case when expiring>0 then ' '||expiring||' report(s) is(are) expiring.' else null end from ASHA_MV_REPORTS_RETENTIONS i where i.PROJ_ID=x.PROJ_ID) proj_warnings
from asha_cube_projects x
where owner=decode(owner,'PUBLIC',owner,decode(is_public,'Y',owner,nvl(V('APP_USER'),'~^')));
