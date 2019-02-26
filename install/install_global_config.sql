define namepref=opas45

@@version.sql

-- Oracle Performance Analytic Suite scheme for local database
define localscheme=&namepref.

-- Tablespace name for Oracle Performance Analytic Suite
define tblspc_name=&namepref.tbs

-- Local database connection string host:port/service_name
define localdb=localhost:1521/pdb1.localdomain

-- Local SYS password (can be empty)
define localsys=qazwsx

-- module configs
@../modules/awr_warehouse/install/install_config