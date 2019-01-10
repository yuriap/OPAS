--SQL Trace uninstallation script

define MODNM=SQL_TRACE

conn &localscheme./&localscheme.@&localdb.

set serveroutput on
@../modules/core/install/cleanup_common.sql TRC_CUBE


