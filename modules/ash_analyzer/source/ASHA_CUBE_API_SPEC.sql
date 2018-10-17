CREATE OR REPLACE
PACKAGE ASHA_CUBE_API AS

  gMODNAME       constant varchar2(32) := 'ASH_ANALYZER';

  function  getMODNAME return varchar2;
  procedure CLEANUP_CUBE;

END ASHA_CUBE_API;
/
