declare
procedure lock_stats(p_table_name varchar2) is
begin
  DBMS_STATS.LOCK_TABLE_STATS(OWNNAME=> user, TABNAME=> p_table_name);
end;
begin
  lock_stats('ASHA_CUBE');
  lock_stats('ASHA_CUBE_SEG');
  lock_stats('ASHA_CUBE_SESS');
  lock_stats('ASHA_CUBE_TIMELINE');
  lock_stats('ASHA_CUBE_UNKNOWN');
  lock_stats('ASHA_CUBE_BLOCK');
  lock_stats('ASHA_CUBE_METRICS');
end;
/