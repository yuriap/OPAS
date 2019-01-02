-- Oracle Performance Analytic Suite install script
-- Installation from scratch

spool ./logs/install.log
set echo on

--Global Config
@install_global_config

--Module installation
@install_modules

spool off
set echo off