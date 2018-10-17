begin
  for t in (select table_name from user_tables where table_name='OPAS_STAT_BACKUP') loop
    execute immediate 'drop table '||t.table_name;
  end loop;
  dbms_stats.create_stat_table(user, 'OPAS_STAT_BACKUP');
end;
/
alter session set cursor_sharing=force;
@@cube_stats.sql
commit;
alter session set cursor_sharing=exact;

update OPAS_STAT_BACKUP set 
c5=case when c5 is not null then user else c5 end,
c6=case when c6 is not null then user else c6 end;
commit;
begin
  dbms_stats.import_schema_stats(ownname=>user, stattab => 'OPAS_STAT_BACKUP', statid => 'EXPORT_CUBE_STAT', force=>true);
end;
/

@@lock_cube_stats