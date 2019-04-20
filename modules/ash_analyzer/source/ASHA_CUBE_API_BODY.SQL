CREATE OR REPLACE
PACKAGE BODY ASHA_CUBE_API AS

  function  getMODNAME return varchar2 is begin return gMODNAME; end;

  procedure refresh_dictionaries
  is
    l_dblink varchar2(100);
    invalid_password exception;
    pragma exception_init(invalid_password,-1017);
  begin
    --coremod_log.log('Reloading RAC node dictionary');
    for i in (select *
                from (select p2l.src_dblink, min(created) min_created
                        from asha_cube_srcdblink2projects p2l, asha_cube_racnodes_cache c, v$opas_db_links l
                       where p2l.src_dblink=c.src_dblink(+) and p2l.src_dblink=l.db_link_name and l.status=COREMOD_API.dblCREATED and p2l.src_dblink<>'$LOCAL$'
                       group by p2l.src_dblink)
               where (min_created is null or min_created < (systimestamp - to_number(COREMOD_API.getconf('DICRETENTION',gMODNAME)))))
    loop
      coremod_log.log('Reloading RAC node dictionary for: '||i.src_dblink||'('||COREMOD_API.get_ora_dblink(i.src_dblink)||')');
      begin
        COREMOD_API.test_dblink(i.src_dblink);
        delete from asha_cube_racnodes_cache where src_dblink=i.src_dblink;
        execute immediate
q'[insert into asha_cube_racnodes_cache (src_dblink, inst_name, inst_id)
select :p_src_dblink, instance_name||' (Node'||inst_id||')', inst_id from gv$instance@]'||COREMOD_API.get_ora_dblink(i.src_dblink)||q'[
union all
select :p_src_dblink, 'Cluster wide', -1 from dual]' using i.src_dblink,i.src_dblink;
        commit;
      exception
        when others then
          --COREMOD_API.drop_dblink(i.src_dblink, p_suspend => true);
          --coremod_log.log('DB Link: '||i.src_dblink||' has been suspended due to: '||sqlerrm);
          coremod_log.log('DB Link: '||i.src_dblink||' is unavailable now: '||sqlerrm);
      end;
    end loop;
  exception
    when others then rollback;dbms_output.put_line(sqlerrm);coremod_log.log('ASHA_CUBE_API.refresh_dictionaries error: '||sqlerrm);
  end;

  procedure add_dic_metrics(p_metric_id number)
  is
  begin
    merge into asha_cube_metrics_dic t
    using (select group_id, group_name, metric_id, metric_name||' ('||metric_unit||')' metric_name, 'Y' is_manual, systimestamp created
             from v$metricname where metric_id=p_metric_id) s
    on (t.group_id=s.group_id and t.metric_id=s.metric_id)
    when not matched then insert (t.group_id, t.group_name, t.metric_id, t.metric_name, t.is_manual, t.created)
    values (s.group_id, s.group_name, s.metric_id, s.metric_name, s.is_manual, s.created);
  end;

  procedure set_report_retention(p_report_id          asha_cube_reports.report_id%type,
                                 p_report_retention   asha_cube_reports.report_retention%type)
  is
  begin
    update asha_cube_reports set
      report_retention = decode(p_report_retention,-1,null,p_report_retention)
     where report_id = p_report_id;
    update asha_cube_reports set
      report_retention = decode(p_report_retention,-1,null,p_report_retention)
     where report_id in (select report_id from opas_reports where parent_id=p_report_id);
  end;

  procedure pin_cube_sqls(p_sess_id             asha_cube_sess.sess_id%type default null,
                          p_sess_retention_days asha_cube_sess.sess_retention_days%type,
                          p_sql_id              varchar2 default null)
  is
  begin
    if p_sess_retention_days > 10 or p_sess_retention_days = 0 then
      if p_sql_id is not null then
        COREMOD_REPORT_UTILS.pin_sql_in_cache (  P_SQL_ID => p_sql_id, P_DAYS => case when p_sess_retention_days = 0 then 365*10 else p_sess_retention_days end) ;
      else
        for i in (select sql_id from (SELECT c.sql_id, smpls
                                        FROM asha_cube c, opas_qry_cache q
                                       where c.sess_id = p_sess_id and c.g2=0 and c.sql_id=q.sql_id
                                       ORDER BY 2 desc) where rownum<11)
        loop
          COREMOD_REPORT_UTILS.pin_sql_in_cache (  P_SQL_ID => i.sql_id, P_DAYS => case when p_sess_retention_days = 0 then 365*10 else p_sess_retention_days end) ;
        end loop;
      end if;
    end if;
  end;

  procedure edit_session(p_sess_id             asha_cube_sess.sess_id%type,
                         p_sess_retention_days asha_cube_sess.sess_retention_days%type,
                         p_sess_description    asha_cube_sess.sess_description%type)
  is
  begin
    update asha_cube_sess set
      sess_retention_days = decode(p_sess_retention_days,-1,null,p_sess_retention_days),
      sess_description = p_sess_description
     where sess_id = p_sess_id;
    update asha_cube_sess set
     sess_retention_days = decode(p_sess_retention_days,-1,null,p_sess_retention_days)
     where parent_id = p_sess_id;

    --set the same retrntion for related reports
    for i in (select * from asha_cube_reports where sess_id=p_sess_id or sess_id in (select sess_id from asha_cube_sess where parent_id = p_sess_id)) loop
      set_report_retention(i.report_id,p_sess_retention_days);
    end loop;

    --set cache pin for sqls
    pin_cube_sqls(p_sess_id,p_sess_retention_days);
  end;

  procedure edit_report_properties(p_report_id          asha_cube_reports.report_id%type,
                                   p_report_retention   asha_cube_reports.report_retention%type,
                                   p_report_note        asha_cube_reports.report_note%type)
  is
  begin
    update asha_cube_reports set
      report_note = p_report_note
     where report_id = p_report_id;
    set_report_retention(p_report_id,p_report_retention);
  end;

  procedure delete_report(p_proj_id          asha_cube_reports.proj_id%type,
                          p_report_id          asha_cube_reports.report_id%type)
  is
  begin
    coremod_report_utils.drop_report(p_report_id);
    delete from asha_cube_reports where report_id=p_report_id and proj_id=p_proj_id;
  end;

  function get_cube_retention(p_sess_id asha_cube_reports.sess_id%type) return asha_cube_sess.sess_retention_days%type
  is
    l_ret asha_cube_sess.sess_retention_days%type;
  begin
    if p_sess_id is not null then
      select sess_retention_days into l_ret from asha_cube_sess where sess_id=p_sess_id;
      return l_ret;
    else
      return null; --default retention
    end if;
  end;

