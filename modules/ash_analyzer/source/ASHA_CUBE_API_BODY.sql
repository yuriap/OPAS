CREATE OR REPLACE
PACKAGE BODY ASHA_CUBE_API AS

  function  getMODNAME return varchar2 is begin return gMODNAME; end;

  procedure CLEANUP_CUBE
  is
  begin
    delete from asha_cube_sess where sess_created < (systimestamp - to_number(COREMOD_API.getconf('CUBERETENTION',gMODNAME))/24);
    coremod_log.log('Deleted '||sql%rowcount||' session(s).');
    commit;
  exception
    when others then rollback;dbms_output.put_line(sqlerrm);coremod_log.log('ASHA_CUBE.CLEANUP_CUBE error: '||sqlerrm);
  end;

END ASHA_CUBE_API;
/
