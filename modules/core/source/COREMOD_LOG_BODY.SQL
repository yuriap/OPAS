CREATE OR REPLACE
package body COREMOD_LOG is

  g_user_expirience_id varchar2(100);

  procedure debug_on
  is
  begin
    UPDATE opas_config
    SET    cvalue = 'DEBUG'
    WHERE
    modname = COREMOD_API.gMODNAME
    AND cgroup = 'LOGGING'
    AND ckey = 'LOGGING_LEVEL';
  end;

  procedure debug_off
  is
  begin
    UPDATE opas_config
    SET    cvalue = 'INFO'
    WHERE
    modname = COREMOD_API.gMODNAME
    AND cgroup = 'LOGGING'
    AND ckey = 'LOGGING_LEVEL';
  end;

  function bool2str(p_bool boolean) return varchar2
  is
  begin
    if p_bool is not null then
      if p_bool then return 'TRUE'; else return 'FALSE'; end if;
    else
      return 'NULL';
    end if;
  end;

  procedure log(p_msg clob, p_loglevel varchar2 default 'INFO')
  is
    l_level varchar2(100):=COREMOD_API.getconf('LOGGING_LEVEL',COREMOD_API.gMODNAME);
  begin
    if (l_level='INFO' and p_loglevel='INFO') or
       (l_level='DEBUG' and p_loglevel in ('INFO', 'DEBUG'))
    then
      coremod_tasks.log(p_msg);
    end if;
  end;

  procedure cleanup_logs
  is
    l_rows_processed number;
  begin
    delete from opas_log where created < sysdate-to_number(COREMOD_API.getconf('LOGRETENTION',COREMOD_API.gMODNAME));
    l_rows_processed:=sql%rowcount;
    commit;
    coremod_log.log('Cleanup logs: deleted '||l_rows_processed||' log row(s).');
  end;

  procedure Start_SQL_GATHER_STAT(p_name varchar2)
  is
  begin
    if nvl(coremod_api.getconf('INSTR_SQL_GATHER_STAT',COREMOD_API.gMODNAME),'~^') = p_name then
      execute immediate 'alter session set statistics_level=all';
      coremod_log.log('Start_SQL_GATHER_STAT: '||coremod_api.getconf('INSTR_SQL_GATHER_STAT',COREMOD_API.gMODNAME));
    end if;
  end;

  procedure Stop_SQL_GATHER_STAT(p_name varchar2)
  is
  begin
    if nvl(coremod_api.getconf('INSTR_SQL_GATHER_STAT',COREMOD_API.gMODNAME),'~^') = p_name then
      execute immediate 'alter session set statistics_level=TYPICAL';
      coremod_log.log('Stop_SQL_GATHER_STAT: '||coremod_api.getconf('INSTR_SQL_GATHER_STAT',COREMOD_API.gMODNAME));
    end if;
  end;

  procedure Start_SQL_TRACE(p_name varchar2)
  is
    l_trc_file varchar(4000);
  begin
    if nvl(coremod_api.getconf('INSTR_SQL_TRACE',COREMOD_API.gMODNAME),'~^') = p_name then
      select value into l_trc_file from v$diag_info where name = 'Default Trace File';
      g_user_expirience_id := sys_guid();
      coremod_log.log('Start_SQL_TRACE: '||coremod_api.getconf('INSTR_SQL_TRACE',COREMOD_API.gMODNAME)||'; EXPIRIENCE ID: '||nvl(g_user_expirience_id,'N/A'));
      coremod_log.log('Trace file: '||l_trc_file);
      execute immediate q'[begin DBMS_SESSION.SESSION_TRACE_ENABLE(]'||nvl(coremod_api.getconf('INSTR_SQL_TRACE_PARAMS',COREMOD_API.gMODNAME),q'[TRUE,TRUE,'FIRST_EXECUTION']')||q'[); end;]';
      dbms_log.ksdwrt(1, '*** EXPERIENCE ID:('||g_user_expirience_id||'-'||p_name||'-START)');
    end if;
  end;

  procedure Stop_SQL_TRACE(p_name varchar2)
  is
  begin
    if nvl(coremod_api.getconf('INSTR_SQL_TRACE',COREMOD_API.gMODNAME),'~^') = p_name then
      dbms_log.ksdwrt(1, '*** EXPERIENCE ID:('||nvl(g_user_expirience_id,'N/A')||'-'||p_name||'-END)');
      DBMS_SESSION.SESSION_TRACE_DISABLE;
      coremod_log.log('Stop_SQL_TRACE: '||coremod_api.getconf('INSTR_SQL_TRACE',COREMOD_API.gMODNAME)||'; EXPIRIENCE ID: '||nvl(g_user_expirience_id,'N/A'));
    end if;
  end;

end;
/
