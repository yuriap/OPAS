CREATE OR REPLACE
PACKAGE BODY AWRWH_REPORT_API AS

  procedure create_report_awrrpt(p_proj_id      awrwh_reports.proj_id%type,
                                 p_dbid         number,
                                 p_min_snap     number,
                                 p_max_snap     number,
                                 p_instance_num number,
                                 p_dump_id      awrwh_dumps.dump_id%type default null,
                                 p_dblink       varchar2 default null)
  is
    l_proj      awrwh_projects%rowtype;
    l_report_id opas_reports.report_id%type;
  begin
    l_proj:=AWRWH_PROJ_API.getproject(p_proj_id,true);

    l_report_id := coremod_reports.queue_report_awrrpt(p_modname => AWRWH_API.gMODNAME,
                                                       p_owner => l_proj.owner,
                                                       P_DBID => P_DBID,
                                                       P_MIN_SNAP => P_MIN_SNAP,
                                                       P_MAX_SNAP => P_MAX_SNAP,
                                                       P_INSTANCE_NUM => P_INSTANCE_NUM,
                                                       p_dblink => p_dblink);

    INSERT INTO awrwh_reports (proj_id,report_id,dump_id,dump_id_2,report_retention,report_note,created)
                       VALUES (p_proj_id,l_report_id,p_dump_id,null,default,null,systimestamp);

    commit;
  end;

  procedure create_report_awrrpt(p_proj_id      awrwh_reports.proj_id%type,
                                 p_dump_id      awrwh_dumps.dump_id%type)
  is
  begin
    for i in (select dbid,min_snap_id,max_snap_id from awrwh_dumps where dump_id=p_dump_id and status in (AWRWH_FILE_LCC.c_dmpfilestate_awrloaded, AWRWH_FILE_LCC.c_dmpfilestate_compressed)) loop
      for j in (select instance_number from dba_hist_snapshot where dbid=i.dbid and snap_id between i.min_snap_id and i.max_snap_id) loop
        create_report_awrrpt(p_proj_id,i.dbid,i.min_snap_id,i.max_snap_id, j.instance_number, p_dump_id);
      end loop;
    end loop;
  end;

--  =============================================================================================================================================
--  =============================================================================================================================================
--  =============================================================================================================================================

  procedure create_report_sqawrrpt(p_proj_id      awrwh_reports.proj_id%type,
                                   p_sql_id       varchar2,
                                   p_dbid         number,
                                   p_min_snap     number,
                                   p_max_snap     number,
                                   p_instance_num number,
                                   p_dump_id      awrwh_dumps.dump_id%type default null,
                                   p_dblink       varchar2 default null)
  is
    l_proj      awrwh_projects%rowtype;
    l_report_id opas_reports.report_id%type;
  begin
    l_proj:=AWRWH_PROJ_API.getproject(p_proj_id,true);

    l_report_id := coremod_reports.queue_report_sqawrrpt(p_modname => AWRWH_API.gMODNAME,
                                                         p_owner => l_proj.owner,
                                                         p_sql_id => p_sql_id,
                                                         P_DBID => P_DBID,
                                                         P_MIN_SNAP => P_MIN_SNAP,
                                                         P_MAX_SNAP => P_MAX_SNAP,
                                                         P_INSTANCE_NUM => P_INSTANCE_NUM,
                                                         p_dblink => p_dblink);

    INSERT INTO awrwh_reports (proj_id,report_id,dump_id,dump_id_2,report_retention,report_note,created)
                       VALUES (p_proj_id,l_report_id,p_dump_id,null,default,null,systimestamp);

    commit;
  end;

  procedure create_report_sqawrrpt(p_proj_id      awrwh_reports.proj_id%type,
                                   p_sql_id       varchar2,
                                   p_dump_id      awrwh_dumps.dump_id%type)
  is
  begin
    for i in (select dbid,min_snap_id,max_snap_id from awrwh_dumps where dump_id=p_dump_id and status in (AWRWH_FILE_LCC.c_dmpfilestate_awrloaded, AWRWH_FILE_LCC.c_dmpfilestate_compressed)) loop
      for j in (select instance_number from dba_hist_snapshot where dbid=i.dbid and snap_id between i.min_snap_id and i.max_snap_id) loop
        create_report_sqawrrpt(p_proj_id,p_sql_id,i.dbid,i.min_snap_id,i.max_snap_id, j.instance_number, p_dump_id);
      end loop;
    end loop;
  end;

