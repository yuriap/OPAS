CREATE OR REPLACE
package body coremod_reports
as

  function queue_report_awrrpt(p_modname varchar2, p_owner varchar2, p_dbid number, p_min_snap number, p_max_snap number, p_instance_num number, p_dblink varchar2) return opas_reports.report_id%type
  is
    l_report_id opas_reports.report_id%type;
  begin
    coremod_report_utils.init_report(p_modname,l_report_id, null);
    coremod_report_utils.set_report_type (l_report_id, coremod_report_utils.qAWRRPT);
    coremod_report_utils.set_report_param(l_report_id,coremod_report_utils.gparOWNER,       p_owner);
    coremod_report_utils.set_report_param(l_report_id,coremod_report_utils.gparDBID,        p_dbid);
    coremod_report_utils.set_report_param(l_report_id,coremod_report_utils.gparMIN_SNAP,    p_min_snap);
    coremod_report_utils.set_report_param(l_report_id,coremod_report_utils.gparMAX_SNAP,    p_max_snap);
    coremod_report_utils.set_report_param(l_report_id,coremod_report_utils.gparINSTANCE_NUM,p_instance_num);
    coremod_report_utils.set_report_param(l_report_id,coremod_report_utils.gparDBLINK,      p_dblink);
    coremod_report_utils.queue_report(l_report_id);
    return l_report_id;
  end;

  function getreport_awrrpt(p_dbid number, p_min_snap number, p_max_snap number, p_instance_num number) return coremod_report_utils.t_output_lines
  is
    l_report coremod_report_utils.t_output_lines;
    l_inst_lst    AWRRPT_INSTANCE_LIST_TYPE;
    l_mis         number;
    l_mas         number;
  begin
    if p_instance_num is null then
      select unique INSTANCE_NUMBER bulk collect into l_inst_lst from dba_hist_snapshot x where dbid=p_dbid and SNAP_ID between p_min_snap and p_max_snap;
      select min(snap_id) mis, max(snap_id) mas into l_mis, l_mas from dba_hist_snapshot x where dbid=p_dbid and SNAP_ID between p_min_snap and p_max_snap;
      begin
        for j in (select rownum rn, output from table(dbms_workload_repository.awr_global_report_html(p_dbid,l_inst_lst,l_mis,l_mas)))
        loop
          l_report(j.rn):=j.output;
        end loop;
      exception
        when others then l_report(1):=sqlerrm;
      end;
    else
      select min(snap_id) mis, max(snap_id) mas into l_mis, l_mas
        from dba_hist_snapshot x where dbid=p_dbid and SNAP_ID between p_min_snap and p_max_snap and INSTANCE_NUMBER = p_instance_num;
      begin
        for j in (select rownum rn, output from table(dbms_workload_repository.awr_report_html(p_dbid,p_instance_num,l_mis,l_mas)))
        loop
          l_report(j.rn):=j.output;
        end loop;
      exception
        when others then l_report(1):=sqlerrm;
      end;
    end if;
    return l_report;
  end;

  function getreport_awrrpt(p_dbid number, p_min_snap number, p_max_snap number, p_instance_num number, p_dblink varchar2) return clob
  is
    l_out clob;
    l_sql varchar2(4000) := q'[
declare
l_mis number; l_mas number; l_inst_lst AWRRPT_INSTANCE_LIST_TYPE;
begin
  select unique INSTANCE_NUMBER bulk collect into l_inst_lst from dba_hist_snapshot x where dbid=<DBID> and SNAP_ID between <MIS> and <MAS>;
  select min(snap_id), max(snap_id) into l_mis, l_mas from dba_hist_snapshot x where dbid=<DBID> and SNAP_ID between <MIS> and <MAS> <INST>;
  begin
    for j in (select output from table(dbms_workload_repository.<FNC>(<DBID>,<INSTLST>,l_mis,l_mas)))
    loop
      l_out:=l_out||j.output||chr(10);
    end loop;
  exception
    when others then l_out:=sqlerrm;
  end;
end;]';
  begin
    l_sql := replace(replace(replace(l_sql,'<DBID>',p_dbid),'<MIS>',p_min_snap),'<MAS>',p_max_snap);
    if p_instance_num is null then
      l_sql := replace(replace(replace(l_sql,'<FNC>','awr_global_report_html'),'<INSTLST>','l_inst_lst'),'<INST>',null);
    else
      l_sql := replace(replace(replace(l_sql,'<FNC>','awr_report_html'),'<INSTLST>',p_instance_num),'<INST>','and INSTANCE_NUMBER='||p_instance_num);
    end if;
    coremod_log.log('Remote AWR Report: '||l_sql,'DEBUG');
    coremod_log.log('Remote AWR Report DB Link: '||p_dblink,'DEBUG');
    COREMOD_REPORT_UTILS.get_clob_remotelly(l_sql,p_dblink,l_out);
    return l_out;
  end;

--  =============================================================================================================================================
--  =============================================================================================================================================
--  =============================================================================================================================================

  function queue_report_sqawrrpt(p_modname varchar2, p_owner varchar2, p_sql_id varchar2, p_dbid number, p_min_snap number, p_max_snap number, p_instance_num number, p_dblink varchar2) return opas_reports.report_id%type
  is
    l_report_id opas_reports.report_id%type;
  begin
    coremod_report_utils.init_report(p_modname,l_report_id, null);
    coremod_report_utils.set_report_type (l_report_id, coremod_report_utils.qSQAWRRPT);
    coremod_report_utils.set_report_param(l_report_id,coremod_report_utils.gparOWNER,       p_owner);
    coremod_report_utils.set_report_param(l_report_id,coremod_report_utils.gparSQLID,       p_sql_id);
    coremod_report_utils.set_report_param(l_report_id,coremod_report_utils.gparDBID,        p_dbid);
    coremod_report_utils.set_report_param(l_report_id,coremod_report_utils.gparMIN_SNAP,    p_min_snap);
    coremod_report_utils.set_report_param(l_report_id,coremod_report_utils.gparMAX_SNAP,    p_max_snap);
    coremod_report_utils.set_report_param(l_report_id,coremod_report_utils.gparINSTANCE_NUM,p_instance_num);
    coremod_report_utils.set_report_param(l_report_id,coremod_report_utils.gparDBLINK,      p_dblink);
    coremod_report_utils.queue_report(l_report_id);
    return l_report_id;
  end;

  function getreport_sqawrrpt(p_sql_id varchar2, p_dbid number, p_min_snap number, p_max_snap number, p_instance_num number) return coremod_report_utils.t_output_lines
  is
    l_report coremod_report_utils.t_output_lines;
    l_mis         number;
    l_mas         number;
  begin
    select min(snap_id) mis, max(snap_id) mas into l_mis, l_mas
      from dba_hist_snapshot x where dbid=p_dbid and SNAP_ID between p_min_snap and p_max_snap and INSTANCE_NUMBER = p_instance_num;
    begin
      for j in (select rownum rn, output from table(dbms_workload_repository.awr_sql_report_html(p_dbid,p_instance_num,l_mis,l_mas,p_sql_id)))
      loop
        l_report(j.rn):=j.output;
      end loop;
    exception
      when others then l_report(1):=sqlerrm;
    end;
    return l_report;
  end;

  function getreport_sqawrrpt(p_sql_id varchar2, p_dbid number, p_min_snap number, p_max_snap number, p_instance_num number, p_dblink varchar2) return clob
  is
    l_out clob;
    l_sql varchar2(4000) := q'[
declare
l_mis number; l_mas number;
begin
  select min(snap_id), max(snap_id) into l_mis, l_mas from dba_hist_snapshot x where dbid=<DBID> and SNAP_ID between <MIS> and <MAS> and INSTANCE_NUMBER = <INST>;
  begin
    for j in (select output from table(dbms_workload_repository.awr_sql_report_html(<DBID>,<INST>,l_mis,l_mas,'<SQLID>')))
    loop
      l_out:=l_out||j.output||chr(10);
    end loop;
  exception
    when others then l_out:=sqlerrm;
  end;
end;]';
  begin
    l_sql := replace(replace(replace(replace(replace(l_sql,'<DBID>',p_dbid),'<MIS>',p_min_snap),'<MAS>',p_max_snap),'<INST>',p_instance_num),'<SQLID>',p_sql_id);
    coremod_tasks.log('Remote AWR SQL Report: '||l_sql,coremod_tasks.get_curr_tq_id);
    coremod_tasks.log('Remote AWR SQL Report DB Link: '||p_dblink,coremod_tasks.get_curr_tq_id);
    coremod_log.log('Remote AWR SQL Report: '||l_sql,'DEBUG');
    coremod_log.log('Remote AWR SQL Report DB Link: '||p_dblink,'DEBUG');
    COREMOD_REPORT_UTILS.get_clob_remotelly(l_sql,p_dblink,l_out);
    return l_out;
  end;

--  =============================================================================================================================================
--  =============================================================================================================================================
--  =============================================================================================================================================

  function queue_report_diffrpt(p_modname varchar2, p_owner varchar2,
                                p_dbid1 number, p_min_snap1 number, p_max_snap1 number, p_instance_num1 number,
                                p_dbid2 number, p_min_snap2 number, p_max_snap2 number, p_instance_num2 number, p_dblink varchar2) return opas_reports.report_id%type
  is
    l_report_id opas_reports.report_id%type;
  begin
    coremod_report_utils.init_report(p_modname,l_report_id, null);
    coremod_report_utils.set_report_type (l_report_id, coremod_report_utils.qAWRDIFF);
    coremod_report_utils.set_report_param(l_report_id,coremod_report_utils.gparOWNER,       p_owner);

    coremod_report_utils.set_report_param(l_report_id,coremod_report_utils.gparDBID,        p_dbid1);
    coremod_report_utils.set_report_param(l_report_id,coremod_report_utils.gparMIN_SNAP,    p_min_snap1);
    coremod_report_utils.set_report_param(l_report_id,coremod_report_utils.gparMAX_SNAP,    p_max_snap1);
    coremod_report_utils.set_report_param(l_report_id,coremod_report_utils.gparINSTANCE_NUM,p_instance_num1);

    coremod_report_utils.set_report_param(l_report_id,coremod_report_utils.gparDBID,        p_dbid2);
    coremod_report_utils.set_report_param(l_report_id,coremod_report_utils.gparMIN_SNAP,    p_min_snap2);
    coremod_report_utils.set_report_param(l_report_id,coremod_report_utils.gparMAX_SNAP,    p_max_snap2);
    coremod_report_utils.set_report_param(l_report_id,coremod_report_utils.gparINSTANCE_NUM,p_instance_num2);

    coremod_report_utils.set_report_param(l_report_id,coremod_report_utils.gparDBLINK,      p_dblink);
    coremod_report_utils.queue_report(l_report_id);
    return l_report_id;
  end;

  function getreport_diffrpt(p_dbid1 number, p_min_snap1 number, p_max_snap1 number, p_instance_num1 number,
                             p_dbid2 number, p_min_snap2 number, p_max_snap2 number, p_instance_num2 number) return coremod_report_utils.t_output_lines
  is
    l_report coremod_report_utils.t_output_lines;
    l_inst_lst1    AWRRPT_INSTANCE_LIST_TYPE;
    l_inst_lst2    AWRRPT_INSTANCE_LIST_TYPE;
    l_mis1         number;
    l_mas1         number;
    l_mis2         number;
    l_mas2         number;
  begin
    if p_instance_num1 is null or p_instance_num2 is null then
      select unique INSTANCE_NUMBER bulk collect into l_inst_lst1 from dba_hist_snapshot x where dbid=p_dbid1 and SNAP_ID between p_min_snap1 and p_max_snap1;
      select unique INSTANCE_NUMBER bulk collect into l_inst_lst2 from dba_hist_snapshot x where dbid=p_dbid2 and SNAP_ID between p_min_snap2 and p_max_snap2;
      select min(snap_id) mis, max(snap_id) mas into l_mis1, l_mas1 from dba_hist_snapshot x where dbid=p_dbid1 and SNAP_ID between p_min_snap1 and p_max_snap1;
      select min(snap_id) mis, max(snap_id) mas into l_mis2, l_mas2 from dba_hist_snapshot x where dbid=p_dbid2 and SNAP_ID between p_min_snap2 and p_max_snap2;
      begin
        for j in (select rownum rn, output from table(dbms_workload_repository.awr_global_diff_report_text(p_dbid1,l_inst_lst1,l_mis1,l_mas1,p_dbid2,l_inst_lst2,l_mis2,l_mas2)))
        loop
          l_report(j.rn):=j.output;
        end loop;
      exception
        when others then l_report(1):=sqlerrm;
      end;
    else
      select min(snap_id) mis, max(snap_id) mas into l_mis1, l_mas1 from dba_hist_snapshot x where dbid=p_dbid1 and SNAP_ID between p_min_snap1 and p_max_snap1 and INSTANCE_NUMBER = p_instance_num1;
      select min(snap_id) mis, max(snap_id) mas into l_mis2, l_mas2 from dba_hist_snapshot x where dbid=p_dbid2 and SNAP_ID between p_min_snap2 and p_max_snap2 and INSTANCE_NUMBER = p_instance_num2;
      begin
        for j in (select rownum rn, output from table(dbms_workload_repository.awr_diff_report_html(p_dbid1,p_instance_num1,l_mis1,l_mas1,p_dbid2,p_instance_num2,l_mis2,l_mas2)))
        loop
          l_report(j.rn):=j.output;
        end loop;
      exception
        when others then l_report(1):=sqlerrm;
      end;
    end if;
    return l_report;
  end;

  function getreport_diffrpt(p_dbid1 number, p_min_snap1 number, p_max_snap1 number, p_instance_num1 number,
                             p_dbid2 number, p_min_snap2 number, p_max_snap2 number, p_instance_num2 number, p_dblink varchar2) return clob
  is
    l_out clob;
    l_sql varchar2(4000) := q'[
