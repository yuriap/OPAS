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
    l_level varchar2(100):=COREMOD_API.getconf('LOGGING_LEVEL');
  begin
    if (l_level='INFO' and p_loglevel='INFO') or
       (l_level='DEBUG' and p_loglevel in ('INFO', 'DEBUG'))
    then
      insert into opas_log values (default, p_msg);
      commit;
    end if;
  end;

  procedure cleanup_logs
  is
  begin
    delete from opas_log where ts < sysdate-to_number(COREMOD_API.getconf('LOGS_EXPIRE_TIME'));
    dbms_output.put_line('Deleted '||sql%rowcount||' log row(s).');
    commit;
  exception
    when others then rollback;dbms_output.put_line(sqlerrm);
  end;
  
  procedure Start_SQL_GATHER_STAT(p_name varchar2)
  is
  begin
    if nvl(coremod_api.getconf('INSTR_SQL_GATHER_STAT'),'~^') = p_name then
      execute immediate 'alter session set statistics_level=all';
    end if;
  end;
  
  procedure Stop_SQL_GATHER_STAT(p_name varchar2)
  is
  begin
    if nvl(coremod_api.getconf('INSTR_SQL_GATHER_STAT'),'~^') = p_name then
      execute immediate 'alter session set statistics_level=TYPICAL';
    end if;
  end;  
  
  procedure Start_SQL_TRACE(p_name varchar2)
  is
  begin
    if nvl(coremod_api.getconf('INSTR_SQL_TRACE'),'~^') = p_name then
      execute immediate q'[alter session set events '10046 trace name context forever, level ]'||nvl(coremod_api.getconf('INSTR_SQL_TRACE'),12)||q'[']';
    end if;
  end;  
  procedure Stop_SQL_TRACE(p_name varchar2)
  is
  begin
    if nvl(coremod_api.getconf('INSTR_SQL_TRACE'),'~^') = p_name then
      execute immediate q'[alter session set events '10046 trace name context off']';
    end if;
  end;    
end;
/

--------------------------------------------------------
show errors
--------------------------------------------------------