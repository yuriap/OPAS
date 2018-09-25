insert into opas_project_types (proj_type, modname, page_title, startpage) values ('DEFAULT','&MODNM.','Default projects', null );
insert into opas_project_cleanup (modname,proj_type,code,display_name,display_descr,cleanup_prc,ordr) values ('&MODNM.','DEFAULT','DEFAULT','Default retention applied', 'Project will be removed after <%p1>','COREPROJ_API.cleanup_project_default',1);


--Dictionatiries
insert into opas_dic_retention (ret_code, ret_display_name, ret_display_descr) values ('DEFAULT', 'Default retention applied', 'Project will be removed after <%p1>');
insert into opas_dic_retention (ret_code, ret_display_name, ret_display_descr) values ('KEEPALLFOREVER', 'Keep forever', 'Will be kept forever');
insert into opas_dic_retention (ret_code, ret_display_name, ret_display_descr) values ('KEEPSOURCEDATAONLY', 'Keep source files only', 'Parsed data will be removed in <%p1> days');
insert into opas_dic_retention (ret_code, ret_display_name, ret_display_descr) values ('KEEPPARSEDDATAONLY', 'Keep parsed data only', 'Trace files will be removed in <%p1> days');


insert into opas_project_types (proj_type, modname, page_title, startpage, cleanup_prc) values ('EXTSQLTRACE','&MODNM.','Extended SQL Trace Projects',110,'TRC_FILE_API.cleanup_files');
--insert into opas_project_cleanup (modname,proj_type,code,display_name,cleanup_prc,ordr,is_compress,is_archive) values ('&MODNM.','EXTSQLTRACE','SOURCEDATA','Source trace files','TRC_UTILS.remove_project_source_data', 1 ,'Y','N');
--insert into opas_project_cleanup (modname,proj_type,code,display_name,cleanup_prc,ordr,is_compress,is_archive) values ('&MODNM.','EXTSQLTRACE','PARSEDDATA','Parsed representation of trace files','TRC_UTILS.remove_project_parsed_data', 2,'N','Y');
--insert into opas_project_cleanup (modname,proj_type,code,display_name,cleanup_prc,ordr,is_compress,is_archive) values ('&MODNM.','EXTSQLTRACE','REPORTS','Reports','TRC_UTILS.remove_project_reports', 3,'N','N');

INSERT INTO opas_config (modname,cgroup,ckey,cvalue,descr) VALUES ('&MODNM.','PRJRETENTION','PROJECTRETENTION',30,'Retention time in days for trace projects.');
INSERT INTO opas_config (modname,cgroup,ckey,cvalue,descr) VALUES ('&MODNM.','REPORT','TOPSQL',50,'Default value for number of Top SQL to show.');

commit;