declare
l_mis1 number; l_mas1 number; l_inst_lst1 AWRRPT_INSTANCE_LIST_TYPE;
l_mis2 number; l_mas2 number; l_inst_lst2 AWRRPT_INSTANCE_LIST_TYPE;
begin
  select unique INSTANCE_NUMBER bulk collect into l_inst_lst1 from dba_hist_snapshot x where dbid=<DBID1> and SNAP_ID between <MIS1> and <MAS1>;
  select unique INSTANCE_NUMBER bulk collect into l_inst_lst2 from dba_hist_snapshot x where dbid=<DBID2> and SNAP_ID between <MIS2> and <MAS2>;
  select min(snap_id), max(snap_id) into l_mis1, l_mas1 from dba_hist_snapshot x where dbid=<DBID1> and SNAP_ID between <MIS1> and <MAS1> <INST1>;
  select min(snap_id), max(snap_id) into l_mis2, l_mas2 from dba_hist_snapshot x where dbid=<DBID2> and SNAP_ID between <MIS2> and <MAS2> <INST2>;
  begin
    for j in (select output from table(dbms_workload_repository.<FNC>(<DBID1>,<INSTLST1>,l_mis1,l_mas1,<DBID2>,<INSTLST2>,l_mis2,l_mas2)))
    loop
      l_out:=l_out||j.output||chr(10);
    end loop;
  exception
    when others then l_out:=sqlerrm;
  end;
end;]';
  begin
    l_sql := replace(replace(replace(l_sql,'<DBID1>',p_dbid1),'<MIS1>',p_min_snap1),'<MAS1>',p_max_snap1);
    l_sql := replace(replace(replace(l_sql,'<DBID2>',p_dbid2),'<MIS2>',p_min_snap2),'<MAS2>',p_max_snap2);
    if p_instance_num1 is null or p_instance_num2 is null then
      l_sql := replace(replace(replace(l_sql,'<FNC>','awr_global_diff_report_text'),'<INSTLST1>','l_inst_lst1'),'<INST1>',null);
      l_sql := replace(replace(l_sql,'<INSTLST2>','l_inst_lst2'),'<INST2>',null);
    else
      l_sql := replace(replace(replace(l_sql,'<FNC>','awr_diff_report_html'),'<INSTLST1>',p_instance_num1),'<INST1>','and INSTANCE_NUMBER='||p_instance_num1);
      l_sql := replace(replace(l_sql,'<INSTLST2>',p_instance_num2),'<INST2>','and INSTANCE_NUMBER='||p_instance_num2);
    end if;
    coremod_log.log('Remote AWR Diff Report: '||l_sql,'DEBUG');
    coremod_log.log('Remote AWR Diff Report DB Link: '||p_dblink,'DEBUG');
    coremod_tasks.log('Remote AWR Diff Report: '||l_sql,coremod_tasks.get_curr_tq_id);
    coremod_tasks.log('Remote AWR Diff Report DB Link: '||p_dblink,coremod_tasks.get_curr_tq_id);
    COREMOD_REPORT_UTILS.get_clob_remotelly(l_sql,p_dblink,l_out);
    return l_out;
  end;
--  =============================================================================================================================================
--  =============================================================================================================================================
--  =============================================================================================================================================

  function queue_report_ashrpt(p_modname varchar2, p_owner varchar2, p_dbid number, p_btime date, p_etime date, p_instance_num number, p_dblink varchar2) return opas_reports.report_id%type
  is
    l_report_id opas_reports.report_id%type;
  begin
    coremod_report_utils.init_report(p_modname,l_report_id, null);
    coremod_report_utils.set_report_type (l_report_id, coremod_report_utils.qASHRPT);
    coremod_report_utils.set_report_param(l_report_id,coremod_report_utils.gparOWNER,       p_owner);
    coremod_report_utils.set_report_param(l_report_id,coremod_report_utils.gparDBID,        p_dbid);
    coremod_report_utils.set_report_param(l_report_id,coremod_report_utils.gparBTIME,       p_btime);
    coremod_report_utils.set_report_param(l_report_id,coremod_report_utils.gparETIME,       p_etime);
    coremod_report_utils.set_report_param(l_report_id,coremod_report_utils.gparINSTANCE_NUM,p_instance_num);
    coremod_report_utils.set_report_param(l_report_id,coremod_report_utils.gparDBLINK,      p_dblink);
    coremod_report_utils.queue_report(l_report_id);
    return l_report_id;
  end;

  function getreport_ashrpt(p_dbid number, p_btime date, p_etime date, p_instance_num number) return coremod_report_utils.t_output_lines
  is
    l_report coremod_report_utils.t_output_lines;
    l_inst_lst    varchar2(256);
  begin
    if p_instance_num is null then
      for i in (select unique INSTANCE_NUMBER from dba_hist_snapshot x where dbid=p_dbid and end_interval_time between p_btime - 1.5/24 and p_etime + 1.5/24)
      loop
        l_inst_lst:=l_inst_lst||i.INSTANCE_NUMBER||',';
      end loop;
      l_inst_lst:=rtrim(l_inst_lst,',');

      begin
        for j in (select rownum rn, output from table(dbms_workload_repository.ash_global_report_html(p_dbid,l_inst_lst,p_btime,p_etime)))
        loop
          l_report(j.rn):=j.output;
        end loop;
      exception
        when others then l_report(1):=sqlerrm;
      end;
    else
      begin
        for j in (select rownum rn, output from table(dbms_workload_repository.ash_report_html(p_dbid,p_instance_num,p_btime,p_etime)))
        loop
          l_report(j.rn):=j.output;
        end loop;
      exception
        when others then l_report(1):=sqlerrm;
      end;
    end if;
    return l_report;
  end;

  function getreport_ashrpt(p_dbid number, p_btime date, p_etime date, p_instance_num number, p_dblink varchar2) return clob
  is
    l_out clob;
    l_sql varchar2(4000) := q'[
declare
l_inst_lst    varchar2(256);
begin
  for i in (select unique INSTANCE_NUMBER from dba_hist_snapshot x where dbid=<DBID> and end_interval_time between to_date('<btime>','<dtfmt>') - 1.5/24 and to_date('<etime>','<dtfmt>') + 1.5/24)
    loop
      l_inst_lst:=l_inst_lst||i.INSTANCE_NUMBER||',';
    end loop;
    l_inst_lst:=rtrim(l_inst_lst,',');
  begin
    for j in (select output from table(dbms_workload_repository.<FNC>(<DBID>,<INSTLST>,to_date('<btime>','<dtfmt>'),to_date('<etime>','<dtfmt>'))))
    loop
      l_out:=l_out||j.output||chr(10);
    end loop;
  exception
    when others then l_out:=sqlerrm;
  end;
end;]';
  begin
    l_sql := replace(replace(replace(replace(l_sql,'<DBID>',p_dbid),'<btime>',to_char(p_btime,COREMOD_REPORT_UTILS.gDTFMT)),'<etime>',to_char(p_etime,COREMOD_REPORT_UTILS.gDTFMT)),'<dtfmt>',COREMOD_REPORT_UTILS.gDTFMT);
    if p_instance_num is null then
      l_sql := replace(replace(l_sql,'<FNC>','ash_global_report_html'),'<INSTLST>','l_inst_lst');
    else
      l_sql := replace(replace(l_sql,'<FNC>','ash_report_html'),'<INSTLST>',p_instance_num);
    end if;
    coremod_log.log('Remote ASH Report: '||l_sql,'DEBUG');
    coremod_log.log('Remote ASH Report DB Link: '||p_dblink,'DEBUG');
    coremod_tasks.log('Remote ASH Report: '||l_sql,coremod_tasks.get_curr_tq_id);
    coremod_tasks.log('Remote ASH Report DB Link: '||p_dblink,coremod_tasks.get_curr_tq_id);
    COREMOD_REPORT_UTILS.get_clob_remotelly(l_sql,p_dblink,l_out);
    return l_out;
  end;

