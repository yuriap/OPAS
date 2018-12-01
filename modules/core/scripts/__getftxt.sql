set long 10000000
set pages 9999
column "Full query text" format a300 word_wrapped
select sql_fulltext "Full query text"
  from (select sql_fulltext
          from gv$sql
         where sql_id = '&1'
        union all
        select sql_fulltext
          from gv$sqlarea
         where sql_id = '&1'
        union all
        select sql_fulltext from gv$sqlstats where sql_id = '&1')
 where rownum = 1;
