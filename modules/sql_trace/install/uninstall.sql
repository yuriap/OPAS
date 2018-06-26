--SQL Trace uninstallation script
drop view v$trc_parced_file;
drop table trc$tmp_file_content;
drop table trc_stat;
drop table trc_wait;
drop table trc_binds;
drop table trc_call;
drop table trc_statement;
drop table trc_client_identity;
drop table trc_trans;
drop table trc_session;
drop table trc_file;