--  =============================================================================================================================================
--  =============================================================================================================================================
--  =============================================================================================================================================

  function queue_report_sql_memory_stats_i(p_modname varchar2, p_owner varchar2, p_sql_id varchar2, p_dblink varchar2, p_parent number) return opas_reports.report_id%type
  is
    l_report_id opas_reports.report_id%type;
  begin
    coremod_report_utils.init_report(p_modname,l_report_id, p_parent);
    coremod_report_utils.set_report_type(l_report_id, coremod_report_utils.gSQL_MEMORY_REPORT);
    coremod_report_utils.set_report_param(l_report_id,coremod_report_utils.gparOWNER,p_owner);
    coremod_report_utils.set_report_param(l_report_id,coremod_report_utils.gparSQLID,p_sql_id);
    coremod_report_utils.set_report_param(l_report_id,coremod_report_utils.gparDBLINK,p_dblink);
    coremod_report_utils.queue_report(l_report_id);
    return l_report_id;
  end;

  function queue_report_sql_memory_stats(p_modname varchar2, p_owner varchar2, p_sql_id varchar2, p_dblink varchar2) return opas_reports.report_id%type
  is
    l_report_id opas_reports.report_id%type;
    l_sql varchar2(32765) := replace(replace(
           q'[select sql_id from (
              select sql_id, count(1) cnt
                from gv$active_session_history<dblink>
               where top_level_sql_id = '<sql_id>'
                 and sql_id<>top_level_sql_id
               group by sql_id
              having count(1) > 60
               order by cnt desc)]','<dblink>',case when p_dblink is null then null else '@'||p_dblink end),'<sql_id>',p_sql_id);
    l_crsr sys_refcursor;
    l_sql_id varchar2(100);
    l_main_report opas_reports.report_id%type;
    l_rec_report  opas_reports.report_id%type;
  begin
    --main query report
    l_main_report := queue_report_sql_memory_stats_i(p_modname, p_owner, p_sql_id, p_dblink, null);
    commit;

    --recursive queries
    open l_crsr for l_sql;
    loop
      fetch l_crsr into l_sql_id;
      exit when l_crsr%notfound;
      l_rec_report := queue_report_sql_memory_stats_i(p_modname, p_owner, l_sql_id, p_dblink, l_main_report);
    end loop;
    close l_crsr;
    commit;
    return l_main_report;
  end;

  function getreport_sql_memory_stats(p_sql_id varchar2, p_dblink varchar2) return coremod_report_utils.t_output_lines
  is
    l_timing boolean := true;
    l_time number; l_tot_tim number:=0;
    l_cpu_tim number; l_tot_cpu_tim number:=0;
    l_script varchar2(32767);
    l_report coremod_report_utils.t_output_lines;

    l_output coremod_report_utils.t_output_lines;
    l_plsql_output clob;
    l_indx   number := 1;

    procedure p(p_line varchar2) is
    begin
      l_report(l_indx):=p_line;
      l_indx := l_indx + 1;
    end;
    procedure p1(p_output coremod_report_utils.t_output_lines) is
    begin
      for i in 1..p_output.count loop
        p(p_output(i));
      end loop;
    end;
  begin
    COREMOD_REPORT_UTILS.init_lo_report(p_op_name => 'SQL V$ report: '||p_sql_id,
                                        p_target_desc => 'section',
                                        p_units => 'sections',
                                        p_totalwork => 14);
    COREMOD_REPORT_UTILS.start_lo_section(p_module_name => 'SQL V$ report: '||p_sql_id, p_action_name => 'Preparation');

    p(HTF.header (1,'SQL Report for SQL_ID='||p_sql_id,cattributes=>'class="awr"'));
    p(HTF.BR);
    p(HTF.BR);
    p(HTF.header (2,cheader=>HTF.ANCHOR (curl=>'',ctext=>'Table of contents',cname=>'tblofcont',cattributes=>'class="awr"'),cattributes=>'class="awr"'));
    p(HTF.BR);
    p(HTF.LISTITEM(cattributes=>'class="awr"',ctext=>HTF.ANCHOR (curl=>'#sql_text',ctext=>'SQL text',cattributes=>'class="awr"')));
    p(HTF.LISTITEM(cattributes=>'class="awr"',ctext=>HTF.ANCHOR (curl=>'#non_shared',ctext=>'Non shared reason',cattributes=>'class="awr"')));
    p(HTF.LISTITEM(cattributes=>'class="awr"',ctext=>HTF.ANCHOR (curl=>'#v_sql_stat',ctext=>'V$SQL statistics',cattributes=>'class="awr"')));
    p(HTF.LISTITEM(cattributes=>'class="awr"',ctext=>HTF.ANCHOR (curl=>'#exadata',ctext=>'Exadata statistics',cattributes=>'class="awr"')));
    p(HTF.LISTITEM(cattributes=>'class="awr"',ctext=>HTF.ANCHOR (curl=>'#sql_mon',ctext=>'SQL Monitor report',cattributes=>'class="awr"')));
    p(HTF.LISTITEM(cattributes=>'class="awr"',ctext=>HTF.ANCHOR (curl=>'#sql_workarea',ctext=>'SQL Workarea',cattributes=>'class="awr"')));
    p(HTF.LISTITEM(cattributes=>'class="awr"',ctext=>HTF.ANCHOR (curl=>'#cbo_env',ctext=>'CBO environment',cattributes=>'class="awr"')));
    p(HTF.LISTITEM(cattributes=>'class="awr"',ctext=>HTF.ANCHOR (curl=>'#dp_last',ctext=>'Display cursor (last)',cattributes=>'class="awr"')));
    p(HTF.LISTITEM(cattributes=>'class="awr"',ctext=>HTF.ANCHOR (curl=>'#dp_rac',ctext=>'Display cursor (RAC)',cattributes=>'class="awr"')));
    p(HTF.LISTITEM(cattributes=>'class="awr"',ctext=>HTF.ANCHOR (curl=>'#dp_last_adv',ctext=>'Display cursor (LAST ADVANCED)',cattributes=>'class="awr"')));
    p(HTF.LISTITEM(cattributes=>'class="awr"',ctext=>HTF.ANCHOR (curl=>'#dp_all',ctext=>'Display cursor (ALL)',cattributes=>'class="awr"')));
    p(HTF.LISTITEM(cattributes=>'class="awr"',ctext=>HTF.ANCHOR (curl=>'#dp_adaptive',ctext=>'Display cursor (ADAPTIVE)',cattributes=>'class="awr"')));
    p(HTF.LISTITEM(cattributes=>'class="awr"',ctext=>HTF.ANCHOR (curl=>'#sql_mon_hist',ctext=>'SQL Monitor report history',cattributes=>'class="awr"')));
    p(HTF.LISTITEM(cattributes=>'class="awr"',ctext=>HTF.ANCHOR (curl=>'#ash_p3',ctext=>'ASH Summary',cattributes=>'class="awr"')));
    p(HTF.BR);
    p(HTF.BR);

--  =============================================================================================================================================
    --SQL TEXT
    COREMOD_REPORT_UTILS.start_lo_section(p_module_name => 'SQL V$ report: '||p_sql_id, p_action_name => 'SQL TEXT');

    l_script:=coremod_api.getscript('PROC_GETGTXT');
    p(HTF.header (3,cheader=>HTF.ANCHOR (curl=>'',ctext=>'SQL text',cname=>'sql_text',cattributes=>'class="awr"'),cattributes=>'class="awr"'));
    p(HTF.BR);
    COREMOD_REPORT_UTILS.prepare_script(l_script,p_sql_id);
    l_output.delete;
    coremod_report_utils.print_table_html_remotelly(p_query=>l_script,p_width=>500,p_summary=>'SQL text', p_dblink => p_dblink, p_output=> l_output);
    p1(l_output);
    p(HTF.BR);
    p(HTF.LISTITEM(cattributes=>'class="awr"',ctext=>HTF.ANCHOR (curl=>'#tblofcont',ctext=>'Back to top',cattributes=>'class="awr"')));
    p(HTF.BR);
    p(COREMOD_REPORT_UTILS.end_lo_section);
    p(HTF.BR);

--  =============================================================================================================================================
    --Non shared
    COREMOD_REPORT_UTILS.start_lo_section(p_module_name => 'SQL V$ report: '||p_sql_id, p_action_name => 'Non shared');

    l_script:=coremod_api.getscript('PROC_NON_SHARED');
    p(HTF.header (3,cheader=>HTF.ANCHOR (curl=>'',ctext=>'Non shared reason',cname=>'non_shared',cattributes=>'class="awr"'),cattributes=>'class="awr"'));
    p(HTF.BR);
    COREMOD_REPORT_UTILS.prepare_script(l_script,p_sql_id);
    l_output.delete;
    coremod_report_utils.print_table_html_remotelly(p_query=>l_script,p_width=>1000,p_summary=>'Non shared reason', p_dblink => p_dblink, p_output=> l_output);
    p1(l_output);
    p(HTF.BR);
    p(HTF.LISTITEM(cattributes=>'class="awr"',ctext=>HTF.ANCHOR (curl=>'#tblofcont',ctext=>'Back to top',cattributes=>'class="awr"')));
    p(HTF.BR);
    p(COREMOD_REPORT_UTILS.end_lo_section);
    p(HTF.BR);

--  =============================================================================================================================================
    --V$SQL statistics
    COREMOD_REPORT_UTILS.start_lo_section(p_module_name => 'SQL V$ report: '||p_sql_id, p_action_name => 'V$SQL statistics');

    l_script:=coremod_api.getscript('PROC_VSQL_STAT');
    p(HTF.header (3,cheader=>HTF.ANCHOR (curl=>'',ctext=>'V$SQL statistics',cname=>'v_sql_stat',cattributes=>'class="awr"'),cattributes=>'class="awr"'));
    p(HTF.BR);

    COREMOD_REPORT_UTILS.prepare_script(l_script,p_sql_id);

    l_plsql_output:=null;
    coremod_report_utils.execute_plsql_remotelly(p_sql => l_script, p_dblink => p_dblink, p_output => l_plsql_output);

    declare
      l_user varchar2(512); l_host varchar2(512);
    begin
      select username, host into l_user, l_host from user_db_links where db_link=upper(p_dblink);
      l_plsql_output:=replace(replace(l_plsql_output,'&_USER.',l_user),'&_CONNECT_IDENTIFIER.',l_host);
    exception
      when no_data_found then
        l_user:='<UNKNOWN>'; l_host:='<UNKNOWN>';
        l_plsql_output:=replace(replace(l_plsql_output,'&_USER.',l_user),'&_CONNECT_IDENTIFIER.',l_host);
    end;

    coremod_report_utils.print_text_as_table(p_text=>l_plsql_output,p_t_header=>'V$SQL',p_width=>600, p_search=>'CHILD_NUMBER=([[:digit:]]*)',p_replacement=>HTF.ANCHOR (curl=>'#child_last_\1',ctext=>'CHILD_NUMBER=\1',cattributes=>'class="awr"'), p_output=> l_output);
    p1(l_output);

    p(HTF.BR);
    p(HTF.LISTITEM(cattributes=>'class="awr"',ctext=>HTF.ANCHOR (curl=>'#tblofcont',ctext=>'Back to top',cattributes=>'class="awr"')));
    p(HTF.BR);
    p(COREMOD_REPORT_UTILS.end_lo_section);
    p(HTF.BR);

--  =============================================================================================================================================
    --Exadata statistics
    COREMOD_REPORT_UTILS.start_lo_section(p_module_name => 'SQL V$ report: '||p_sql_id, p_action_name => 'Exadata statistics');

    p(HTF.header (3,cheader=>HTF.ANCHOR (curl=>'',ctext=>'Exadata statistics',cname=>'exadata',cattributes=>'class="awr"'),cattributes=>'class="awr"'));
    p(HTF.BR);

    l_script:=coremod_api.getscript('PROC_OFFLOAD_PCT1');
    COREMOD_REPORT_UTILS.prepare_script(l_script,p_sql_id);
    l_output.delete;
    coremod_report_utils.print_table_html_remotelly(p_query=>l_script,p_width=>1000,p_summary=>'Exadata statistics #1', p_dblink => p_dblink, p_output=> l_output);
    p1(l_output);

    p(HTF.BR);

    l_script:=coremod_api.getscript('PROC_OFFLOAD_PCT2');
    COREMOD_REPORT_UTILS.prepare_script(l_script,p_sql_id);
    l_output.delete;
    coremod_report_utils.print_table_html_remotelly(p_query=>l_script,p_width=>1000,p_summary=>'Exadata statistics #2', p_dblink => p_dblink, p_output=> l_output);
    p1(l_output);

    p(HTF.BR);
    p(HTF.LISTITEM(cattributes=>'class="awr"',ctext=>HTF.ANCHOR (curl=>'#tblofcont',ctext=>'Back to top',cattributes=>'class="awr"')));
    p(HTF.BR);
    p(COREMOD_REPORT_UTILS.end_lo_section);
    p(HTF.BR);

