-- Oracle Performance Analytic Suite install script
-- Uninstallation

spool ./logs/reinstall.log
set echo on

--Global Config
@install_global_config

--Module uninstallation
@uninstall_modules

--Module installation
@install_modules

spool off
set echo off