--  =============================================================================================================================================
--  =============================================================================================================================================
--  =============================================================================================================================================
/*
  procedure create_report(p_report_type      varchar2,
                          p_proj_id          asha_cube_reports.proj_id%type,
                          p_sess_id          asha_cube_reports.sess_id%type,
                          p_sql_id           varchar2,
                          p_dblink           varchar2,
                          p_limit            number default 0)
  is
    l_proj asha_cube_projects%rowtype;
    l_report_id opas_reports.report_id%type;
  begin
    l_proj:=ASHA_PROJ_API.getproject(p_proj_id,true);

    if p_report_type = COREMOD_REPORT_UTILS.gSQL_MEMORY_REPORT then
      l_report_id := coremod_reports.queue_report_sql_memory_stats(p_modname => gMODNAME, p_owner => l_proj.owner, p_sql_id => p_sql_id, p_dblink => p_dblink);
    elsif p_report_type = COREMOD_REPORT_UTILS.gSQL_AWR_REPORT then
      l_report_id := coremod_reports.queue_report_sql_awr_stats(p_modname => gMODNAME, p_owner => l_proj.owner, p_sql_id => p_sql_id, p_dblink => p_dblink, p_report_limit => p_limit);
    else
      raise_application_error(-20000,'Unsupported report type: '||p_report_type);
    end if;

    INSERT INTO asha_cube_reports (proj_id,report_id,sess_id,report_retention,report_note)
    VALUES                        (p_proj_id,l_report_id,p_sess_id,get_cube_retention(p_sess_id),null);

    insert into asha_cube_reports (proj_id,report_id,sess_id,report_retention,report_note)
    select p_proj_id,report_id,p_sess_id,get_cube_retention(p_sess_id),null from opas_reports where parent_id=l_report_id;

    commit;
  end;
*/
  procedure gather_recursive_reports
  is
  begin
    for i in (select r.report_id, a.report_retention, a.sess_id, a.proj_id from asha_cube_reports a, opas_reports r where a.created > sysdate - 1/24 and r.report_id=a.report_id) loop
      insert into asha_cube_reports (proj_id,report_id,sess_id,report_retention,report_note)
      select i.proj_id,report_id,i.sess_id,i.report_retention,null from opas_reports where parent_id=i.report_id and (report_id) not in (select report_id from asha_cube_reports);
    end loop;
    commit;
  end;

  procedure create_memsql_report(p_proj_id          asha_cube_reports.proj_id%type,
                                 p_sess_id          asha_cube_reports.sess_id%type default null,
                                 p_sql_id           varchar2,
                                 p_dblink           varchar2)
  is
    l_proj asha_cube_projects%rowtype;
    l_report_id opas_reports.report_id%type;
  begin
    l_proj:=ASHA_PROJ_API.getproject(p_proj_id,true);

    l_report_id := coremod_reports.queue_report_sql_memory_stats(p_modname => gMODNAME, p_owner => l_proj.owner, p_sql_id => p_sql_id, p_dblink => p_dblink);

    INSERT INTO asha_cube_reports (proj_id,report_id,sess_id,report_retention,report_note)
    VALUES                        (p_proj_id,l_report_id,p_sess_id,get_cube_retention(p_sess_id),null);

    --insert into asha_cube_reports (proj_id,report_id,sess_id,report_retention,report_note)
    --select p_proj_id,report_id,p_sess_id,get_cube_retention(p_sess_id),null from opas_reports where parent_id=l_report_id;

    commit;
  end;

  procedure create_awrsql_report(p_proj_id          asha_cube_reports.proj_id%type,
                                 p_sess_id          asha_cube_reports.sess_id%type default null,
                                 p_sql_id           varchar2,
                                 p_dblink           varchar2,
                                 p_limit            number,
                                 p_dbid             number,
                                 p_min_snap         number,
                                 p_max_snap         number)
  is
    l_proj asha_cube_projects%rowtype;
    l_report_id opas_reports.report_id%type;
  begin
    l_proj:=ASHA_PROJ_API.getproject(p_proj_id,true);

    l_report_id := coremod_reports.queue_report_sql_awr_stats(
                                 p_modname      => gMODNAME,
                                 p_owner        => l_proj.owner,
                                 p_sql_id       => p_sql_id,
                                 p_dblink       => p_dblink,
                                 p_report_limit => p_limit,
                                 p_dbid         => p_dbid,
                                 p_min_snap     => p_min_snap,
                                 p_max_snap     => p_max_snap);

    INSERT INTO asha_cube_reports (proj_id,report_id,sess_id,report_retention,report_note)
    VALUES                        (p_proj_id,l_report_id,p_sess_id,get_cube_retention(p_sess_id),null);

    --insert into asha_cube_reports (proj_id,report_id,sess_id,report_retention,report_note)
    --select p_proj_id,report_id,p_sess_id,get_cube_retention(p_sess_id),null from opas_reports where parent_id=l_report_id;

    commit;
  end;

