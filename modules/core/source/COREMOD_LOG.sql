create or replace package COREMOD_LOG is
  -- INFO
  -- DEBUG
  procedure log(p_msg clob, p_loglevel varchar2 default 'INFO');
  procedure cleanup;
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
  
  procedure cleanup
  is
  begin
    delete from opas_log where ts < sysdate-to_number(COREMOD_API.getconf('LOGS_EXPIRE_TIME'));
    dbms_output.put_line('Deleted '||sql%rowcount||' log row(s).');
    commit;
  exception
    when others then rollback;dbms_output.put_line(sqlerrm);
  end;
end;
/

--------------------------------------------------------
show errors
--------------------------------------------------------