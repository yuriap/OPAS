--AWR WareHouse uninstallation script
define MODNM=AWR_WAREHOUSE

@@install_config

conn &localscheme./&localscheme.@&localdb.

set serveroutput on

begin
  for i in (select * from awrwh_dumps where status in ('LOADED INTO AWR','COMPRESSED')) loop
  AWRWH_API.unload_awr_ranges (  P_IS_REMOTE => I.IS_REMOTE,
    P_SNAP_MIN => I.MIN_SNAP_ID,
    P_SNAP_MAX => I.MAX_SNAP_ID,
    P_DBID => I.DBID) ;   
  end loop;
end;
/

drop database link &DBLINK.;

@../modules/core/install/cleanup_common.sql AWRWH

commit;

conn sys/&remotesys.@&remotedb. as sysdba
drop directory &dirname.;
drop user &remotescheme. cascade;
drop tablespace &tblspc_name.;
disc