--  =============================================================================================================================================
--  =============================================================================================================================================
--  =============================================================================================================================================

  procedure create_report_awrrpt(p_proj_id      asha_cube_reports.proj_id%type,
                                 p_dbid         number,
                                 p_min_snap     number,
                                 p_max_snap     number,
                                 p_instance_num varchar2,
                                 p_dblink       varchar2 default null,
                                 p_sess_id      asha_cube_reports.sess_id%type default null)
  is
    l_proj      asha_cube_projects%rowtype;
    l_report_id opas_reports.report_id%type;
  begin
    l_proj:=ASHA_PROJ_API.getproject(p_proj_id,true);

    l_report_id := coremod_reports.queue_report_awrrpt(p_modname => gMODNAME,
                                                       p_owner => l_proj.owner,
                                                       P_DBID => P_DBID,
                                                       P_MIN_SNAP => P_MIN_SNAP,
                                                       P_MAX_SNAP => P_MAX_SNAP,
                                                       P_INSTANCE_NUM => P_INSTANCE_NUM,
                                                       p_dblink => p_dblink);

    INSERT INTO asha_cube_reports (proj_id,report_id,sess_id,report_retention,report_note)
    VALUES                        (p_proj_id,l_report_id,p_sess_id,get_cube_retention(p_sess_id),null);

    commit;
  end;
