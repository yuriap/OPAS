CREATE OR REPLACE
package COREMOD_API as

   gDefaultSource constant varchar2(32) := 'LOCAL';
   gDefaultOwner  constant varchar2(32) := 'PUBLIC';

   gMODNAME       constant varchar2(32) := 'OPASCORE';

   exDBLinkSuspended exception;
   pragma exception_init(exDBLinkSuspended, -20999);

   dblNEW        constant varchar2(32) := 'NEW';
   dblMODIFIED   constant varchar2(32) := 'MODIFIED';
   dblCREATED    constant varchar2(32) := 'CREATED';
   dblSUSPENDED  constant varchar2(32) := 'SUSPENDED';
   dblTODELETE   constant varchar2(32) := 'TODELETE';

   function getconf(p_key varchar2, p_module opas_modules.modname%type) return varchar2 RESULT_CACHE;
   function getscript(p_script_id varchar2) return clob;
   function getmodver(p_module opas_modules.modname%type) return varchar2 RESULT_CACHE;

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
   procedure drop_dblink(p_db_link_name varchar2, p_suspend boolean default false);
   procedure test_dblink(p_db_link_name varchar2);
   function get_ora_dblink(p_db_link_name varchar2) return varchar2;

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
