CREATE OR REPLACE
PACKAGE BODY ASHA_CUBE_API AS

  function  getMODNAME return varchar2 is begin return gMODNAME; end;

  procedure CLEANUP_CACHE_INT
  is
  begin
    delete from asha_cube_qry_cache where created < (systimestamp - to_number(COREMOD_API.getconf('DICRETENTION',gMODNAME)));
    coremod_log.log('Cleanup query cache: Deleted '||sql%rowcount||' query text(s).');
    commit;
  exception
    when others then
      rollback;
      dbms_output.put_line(sqlerrm);
      coremod_log.log('ASHA_CUBE_API.CLEANUP_CACHE_INT error: '||sqlerrm);
  end;

  procedure CLEANUP_CUBE
  is begin
    CLEANUP_CACHE_INT;
  end;

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
    insert into asha_cube_metrics_dic
    select group_id, group_name, metric_id, metric_name||' ('||metric_unit||')' metric_name, 'Y' is_manual, systimestamp created
    from v$metricname where metric_id=p_metric_id;
  end;

  function get_sql_qry_txt(p_srcdb varchar2, p_sql_id varchar2) return clob AS
    l_txt  varchar2(4000);
    l_dbid number;
    l_sql  varchar2(32765);
    pragma autonomous_transaction;
  BEGIN
    select sql_text into l_txt from asha_cube_qry_cache where sql_id=p_sql_id;
    return l_txt;
  exception
    when no_data_found then
      begin
        begin
          select sql_text into l_txt from dba_hist_sqltext where sql_id=p_sql_id and rownum=1;
        exception
          when no_data_found then null;
        end;

        if l_txt is null and p_srcdb is not null and p_srcdb <> '$LOCAL$' then
          execute immediate 'select dbid from v$database@'||p_srcdb into l_dbid;

          begin
            l_sql := 'select txt from (select cast(substr(sql_text,1,4000) as varchar2(4000)) txt from dba_hist_sqltext@'||p_srcdb||' a where sql_id=:p_sql_id and dbid=:p_dbid) where rownum<2';
            execute immediate l_sql into l_txt using p_sql_id, l_dbid;
          exception
            when no_data_found then null;
          end;

          if l_txt is null and p_srcdb is not null and p_srcdb <> '$LOCAL$' then
            begin
              l_sql := 'select txt from (select cast(substr(SQL_FULLTEXT,1,4000) as varchar2(4000)) from gv$sql@'||p_srcdb||' a where sql_id=:p_sql_id) where rownum<2';
              execute immediate l_sql into l_txt using p_sql_id;
            exception
              when no_data_found then null;
            end;
          end if;
        end if;

        if l_txt is null then
          l_txt := 'No sql text found.';
        else
          INSERT INTO asha_cube_qry_cache (sql_id,sql_text,created)
               VALUES (p_sql_id,l_txt,default);
          commit;
        end if;
        return l_txt;
      end;
  END get_sql_qry_txt;

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

  procedure create_report_sql_memory_report(
                          p_proj_id          asha_cube_reports.proj_id%type,
                          p_sess_id          asha_cube_reports.sess_id%type,
                          p_sql_id           varchar2,
                          p_dblink           varchar2)
  is
    l_proj asha_cube_projects%rowtype;
    l_report_id opas_reports.report_id%type;
  begin
    l_proj:=ASHA_PROJ_API.getproject(p_proj_id,true);

    l_report_id := coremod_reports.queue_report_sql_memory_stats(p_modname => gMODNAME, p_owner => l_proj.owner, p_sql_id => p_sql_id, p_dblink => p_dblink);

    INSERT INTO asha_cube_reports (proj_id,report_id,sess_id,report_retention,report_note)
    VALUES                        (p_proj_id,l_report_id,p_sess_id,null,null);

    commit;

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

END ASHA_CUBE_API;
/