--=============================================================================================================================================
  procedure create_report_sqawrrpt(p_proj_id      asha_cube_reports.proj_id%type,
                                   p_sql_id       varchar2,
                                   p_dbid         number,
                                   p_min_snap     number,
                                   p_max_snap     number,
                                   p_instance_num number,
                                   p_dblink       varchar2 default null,
                                   p_sess_id      asha_cube_reports.sess_id%type default null)

  is
    l_proj      asha_cube_projects%rowtype;
    l_report_id opas_reports.report_id%type;
  begin
    l_proj:=ASHA_PROJ_API.getproject(p_proj_id,true);

    l_report_id := coremod_reports.queue_report_sqawrrpt(p_modname => gMODNAME,
                                                         p_owner => l_proj.owner,
                                                         p_sql_id => p_sql_id,
                                                         P_DBID => P_DBID,
                                                         P_MIN_SNAP => P_MIN_SNAP,
                                                         P_MAX_SNAP => P_MAX_SNAP,
                                                         P_INSTANCE_NUM => P_INSTANCE_NUM,
                                                         p_dblink => p_dblink);

    INSERT INTO asha_cube_reports (proj_id,report_id,sess_id,report_retention,report_note)
    VALUES                        (p_proj_id,l_report_id,p_sess_id,get_cube_retention(p_sess_id),null);

    commit;
  end;
--=============================================================================================================================================
  procedure create_report_diffrpt(p_proj_id       asha_cube_reports.proj_id%type,
                                  p_dbid1         number,
                                  p_min_snap1     number,
                                  p_max_snap1     number,
                                  p_instance_num1 varchar2,
                                  p_dbid2         number,
                                  p_min_snap2     number,
                                  p_max_snap2     number,
                                  p_instance_num2 varchar2,
                                  p_dblink        varchar2 default null,
                                  p_sess_id       asha_cube_reports.sess_id%type default null)

  is
    l_proj      asha_cube_projects%rowtype;
    l_report_id opas_reports.report_id%type;
  begin
    l_proj:=ASHA_PROJ_API.getproject(p_proj_id,true);

    l_report_id := coremod_reports.queue_report_diffrpt(p_modname => gMODNAME,
                                                       p_owner => l_proj.owner,
                                                       P_DBID1 => P_DBID1,
                                                       P_MIN_SNAP1 => P_MIN_SNAP1,
                                                       P_MAX_SNAP1 => P_MAX_SNAP1,
                                                       P_INSTANCE_NUM1 => P_INSTANCE_NUM1,
                                                       P_DBID2 => P_DBID2,
                                                       P_MIN_SNAP2 => P_MIN_SNAP2,
                                                       P_MAX_SNAP2 => P_MAX_SNAP2,
                                                       P_INSTANCE_NUM2 => P_INSTANCE_NUM2,
                                                       p_dblink => p_dblink);

    INSERT INTO asha_cube_reports (proj_id,report_id,sess_id,report_retention,report_note)
    VALUES                        (p_proj_id,l_report_id,p_sess_id,get_cube_retention(p_sess_id),null);

    commit;
  end;
--=============================================================================================================================================
  procedure create_report_ashrpt(p_proj_id      asha_cube_reports.proj_id%type,
                                 p_dbid         number,
                                 p_bdate        date,
                                 p_edate        date,
                                 p_instance_num varchar2,
                                 p_dblink       varchar2 default null,
                                 p_sess_id      asha_cube_reports.sess_id%type default null)

  is
    l_proj      asha_cube_projects%rowtype;
    l_report_id opas_reports.report_id%type;
  begin
    l_proj:=ASHA_PROJ_API.getproject(p_proj_id,true);

    l_report_id := coremod_reports.queue_report_ashrpt(p_modname => gMODNAME,
                                                       p_owner => l_proj.owner,
                                                       P_DBID => P_DBID,
                                                       p_btime => p_bdate,
                                                       p_etime => p_edate,
                                                       P_INSTANCE_NUM => P_INSTANCE_NUM,
                                                       p_dblink => p_dblink);

    INSERT INTO asha_cube_reports (proj_id,report_id,sess_id,report_retention,report_note)
    VALUES                        (p_proj_id,l_report_id,p_sess_id,get_cube_retention(p_sess_id),null);

    commit;
  end;

END ASHA_CUBE_API;
/