--  =============================================================================================================================================
    --SQL Monitor report
    COREMOD_REPORT_UTILS.start_lo_section(p_module_name => 'SQL V$ report: '||p_sql_id, p_action_name => 'SQL Monitor report');

    l_script:=coremod_api.getscript('PROC_SQLMON');
    p(HTF.header (3,cheader=>HTF.ANCHOR (curl=>'',ctext=>'SQL Monitor report (11g+)',cname=>'sql_mon',cattributes=>'class="awr"'),cattributes=>'class="awr"'));
    p(HTF.BR);
    COREMOD_REPORT_UTILS.prepare_script(l_script,p_sql_id);

    l_plsql_output:=null;
    coremod_report_utils.execute_plsql_remotelly(p_sql => l_script, p_dblink => p_dblink, p_output => l_plsql_output);
    coremod_report_utils.print_text_as_table(p_text=>l_plsql_output||chr(10),p_t_header=>'SQL Monitor report',p_width=>600, p_output=> l_output);
    p1(l_output);

    p(HTF.BR);
    p(HTF.LISTITEM(cattributes=>'class="awr"',ctext=>HTF.ANCHOR (curl=>'#tblofcont',ctext=>'Back to top',cattributes=>'class="awr"')));
    p(HTF.BR);
    p(COREMOD_REPORT_UTILS.end_lo_section);
    p(HTF.BR);

--  =============================================================================================================================================
    --SQL Workarea
    COREMOD_REPORT_UTILS.start_lo_section(p_module_name => 'SQL V$ report: '||p_sql_id, p_action_name => 'SQL Workarea');

    l_script:=coremod_api.getscript('PROC_SQLWORKAREA');
    p(HTF.header (3,cheader=>HTF.ANCHOR (curl=>'',ctext=>'SQL Workarea',cname=>'sql_workarea',cattributes=>'class="awr"'),cattributes=>'class="awr"'));
    p(HTF.BR);
    COREMOD_REPORT_UTILS.prepare_script(l_script,p_sql_id);
    l_output.delete;
    coremod_report_utils.print_table_html_remotelly(p_query=>l_script,p_width=>1000,p_summary=>'SQL Workarea', p_dblink => p_dblink, p_output=> l_output);
    p1(l_output);

    p(HTF.BR);
    p(HTF.LISTITEM(cattributes=>'class="awr"',ctext=>HTF.ANCHOR (curl=>'#tblofcont',ctext=>'Back to top',cattributes=>'class="awr"')));
    p(HTF.BR);
    p(COREMOD_REPORT_UTILS.end_lo_section);
    p(HTF.BR);

--  =============================================================================================================================================
    --CBO environment
    COREMOD_REPORT_UTILS.start_lo_section(p_module_name => 'SQL V$ report: '||p_sql_id, p_action_name => 'CBO environment');

    l_script:=coremod_api.getscript('PROC_OPTENV');
    p(HTF.header (3,cheader=>HTF.ANCHOR (curl=>'',ctext=>'CBO environment',cname=>'cbo_env',cattributes=>'class="awr"'),cattributes=>'class="awr"'));
    p(HTF.BR);
    COREMOD_REPORT_UTILS.prepare_script(l_script,p_sql_id);
    l_output.delete;
    coremod_report_utils.print_table_html_remotelly(p_query=>l_script,p_width=>1000,p_summary=>'CBO environment', p_dblink => p_dblink, p_output=> l_output);
    p1(l_output);
    p(HTF.BR);
    p(HTF.LISTITEM(cattributes=>'class="awr"',ctext=>HTF.ANCHOR (curl=>'#tblofcont',ctext=>'Back to top',cattributes=>'class="awr"')));
    p(HTF.BR);
    p(COREMOD_REPORT_UTILS.end_lo_section);
    p(HTF.BR);

--  =============================================================================================================================================
    --Execution plans
    p(HTF.header (3,cheader=>HTF.ANCHOR (curl=>'',ctext=>'Execution plans',cname=>'tblofcont_plans',cattributes=>'class="awr"'),cattributes=>'class="awr"'));
    p(HTF.BR);
    p(HTF.LISTITEM(cattributes=>'class="awr"',ctext=>HTF.ANCHOR (curl=>'#dp_last',ctext=>'Display cursor (last)',cattributes=>'class="awr"')));
    p(HTF.LISTITEM(cattributes=>'class="awr"',ctext=>HTF.ANCHOR (curl=>'#dp_rac',ctext=>'Display cursor (RAC)',cattributes=>'class="awr"')));
    p(HTF.LISTITEM(cattributes=>'class="awr"',ctext=>HTF.ANCHOR (curl=>'#dp_last_adv',ctext=>'Display cursor (LAST ADVANCED)',cattributes=>'class="awr"')));
    p(HTF.LISTITEM(cattributes=>'class="awr"',ctext=>HTF.ANCHOR (curl=>'#dp_all',ctext=>'Display cursor (ALL)',cattributes=>'class="awr"')));
    p(HTF.LISTITEM(cattributes=>'class="awr"',ctext=>HTF.ANCHOR (curl=>'#dp_adaptive',ctext=>'Display cursor (ADAPTIVE)',cattributes=>'class="awr"')));
    p(HTF.LISTITEM(cattributes=>'class="awr"',ctext=>HTF.ANCHOR (curl=>'#tblofcont',ctext=>'Back to top',cattributes=>'class="awr"')));
    p(HTF.BR);
    p(HTF.BR);
--  =============================================================================================================================================
    --Display cursor (last)
    COREMOD_REPORT_UTILS.start_lo_section(p_module_name => 'SQL V$ report: '||p_sql_id, p_action_name => 'Display cursor (last)');

    p(HTF.header (3,cheader=>HTF.ANCHOR (curl=>'',ctext=>'Display cursor (last)',cname=>'dp_last',cattributes=>'class="awr"'),cattributes=>'class="awr"'));
    p(HTF.BR);
    l_script:=q'[select * from table(dbms_xplan.display_cursor('&SQLID', null, 'LAST ALLSTATS +peeked_binds'))]'||chr(10);
    COREMOD_REPORT_UTILS.prepare_script(l_script,p_sql_id);
    l_output.delete;
    coremod_report_utils.print_table_html_remotelly(p_query=>l_script,
                               p_width=>1500,
                               p_summary=>'Display cursor (last)',
                               p_search => 'child number ([[:digit:]]*)',
                               p_replacement => HTF.ANCHOR(curl=>'#child_all_\1',ctext=>'child number \1',cname=>'child_last_\1',cattributes=>'class="awr"'),
                               p_dblink => p_dblink, p_output=> l_output);
    p1(l_output);
    p(HTF.BR);
    p(HTF.LISTITEM(cattributes=>'class="awr"',ctext=>HTF.ANCHOR (curl=>'#tblofcont_plans',ctext=>'Back to Execution plans',cattributes=>'class="awr"')));
    p(HTF.LISTITEM(cattributes=>'class="awr"',ctext=>HTF.ANCHOR (curl=>'#tblofcont',ctext=>'Back to top',cattributes=>'class="awr"')));
    p(HTF.BR);
    p(COREMOD_REPORT_UTILS.end_lo_section);
    p(HTF.BR);

--  =============================================================================================================================================
    --Display cursor (RAC)
    COREMOD_REPORT_UTILS.start_lo_section(p_module_name => 'SQL V$ report: '||p_sql_id, p_action_name => 'Display cursor (RAC)');

    l_script:=coremod_api.getscript('PROC_RACPLAN');
    p(HTF.header (3,cheader=>HTF.ANCHOR (curl=>'',ctext=>'Display cursor (RAC)',cname=>'dp_rac',cattributes=>'class="awr"'),cattributes=>'class="awr"'));
    p(HTF.BR);
    COREMOD_REPORT_UTILS.prepare_script(l_script,p_sql_id);
    l_output.delete;
    coremod_report_utils.print_table_html_remotelly(p_query=>l_script,p_width=>1500,p_summary=>'Display cursor (RAC)', p_dblink => p_dblink, p_output=> l_output);
    p1(l_output);
    p(HTF.BR);
    p(HTF.LISTITEM(cattributes=>'class="awr"',ctext=>HTF.ANCHOR (curl=>'#tblofcont_plans',ctext=>'Back to Execution plans',cattributes=>'class="awr"')));
    p(HTF.LISTITEM(cattributes=>'class="awr"',ctext=>HTF.ANCHOR (curl=>'#tblofcont',ctext=>'Back to top',cattributes=>'class="awr"')));
    p(HTF.BR);
    p(COREMOD_REPORT_UTILS.end_lo_section);
    p(HTF.BR);

--  =============================================================================================================================================
    --Display cursor (LAST ADVANCED)
    COREMOD_REPORT_UTILS.start_lo_section(p_module_name => 'SQL V$ report: '||p_sql_id, p_action_name => 'Display cursor (LAST ADVANCED)');

    p(HTF.header (3,cheader=>HTF.ANCHOR (curl=>'Display cursor (RAC)',ctext=>'Display cursor (LAST ADVANCED)',cname=>'dp_last_adv',cattributes=>'class="awr"'),cattributes=>'class="awr"'));
    p(HTF.BR);
    l_script:=q'[select * from table(dbms_xplan.display_cursor('&SQLID', null, 'LAST ADVANCED'))]'||chr(10);
    COREMOD_REPORT_UTILS.prepare_script(l_script,p_sql_id);
    l_output.delete;
    coremod_report_utils.print_table_html_remotelly(p_query=>l_script,
                               p_width=>1500,
                               p_summary=>'Display cursor (LAST ADVANCED)',
                               p_dblink => p_dblink, p_output=> l_output);
    p1(l_output);
    p(HTF.BR);
    p(HTF.LISTITEM(cattributes=>'class="awr"',ctext=>HTF.ANCHOR (curl=>'#tblofcont_plans',ctext=>'Back to Execution plans',cattributes=>'class="awr"')));
    p(HTF.LISTITEM(cattributes=>'class="awr"',ctext=>HTF.ANCHOR (curl=>'#tblofcont',ctext=>'Back to top',cattributes=>'class="awr"')));
    p(HTF.BR);
    p(COREMOD_REPORT_UTILS.end_lo_section);
    p(HTF.BR);

--  =============================================================================================================================================
    --Display cursor (ALL)
    COREMOD_REPORT_UTILS.start_lo_section(p_module_name => 'SQL V$ report: '||p_sql_id, p_action_name => 'Display cursor (ALL)');

    p(HTF.header (3,cheader=>HTF.ANCHOR (curl=>'',ctext=>'Display cursor (ALL)',cname=>'dp_all',cattributes=>'class="awr"'),cattributes=>'class="awr"'));
    p(HTF.BR);
    l_script:=q'[select * from table(dbms_xplan.display_cursor('&SQLID', null, 'ALL ALLSTATS +peeked_binds'))]'||chr(10);
    COREMOD_REPORT_UTILS.prepare_script(l_script,p_sql_id);
    l_output.delete;
    coremod_report_utils.print_table_html_remotelly(p_query=>l_script,
                               p_width=>2000,
                               p_summary=>'Display cursor (ALL)',
                               p_search => 'child number ([[:digit:]]*)',
                               p_replacement => HTF.ANCHOR(curl=>'',ctext=>'child number \1',cname=>'child_all_\1',cattributes=>'class="awr"'),
                               p_dblink => p_dblink, p_output=> l_output);
    p1(l_output);
    p(HTF.BR);
    p(HTF.LISTITEM(cattributes=>'class="awr"',ctext=>HTF.ANCHOR (curl=>'#tblofcont_plans',ctext=>'Back to Execution plans',cattributes=>'class="awr"')));
    p(HTF.LISTITEM(cattributes=>'class="awr"',ctext=>HTF.ANCHOR (curl=>'#tblofcont',ctext=>'Back to top',cattributes=>'class="awr"')));
    p(HTF.BR);
    p(COREMOD_REPORT_UTILS.end_lo_section);
    p(HTF.BR);

