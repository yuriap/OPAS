alter table asha_cube_metrics add (inst_id number, group_id number, aggfnc varchar2(10));


declare
  l_inst number;
  l_grp number;
  l_mid number;
  l_agg varchar2(100);
  l_metric_tab ASHA_CUBE_PKG.tt_metric_tab;
  l_params ASHA_CUBE_PKG.tt_params_t;
begin
  for i in (select unique sess_id from asha_cube_metrics where inst_id is null)
  loop
    l_metric_tab:=ASHA_CUBE_PKG.get_metric_tab(i.sess_id);
    l_params:=ASHA_CUBE_PKG.get_sess_pars(i.sess_id);
    
    l_inst := l_params(ASHA_CUBE_PKG.c_inst_id);
    if l_inst = -1 then l_inst := 1; end if;
    
    if l_metric_tab.count=0 then
      l_grp:=l_params(ASHA_CUBE_PKG.c_metricgroup_id);
      l_mid:=l_params(ASHA_CUBE_PKG.c_metric_id);
      l_agg:=l_params(ASHA_CUBE_PKG.c_metricagg);  
      update asha_cube_metrics set
        inst_id=l_inst,group_id=l_grp, aggfnc=l_agg
       where sess_id=i.sess_id and metric_id=l_mid;
    else
      l_grp:=l_metric_tab(1).pa_metricgroup_id;
      l_mid:=l_metric_tab(1).pa_metric_id;
      l_agg:=l_metric_tab(1).pa_metricagg;
      update asha_cube_metrics set
        inst_id=l_inst,group_id=l_grp, aggfnc=l_agg
       where sess_id=i.sess_id and metric_id=l_mid;
      if l_metric_tab.exists(2) then
        l_grp:=l_metric_tab(2).pa_metricgroup_id;
        l_mid:=l_metric_tab(2).pa_metric_id;
        l_agg:=l_metric_tab(2).pa_metricagg;    
        update asha_cube_metrics set
          inst_id=l_inst,group_id=l_grp, aggfnc=l_agg
         where sess_id=i.sess_id and metric_id=l_mid;
      end if;
      if l_metric_tab.exists(3) then
        l_grp:=l_metric_tab(3).pa_metricgroup_id;
        l_mid:=l_metric_tab(3).pa_metric_id;
        l_agg:=l_metric_tab(3).pa_metricagg;    
        update asha_cube_metrics set
          inst_id=l_inst,group_id=l_grp, aggfnc=l_agg
         where sess_id=i.sess_id and metric_id=l_mid;
      end if;    
    end if;
  end loop;
end;
/