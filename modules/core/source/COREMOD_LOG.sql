create or replace package COREMOD_LOG is
  -- INFO
  -- DEBUG
  procedure log(p_msg clob, p_loglevel varchar2 default 'INFO');
  procedure cleanup_logs;
  
  procedure Start_SQL_GATHER_STAT(p_name varchar2);
  procedure Stop_SQL_GATHER_STAT(p_name varchar2);
  
  procedure Start_SQL_TRACE(p_name varchar2);
  procedure Stop_SQL_TRACE(p_name varchar2);
  
end;
/

--------------------------------------------------------
show errors
--------------------------------------------------------

create or replace package body COREMOD_LOG is

  procedure log(p_msg clob, p_loglevel varchar2 default 'INFO')
  is
    PRAGMA AUTONOMOUS_TRANSACTION;
    l_level varchar2(100):=COREMOD_API.getconf('LOGGING_LEVEL',COREMOD_API.gCOREMOD);
  begin
    if (l_level='INFO' and p_loglevel='INFO') or
       (l_level='DEBUG' and p_loglevel in ('INFO', 'DEBUG'))
    then
      insert into opas_log (created, msg, tq_id) values (default, p_msg, null);
      commit;
    end if;
  end;

  procedure cleanup_logs
  is
    l_rows_processed number;
  begin
    delete from opas_log where created < sysdate-to_number(COREMOD_API.getconf('LOGRETENTION',COREMOD_API.gCOREMOD));
    l_rows_processed:=sql%rowcount;
    commit;
    coremod_log.log('Cleanup logs: deleted '||l_rows_processed||' log row(s).');
  end;
  
  procedure Start_SQL_GATHER_STAT(p_name varchar2)
  is
  begin
    if nvl(coremod_api.getconf('INSTR_SQL_GATHER_STAT',COREMOD_API.gCOREMOD),'~^') = p_name then
      execute immediate 'alter session set statistics_level=all';
    end if;
  end;
  
  procedure Stop_SQL_GATHER_STAT(p_name varchar2)
  is
  begin
    if nvl(coremod_api.getconf('INSTR_SQL_GATHER_STAT',COREMOD_API.gCOREMOD),'~^') = p_name then
      execute immediate 'alter session set statistics_level=TYPICAL';
    end if;
  end;  
  
  procedure Start_SQL_TRACE(p_name varchar2)
  is
  begin
    if nvl(coremod_api.getconf('INSTR_SQL_TRACE',COREMOD_API.gCOREMOD),'~^') = p_name then
      execute immediate q'[alter session set events '10046 trace name context forever, level ]'||nvl(coremod_api.getconf('INSTR_SQL_TRACE',COREMOD_API.gCOREMOD),12)||q'[']';
    end if;
  end;  
  procedure Stop_SQL_TRACE(p_name varchar2)
  is
  begin
    if nvl(coremod_api.getconf('INSTR_SQL_TRACE',COREMOD_API.gCOREMOD),'~^') = p_name then
      execute immediate q'[alter session set events '10046 trace name context off']';
    end if;
  end;    
end;
/

--------------------------------------------------------
show errors
--------------------------------------------------------