--  =============================================================================================================================================
    --Display cursor (ADAPTIVE)
    COREMOD_REPORT_UTILS.start_lo_section(p_module_name => 'SQL V$ report: '||p_sql_id, p_action_name => 'Display cursor (ADAPTIVE)');

    p(HTF.header (3,cheader=>HTF.ANCHOR (curl=>'',ctext=>'Display cursor (ADAPTIVE)',cname=>'dp_adaptive',cattributes=>'class="awr"'),cattributes=>'class="awr"'));
    p(HTF.BR);
    l_script:=q'[SELECT * FROM TABLE(DBMS_XPLAN.display_cursor('&SQLID', null, format => 'adaptive LAST ALLSTATS +peeked_binds'))]'||chr(10);
    COREMOD_REPORT_UTILS.prepare_script(l_script,p_sql_id);
    l_output.delete;
    coremod_report_utils.print_table_html_remotelly(p_query=>l_script,
                               p_width=>1500,
                               p_summary=>'Display cursor (ADAPTIVE)',
                               p_dblink => p_dblink, p_output=> l_output);
    p1(l_output);
    p(HTF.BR);
    p(HTF.LISTITEM(cattributes=>'class="awr"',ctext=>HTF.ANCHOR (curl=>'#tblofcont_plans',ctext=>'Back to Execution plans',cattributes=>'class="awr"')));
    p(HTF.LISTITEM(cattributes=>'class="awr"',ctext=>HTF.ANCHOR (curl=>'#tblofcont',ctext=>'Back to top',cattributes=>'class="awr"')));

    p(HTF.BR);
    p(HTF.BR);

    l_script:=q'[SELECT * FROM TABLE(DBMS_XPLAN.display_cursor('&SQLID', null, format => 'adaptive ALL ALLSTATS +peeked_binds'))]'||chr(10);
    COREMOD_REPORT_UTILS.prepare_script(l_script,p_sql_id);
    l_output.delete;
    coremod_report_utils.print_table_html_remotelly(p_query=>l_script,
                               p_width=>2000,
                               p_summary=>'Display cursor (ADAPTIVE)',
                               p_dblink => p_dblink, p_output=> l_output);
    p1(l_output);
    p(HTF.BR);
    p(HTF.LISTITEM(cattributes=>'class="awr"',ctext=>HTF.ANCHOR (curl=>'#tblofcont_plans',ctext=>'Back to Execution plans',cattributes=>'class="awr"')));
    p(HTF.LISTITEM(cattributes=>'class="awr"',ctext=>HTF.ANCHOR (curl=>'#tblofcont',ctext=>'Back to top',cattributes=>'class="awr"')));
    p(HTF.BR);
    p(COREMOD_REPORT_UTILS.end_lo_section);
    p(HTF.BR);

--  =============================================================================================================================================
    --SQL Monitor report history
    COREMOD_REPORT_UTILS.start_lo_section(p_module_name => 'SQL V$ report: '||p_sql_id, p_action_name => 'SQL Monitor report history');

    l_script:=coremod_api.getscript('PROC_SQLMON_HIST');
    p(HTF.header (3,cheader=>HTF.ANCHOR (curl=>'',ctext=>'SQL Monitor report history (12c+)',cname=>'sql_mon_hist',cattributes=>'class="awr"'),cattributes=>'class="awr"'));
    p(HTF.BR);
    COREMOD_REPORT_UTILS.prepare_script(l_script,p_sql_id);
    l_plsql_output:=null;
    coremod_report_utils.execute_plsql_remotelly(p_sql => l_script, p_dblink => p_dblink, p_output => l_plsql_output);
    coremod_report_utils.print_text_as_table(p_text=>l_plsql_output,p_t_header=>'SQL Monitor report history',p_width=>600, p_output=> l_output);
    p1(l_output);
    p(HTF.BR);
    p(HTF.LISTITEM(cattributes=>'class="awr"',ctext=>HTF.ANCHOR (curl=>'#tblofcont',ctext=>'Back to top',cattributes=>'class="awr"')));
    p(HTF.BR);
    p(COREMOD_REPORT_UTILS.end_lo_section);
    p(HTF.BR);

--  =============================================================================================================================================
    --AWR ASH (SQL Monitor) P3
    COREMOD_REPORT_UTILS.start_lo_section(p_module_name => 'SQL V$ report: '||p_sql_id, p_action_name => 'ASH Summary');

    p(HTF.header (3,cheader=>HTF.ANCHOR (curl=>'',ctext=>'ASH Summary',cname=>'ash_p3',cattributes=>'class="awr"'),cattributes=>'class="awr"'));
    p(HTF.BR);

    l_script:=coremod_api.getscript('PROC_AWRASHP3');
    COREMOD_REPORT_UTILS.prepare_script(l_script,p_sql_id);

    l_output.delete;
    coremod_report_utils.print_table_html_remotelly(p_query=>l_script,
                               p_width=>1000,
                               p_summary=>'ASH summary',
                               p_style1 =>'awrncbbt',
                               p_style2 =>'awrcbbt',
                               --p_search => 'PLAN_HASH',
                               --p_replacement => HTF.ANCHOR (curl=>'#awrplan_\1',ctext=>'\1',cattributes=>'class="awr"'),
                               p_header=>25,
                               p_break_col=>'SQL_EXEC_START',
                               p_dblink => p_dblink, p_output=> l_output);
    p1(l_output);
    p(HTF.BR);
    p(HTF.LISTITEM(cattributes=>'class="awr"',ctext=>HTF.ANCHOR (curl=>'#tblofcont',ctext=>'Back to top',cattributes=>'class="awr"')));
    p(HTF.BR);
    p(HTF.BR);
    p(COREMOD_REPORT_UTILS.end_lo_section(true));
    p(HTF.BR);
    p('End of report.');

--  =============================================================================================================================================

    return l_report;
    --coremod_report_utils.save_report_for_download('sql_'||p_sql_id||'.html', l_report, p_id, p_parent_id);
--  exception
--    when others then
--      coremod_log.log(sqlerrm);
--      coremod_log.log(DBMS_UTILITY.FORMAT_ERROR_STACK);
--      coremod_log.log(DBMS_UTILITY.FORMAT_ERROR_BACKTRACE);
--      raise_application_error(-20000, sqlerrm);
  end;

