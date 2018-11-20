CREATE OR REPLACE
PACKAGE BODY ASHA_CUBE_API AS

  function  getMODNAME return varchar2 is begin return gMODNAME; end;

  procedure CLEANUP_CACHE_INT
  is
  begin
    delete from asha_cube_qry_cache where created < (systimestamp - to_number(COREMOD_API.getconf('DICRETENTION',gMODNAME)));
    coremod_log.log('ASHA_CUBE_API.CLEANUP_CACHE_INT: Deleted '||sql%rowcount||' query text(s).');
    commit;
  exception
    when others then
      rollback;
      dbms_output.put_line(sqlerrm);
      coremod_log.log('ASHA_CUBE_API.CLEANUP_CACHE_INT error: '||sqlerrm);
  end;

  procedure CLEANUP_CUBE_INT
  is
  begin
    delete from asha_cube_sess where sess_created < (systimestamp - to_number(COREMOD_API.getconf('CUBERETENTION',gMODNAME))/24);
    coremod_log.log('ASHA_CUBE_API.CLEANUP_CUBE_INT: Deleted '||sql%rowcount||' session(s).');
    commit;
  exception
    when others then
      rollback;
      dbms_output.put_line(sqlerrm);
      coremod_log.log('ASHA_CUBE_API.CLEANUP_CUBE_INT error: '||sqlerrm);
  end;

  procedure CLEANUP_CUBE
  is begin
    CLEANUP_CACHE_INT;
    CLEANUP_CUBE_INT;
  end;

  procedure refresh_dictionaries
  is
  begin
    for i in (select *
                from (select p2l.src_dblink, min(created) min_created
                        from asha_cube_srcdblink2projects p2l, asha_cube_racnodes_cache c
                       where p2l.src_dblink=c.src_dblink(+)
                       group by p2l.src_dblink)
               where (min_created is null or min_created < (systimestamp - to_number(COREMOD_API.getconf('DICRETENTION',gMODNAME)))))
    loop
      coremod_log.log('Reloading RAC node dictionary for: '||i.src_dblink);
      delete from asha_cube_racnodes_cache where src_dblink=i.src_dblink;
      execute immediate
q'[insert into asha_cube_racnodes_cache (src_dblink, inst_name, inst_id)
select :p_src_dblink, instance_name||' (Node'||inst_id||')', inst_id from gv$instance@]'||i.src_dblink||q'[
union all
select :p_src_dblink, 'Cluster wide', -1 from dual]' using i.src_dblink;
    end loop;
    commit;
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
    l_txt clob;
    l_dbid number;
    l_sql varchar2(32765);
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

END ASHA_CUBE_API;
/
