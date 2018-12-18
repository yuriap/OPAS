CREATE OR REPLACE
PACKAGE BODY AWRWH_REPORT_API AS

  procedure create_report_awrrpt(p_proj_id      awrwh_reports.proj_id%type,
                                 p_dbid         number,
                                 p_min_snap     number,
                                 p_max_snap     number,
                                 p_instance_num number default 1)
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
                                                       P_INSTANCE_NUM => P_INSTANCE_NUM);

    INSERT INTO awrwh_reports (proj_id,report_id,dump_id,dump_id_2,report_retention,report_note,created)
                       VALUES (p_proj_id,l_report_id,null,null,default,null,systimestamp);

    commit;
  end;

  procedure create_report_awrrpt(p_proj_id      awrwh_reports.proj_id%type,
                                 p_dump_id      awrwh_dumps.dump_id%type)
  is
  begin
    for i in (select * from awrwh_dumps where dump_id=p_dump_id and status in (AWRWH_FILE_LCC.c_dmpfilestate_awrloaded, AWRWH_FILE_LCC.c_dmpfilestate_compressed)) loop
      for j in (select * from dba_hist_snapshot where dbid=i.dbid and snap_id between i.min_snap_id and i.max_snap_id) loop
        create_report_awrrpt(p_proj_id,i.dbid,i.min_snap_id,i.max_snap_id, j.instance_number);
      end loop;
    end loop;
  end;

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