--==============================================================================================================================
--==============================================================================================================================
--==============================================================================================================================
--==============================================================================================================================
--==============================================================================================================================


  function queue_report_sql_awr_stats_i(p_modname varchar2, p_owner varchar2, p_sql_id varchar2, p_dblink varchar2, p_report_limit number, p_parent number) return opas_reports.report_id%type
  is
    l_report_id opas_reports.report_id%type;
  begin
    coremod_report_utils.init_report(p_modname,l_report_id, p_parent);
    coremod_report_utils.set_report_type(l_report_id, coremod_report_utils.gSQL_AWR_REPORT);
    coremod_report_utils.set_report_param(l_report_id,coremod_report_utils.gparOWNER,p_owner);
    coremod_report_utils.set_report_param(l_report_id,coremod_report_utils.gparSQLID,p_sql_id);
    coremod_report_utils.set_report_param(l_report_id,coremod_report_utils.gparDBLINK,p_dblink);
    coremod_report_utils.set_report_param(l_report_id,coremod_report_utils.gparREP_LIMIT,to_number(p_report_limit));
    coremod_report_utils.queue_report(l_report_id);
    return l_report_id;
  end;

  function queue_report_sql_awr_stats(p_modname varchar2, p_owner varchar2, p_sql_id varchar2, p_dblink varchar2, p_report_limit number) return opas_reports.report_id%type
  is
    l_report_id opas_reports.report_id%type;
    l_sql varchar2(32765) := replace(replace(
           q'[select sql_id from (
              select sql_id, count(1) cnt
                from dba_hist_active_sess_history<dblink>
               where top_level_sql_id = '<sql_id>'
                 and sql_id<>top_level_sql_id
               group by sql_id
              having count(1) > 6
               order by cnt desc)]','<dblink>',case when p_dblink is null then null else '@'||p_dblink end),'<sql_id>',p_sql_id);
    l_crsr sys_refcursor;
    l_sql_id varchar2(100);
    l_main_report opas_reports.report_id%type;
    l_rec_report  opas_reports.report_id%type;
  begin
    --main query report
    l_main_report := queue_report_sql_awr_stats_i(p_modname, p_owner, p_sql_id, p_dblink, p_report_limit, null);
    commit;

    --recursive queries
    open l_crsr for l_sql;
    loop
      fetch l_crsr into l_sql_id;
      exit when l_crsr%notfound;
      l_rec_report := queue_report_sql_awr_stats_i(p_modname, p_owner, l_sql_id, p_dblink, p_report_limit, l_main_report);
    end loop;
    close l_crsr;
    commit;
    return l_main_report;
  end;

  function getreport_sql_awr_stats(p_sql_id varchar2, p_dblink varchar2, p_report_limit number) return coremod_report_utils.t_output_lines
  --procedure getplanawrh_i(p_sql_id varchar2, p_dblink varchar2, p_report_limit number)
  is
    l_timing boolean := true;
    l_time number; l_tot_tim number:=0;
    l_cpu_tim number; l_tot_cpu_tim number:=0;
    l_script varchar2(32767);
    l_report coremod_report_utils.t_output_lines;

    l_output coremod_report_utils.t_output_lines;
    l_plsql_output clob;
    l_indx   number := 1;

    l_crsr sys_refcursor;
    l_dbidn number;
    l_inst_id number;

    l_start_snap number;
    l_end_snap number;

    type t_num_array is table of number;
    l_dbid t_num_array;

    procedure p(p_line varchar2) is
    begin
      l_report(l_indx):=p_line;
      l_indx := l_indx + 1;
    end;
    procedure p1(p_output coremod_report_utils.t_output_lines) is
    begin
      for i in 1..p_output.count loop
        p(p_output(i));
      end loop;
    end;

  begin

    COREMOD_REPORT_UTILS.init_lo_report(p_op_name => 'SQL AWR report: '||p_sql_id,
                                        p_target_desc => 'section',
                                        p_units => 'sections',
                                        p_totalwork => 13);
    COREMOD_REPORT_UTILS.start_lo_section(p_module_name => 'SQL AWR report: '||p_sql_id, p_action_name => 'Preparation');

    execute immediate q'[select nvl(min(snap_id),1) , nvl(max(snap_id),1e6) from dba_hist_sqlstat@]'||p_dblink||q'[ where sql_id=']'||p_sql_id||q'[' and dbid in (select dbid from dba_hist_sqltext@]'||p_dblink||q'[ where sql_id=']'||p_sql_id||q'[')]'
        into l_start_snap, l_end_snap;

    if p_report_limit = 0 /*unlimited*/ then
      null;
    elsif p_report_limit>0 then
      execute immediate q'[select nvl(min(snap_id),1) from dba_hist_snapshot@]'||p_dblink||q'[ where end_interval_time>=(select min(end_interval_time)-:p_report_limit from dba_hist_snapshot@]'||p_dblink||q'[ where snap_id = :p_end_snap )]' into l_start_snap using p_report_limit, l_end_snap;
      --awrtools_logging.log('calc2 snaps: '||l_start_snap||','||l_end_snap,'DEBUG');
    else
      raise_application_error(-20000,'Invalid value for p_report_limit: '||p_report_limit||'. Must be >=0.');
    end if;

    execute immediate 'select unique dbid from dba_hist_sqltext@'||p_dblink||q'[ where sql_id=']'||p_sql_id||q'[' order by 1]'
      bulk collect into l_dbid;

    p(HTF.header (1,'AWR SQL Report for SQL_ID='||p_sql_id,cattributes=>'class="awr"'));
    p(HTF.BR);
    p(HTF.BR);
    p(HTF.header (2,cheader=>HTF.ANCHOR (curl=>'',ctext=>'Table of contents',cname=>'tblofcont',cattributes=>'class="awr"'),cattributes=>'class="awr"'));
    p(HTF.BR);

    p(HTF.header (4,cheader=>'Statistics',cattributes=>'class="awr"'));

    p(HTF.LISTITEM(cattributes=>'class="awr"',ctext=>HTF.ANCHOR (curl=>'#sql_text',ctext=>'SQL text',cattributes=>'class="awr"')));
    p(HTF.LISTITEM(cattributes=>'class="awr"',ctext=>HTF.ANCHOR (curl=>'#db_desc',ctext=>'DB description',cattributes=>'class="awr"')));
    p(HTF.LISTITEM(cattributes=>'class="awr"',ctext=>HTF.ANCHOR (curl=>'#sql_stat',ctext=>'SQL statistics',cattributes=>'class="awr"')));
    p(HTF.LISTITEM(cattributes=>'class="awr"',ctext=>HTF.ANCHOR (curl=>'#binds',ctext=>'Bind values',cattributes=>'class="awr"')));

    p(HTF.header (4,cheader=>'Explain plan',cattributes=>'class="awr"'));

    p(HTF.LISTITEM(cattributes=>'class="awr"',ctext=>HTF.ANCHOR (curl=>'#awrplans',ctext=>'AWR SQL execution plans',cattributes=>'class="awr"')));
    p(HTF.LISTITEM(cattributes=>'class="awr"',ctext=>HTF.ANCHOR (curl=>'#awrplanscomp',ctext=>'AWR SQL plans comparison',cattributes=>'class="awr"')));
    p(HTF.LISTITEM(cattributes=>'class="awr"',ctext=>HTF.ANCHOR (curl=>'#epplan',ctext=>'Explain plan',cattributes=>'class="awr"')));

    p(HTF.header (4,cheader=>'ASH',cattributes=>'class="awr"'));

    p(HTF.LISTITEM(cattributes=>'class="awr"',ctext=>HTF.ANCHOR (curl=>'#ash',ctext=>'ASH',cattributes=>'class="awr"')));
    p(HTF.LISTITEM(cattributes=>'class="awr"',ctext=>HTF.ANCHOR (curl=>'#ash_plsql',ctext=>'PL/SQL',cattributes=>'class="awr"')));
    p(HTF.LISTITEM(cattributes=>'class="awr"',ctext=>HTF.ANCHOR (curl=>'#ash_summ',ctext=>'ASH summary',cattributes=>'class="awr"')));
    --p(HTF.LISTITEM(cattributes=>'class="awr"',ctext=>HTF.ANCHOR (curl=>'#ash_p1',ctext=>'AWR ASH (SQL Monitor) P1',cattributes=>'class="awr"')));
    p(HTF.LISTITEM(cattributes=>'class="awr"',ctext=>HTF.ANCHOR (curl=>'#ash_p1.1',ctext=>'AWR ASH (SQL Monitor) P1',cattributes=>'class="awr"')));
    p(HTF.LISTITEM(cattributes=>'class="awr"',ctext=>HTF.ANCHOR (curl=>'#ash_p2',ctext=>'AWR ASH (SQL Monitor) P2',cattributes=>'class="awr"')));
    p(HTF.LISTITEM(cattributes=>'class="awr"',ctext=>HTF.ANCHOR (curl=>'#ash_p3',ctext=>'AWR ASH (SQL Monitor) P3',cattributes=>'class="awr"')));

    p(HTF.header (4,cheader=>'SQL Monitor',cattributes=>'class="awr"'));

    p(HTF.LISTITEM(cattributes=>'class="awr"',ctext=>HTF.ANCHOR (curl=>'#sql_mon_hist',ctext=>'SQL Monitor report history',cattributes=>'class="awr"')));
    p(HTF.BR);
    p(HTF.BR);

--  =============================================================================================================================================
    --SQL TEXT
    COREMOD_REPORT_UTILS.start_lo_section(p_module_name => 'SQL AWR report: '||p_sql_id, p_action_name => 'SQL TEXT');

    p(HTF.header (3,cheader=>HTF.ANCHOR (curl=>'',ctext=>'SQL text',cname=>'sql_text',cattributes=>'class="awr"'),cattributes=>'class="awr"'));
    p(HTF.BR);

    l_script:=q'[select x.sql_text text from dba_hist_sqltext x where sql_id=']'||p_sql_id||q'[' and rownum=1]'||chr(10);
    l_output.delete;
    coremod_report_utils.print_table_html_remotelly(p_query=>l_script,p_width=>500,p_summary=>'SQL text', p_dblink => p_dblink, p_output=> l_output);
    p1(l_output);

    p(HTF.BR);
    p(HTF.LISTITEM(cattributes=>'class="awr"',ctext=>HTF.ANCHOR (curl=>'#tblofcont',ctext=>'Back to top',cattributes=>'class="awr"')));
    p(HTF.BR);
    p(COREMOD_REPORT_UTILS.end_lo_section);
    p(HTF.BR);

--  =============================================================================================================================================
    --DB description
    COREMOD_REPORT_UTILS.start_lo_section(p_module_name => 'SQL AWR report: '||p_sql_id, p_action_name => 'DB description');

    p(HTF.header (3,cheader=>HTF.ANCHOR (curl=>'',ctext=>'DB description',cname=>'db_desc',cattributes=>'class="awr"'),cattributes=>'class="awr"'));
    p(HTF.BR);

    l_script:=q'[select unique INSTANCE_NUMBER INST_ID, DB_NAME,dbid,version,host_name,platform_name from dba_hist_database_instance where dbid in (select dbid from dba_hist_sqltext where sql_id=']'||p_sql_id||q'[')]'||chr(10);
    l_output.delete;
    coremod_report_utils.print_table_html_remotelly(p_query=>l_script,p_width=>1000,p_summary=>'DB description', p_dblink => p_dblink, p_output=> l_output);
    p1(l_output);

    p(HTF.BR);
    p(HTF.LISTITEM(cattributes=>'class="awr"',ctext=>HTF.ANCHOR (curl=>'#tblofcont',ctext=>'Back to top',cattributes=>'class="awr"')));
    p(HTF.BR);
    p(COREMOD_REPORT_UTILS.end_lo_section);
    p(HTF.BR);

--  =============================================================================================================================================
    --SQL statistics
    COREMOD_REPORT_UTILS.start_lo_section(p_module_name => 'SQL AWR report: '||p_sql_id, p_action_name => 'SQL statistics');

    p(HTF.header (3,cheader=>HTF.ANCHOR (curl=>'',ctext=>'SQL statistics',cname=>'sql_stat',cattributes=>'class="awr"'),cattributes=>'class="awr"'));
    p(HTF.BR);
    p('POE - per one exec, time in milliseconds (1/1000 of second)');
    p(HTF.BR);
    open l_crsr for 'select unique dbid,INSTANCE_NUMBER from dba_hist_database_instance@'||p_dblink||' where dbid in (select dbid from dba_hist_sqltext@'||p_dblink||q'[ where sql_id=']'||p_sql_id||q'[') order by 1,2]';
    --for i in (select unique dbid,INSTANCE_NUMBER from dba_hist_database_instance where dbid in (select dbid from dba_hist_sqltext where sql_id=l_sql_id) order by 1,2)
    loop
      fetch l_crsr into l_dbidn, l_inst_id;
      exit when l_crsr%notfound;
      p('DBID: '||l_dbidn||'; INST_ID: '||l_inst_id);
      --l_sql:=l_sqlstat;
      l_script:=coremod_api.getscript('PROC_AWRSQLSTAT');
      COREMOD_REPORT_UTILS.prepare_script(l_script,p_sql_id,p_dbid=>l_dbidn,p_inst_id=>l_inst_id, p_start_snap => l_start_snap, p_end_snap => l_end_snap);
      l_output.delete;
      coremod_report_utils.print_table_html_remotelly(p_query=>l_script,
                                 p_width=>1000,
                                 p_summary=>'SQL statistics',
                                 p_style1 =>'awrncbbt',
                                 p_style2 =>'awrcbbt',
                                 p_search => 'PLAN_HASH',
                                 p_replacement => HTF.ANCHOR (curl=>'#awrplan_\1',ctext=>'\1',cattributes=>'class="awr"'),
                                 p_header=>25,
                                 p_dblink => p_dblink, p_output=> l_output);
      p1(l_output);
      p(HTF.BR);
      p(HTF.LISTITEM(cattributes=>'class="awr"',ctext=>HTF.ANCHOR (curl=>'#tblofcont',ctext=>'Back to top',cattributes=>'class="awr"')));
      p(HTF.BR);
    end loop;
    close l_crsr;
    p(HTF.BR);
    p(COREMOD_REPORT_UTILS.end_lo_section);
    p(HTF.BR);

--  =============================================================================================================================================
    --Bind values
    COREMOD_REPORT_UTILS.start_lo_section(p_module_name => 'SQL AWR report: '||p_sql_id, p_action_name => 'Bind values');

    p(HTF.header (3,cheader=>HTF.ANCHOR (curl=>'',ctext=>'Bind values',cname=>'binds',cattributes=>'class="awr"'),cattributes=>'class="awr"'));
    p(HTF.BR);

    l_script:=q'[select snap_id snap, name, datatype_string,to_char(last_captured,'yyyy/mm/dd hh24:mi:ss') last_captured, value_string from dba_hist_sqlbind where sql_id=']'||p_sql_id||q'[' and snap_id between ]'||l_start_snap||' and '||l_end_snap||q'[ order by snap_id,position]'||chr(10);
    l_output.delete;
    coremod_report_utils.print_table_html_remotelly(p_query=>l_script,p_width=>1000,p_summary=>'Bind values',p_header=>25, p_dblink => p_dblink, p_output=> l_output);
    p1(l_output);

    p(HTF.BR);
    p(HTF.LISTITEM(cattributes=>'class="awr"',ctext=>HTF.ANCHOR (curl=>'#tblofcont',ctext=>'Back to top',cattributes=>'class="awr"')));
    p(HTF.BR);
    p(COREMOD_REPORT_UTILS.end_lo_section);
    p(HTF.BR);

--  =============================================================================================================================================
    --AWR SQL execution plans
    COREMOD_REPORT_UTILS.start_lo_section(p_module_name => 'SQL AWR report: '||p_sql_id, p_action_name => 'AWR SQL execution plans');

    p(HTF.header (3,cheader=>HTF.ANCHOR (curl=>'',ctext=>'AWR SQL execution plans',cname=>'awrplans',cattributes=>'class="awr"'),cattributes=>'class="awr"'));
    p(HTF.BR);
    p(HTF.LISTITEM(cattributes=>'class="awr"',ctext=>HTF.ANCHOR (curl=>'#awrplanscomp',ctext=>'AWR SQL plans comparison',cattributes=>'class="awr"')));
    p(HTF.LISTITEM(cattributes=>'class="awr"',ctext=>HTF.ANCHOR (curl=>'#epplan',ctext=>'Explain plan',cattributes=>'class="awr"')));
    p(HTF.BR);   p(HTF.BR);
    -- for i in (select unique dbid from dba_hist_database_instance where dbid in (select dbid from dba_hist_sqltext where sql_id=l_sql_id) order by 1)
    for i in 1..l_dbid.count
    loop
      p('DBID: '||l_dbid(i));

      l_script:=q'[select * from table(dbms_xplan.display_awr(']'||p_sql_id||q'[', null, ]'||l_dbid(i)||q'[, 'ADVANCED'))]'||chr(10);
      l_output.delete;
      coremod_report_utils.print_table_html_remotelly(p_query=>l_script,
                                 p_width=>1000,
                                 p_summary=>'AWR SQL execution plans',
                                 p_search => 'Plan hash value: ([[:digit:]]*)',
                                 p_replacement => HTF.ANCHOR(curl=>'#epplan_\1',ctext=>'Plan hash value: \1',cname=>'awrplan_\1',cattributes=>'class="awr"'),
                                 p_dblink => p_dblink, p_output=> l_output);
      p1(l_output);

      p(HTF.BR);
      p(HTF.LISTITEM(cattributes=>'class="awr"',ctext=>HTF.ANCHOR (curl=>'#awrplans',ctext=>'Back to AWR SQL execution plans',cattributes=>'class="awr"')));
      p(HTF.LISTITEM(cattributes=>'class="awr"',ctext=>HTF.ANCHOR (curl=>'#tblofcont',ctext=>'Back to top',cattributes=>'class="awr"')));
      p(HTF.BR);
    end loop;
    p(HTF.BR);
    p(COREMOD_REPORT_UTILS.end_lo_section);
    p(HTF.BR);

--  =============================================================================================================================================
    --Comparsion
    COREMOD_REPORT_UTILS.start_lo_section(p_module_name => 'SQL AWR report: '||p_sql_id, p_action_name => 'Comparsion');

    p(HTF.header (3,cheader=>HTF.ANCHOR (curl=>'',ctext=>'AWR SQL plans comparison',cname=>'awrplanscomp',cattributes=>'class="awr"'),cattributes=>'class="awr"'));
    p(HTF.BR);
    p('Not implemented for remote database.');
/*    stim();


    for c in (select dbid, sql_id, min(snap_id) mi, max(snap_id) ma, count(unique plan_hash_value) cnt
                from dba_hist_sqlstat
               where plan_hash_value<>0
                 and CPU_TIME_DELTA+ELAPSED_TIME_DELTA+BUFFER_GETS_DELTA+EXECUTIONS_DELTA>0
                 and sql_id=l_sql_id
               group by dbid, sql_id
              having count(unique plan_hash_value)>1)
    loop
      l_script:=awrtools_api.getscript('GETCOMPREPORT');
      execute immediate
         replace(
         replace(
         replace(
         replace(
         replace(
         replace(
         replace(
         replace(
         replace(
         replace(
         replace(l_script
                          ,'!dblnk.','')
                          ,'!dbid1.',to_char(c.dbid))
                          ,'!start_snap1.',to_char(c.mi-1))
                          ,'!end_snap1.',to_char(c.ma))
                          ,'!dbid2.',to_char(c.dbid))
                          ,'!start_snap2.',to_char(c.mi-1))
                          ,'!end_snap2.',to_char(c.ma))
                          ,'!filter.',q'[sql_id=']'||l_sql_id||q'[']')
                          ,'!sortcol.','ELAPSED_TIME_DELTA')
                          ,'!sortlimit.','1')
                          ,'!embeded.','TRUE');
    end loop;
*/
    p(HTF.LISTITEM(cattributes=>'class="awr"',ctext=>HTF.ANCHOR (curl=>'#awrplans',ctext=>'Back to AWR SQL execution plans',cattributes=>'class="awr"')));
    p(HTF.LISTITEM(cattributes=>'class="awr"',ctext=>HTF.ANCHOR (curl=>'#tblofcont',ctext=>'Back to top',cattributes=>'class="awr"')));
    p(HTF.BR);
    p(COREMOD_REPORT_UTILS.end_lo_section);
    p(HTF.BR);

--  =============================================================================================================================================
    --Explain plan
    COREMOD_REPORT_UTILS.start_lo_section(p_module_name => 'SQL AWR report: '||p_sql_id, p_action_name => 'Explain plan');

    p(HTF.header (3,cheader=>HTF.ANCHOR (curl=>'',ctext=>'Explain plan',cname=>'epplan',cattributes=>'class="awr"'),cattributes=>'class="awr"'));
    p(HTF.BR);
    p(HTF.LISTITEM(cattributes=>'class="awr"',ctext=>HTF.ANCHOR (curl=>'#ep_simple',ctext=>'Explain plan (simple)',cattributes=>'class="awr"')));
    p(HTF.LISTITEM(cattributes=>'class="awr"',ctext=>HTF.ANCHOR (curl=>'#ep_adv',ctext=>'Explain plan (advanced)',cattributes=>'class="awr"')));

    p(HTF.BR);p(HTF.BR);

    declare
      l_out clob;
    begin
      execute immediate 'select x.sql_text from dba_hist_sqltext@'||p_dblink||q'[ x where sql_id=']'||p_sql_id||q'[' and rownum=1]' into l_script;
      execute immediate 'delete from plan_table@'||p_dblink;
      --execute immediate 'explain plan for '||chr(10)||l_script;
      coremod_report_utils.execute_plsql_remotelly(p_sql => q'(execute immediate q'[explain plan for )'||chr(10)||l_script||q'(]';)', p_dblink => p_dblink, p_output => l_out, p_is_output => false);
    exception
      when others then p(sqlerrm);
    end;

    p(HTF.header (3,cheader=>HTF.ANCHOR (curl=>'',ctext=>'Explain plan (simple)',cname=>'ep_simple',cattributes=>'class="awr"'),cattributes=>'class="awr"'));

    l_script:=q'[select * from table(dbms_xplan.display())]'||chr(10);
    l_output.delete;
    coremod_report_utils.print_table_html_remotelly(p_query=>l_script,
                               p_width=> 1000,
                               p_summary=> 'Explain plan',
                               p_search => 'Plan hash value: ([[:digit:]]*)',
                               p_replacement => HTF.ANCHOR(curl=>'#epplanadv_\1',ctext=>'Plan hash value: \1',cname=>'epplan_\1',cattributes=>'class="awr"'),
                               p_dblink => p_dblink, p_output=> l_output);
    p1(l_output);

    p(HTF.BR);p(HTF.BR);
    p(HTF.LISTITEM(cattributes=>'class="awr"',ctext=>HTF.ANCHOR (curl=>'#epplan',ctext=>'Back to Explain plan',cattributes=>'class="awr"')));
    p(HTF.LISTITEM(cattributes=>'class="awr"',ctext=>HTF.ANCHOR (curl=>'#awrplans',ctext=>'Back to AWR SQL execution plans',cattributes=>'class="awr"')));
    p(HTF.LISTITEM(cattributes=>'class="awr"',ctext=>HTF.ANCHOR (curl=>'#tblofcont',ctext=>'Back to top',cattributes=>'class="awr"')));
    p(HTF.BR);p(HTF.BR);
    p(HTF.header (3,cheader=>HTF.ANCHOR (curl=>'',ctext=>'Explain plan (advanced)',cname=>'ep_adv',cattributes=>'class="awr"'),cattributes=>'class="awr"'));

    l_script:=q'[select * from table(dbms_xplan.display(null,null,'ADVANCED',null))]'||chr(10);
    l_output.delete;
    coremod_report_utils.print_table_html_remotelly(p_query=>l_script,
                               p_width=>1000,
                               p_summary=>'Explain plan (advanced)',
                               p_search => 'Plan hash value: ([[:digit:]]*)',
                               p_replacement => HTF.ANCHOR(curl=>'',ctext=>'Plan hash value: \1',cname=>'epplanadv_\1',cattributes=>'class="awr"'),
                               p_dblink => p_dblink, p_output=> l_output);
    p1(l_output);

    p(HTF.BR);p(HTF.BR);
    p(HTF.LISTITEM(cattributes=>'class="awr"',ctext=>HTF.ANCHOR (curl=>'#epplan',ctext=>'Back to Explain plan',cattributes=>'class="awr"')));
    p(HTF.LISTITEM(cattributes=>'class="awr"',ctext=>HTF.ANCHOR (curl=>'#awrplans',ctext=>'Back to AWR SQL execution plans',cattributes=>'class="awr"')));
    p(HTF.LISTITEM(cattributes=>'class="awr"',ctext=>HTF.ANCHOR (curl=>'#tblofcont',ctext=>'Back to top',cattributes=>'class="awr"')));
    rollback;
    p(HTF.BR);
    p(COREMOD_REPORT_UTILS.end_lo_section);
    p(HTF.BR);

--  =============================================================================================================================================
    p(HTF.header (3,cheader=>HTF.ANCHOR (curl=>'',ctext=>'ASH',cname=>'ash',cattributes=>'class="awr"'),cattributes=>'class="awr"'));
    p(HTF.BR);
    p(HTF.LISTITEM(cattributes=>'class="awr"',ctext=>HTF.ANCHOR (curl=>'#ash_plsql',ctext=>'PL/SQL',cattributes=>'class="awr"')));
    p(HTF.LISTITEM(cattributes=>'class="awr"',ctext=>HTF.ANCHOR (curl=>'#ash_summ',ctext=>'ASH summary',cattributes=>'class="awr"')));
    --p(HTF.LISTITEM(cattributes=>'class="awr"',ctext=>HTF.ANCHOR (curl=>'#ash_p1',ctext=>'AWR ASH (SQL Monitor) P1',cattributes=>'class="awr"')));
    p(HTF.LISTITEM(cattributes=>'class="awr"',ctext=>HTF.ANCHOR (curl=>'#ash_p1.1',ctext=>'AWR ASH (SQL Monitor) P1',cattributes=>'class="awr"')));
    p(HTF.LISTITEM(cattributes=>'class="awr"',ctext=>HTF.ANCHOR (curl=>'#ash_p2',ctext=>'AWR ASH (SQL Monitor) P2',cattributes=>'class="awr"')));
    p(HTF.LISTITEM(cattributes=>'class="awr"',ctext=>HTF.ANCHOR (curl=>'#ash_p3',ctext=>'AWR ASH (SQL Monitor) P3',cattributes=>'class="awr"')));
    p(HTF.BR);p(HTF.BR);

--  =============================================================================================================================================
    --ASH PL/SQL
    COREMOD_REPORT_UTILS.start_lo_section(p_module_name => 'SQL AWR report: '||p_sql_id, p_action_name => 'ASH PL/SQL');

    p(HTF.header (3,cheader=>HTF.ANCHOR (curl=>'',ctext=>'ASH PL/SQL',cname=>'ash_plsql',cattributes=>'class="awr"'),cattributes=>'class="awr"'));
    p(HTF.BR);
    for i in 1..l_dbid.count
    loop
      p('DBID: '||l_dbid(i));
      if sys_context('USERENV','CON_ID')=0 then --in multitenant it runs forever
        l_script:=q'[select * from dba_procedures where (object_id,subprogram_id) in (select unique plsql_entry_object_id,plsql_entry_subprogram_id from dba_hist_active_sess_history where instance_number between 1 and 255 and snap_id between ]'||l_start_snap||q'[ and ]'||l_end_snap||q'[ and sql_id = ']'||p_sql_id||q'[' and dbid= ]'||l_dbid(i)||q'[)]'||chr(10);
        l_output.delete;
        coremod_report_utils.print_table_html_remotelly(p_query=>l_script,p_width=>1500,p_summary=>'ASH PL/SQL',p_style1 =>'awrc1',p_style2 =>'awrnc1', p_dblink => p_dblink, p_output=> l_output);
        p1(l_output);
      else
        p('No PL/SQL source data for multitenant DB.');
      end if;

      p(HTF.BR);
      p(HTF.LISTITEM(cattributes=>'class="awr"',ctext=>HTF.ANCHOR (curl=>'#ash',ctext=>'Back to ASH',cattributes=>'class="awr"')));
      p(HTF.LISTITEM(cattributes=>'class="awr"',ctext=>HTF.ANCHOR (curl=>'#tblofcont',ctext=>'Back to top',cattributes=>'class="awr"')));
      p(HTF.BR);
    end loop;
    p(HTF.BR);
    p(COREMOD_REPORT_UTILS.end_lo_section);
    p(HTF.BR);

--  =============================================================================================================================================
    --ASH summary
    COREMOD_REPORT_UTILS.start_lo_section(p_module_name => 'SQL AWR report: '||p_sql_id, p_action_name => 'ASH summary');

    p(HTF.header (3,cheader=>HTF.ANCHOR (curl=>'',ctext=>'ASH summary',cname=>'ash_summ',cattributes=>'class="awr"'),cattributes=>'class="awr"'));
    p(HTF.BR);
    for i in 1..l_dbid.count
    loop
      p('DBID: '||l_dbid(i));
      l_script:=coremod_api.getscript('PROC_AWRASHSUMM');
      COREMOD_REPORT_UTILS.prepare_script(l_script,p_sql_id,p_dbid=>l_dbid(i), p_start_snap => l_start_snap, p_end_snap => l_end_snap);

      l_output.delete;
      coremod_report_utils.print_table_html_remotelly(p_query=>l_script,
                                 p_width=>1500,
                                 p_summary=>'ASH summary',
                                 p_style1 =>'awrncbbt',
                                 p_style2 =>'awrcbbt',
                                 p_search => 'PLAN_HASH',
                                 p_replacement => HTF.ANCHOR (curl=>'#awrplan_\1',ctext=>'\1',cattributes=>'class="awr"'),
                                 p_header=>25,
                                 p_dblink => p_dblink, p_output=> l_output);
      p1(l_output);

      p(HTF.BR);
      p(HTF.LISTITEM(cattributes=>'class="awr"',ctext=>HTF.ANCHOR (curl=>'#ash',ctext=>'Back to ASH',cattributes=>'class="awr"')));
      p(HTF.LISTITEM(cattributes=>'class="awr"',ctext=>HTF.ANCHOR (curl=>'#tblofcont',ctext=>'Back to top',cattributes=>'class="awr"')));
      p(HTF.BR);
    end loop;
    p(HTF.BR);
    p(COREMOD_REPORT_UTILS.end_lo_section);
    p(HTF.BR);

--  =============================================================================================================================================
    --AWR ASH (SQL Monitor) P1
/*    DBMS_APPLICATION_INFO.SET_MODULE ( module_name => 'SQL AWR report: '||p_sql_id, action_name => 'AWR ASH (SQL Monitor) P1');
    stim();
    p(HTF.header (3,cheader=>HTF.ANCHOR (curl=>'',ctext=>'AWR ASH (SQL Monitor) P1',cname=>'ash_p1',cattributes=>'class="awr"'),cattributes=>'class="awr"'));
    p(HTF.BR);

    for i in 1..l_dbid.count
    loop
      p('DBID: '||l_dbid(i));
      l_script:=awrtools_api.getscript('PROC_AWRASHP1');
      prepare_script(l_script,p_sql_id,p_dbid=>l_dbid(i), p_start_snap => l_start_snap, p_end_snap => l_end_snap);

      l_output.delete;
      print_table_html_remotelly(p_query=>l_script,
                                 p_width=>1000,
                                 p_summary=>'AWR ASH (SQL Monitor) P1',
                                 p_style1 =>'awrncbbt',
                                 p_style2 =>'awrcbbt',
                                 p_search => 'PLAN_HASH',
                                 p_replacement => HTF.ANCHOR (curl=>'#awrplan_\1',ctext=>'\1',cattributes=>'class="awr"'),
                                 p_header=>50,
                                 p_break_col=>'SQL_EXEC_START',
                                 p_dblink => p_dblink, p_output=> l_output);
      p1(l_output);
      p(HTF.BR);
      p(HTF.LISTITEM(cattributes=>'class="awr"',ctext=>HTF.ANCHOR (curl=>'#ash',ctext=>'Back to ASH',cattributes=>'class="awr"')));
      p(HTF.LISTITEM(cattributes=>'class="awr"',ctext=>HTF.ANCHOR (curl=>'#tblofcont',ctext=>'Back to top',cattributes=>'class="awr"')));
      p(HTF.BR);
    end loop;
    etim();
    p(HTF.BR);
    p(HTF.BR);*/

--  =============================================================================================================================================
    --AWR ASH (SQL Monitor) P1.1
    COREMOD_REPORT_UTILS.start_lo_section(p_module_name => 'SQL AWR report: '||p_sql_id, p_action_name => 'AWR ASH (SQL Monitor) P1');

    p(HTF.header (3,cheader=>HTF.ANCHOR (curl=>'',ctext=>'AWR ASH (SQL Monitor) P1',cname=>'ash_p1.1',cattributes=>'class="awr"'),cattributes=>'class="awr"'));
    p(HTF.BR);
    for i in 1..l_dbid.count
    loop
      p('DBID: '||l_dbid(i));
      l_script:=coremod_api.getscript('PROC_AWRASHP1_1');
      COREMOD_REPORT_UTILS.prepare_script(l_script,p_sql_id,p_dbid=>l_dbid(i), p_start_snap => l_start_snap, p_end_snap => l_end_snap);

      l_output.delete;
      coremod_report_utils.print_table_html_remotelly(p_query=>l_script,
                                 p_width=>1000,
                                 p_summary=>'AWR ASH (SQL Monitor) P1',
                                 p_style1 =>'awrncbbt',
                                 p_style2 =>'awrcbbt',
                                 p_search => 'PLAN_HASH',
                                 p_replacement => HTF.ANCHOR (curl=>'#awrplan_\1',ctext=>'\1',cattributes=>'class="awr"'),
                                 p_header=>25,
                                 p_break_col=>'ID',
                                 p_dblink => p_dblink, p_output=> l_output);
      p1(l_output);
      p(HTF.BR);
      p(HTF.LISTITEM(cattributes=>'class="awr"',ctext=>HTF.ANCHOR (curl=>'#ash',ctext=>'Back to ASH',cattributes=>'class="awr"')));
      p(HTF.LISTITEM(cattributes=>'class="awr"',ctext=>HTF.ANCHOR (curl=>'#tblofcont',ctext=>'Back to top',cattributes=>'class="awr"')));
      p(HTF.BR);
    end loop;
    p(HTF.BR);
    p(COREMOD_REPORT_UTILS.end_lo_section);
    p(HTF.BR);

--  =============================================================================================================================================
    --AWR ASH (SQL Monitor) P2
    COREMOD_REPORT_UTILS.start_lo_section(p_module_name => 'SQL AWR report: '||p_sql_id, p_action_name => 'AWR ASH (SQL Monitor) P2');

    p(HTF.header (3,cheader=>HTF.ANCHOR (curl=>'',ctext=>'AWR ASH (SQL Monitor) P2',cname=>'ash_p2',cattributes=>'class="awr"'),cattributes=>'class="awr"'));
    p(HTF.BR);
    for i in 1..l_dbid.count
    loop
      p('DBID: '||l_dbid(i));
      l_script:=coremod_api.getscript('PROC_AWRASHP2');
      COREMOD_REPORT_UTILS.prepare_script(l_script,p_sql_id,p_dbid=>l_dbid(i), p_start_snap => l_start_snap, p_end_snap => l_end_snap);

      l_output.delete;
      coremod_report_utils.print_table_html_remotelly(p_query=>l_script,
                                 p_width=>1000,
                                 p_summary=>'AWR ASH (SQL Monitor) P2',
                                 p_style1 =>'awrncbbt',
                                 p_style2 =>'awrcbbt',
                                 p_search => 'PLAN_HASH',
                                 p_replacement => HTF.ANCHOR (curl=>'#awrplan_\1',ctext=>'\1',cattributes=>'class="awr"'),
                                 p_header=>50,
                                 p_break_col=>'SQL_EXEC_START',
                                 p_dblink => p_dblink, p_output=> l_output);
      p1(l_output);
      p(HTF.BR);
      p(HTF.LISTITEM(cattributes=>'class="awr"',ctext=>HTF.ANCHOR (curl=>'#ash',ctext=>'Back to ASH',cattributes=>'class="awr"')));
      p(HTF.LISTITEM(cattributes=>'class="awr"',ctext=>HTF.ANCHOR (curl=>'#tblofcont',ctext=>'Back to top',cattributes=>'class="awr"')));
      p(HTF.BR);
    end loop;
    p(HTF.BR);
    p(COREMOD_REPORT_UTILS.end_lo_section);
    p(HTF.BR);

--  =============================================================================================================================================
    --AWR ASH (SQL Monitor) P3
    COREMOD_REPORT_UTILS.start_lo_section(p_module_name => 'SQL AWR report: '||p_sql_id, p_action_name => 'AWR ASH (SQL Monitor) P3');

    p(HTF.header (3,cheader=>HTF.ANCHOR (curl=>'',ctext=>'AWR ASH (SQL Monitor) P3',cname=>'ash_p3',cattributes=>'class="awr"'),cattributes=>'class="awr"'));
    p(HTF.BR);

    l_script:=coremod_api.getscript('PROC_AWRASHP3');
    COREMOD_REPORT_UTILS.prepare_script(l_script,p_sql_id, p_start_snap => l_start_snap, p_end_snap => l_end_snap);

    l_output.delete;
    coremod_report_utils.print_table_html_remotelly(p_query=>l_script,
                               p_width=>1000,
                               p_summary=>'AWR ASH (SQL Monitor) P3',
                               p_style1 =>'awrncbbt',
                               p_style2 =>'awrcbbt',
                               p_search => 'PLAN_HASH',
                               p_replacement => HTF.ANCHOR (curl=>'#awrplan_\1',ctext=>'\1',cattributes=>'class="awr"'),
                               p_header=>25,
                               p_break_col=>'SQL_EXEC_START',
                               p_dblink => p_dblink, p_output=> l_output);
    p1(l_output);
    p(HTF.BR);
    p(HTF.LISTITEM(cattributes=>'class="awr"',ctext=>HTF.ANCHOR (curl=>'#ash',ctext=>'Back to ASH',cattributes=>'class="awr"')));
    p(HTF.LISTITEM(cattributes=>'class="awr"',ctext=>HTF.ANCHOR (curl=>'#tblofcont',ctext=>'Back to top',cattributes=>'class="awr"')));
    p(HTF.BR);
    p(COREMOD_REPORT_UTILS.end_lo_section);
    p(HTF.BR);

--  =============================================================================================================================================
    --SQL Monitor report history
    COREMOD_REPORT_UTILS.start_lo_section(p_module_name => 'SQL AWR report: '||p_sql_id, p_action_name => 'SQL Monitor report history');

    p(HTF.header (3,cheader=>HTF.ANCHOR (curl=>'',ctext=>'SQL Monitor report history (12c+)',cname=>'sql_mon_hist',cattributes=>'class="awr"'),cattributes=>'class="awr"'));
    p(HTF.BR);
    l_script:=coremod_api.getscript('PROC_SQLMON_HIST');
    COREMOD_REPORT_UTILS.prepare_script(l_script,p_sql_id,p_start_snap => l_start_snap, p_end_snap => l_end_snap);
    l_plsql_output:=null;
    coremod_report_utils.execute_plsql_remotelly(p_sql => l_script, p_dblink => p_dblink, p_output => l_plsql_output);
    coremod_report_utils.print_text_as_table(p_text=>l_plsql_output,
                        p_t_header=>'SQL Monitor report history',
                        p_width=>600,
                        p_search=>'Plan Hash Value=([[:digit:]]*)',
                        p_replacement=>HTF.ANCHOR (curl=>'#awrplan_\1',ctext=>'Plan Hash Value=\1',cattributes=>'class="awr"'),
                        p_output=> l_output);
    p1(l_output);

    p(HTF.BR);
    p(HTF.LISTITEM(cattributes=>'class="awr"',ctext=>HTF.ANCHOR (curl=>'#tblofcont',ctext=>'Back to top',cattributes=>'class="awr"')));
    p(HTF.BR);
    p(HTF.BR);
    p(COREMOD_REPORT_UTILS.end_lo_section(true));
    p(HTF.BR);
    p('End of report.');

    return l_report;
--  =============================================================================================================================================
    --save_report_for_download('awr_'||p_sql_id||'.html', l_report, p_id, p_parent_id);
--  exception
--    when others then
--      awrtools_logging.log(sqlerrm);
--      awrtools_logging.log(DBMS_UTILITY.FORMAT_ERROR_STACK);
--      awrtools_logging.log(DBMS_UTILITY.FORMAT_ERROR_BACKTRACE);
--      raise_application_error(-20000, sqlerrm);
  end;


end;
/
