create or replace package COREMOD_API as

   gDefaultSource constant varchar2(32) := 'LOCAL';
   gDefaultOwner  constant varchar2(32) := 'PUBLIC';

   function getconf(p_key varchar2) return varchar2 RESULT_CACHE;
   function getscript(p_script_id varchar2) return clob;

   procedure create_dblink(p_db_link_name varchar2, p_owner varchar2);
   function get_def_source return varchar2;
   function get_def_owner return varchar2;
   
   procedure init_longops(p_op_name varchar2, p_target_desc varchar2, p_units varchar2, p_totalwork number);
   procedure start_longops_section(p_module_name varchar2, p_action_name varchar2);
   procedure end_longops_section(p_sofar number default 1);

end COREMOD_API;
/
--------------------------------------------------------
show errors
--------------------------------------------------------

create or replace package body COREMOD_API as

  g_rindex    BINARY_INTEGER;
  g_slno      BINARY_INTEGER;
  g_totalwork number;
  g_sofar     number;
  g_obj       BINARY_INTEGER;
  g_op_name   varchar2(100);
  g_target_desc varchar2(100);
  g_units     varchar2(100);   

  procedure init_longops(p_op_name varchar2, p_target_desc varchar2, p_units varchar2, p_totalwork number) 
  is
  begin
    g_op_name     := p_op_name;
    g_target_desc := p_target_desc;
    g_units       := p_units;  
    
    g_rindex      := dbms_application_info.set_session_longops_nohint;
    g_sofar       := 0;
    g_totalwork   := p_totalwork;
    dbms_application_info.set_session_longops(g_rindex, g_slno, g_op_name, g_obj, 0, g_sofar, g_totalwork, g_target_desc, g_units);   
  end;
  
  procedure start_longops_section(p_module_name varchar2, p_action_name varchar2)
  is
  begin
    DBMS_APPLICATION_INFO.SET_MODULE ( module_name => p_module_name, action_name => p_action_name);
  end;
  
  procedure end_longops_section(p_sofar number default 1)
  is
  begin
    if p_sofar = 1 then
      g_sofar := g_sofar + p_sofar;
    else
      g_sofar := p_sofar;
    end if;
    dbms_application_info.set_session_longops(g_rindex, g_slno, g_op_name, g_obj, 0, g_sofar, g_totalwork, g_target_desc, g_units);
  end;
  
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