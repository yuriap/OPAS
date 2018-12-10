CREATE OR REPLACE
PACKAGE BODY ASHA_CUBE_API AS

  function  getMODNAME return varchar2 is begin return gMODNAME; end;

  procedure refresh_dictionaries
  is
    l_dblink varchar2(100);
  begin
    --coremod_log.log('Reloading RAC node dictionary');
    for i in (select *
                from (select p2l.src_dblink, min(created) min_created
                        from asha_cube_srcdblink2projects p2l, asha_cube_racnodes_cache c
                       where p2l.src_dblink=c.src_dblink(+)
                       group by p2l.src_dblink)
               where (min_created is null or min_created < (systimestamp - to_number(COREMOD_API.getconf('DICRETENTION',gMODNAME)))))
    loop
      coremod_log.log('Reloading RAC node dictionary for: '||i.src_dblink||'('||COREMOD_API.get_ora_dblink(i.src_dblink)||')');
      delete from asha_cube_racnodes_cache where src_dblink=i.src_dblink;
      execute immediate
q'[insert into asha_cube_racnodes_cache (src_dblink, inst_name, inst_id)
select :p_src_dblink, instance_name||' (Node'||inst_id||')', inst_id from gv$instance@]'||COREMOD_API.get_ora_dblink(i.src_dblink)||q'[
union all
select :p_src_dblink, 'Cluster wide', -1 from dual]' using i.src_dblink,i.src_dblink;
      commit;
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

  procedure edit_session(p_sess_id             asha_cube_sess.sess_id%type,
                         p_sess_retention_days asha_cube_sess.sess_retention_days%type,
                         p_sess_description    asha_cube_sess.sess_description%type)
  is
  begin
    update asha_cube_sess set
      sess_retention_days = decode(p_sess_retention_days,-1,null,p_sess_retention_days),
      sess_description = p_sess_description
     where sess_id = p_sess_id;
  end;

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

    if p_report_type = gREPORT_SQL_MEMORY then
      l_report_id := coremod_reports.queue_report_sql_memory_stats(p_modname => gMODNAME, p_owner => l_proj.owner, p_sql_id => p_sql_id, p_dblink => p_dblink);
    elsif p_report_type = gREPORT_SQL_AWR then
      l_report_id := coremod_reports.queue_report_sql_awr_stats(p_modname => gMODNAME, p_owner => l_proj.owner, p_sql_id => p_sql_id, p_dblink => p_dblink, p_report_limit => p_limit);
    else
      raise_application_error(-20000,'Unsupported report type: '||p_report_type);
    end if;

    INSERT INTO asha_cube_reports (proj_id,report_id,sess_id,report_retention,report_note)
    VALUES                        (p_proj_id,l_report_id,p_sess_id,null,null);

    insert into asha_cube_reports (proj_id,report_id,sess_id,report_retention,report_note)
    select p_proj_id,report_id,p_sess_id,null,null from opas_reports where parent_id=l_report_id;

    commit;
  end;

  procedure edit_report_properties(p_report_id          asha_cube_reports.report_id%type,
                                   p_report_retention   asha_cube_reports.report_retention%type,
                                   p_report_note        asha_cube_reports.report_note%type)
  is
  begin
    update asha_cube_reports set
      report_retention = decode(p_report_retention,-1,null,p_report_retention),
      report_note = p_report_note
     where report_id = p_report_id;
  end;

  procedure delete_report(p_proj_id          asha_cube_reports.proj_id%type,
                          p_report_id          asha_cube_reports.report_id%type)
  is
  begin
    coremod_report_utils.drop_report(p_report_id);
    delete from asha_cube_reports where report_id=p_report_id and proj_id=p_proj_id;
  end;

END ASHA_CUBE_API;
/
