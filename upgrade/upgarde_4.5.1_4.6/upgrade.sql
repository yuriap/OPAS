set echo on

spool upgrade.log

@../../install/install_global_config

conn &localscheme./&localscheme.@&localdb.

-------------------------------------------------------------------------------------------------------------
-- OPAS Core
-------------------------------------------------------------------------------------------------------------

define MODNM=OPASCORE
define MODVER="1.3.0"

--Module integration
create table opas_integration_tmpl (
int_key              varchar2(30) primary key,
owner_modname        varchar2(128) references opas_modules(modname) on delete cascade,
src_modname          varchar2(128) references opas_modules(modname) on delete cascade,
trg_modname          varchar2(128) references opas_modules(modname) on delete cascade,
src_url_tmpl         varchar2(1000),
trg_url_tmpl         varchar2(1000),
src_desc_tmpl        varchar2(1000),
trg_desc_tmpl        varchar2(1000),
src_desc_dyn_tmpl    varchar2(1000),
trg_desc_dyn_tmpl    varchar2(1000)
);

create index idx_opas_int_tmpl_modo   on opas_integration_tmpl(owner_modname);
create index idx_opas_int_tmpl_mods   on opas_integration_tmpl(src_modname);
create index idx_opas_int_tmpl_modt   on opas_integration_tmpl(trg_modname);

create table opas_integration (
int_id               NUMBER GENERATED ALWAYS AS IDENTITY primary key,
int_key              varchar2(30)  references opas_integration_tmpl(int_key) on delete cascade,
src_entity_id        number,
src_prnt_entity_id   number,
trg_entity_id        number,
trg_prnt_entity_id   number
);

create index idx_opas_integration_src on opas_integration(int_key,src_prnt_entity_id,src_entity_id);
create index idx_opas_integration_trg on opas_integration(int_key,trg_prnt_entity_id,trg_entity_id);

set define off

@../../modules/core/source/COREMOD_INTEGRATION_SPEC.SQL
@../../modules/core/source/COREMOD_INTEGRATION_BODY.SQL

set define on

exec COREMOD.register(p_modname => 'OPASAPP', p_modver => '&OPASVER.', p_installed => sysdate);
exec COREMOD.register(p_modname => '&MODNM.', p_modver => '&MODVER.', p_installed => sysdate);

commit;

-------------------------------------------------------------------------------------------------------------
--ASH Analyzer
-------------------------------------------------------------------------------------------------------------

define MODNM=ASH_ANALYZER
define MODVER="3.4.0"

set define off

/*
@../../modules/ash_analyzer/source/
*/
@../../modules/ash_analyzer/source/ASHA_CUBE_API_SPEC.SQL
@../../modules/ash_analyzer/source/ASHA_CUBE_API_BODY.SQL
@../../modules/ash_analyzer/source/ASHA_CUBE_PKG_SPEC.SQL
@../../modules/ash_analyzer/source/ASHA_CUBE_PKG_BODY.SQL
@../../modules/ash_analyzer/source/ASHA_PROJ_API_BODY.SQL

declare
 l_tmpl asha_cube_sess_tmpl.tmpl_id%type;
begin
  select tmpl_id into l_tmpl from ASHA_CUBE_SESS_TMPL where tmpl_base='Y';
  insert into ASHA_CUBE_SESS_TMPL_PARS (TMPL_ID,TMPL_PAR_NM,TMPL_PAR_EXPR) values (l_tmpl,'DBID',null); 
  insert into ASHA_CUBE_SESS_TMPL_PARS (TMPL_ID,TMPL_PAR_NM,TMPL_PAR_EXPR) values (l_tmpl,'START_SNAP',null); 
  insert into ASHA_CUBE_SESS_TMPL_PARS (TMPL_ID,TMPL_PAR_NM,TMPL_PAR_EXPR) values (l_tmpl,'END_SNAP',null); 
end;
/

set define on

