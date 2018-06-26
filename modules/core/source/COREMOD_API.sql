create or replace package COREMOD_API as
   
   gDefaultSource constant varchar2(32) := 'LOCAL';
   gDefaultOwner  constant varchar2(32) := 'PUBLIC';

   function getconf(p_key varchar2) return varchar2 RESULT_CACHE;
   function getscript(p_script_id varchar2) return clob;
   
   procedure create_dblink(p_db_link_name varchar2, p_owner varchar2);
   function get_def_source return varchar2;
   function get_def_owner return varchar2;
   
end COREMOD_API;
/
--------------------------------------------------------
show errors
--------------------------------------------------------
create or replace package body COREMOD_API as

  function getconf(p_key varchar2) return varchar2 RESULT_CACHE
  is
    l_res opas_config.cvalue%type;
  begin
    select cvalue into l_res from opas_config where ckey=p_key;
    return l_res;
  end;

  function getscript(p_script_id varchar2) return clob
  is
    l_res clob;
  begin
    select script_content into l_res from opas_scripts where script_id=p_script_id;
    return l_res;
  exception
    when no_data_found then raise_application_error(-20000,'Script "'||p_script_id||'" not found.');
  end;

  procedure create_dblink(p_db_link_name varchar2, p_owner varchar2)
  is
  begin
    if p_db_link_name=gDefaultSource then
	  raise_application_error(-20000, gDefaultSource||' db link is not supposed to be created.');
	else
      for i in (select * from opas_db_links where DB_LINK_NAME=p_db_link_name) loop
  	    execute immediate i.DDL_TEXT;
	    update opas_db_links set OWNER=p_owner, STATUS='CREATED' where DB_LINK_NAME=p_db_link_name;
	    commit;
	  end loop;
	end if;
  end;
  
  function get_def_source return varchar2 is begin return gDefaultSource; end;
  function get_def_owner return varchar2 is begin return gDefaultOwner; end;
  
end COREMOD_API;
/
--------------------------------------------------------
show errors
--------------------------------------------------------