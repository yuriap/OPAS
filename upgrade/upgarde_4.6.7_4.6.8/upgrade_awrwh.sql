-------------------------------------------------------------------------------------------------------------
--AWR Warehouse
-------------------------------------------------------------------------------------------------------------

define MODNM=AWR_WAREHOUSE
@../../modules/awr_warehouse/install/version.sql

set define off

rem @../../modules/awr_warehouse/source/AWRWH_PROJ_API_SPEC.SQL

set define on

exec COREMOD.register(p_modname => '&MODNM.', p_modver => '&MODVER.', p_installed => sysdate);

commit;

begin
  AWRWH_EXPIMP.init();
end;
/