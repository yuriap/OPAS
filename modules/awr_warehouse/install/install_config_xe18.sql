rem AWR DataWarehous scheme for remote database
define remotescheme=&namepref.rem

rem Path for directory object for dump processing
rem Make sure the directory already exists and accessible for both local and remote databases
define dirpath="/home/oracle/files/awrdata/"
define dirname=&namepref.dir

rem Remote database connection string host:port/service_name
define remotedb=localhost:41539/xepdb2

rem Connection string host:port/service_name from local to remote database
define dblinkstr=localhost:1539/xepdb2

rem Remote SYS password (can be empty)
define remotesys=qazwsx

rem Database link from local database to remote database
define DBLINK=&namepref.dbl

rem Staging user for load AWR dump into repository
define AWRSTG=&namepref.stg