exec COREMOD.register(p_modname => '&MODNM.', p_modver => '&MODVER.', p_installed => sysdate);

commit;

-------------------------------------------------------------------------------------------------------------
--AWR Warehouse
-------------------------------------------------------------------------------------------------------------

define MODNM=AWR_WAREHOUSE
define MODVER="4.3.0"

set define off


@../../modules/awr_warehouse/source/AWRWH_CALC_ASH_CUBE_PRC.SQL
@../../modules/awr_warehouse/source/AWRWH_API_SPEC.SQL
@../../modules/awr_warehouse/source/AWRWH_FILE_API_SPEC.SQL
@../../modules/awr_warehouse/source/AWRWH_FILE_API_BODY.SQL
@../../modules/awr_warehouse/source/AWRWH_PROJ_API_BODY.SQL

set define on

set define off
set serveroutput on

declare
  l_script clob := 
q'^
@../../modules/awr_warehouse/scripts/_getcomph.sql
^';
begin
  delete from opas_scripts where script_id='PROC_GETCOMP';
  insert into opas_scripts (script_id,modname,script_content) values ('PROC_GETCOMP','AWR_WAREHOUSE',l_script||l_script1||l_script2);  
  COREMOD_REPORT_UTILS.prepare_saved_sql_script (  P_SCRIPT_NAME => 'PROC_GETCOMP');
  dbms_output.put_line('#1: '||dbms_lob.getlength(l_script)||' bytes; #2: '||dbms_lob.getlength(l_script1)||' bytes; #3: '||dbms_lob.getlength(l_script2)||' bytes;');
end;
/  
set define on

BEGIN
  COREMOD_INTEGRATION.register_integration (  P_INT_KEY => AWRWH_API.gintAWRWH2ASH_DUMP2CUBE,
    P_OWNER_MODNAME => 'AWR_WAREHOUSE',
    P_SRC_MODNAME => 'AWR_WAREHOUSE',
    P_TRG_MODNAME => 'ASH_ANALYZER',
    P_SRC_URL_TMPL => 'f?p=<APP_ID>:404:<SESSION>::::P404_DUMP_ID,P404_PROJ_ID:<SRC_ENTITY>,<SRC_PARENT>:',
    P_TRG_URL_TMPL => 'f?p=<APP_ID>:303:<SESSION>::::P303_SESS_ID,P303_TQ_ID,P303_PROJ_ID:<TRG_ENTITY>,0,<TRG_PARENT>:',
    P_SRC_DESC_TMPL => 'Dump file "<VAR2>" with name "<VAR1>" of "<VAR3>" project',
    P_TRG_DESC_TMPL => 'ASH Cube "Created: <VAR1>; Status: <VAR2>" for dump file "<VAR3>"',
    P_SRC_DESC_DYN_TMPL => 'select dump_name, filename, p.proj_name, null from awrwh_dumps d, awrwh_projects p where dump_id=<SRC_ENTITY> and d.proj_id=p.proj_id',
    P_TRG_DESC_DYN_TMPL => q'[select to_char(sess_created,'YYYY-MON-DD HH24:MI:SS'),sess_status, (select filename from awrwh_dumps where dump_id=<SRC_ENTITY>) dump_name, null from asha_cube_sess where sess_id=<TRG_ENTITY>]');
END;
/

exec COREMOD.register(p_modname => '&MODNM.', p_modver => '&MODVER.', p_installed => sysdate);

commit;

set pages 999
set lines 200

select * from user_errors order by 1,2,3,4,5;

begin
  dbms_utility.compile_schema(user);
end;
/

select * from user_errors order by 1,2,3,4,5;

set pages 999
set lines 200
column MODNAME format a32 word_wrapped
column MODDESCR format a100 word_wrapped
select t.modname, t.modver, to_char(t.installed,'YYYY/MON/DD HH24:MI:SS') installed, t.moddescr from opas_modules t order by t.installed;
disc

spool off