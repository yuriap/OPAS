create or replace package COREMOD_API as

   gDefaultSource constant varchar2(32) := 'LOCAL';
   gDefaultOwner  constant varchar2(32) := 'PUBLIC';

   function getconf(p_key varchar2, p_module opas_projects.modname%type default null) return varchar2 RESULT_CACHE;
   function getscript(p_script_id varchar2) return clob;

   procedure register_dblink(p_db_link_name varchar2, 
                             p_db_link_displ_name varchar2, 
                             p_owner varchar2,
                             p_is_public varchar2,
                             p_username varchar2,
                             p_password varchar2,
                             p_connectstring varchar2);
   procedure edit_dblink    (p_db_link_name varchar2, 
                             p_db_link_displ_name varchar2, 
                             p_is_public varchar2,
                             p_username varchar2,
                             p_password varchar2,
                             p_connectstring varchar2);                             
   procedure create_dblink(p_db_link_name varchar2, p_recreate boolean default false);
   procedure drop_dblink(p_db_link_name varchar2);
   procedure test_dblink(p_db_link_name varchar2);
   
   function get_def_source return varchar2;
   function get_def_owner return varchar2;

   procedure init_longops(p_op_name varchar2, p_target_desc varchar2, p_units varchar2, p_totalwork number, p_lops_ind out pls_integer);
   procedure start_longops_section(p_module_name varchar2, p_action_name varchar2);
   procedure end_longops_section(p_sofar number default 1, p_lops_ind pls_integer);
   
   procedure lock_resource(p_resource_name varchar2, p_mode number default DBMS_LOCK.X_MODE, p_timeout number default 0, p_release_on_commit boolean default true);
   function lock_resource(p_resource_name varchar2, p_mode number default DBMS_LOCK.X_MODE, p_timeout number default 0, p_release_on_commit boolean default true) return varchar2;
   procedure release_resource(p_handle varchar2);
   procedure release_resource;

end COREMOD_API;
/
--------------------------------------------------------
show errors
--------------------------------------------------------

