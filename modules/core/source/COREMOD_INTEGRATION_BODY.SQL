CREATE OR REPLACE
PACKAGE BODY COREMOD_INTEGRATION AS

  gURLTMPL constant varchar2(1000) := 'f?p=<APP_ID>:<Page>:<SESSION>::::<PARAMS>:';

  procedure register_integration(p_int_key           opas_integration_tmpl.int_key%type,
                                 p_owner_modname     opas_integration_tmpl.owner_modname%type,
                                 p_src_modname       opas_integration_tmpl.src_modname%type,
                                 p_trg_modname       opas_integration_tmpl.trg_modname%type,
                                 p_src_url_tmpl      opas_integration_tmpl.src_url_tmpl%type,
                                 p_trg_url_tmpl      opas_integration_tmpl.trg_url_tmpl%type,
                                 p_src_desc_tmpl     opas_integration_tmpl.src_desc_tmpl%type,
                                 p_trg_desc_tmpl     opas_integration_tmpl.trg_desc_tmpl%type,
                                 p_src_desc_dyn_tmpl opas_integration_tmpl.src_desc_dyn_tmpl%type,
                                 p_trg_desc_dyn_tmpl opas_integration_tmpl.trg_desc_dyn_tmpl%type)
  is
  begin
    merge INTO opas_integration_tmpl t
         using (select p_int_key int_key,
                       p_owner_modname owner_modname,
                       p_src_modname src_modname,
                       p_trg_modname trg_modname,
                       p_src_url_tmpl src_url_tmpl,
                       p_trg_url_tmpl trg_url_tmpl,
                       p_src_desc_tmpl src_desc_tmpl,
                       p_trg_desc_tmpl trg_desc_tmpl,
                       p_src_desc_dyn_tmpl src_desc_dyn_tmpl,
                       p_trg_desc_dyn_tmpl trg_desc_dyn_tmpl from dual) s
    on (s.int_key=t.int_key)
    when matched then update set
      owner_modname = p_owner_modname,
      src_modname = p_src_modname,
      trg_modname = p_trg_modname,
      src_url_tmpl = p_src_url_tmpl,
      trg_url_tmpl = p_trg_url_tmpl,
      src_desc_tmpl = p_src_desc_tmpl,
      trg_desc_tmpl = p_trg_desc_tmpl,
      src_desc_dyn_tmpl = p_src_desc_dyn_tmpl,
      trg_desc_dyn_tmpl = p_trg_desc_dyn_tmpl
    when not matched then
      insert (t.int_key, t.owner_modname, t.src_modname, t.trg_modname, t.src_url_tmpl, t.trg_url_tmpl, t.src_desc_tmpl, t.trg_desc_tmpl, t.src_desc_dyn_tmpl, t.trg_desc_dyn_tmpl)
      VALUES (s.int_key, s.owner_modname, s.src_modname, s.trg_modname, s.src_url_tmpl, s.trg_url_tmpl, s.src_desc_tmpl, s.trg_desc_tmpl, s.src_desc_dyn_tmpl, s.trg_desc_dyn_tmpl);
  end;

  procedure create_integration(p_int_key             opas_integration.int_key%type,
                               p_src_entity_id       opas_integration.src_entity_id%type,
                               p_src_prnt_entity_id  opas_integration.src_prnt_entity_id%type,
                               p_trg_entity_id       opas_integration.trg_entity_id%type,
                               p_trg_prnt_entity_id  opas_integration.trg_prnt_entity_id%type)
  AS
  BEGIN
    INSERT INTO opas_integration (int_key, src_entity_id, src_prnt_entity_id, trg_entity_id, trg_prnt_entity_id)
         VALUES (p_int_key, p_src_entity_id, p_src_prnt_entity_id, p_trg_entity_id, p_trg_prnt_entity_id);
  END create_integration;

  procedure clone_integration (p_int_key             opas_integration.int_key%type,
                               p_modname             opas_integration_tmpl.owner_modname%type,
                               p_trg_entity_id       opas_integration.trg_entity_id%type,
                               p_trg_prnt_entity_id  opas_integration.trg_prnt_entity_id%type,
                               p_new_trg_entity_id   opas_integration.trg_entity_id%type)
  is
    l_int opas_integration%rowtype;
  begin
    for l_int in (select i.* from opas_integration i, opas_integration_tmpl t where t.trg_modname = p_modname and i.int_key=t.int_key and i.int_key = p_int_key and trg_entity_id=p_trg_entity_id and trg_prnt_entity_id=p_trg_prnt_entity_id)
    loop
      COREMOD_INTEGRATION.create_integration (
        P_INT_KEY => p_int_key,
        P_SRC_ENTITY_ID => l_int.src_entity_id,
        P_SRC_PRNT_ENTITY_ID => l_int.src_prnt_entity_id,
        P_TRG_ENTITY_ID => p_new_trg_entity_id,
        P_TRG_PRNT_ENTITY_ID => l_int.trg_prnt_entity_id) ;
    end loop;
  exception
    when others then coremod_log.log('clone_integration: '||sqlerrm);
  end;

  function get_int_tmpl(p_int_key opas_integration.int_key%type) return opas_integration_tmpl%rowtype
  result_cache
  is
    l_res opas_integration_tmpl%rowtype;
  begin
    select * into l_res from opas_integration_tmpl where int_key = p_int_key;
    return l_res;
  end;

  function get_int(p_int_id opas_integration.int_id%type) return opas_integration%rowtype
  result_cache
  is
    l_res opas_integration%rowtype;
  begin
    select * into l_res from opas_integration where int_id = p_int_id;
    return l_res;
  end;

  function get_src_url(p_int_id opas_integration.int_id%type) return varchar2 AS
    l_url   varchar2(4000);
    l_descr varchar2(1000);
    l_sql   varchar2(1000);
    l_tmpl  opas_integration_tmpl%rowtype;
    l_int   opas_integration%rowtype;
    l_var1  varchar2(1000);
    l_var2  varchar2(1000);
    l_var3  varchar2(1000);
    l_var4  varchar2(1000);
  BEGIN
    l_int  := get_int(p_int_id);
    l_tmpl := get_int_tmpl(l_int.int_key);

    l_sql := replace(replace(replace(replace(l_tmpl.src_desc_dyn_tmpl,'<SRC_ENTITY>',l_int.src_entity_id),'<SRC_PARENT>',l_int.src_prnt_entity_id),
                                                                      '<TRG_ENTITY>',l_int.trg_entity_id),'<TRG_PARENT>',l_int.trg_prnt_entity_id);

    execute immediate l_sql into l_var1,l_var2,l_var3,l_var4;

    l_descr := replace(replace(replace(replace(l_tmpl.src_desc_tmpl,'<VAR1>',l_var1),'<VAR2>',l_var2),'<VAR3>',l_var3),'<VAR4>',l_var4);

    l_url := '<a href="'||replace(replace(replace(replace(l_tmpl.src_url_tmpl,'<APP_ID>',V('APP_ID')),'<SESSION>',V('SESSION')),'<SRC_ENTITY>',l_int.src_entity_id),'<SRC_PARENT>',l_int.src_prnt_entity_id)||'">' || l_descr || '</a>';

   return l_url;
  exception
    when others then
      coremod_log.log('COREMOD_INTEGRATION.get_src_url'||chr(10)||sqlerrm||chr(10)||DBMS_UTILITY.FORMAT_ERROR_BACKTRACE);
      raise_application_error(-20000,'COREMOD_INTEGRATION.get_src_url'||chr(10)||sqlerrm);
  END get_src_url;

  function get_trg_url(p_int_id opas_integration.int_id%type) return varchar2 AS
    l_url   varchar2(4000);
    l_descr varchar2(1000);
    l_sql   varchar2(1000);
    l_tmpl  opas_integration_tmpl%rowtype;
    l_int   opas_integration%rowtype;
    l_var1  varchar2(1000);
    l_var2  varchar2(1000);
    l_var3  varchar2(1000);
    l_var4  varchar2(1000);
  BEGIN
    l_int  := get_int(p_int_id);
    l_tmpl := get_int_tmpl(l_int.int_key);

    l_sql := replace(replace(replace(replace(l_tmpl.trg_desc_dyn_tmpl,'<SRC_ENTITY>',l_int.src_entity_id),'<SRC_PARENT>',l_int.src_prnt_entity_id),
                                                                      '<TRG_ENTITY>',l_int.trg_entity_id),'<TRG_PARENT>',l_int.trg_prnt_entity_id);

    execute immediate l_sql into l_var1,l_var2,l_var3,l_var4;

    l_descr := replace(replace(replace(replace(l_tmpl.trg_desc_tmpl,'<VAR1>',l_var1),'<VAR2>',l_var2),'<VAR3>',l_var3),'<VAR4>',l_var4);

    l_url := '<a href="'||replace(replace(replace(replace(l_tmpl.trg_url_tmpl,'<APP_ID>',V('APP_ID')),'<SESSION>',V('SESSION')),'<TRG_ENTITY>',l_int.trg_entity_id),'<TRG_PARENT>',l_int.trg_prnt_entity_id)||'">' || l_descr || '</a>';

   return l_url;
  exception
    when others then
      coremod_log.log('COREMOD_INTEGRATION.get_trg_url'||chr(10)||sqlerrm||chr(10)||DBMS_UTILITY.FORMAT_ERROR_BACKTRACE);
      raise_application_error(-20000,'COREMOD_INTEGRATION.get_trg_url'||chr(10)||sqlerrm);
  END get_trg_url;

  procedure print_url_list(p_int_key             opas_integration_tmpl.int_key%type,
                           p_type                varchar2, --SOURCE, TARGET
                           p_modname             opas_integration_tmpl.owner_modname%type,
                           p_prnt_entity_id      opas_integration.src_prnt_entity_id%type,
                           p_entity_id           opas_integration.src_entity_id%type default null)
  is
    l_cnt number := 1;
  begin
    if p_type = 'SOURCE' then
      for i in (SELECT int_id FROM opas_integration i, opas_integration_tmpl t where t.src_modname = p_modname and i.int_key=t.int_key and i.int_key = p_int_key and src_prnt_entity_id = p_prnt_entity_id and src_entity_id=nvl(p_entity_id,src_entity_id) order by int_id desc )
      loop
        htp.p(l_cnt||'. '||COREMOD_INTEGRATION.get_trg_url(i.int_id));htp.p('<br>');
        l_cnt:=l_cnt+1;
      end loop;
    elsif p_type = 'TARGET' then
      for i in (SELECT int_id FROM opas_integration i, opas_integration_tmpl t where t.trg_modname = p_modname and i.int_key=t.int_key and i.int_key = p_int_key and trg_prnt_entity_id = p_prnt_entity_id and trg_entity_id=nvl(p_entity_id,trg_entity_id) order by int_id desc )
      loop
        htp.p(l_cnt||'. '||COREMOD_INTEGRATION.get_src_url(i.int_id));htp.p('<br>');
        l_cnt:=l_cnt+1;
      end loop;
    end if;
  end;

  function does_integration_exist(
                           p_int_key             opas_integration_tmpl.int_key%type,
                           p_type                varchar2, --SOURCE, TARGET
                           p_modname             opas_integration_tmpl.owner_modname%type,
                           p_prnt_entity_id      opas_integration.src_prnt_entity_id%type,
                           p_entity_id           opas_integration.src_entity_id%type default null) return boolean
  is
    l_res number;
  begin
    if p_type = 'SOURCE' then
      select count(1) into l_res from dual where exists
        (SELECT /*+ result_cache */ int_id FROM opas_integration i, opas_integration_tmpl t where t.src_modname = p_modname and i.int_key=t.int_key and i.int_key = p_int_key and src_prnt_entity_id = p_prnt_entity_id and src_entity_id=nvl(p_entity_id,src_entity_id));
    end if;
    if p_type = 'TARGET' then
      select count(1) into l_res from dual where exists
        (SELECT /*+ result_cache */ int_id FROM opas_integration i, opas_integration_tmpl t where t.trg_modname = p_modname and i.int_key=t.int_key and i.int_key = p_int_key and trg_prnt_entity_id = p_prnt_entity_id and trg_entity_id=nvl(p_entity_id,trg_entity_id));
    end if;
    return nvl(l_res,0)=1;
  end;

  function does_integration_exist(
                           p_int_key             opas_integration_tmpl.int_key%type,
                           p_modname             opas_integration_tmpl.owner_modname%type,
                           p_prnt_entity_id      opas_integration.src_prnt_entity_id%type,
                           p_entity_id           opas_integration.src_entity_id%type default null) return boolean
  is
    l_res number;
  begin
    return does_integration_exist(p_int_key,'SOURCE',p_modname,p_prnt_entity_id,p_entity_id) or does_integration_exist(p_int_key,'TARGET',p_modname,p_prnt_entity_id,p_entity_id);
  end;

  procedure delete_integration(p_int_id opas_integration.int_id%type) AS
  BEGIN
    delete from opas_integration where int_id=p_int_id;
  END delete_integration;

  procedure remove_integration(
                           p_int_key             opas_integration_tmpl.int_key%type,
                           p_modname             opas_integration_tmpl.owner_modname%type,
                           p_prnt_entity_id      opas_integration.src_prnt_entity_id%type,
                           p_entity_id           opas_integration.src_entity_id%type default null)
  is
  begin
    for i in (select int_id from opas_integration i, opas_integration_tmpl t where t.src_modname = p_modname and i.int_key=t.int_key and i.int_key = p_int_key and src_prnt_entity_id = p_prnt_entity_id and src_entity_id=nvl(p_entity_id,src_entity_id))
    loop
      delete_integration(i.int_id);
    end loop;
    for i in (select int_id from opas_integration i, opas_integration_tmpl t where t.trg_modname = p_modname and i.int_key=t.int_key and i.int_key = p_int_key and trg_prnt_entity_id = p_prnt_entity_id and trg_entity_id=nvl(p_entity_id,trg_entity_id))
    loop
      delete_integration(i.int_id);
    end loop;
  end;

END COREMOD_INTEGRATION;
/
