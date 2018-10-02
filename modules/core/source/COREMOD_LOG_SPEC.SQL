package COREMOD_LOG is
  -- INFO
  -- DEBUG
  procedure log(p_msg clob, p_loglevel varchar2 default 'INFO');
  procedure cleanup_logs;

  procedure Start_SQL_GATHER_STAT(p_name varchar2);
  procedure Stop_SQL_GATHER_STAT(p_name varchar2);

  procedure Start_SQL_TRACE(p_name varchar2);
  procedure Stop_SQL_TRACE(p_name varchar2);

  function bool2str(p_bool boolean) return varchar2;
end;
/
