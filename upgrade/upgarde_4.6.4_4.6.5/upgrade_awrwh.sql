-------------------------------------------------------------------------------------------------------------
--AWR Warehouse
-------------------------------------------------------------------------------------------------------------

define MODNM=AWR_WAREHOUSE
@../../modules/awr_warehouse/install/version.sql

set define off


@../../modules/awr_warehouse/source/AWRWH_EXPIMP_SPEC.SQL
@../../modules/awr_warehouse/source/AWRWH_EXPIMP_BODY.SQL
@../../modules/awr_warehouse/source/AWRWH_API_BODY.SQL
@../../modules/awr_warehouse/source/AWRWH_PROJ_API_BODY.SQL
@../../modules/awr_warehouse/source/AWRWH_REPORT_API_SPEC.SQL
@../../modules/awr_warehouse/source/AWRWH_REPORT_API_BODY.SQL

set define on

exec COREMOD.register(p_modname => '&MODNM.', p_modver => '&MODVER.', p_installed => sysdate);

commit;

begin
  AWRWH_EXPIMP.init();
end;
/