create or replace package body COREMOD_API as

  type t_lops_rec is record(
  g_rindex    BINARY_INTEGER,
  g_slno      BINARY_INTEGER,
  g_totalwork number,
  g_sofar     number,
  g_obj       BINARY_INTEGER,
  g_op_name   varchar2(100),
  g_target_desc varchar2(100),
  g_units     varchar2(100));

  type t_lops_tab is table of t_lops_rec index by pls_integer;

  g_lops_tab t_lops_tab;
  g_lops_idx number := 0;

  -- lock handle
  g_handle varchar2(512);
  
  procedure init_longops(p_op_name varchar2, p_target_desc varchar2, p_units varchar2, p_totalwork number, p_lops_ind out pls_integer)
  is
  begin
    g_lops_idx:=g_lops_idx+1;

    g_lops_tab(g_lops_idx).g_op_name     := p_op_name;
    g_lops_tab(g_lops_idx).g_target_desc := p_target_desc;
    g_lops_tab(g_lops_idx).g_units       := p_units;

    g_lops_tab(g_lops_idx).g_rindex      := dbms_application_info.set_session_longops_nohint;
    g_lops_tab(g_lops_idx).g_sofar       := 0;
    g_lops_tab(g_lops_idx).g_totalwork   := p_totalwork;
    dbms_application_info.set_session_longops(g_lops_tab(g_lops_idx).g_rindex,
                                              g_lops_tab(g_lops_idx).g_slno,
                                              g_lops_tab(g_lops_idx).g_op_name,
                                              g_lops_tab(g_lops_idx).g_obj,
                                              0,
                                              g_lops_tab(g_lops_idx).g_sofar,
                                              g_lops_tab(g_lops_idx).g_totalwork,
                                              g_lops_tab(g_lops_idx).g_target_desc,
                                              g_lops_tab(g_lops_idx).g_units);

    p_lops_ind:=g_lops_idx;
  end;

  procedure start_longops_section(p_module_name varchar2, p_action_name varchar2)
  is
  begin
    DBMS_APPLICATION_INFO.SET_MODULE ( module_name => p_module_name, action_name => p_action_name);
  end;

  procedure end_longops_section(p_sofar number default 1, p_lops_ind pls_integer)
  is
  begin
    if p_sofar = 1 then
      g_lops_tab(p_lops_ind).g_sofar := g_lops_tab(p_lops_ind).g_sofar + p_sofar;
    else
      g_lops_tab(p_lops_ind).g_sofar := p_sofar;
    end if;
    dbms_application_info.set_session_longops(g_lops_tab(p_lops_ind).g_rindex,
                                              g_lops_tab(p_lops_ind).g_slno,
                                              g_lops_tab(p_lops_ind).g_op_name,
                                              g_lops_tab(p_lops_ind).g_obj,
                                              0,
                                              g_lops_tab(p_lops_ind).g_sofar,
                                              g_lops_tab(p_lops_ind).g_totalwork,
                                              g_lops_tab(p_lops_ind).g_target_desc,
                                              g_lops_tab(p_lops_ind).g_units);
  end;

  function getconf(p_key varchar2, p_module opas_projects.modname%type default null) return varchar2 RESULT_CACHE
  is
    l_res opas_config.cvalue%type;
  begin
    if p_module is null then
      select cvalue into l_res from opas_config where ckey=p_key;
    else
      select cvalue into l_res from opas_config where ckey=p_key and modname=p_module;
    end if;
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

  procedure register_dblink(p_db_link_name varchar2, 
                            p_db_link_displ_name varchar2, 
                            p_owner varchar2,
                            p_is_public varchar2,
                            p_username varchar2,
                            p_password varchar2,
                            p_connectstring varchar2)
  is
  begin
    insert into opas_db_links 
      (DB_LINK_NAME,DISPLAY_NAME,OWNER,STATUS,is_public,username,password,connstr) 
    values 
      (upper(p_db_link_name), p_db_link_displ_name, upper(p_owner), 
       'NEW', case when upper(p_owner)='PUBLIC' then 'Y' else case when p_is_public = 'Y' then 'Y' else 'N' end end, p_username,p_password,p_connectstring);
  end;
   
  procedure edit_dblink    (p_db_link_name varchar2, 
                            p_db_link_displ_name varchar2, 
                            p_is_public varchar2,
                            p_username varchar2,
                            p_password varchar2,
                            p_connectstring varchar2)
  is
    l_dblink opas_db_links%rowtype;
  begin
    select * into l_dblink from opas_db_links where DB_LINK_NAME = upper(p_db_link_name) for update nowait;

    if nvl(p_username,'~^')<>nvl(l_dblink.username,'~^') or
       nvl(p_password,'~^')<>nvl(l_dblink.password,'~^') or
       nvl(p_connectstring,'~^')<>nvl(l_dblink.connstr,'~^')
    then       
      update opas_db_links set
             STATUS = 'MODIFIED',
             DISPLAY_NAME = p_db_link_displ_name,
             is_public = case when upper(owner)='PUBLIC' then 'Y' else case when p_is_public = 'Y' then 'Y' else 'N' end end,
             username = p_username,
             password = p_password,
             connstr = p_connectstring
       where DB_LINK_NAME = upper(p_db_link_name);
     else
      update opas_db_links set
             DISPLAY_NAME = p_db_link_displ_name,
             is_public = case when upper(owner)='PUBLIC' then 'Y' else case when p_is_public = 'Y' then 'Y' else 'N' end end
       where DB_LINK_NAME = upper(p_db_link_name);
    end if;     
  end;

  procedure create_dblink(p_db_link_name varchar2, p_recreate boolean default false)
  is
    l_dblink opas_db_links%rowtype;
  begin
    if p_db_link_name=gDefaultSource then
	  raise_application_error(-20000, gDefaultSource||' db link is not supposed to be created.');
	else
      select * into l_dblink from opas_db_links where DB_LINK_NAME = upper(p_db_link_name) for update nowait;
      if p_recreate then
        declare 
          l_domain varchar2(128);
        begin
          select value into l_domain from v$parameter where name like '%domain%';
          execute immediate 'drop database link '||p_db_link_name||'.'||l_domain;
        exception
          when others then 
            COREMOD_LOG.log(DBMS_UTILITY.FORMAT_ERROR_STACK);
            COREMOD_LOG.log(DBMS_UTILITY.FORMAT_ERROR_BACKTRACE);
            COREMOD_LOG.log(sqlerrm);              
        end;
      end if;
  	  execute immediate q'[CREATE DATABASE LINK ]'||l_dblink.db_link_name||q'[ CONNECT TO ]'||l_dblink.username||q'[ IDENTIFIED BY ]'||l_dblink.password||q'[ USING ']'||l_dblink.connstr||q'[']';
	  update opas_db_links set STATUS='CREATED' where DB_LINK_NAME=upper(p_db_link_name);
	  commit;
	end if;
  end;
  
  procedure drop_dblink(p_db_link_name varchar2)
  is
    l_domain varchar2(128);
    l_cnt number;
    --l_dblink opas_db_links%rowtype;
  begin
    if p_db_link_name=gDefaultSource then
	  raise_application_error(-20000, gDefaultSource||' db link is not supposed to be created.');
	else
      --select * into l_dblink from opas_db_links where DB_LINK_NAME = upper(p_db_link_name) for update nowait;
      select value into l_domain from v$parameter where name like '%domain%';
      select count(1) into l_cnt from user_db_links where db_link=upper(p_db_link_name)||'.'||l_domain;
      if l_cnt>0 then
        begin
          update opas_db_links set STATUS='TODELETE' where DB_LINK_NAME=upper(p_db_link_name);
          execute immediate 'drop database link '||p_db_link_name||'.'||l_domain;
        exception
          when others then 
            COREMOD_LOG.log(DBMS_UTILITY.FORMAT_ERROR_STACK);
            COREMOD_LOG.log(DBMS_UTILITY.FORMAT_ERROR_BACKTRACE);
            COREMOD_LOG.log(sqlerrm);              
            raise;
        end;
      end if;
	  delete from opas_db_links where DB_LINK_NAME=upper(p_db_link_name);
	  commit;
	end if;
  end;  

  procedure test_dblink(p_db_link_name varchar2)
  is
    l_dblink varchar2(512);
    a number;
  begin
    select ora_db_link into l_dblink from V$OPAS_DB_LINKS where db_link_name=upper(p_db_link_name);
    execute immediate 'select 1 from dual@'||l_dblink into a;
  end;

  function get_def_source return varchar2 is begin return gDefaultSource; end;
  function get_def_owner return varchar2 is begin return gDefaultOwner; end;


  function lock_resource(p_resource_name varchar2, p_mode number default DBMS_LOCK.X_MODE, p_timeout number default 0, p_release_on_commit boolean default true) return varchar2  
  is
    l_res    integer;
  begin
    DBMS_LOCK.ALLOCATE_UNIQUE (
      lockname         => 'OPAS'||p_resource_name,
      lockhandle       => g_handle);

    l_res:=DBMS_LOCK.REQUEST(
      lockhandle         => g_handle,
      lockmode           => p_mode, --DBMS_LOCK.X_MODE, -- Exclusive mode
      timeout            => p_timeout,
      release_on_commit  => p_release_on_commit);
    
    if l_res <> 0 then
      raise_application_error(-20000, 'Resource '||p_resource_name||' can not be locked right now. Return code: '||l_res);
    end if;
    
    return g_handle;
  end;
  
  procedure lock_resource(p_resource_name varchar2, p_mode number default DBMS_LOCK.X_MODE, p_timeout number default 0, p_release_on_commit boolean default true)
  is
    l_handle varchar2(512);
  begin
    l_handle:=lock_resource(p_resource_name,p_mode,p_timeout,p_release_on_commit);
  end;
  
  procedure release_resource(p_handle varchar2)
  is  
    l_res integer;
  begin
    l_res := DBMS_LOCK.RELEASE(p_handle);
  end;

  procedure release_resource
  is  
  begin
    release_resource(g_handle);
  end;
  
  
end COREMOD_API;
/
--------------------------------------------------------
show errors
--------------------------------------------------------