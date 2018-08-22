insert into opas_project_types (proj_type, modname, page_title, startpage) values ('EXTSQLTRACE','&MODNM.','Extended SQL Trace Projects',110);
insert into opas_project_cleanup (modname,cleanup_mode,cleanup_prc,ordr) values ('&MODNM.','SOURCEDATA','TRC_UTILS.cleanup_project_source_data',1);
insert into opas_project_cleanup (modname,cleanup_mode,cleanup_prc,ordr) values ('&MODNM.','PARSEDDATA','TRC_UTILS.cleanup_project_parsed_data',1);

INSERT INTO opas_config (modname,cgroup,ckey,cvalue,descr) VALUES ('&MODNM.','PRJRETENTION','PROJECTRETENTION',30,'Retention time in days for trace projects.');
INSERT INTO opas_config (modname,cgroup,ckey,cvalue,descr) VALUES ('&MODNM.','REPORT','TOPSQL',50,'Default value for number of Top SQL to show.');

commit;