--  =============================================================================================================================================
--  =============================================================================================================================================
--  =============================================================================================================================================

  procedure create_report_diffrpt(p_proj_id       awrwh_reports.proj_id%type,
                                   p_dbid1         number,
                                   p_min_snap1     number,
                                   p_max_snap1     number,
                                   p_instance_num1 number,
                                   p_dbid2         number,
                                   p_min_snap2     number,
                                   p_max_snap2     number,
                                   p_instance_num2 number,
                                   p_dump_id1      awrwh_dumps.dump_id%type default null,
                                   p_dump_id2      awrwh_dumps.dump_id%type default null,
                                   p_dblink        varchar2 default null)
  is
    l_proj      awrwh_projects%rowtype;
    l_report_id opas_reports.report_id%type;
  begin
    l_proj:=AWRWH_PROJ_API.getproject(p_proj_id,true);

    l_report_id := coremod_reports.queue_report_diffrpt(p_modname => AWRWH_API.gMODNAME,
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

    INSERT INTO awrwh_reports (proj_id,report_id,dump_id,dump_id_2,report_retention,report_note,created)
                       VALUES (p_proj_id,l_report_id,p_dump_id1,p_dump_id2,default,null,systimestamp);

    commit;
  end;

  procedure create_report_diffrpt(p_proj_id      awrwh_reports.proj_id%type,
                                  p_dump_id1      awrwh_dumps.dump_id%type,
                                  p_dump_id2      awrwh_dumps.dump_id%type)
  is
    l_dbid1 number;
    l_mis1  number;
    l_mas1  number;
    l_inst1 number:=1;
    l_dbid2 number;
    l_mis2  number;
    l_mas2  number;
    l_inst2 number:=1;
  begin
    select dbid,min_snap_id,max_snap_id into l_dbid1,l_mis1,l_mas1 from awrwh_dumps where dump_id=p_dump_id1 and status in (AWRWH_FILE_LCC.c_dmpfilestate_awrloaded, AWRWH_FILE_LCC.c_dmpfilestate_compressed);
    select dbid,min_snap_id,max_snap_id into l_dbid2,l_mis2,l_mas2 from awrwh_dumps where dump_id=p_dump_id2 and status in (AWRWH_FILE_LCC.c_dmpfilestate_awrloaded, AWRWH_FILE_LCC.c_dmpfilestate_compressed);

    create_report_diffrpt(p_proj_id, l_dbid1, l_mis1, l_mas1, l_inst1, l_dbid2,l_mis2,l_mas2,l_inst2, p_dump_id1, p_dump_id2);
  end;

--  =============================================================================================================================================
--  =============================================================================================================================================
--  =============================================================================================================================================
  procedure create_report_ashrpt(p_proj_id      awrwh_reports.proj_id%type,
                                 p_dbid         number,
                                 p_bdate        date,
                                 p_edate        date,
                                 p_instance_num number,
                                 p_dump_id      awrwh_dumps.dump_id%type default null,
                                 p_dblink       varchar2 default null)
  is
    l_proj      awrwh_projects%rowtype;
    l_report_id opas_reports.report_id%type;
  begin
    l_proj:=AWRWH_PROJ_API.getproject(p_proj_id,true);

    l_report_id := coremod_reports.queue_report_ashrpt(p_modname => AWRWH_API.gMODNAME,
                                                       p_owner => l_proj.owner,
                                                       P_DBID => P_DBID,
                                                       p_btime => p_bdate,
                                                       p_etime => p_edate,
                                                       P_INSTANCE_NUM => P_INSTANCE_NUM,
                                                       p_dblink => p_dblink);

    INSERT INTO awrwh_reports (proj_id,report_id,dump_id,dump_id_2,report_retention,report_note,created)
                       VALUES (p_proj_id,l_report_id,p_dump_id,null,default,null,systimestamp);

    commit;
  end;

  procedure create_report_ashrpt(p_proj_id      awrwh_reports.proj_id%type,
                                 p_dump_id      awrwh_dumps.dump_id%type)
  is
  begin
    for i in (select dbid,min_snap_dt,max_snap_dt,min_snap_id,max_snap_id from awrwh_dumps where dump_id=p_dump_id and status in (AWRWH_FILE_LCC.c_dmpfilestate_awrloaded, AWRWH_FILE_LCC.c_dmpfilestate_compressed)) loop
      for j in (select instance_number from dba_hist_snapshot where dbid=i.dbid and snap_id between i.min_snap_id and i.max_snap_id) loop
        create_report_ashrpt(p_proj_id,i.dbid,i.min_snap_dt,i.max_snap_dt, j.instance_number, p_dump_id);
      end loop;
    end loop;
  end;

--  =============================================================================================================================================
--  =============================================================================================================================================
--  =============================================================================================================================================
/*
  procedure create_report_awrcomp(p_proj_id      awrwh_reports.proj_id%type,
                                  p_dump_id1     awrwh_dumps.dump_id%type,
                                  p_dump_id2     awrwh_dumps.dump_id%type,
                                  p_sort         varchar2,
                                  p_sort_limit   number,
                                  p_filter       varchar2)
  is
    l_proj      awrwh_projects%rowtype;
    l_report_id opas_reports.report_id%type;
  begin
    l_proj:=AWRWH_PROJ_API.getproject(p_proj_id,true);

    l_report_id := create_report_awrcomp_i(p_modname => AWRWH_API.gMODNAME,
                                                       p_owner => l_proj.owner,
                                                       P_DBID => P_DBID,
                                                       P_MIN_SNAP => P_MIN_SNAP,
                                                       P_MAX_SNAP => P_MAX_SNAP,
                                                       P_INSTANCE_NUM => P_INSTANCE_NUM,
                                                       p_dblink => p_dblink);

    INSERT INTO awrwh_reports (proj_id,report_id,dump_id,dump_id_2,report_retention,report_note,created)
                       VALUES (p_proj_id,l_report_id,p_dump_id1,p_dump_id2,default,null,systimestamp);

    commit;
  end;
  */
  procedure queue_report_awrcomp(p_proj_id      awrwh_reports.proj_id%type,
                                 p_dump_id1     awrwh_dumps.dump_id%type,
                                 p_dump_id2     awrwh_dumps.dump_id%type,
                                 p_sort         varchar2,
                                 p_sort_limit   number,
                                 p_filter       varchar2)
  is
    l_report_id         opas_reports.report_id%type;
    l_proj              awrwh_projects%rowtype;
    l_tq_id             opas_task_queue.tq_id%type;
  begin
    l_proj:=AWRWH_PROJ_API.getproject(p_proj_id,false);

    coremod_report_utils.init_report(AWRWH_API.gMODNAME,l_report_id, null);
    coremod_report_utils.set_report_type (l_report_id,'AWRCOMP');
    coremod_report_utils.set_report_param(l_report_id,'OWNER',     l_proj.owner);
    coremod_report_utils.set_report_param(l_report_id,'DUMP1',     p_dump_id1);
    coremod_report_utils.set_report_param(l_report_id,'DUMP2',     p_dump_id2);
    coremod_report_utils.set_report_param(l_report_id,'SORT',      p_sort);
    coremod_report_utils.set_report_param(l_report_id,'SORTLIMIT', p_sort_limit);
    coremod_report_utils.set_report_param(l_report_id,'FILTER',    p_filter);

    INSERT INTO awrwh_reports (proj_id,report_id,dump_id,dump_id_2,report_retention,report_note,created)
                       VALUES (p_proj_id,l_report_id,p_dump_id1,p_dump_id2,default,null,systimestamp);

    l_tq_id:=COREMOD_TASKS.prep_execute_task (  P_TASKNAME => 'AWRWH_AWRCOMPRPT') ;
    COREMOD_TASKS.set_task_param( p_tq_id => l_tq_id, p_name => 'B1', p_num_par => l_report_id);
    COREMOD_TASKS.queue_task ( p_tq_id => l_tq_id ) ;

    commit;
  end;

  procedure report_awrcomp(p_report_id      awrwh_reports.report_id%type)
  is
    l_scr               clob;
    l_file_content      clob;
    l_dmp_file1         awrwh_dumps%rowtype;
    l_dmp_file2         awrwh_dumps%rowtype;
    l_fn_suff           varchar2(10);
    l_file              opas_files.file_id%type;
    l_file_type         opas_files.file_type%type;
    l_file_name         opas_files.file_name%type;
    l_mime              opas_files.FILE_MIMETYPE%type;
    l_displ_params      opas_reports.report_params_displ%type;
    l_line              varchar(32767);
    l_status            number;
  begin
    l_dmp_file1:=AWRWH_FILE_API.get_file(COREMOD_REPORT_UTILS.get_reppar_n(p_report_id,'DUMP1'),false);
    if l_dmp_file1.is_remote='YES' then raise_application_error(-20000,'DB1 can not be remote.'); end if;
    l_dmp_file2:=AWRWH_FILE_API.get_file(COREMOD_REPORT_UTILS.get_reppar_n(p_report_id,'DUMP2'),false);

    l_scr := COREMOD_API.getscript('PROC_GETCOMP');

    l_scr := replace(l_scr,'~dbid1.',to_char(l_dmp_file1.dbid));
    l_scr := replace(l_scr,'~start_snap1.',to_char(l_dmp_file1.min_snap_id));
    l_scr := replace(l_scr,'~end_snap1.',to_char(l_dmp_file1.max_snap_id));

    l_displ_params:='DB1: '||to_char(l_dmp_file1.dbid)||'; snaps: '||to_char(l_dmp_file1.min_snap_id)||'-'||to_char(l_dmp_file1.max_snap_id)||'; ';

    l_scr := replace(l_scr,'~dbid2.',to_char(l_dmp_file2.dbid));
    l_scr := replace(l_scr,'~start_snap2.',to_char(l_dmp_file2.min_snap_id));
    l_scr := replace(l_scr,'~end_snap2.',to_char(l_dmp_file2.max_snap_id));

    l_displ_params:=l_dmp_file1.dump_name||' - '||l_dmp_file2.dump_name||'; '||l_displ_params||'DB2: '||to_char(l_dmp_file2.dbid)||'; snaps: '||to_char(l_dmp_file2.min_snap_id)||'-'||to_char(l_dmp_file2.max_snap_id)||'; ';

    if l_dmp_file1.is_remote='YES' then
      l_scr := replace(l_scr,'~dblnk.','@'||COREMOD_API.getconf('DBLINK',AWRWH_API.gMODNAME));
      l_displ_params:=l_displ_params||'DB link: '||COREMOD_API.getconf('DBLINK',AWRWH_API.gMODNAME)||'; ';
    else
      l_scr := replace(l_scr,'~dblnk.',null);
    end if;

    select sparse1 into l_fn_suff from opas_dictionary where modname = AWRWH_API.gMODNAME and dic_name = 'AWRCOMP_SORTORDR' and val = COREMOD_REPORT_UTILS.get_reppar_n(p_report_id,'SORT');

    l_scr := replace(l_scr,'~sortcol.',COREMOD_REPORT_UTILS.get_reppar_n(p_report_id,'SORT'));
    l_scr := replace(l_scr,'~filter.',COREMOD_REPORT_UTILS.get_reppar_n(p_report_id,'FILTER'));
    l_scr := replace(l_scr,'~sortlimit.',COREMOD_REPORT_UTILS.get_reppar_n(p_report_id,'SORTLIMIT'));
    l_scr := replace(l_scr,'~embeded.','FALSE');
/*
    if l_dn1 is not null then
      l_scr := replace(l_scr,q'[l_text:=l_text||'DB1:'||chr(10);]',q'[l_text:=l_text||'DB1: ]'||l_dn1||q'['||chr(10);]');
    end if;
    if l_dn2 is not null then
      l_scr := replace(l_scr,q'[l_text:=l_text||'DB2:'||chr(10);]',q'[l_text:=l_text||'DB2: ]'||l_dn2||q'['||chr(10);]');
    end if;

    l_report_params_displ:=l_report_params_displ||'SORT: '||l_sort||'; ';
    l_report_params_displ:=l_report_params_displ||'FILTER: '||get_param(p_report_id,'FILTER')||'; ';
    l_report_params_displ:=l_report_params_displ||'LIMIT: '||get_param(p_report_id,'LIMIT');
    set_filename_and_param_displ(p_report_id,l_file_prefix||l_filename, l_report_params_displ);
*/

    l_file_type := 'AWR Comparison report';
    l_file_name := 'opas_awrcomp_'||l_fn_suff||'.html';
    l_mime := 'HTML';
    --l_displ_params := 'SQL_ID: '||get_reppar_c(p_report_id,gparSQLID)||'; DBLINK: '||get_reppar_c(p_report_id,gparDBLINK);

    l_file := COREFILE_API.create_file(P_MODNAME => AWRWH_API.gMODNAME,
                                       P_FILE_TYPE => l_file_type,
                                       P_FILE_NAME => l_file_name,
                                       P_MIMETYPE => l_mime,
                                       P_OWNER => COREMOD_REPORT_UTILS.get_reppar_n(p_report_id,'OWNER'));

    COREFILE_API.get_locator(l_file,l_file_content);

    execute immediate q'[ALTER SESSION SET NLS_NUMERIC_CHARACTERS = '.,']';
    execute immediate l_scr;

    loop
      DBMS_OUTPUT.GET_LINE (
        line   => l_line,
        status => l_status);
      exit when l_status=1;
      l_file_content:=l_file_content||l_line||chr(10);
    end loop;

    COREFILE_API.store_content(l_file,l_file_content);
    COREMOD_REPORT_UTILS.save_report_for_download (P_FILE => l_file) ;

    --update opas_reports set report_content = l_file, report_params_displ=l_displ_params where report_id=p_report_id;

    commit;

  end;

--  =============================================================================================================================================
--  =============================================================================================================================================
--  =============================================================================================================================================

  procedure edit_report_properties(p_report_id          awrwh_reports.report_id%type,
                                   p_report_retention   awrwh_reports.report_retention%type,
                                   p_report_note        awrwh_reports.report_note%type)
  is
  begin
    update awrwh_reports set
      report_retention = decode(p_report_retention,-1,null,p_report_retention),
      report_note = p_report_note
     where report_id = p_report_id;
  end;

  procedure delete_report(p_proj_id            awrwh_reports.proj_id%type,
                          p_report_id          awrwh_reports.report_id%type)
  is
  begin
    coremod_report_utils.drop_report(p_report_id);
    delete from awrwh_reports where report_id=p_report_id and proj_id=p_proj_id;
  end;
END AWRWH_REPORT_API;
/
