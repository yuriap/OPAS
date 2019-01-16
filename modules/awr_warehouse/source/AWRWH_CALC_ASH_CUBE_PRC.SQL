CREATE OR REPLACE
procedure AWRWH_CALC_ASH_CUBE(p_dump_id awrwh_dumps.dump_id%type, p_ash_proj_id number)
is
    l_dmp_file         awrwh_dumps%rowtype;
    l_sess_id          number;
    l_tmpl_id          number;
    l_tq_id          number;
begin
--can be invalid because it references ASH Analyzer module
    l_dmp_file:=AWRWH_FILE_API.get_file(p_dump_id,false);

    select tmpl_id into l_tmpl_id from ASHA_CUBE_SESS_TMPL where TMPL_BASE='Y';
    ASHA_CUBE_PKG.init_session   (  P_PROJ_ID => p_ash_proj_id, P_RETENTION => null, P_SESS_ID => l_sess_id) ;
    commit;
    ASHA_CUBE_PKG.load_par_tmpl  ( p_tmpl_id => l_tmpl_id, P_SESS_ID => l_sess_id) ;

    ASHA_CUBE_PKG.add_parameter  ( l_sess_id, ASHA_CUBE_PKG.c_dblink,    '$LOCAL$') ;
    ASHA_CUBE_PKG.add_parameter  ( l_sess_id, ASHA_CUBE_PKG.c_dump_id,   p_dump_id) ;
    ASHA_CUBE_PKG.add_parameter  ( l_sess_id, ASHA_CUBE_PKG.c_source,    'AWR');
    ASHA_CUBE_PKG.add_parameter  ( l_sess_id, ASHA_CUBE_PKG.c_start_dt,  to_char(l_dmp_file.min_snap_dt,ASHA_CUBE_PKG.c_datetime_fmt));
    ASHA_CUBE_PKG.add_parameter  ( l_sess_id, ASHA_CUBE_PKG.c_end_dt,    to_char(l_dmp_file.max_snap_dt,ASHA_CUBE_PKG.c_datetime_fmt));

    ASHA_CUBE_PKG.add_parameter  ( l_sess_id, ASHA_CUBE_PKG.c_DBID,      l_dmp_file.dbid);
    ASHA_CUBE_PKG.add_parameter  ( l_sess_id, ASHA_CUBE_PKG.c_START_SNAP,l_dmp_file.min_snap_id);
    ASHA_CUBE_PKG.add_parameter  ( l_sess_id, ASHA_CUBE_PKG.c_END_SNAP,  l_dmp_file.max_snap_id);

    COREMOD_INTEGRATION.create_integration (
        P_INT_KEY => AWRWH_API.gintAWRWH2ASH_DUMP2CUBE,
        P_SRC_ENTITY_ID => l_dmp_file.dump_id,
        P_SRC_PRNT_ENTITY_ID => l_dmp_file.proj_id,
        P_TRG_ENTITY_ID => l_sess_id,
        P_TRG_PRNT_ENTITY_ID => p_ash_proj_id) ;

    ASHA_CUBE_PKG.queue_load_cube( l_sess_id, l_tq_id);
    commit;
end;
/
