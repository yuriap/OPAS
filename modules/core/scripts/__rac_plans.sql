BREAK on inst_id ON CH#

column INST format 999
column CH# format 999
column plan_table_output format a300
select i.inst_id "INST",i.CHILD_NUMBER CH#,y.plan_table_output
  from gv$sql i,
       table(dbms_xplan.display('gv$sql_plan_statistics_all',
                                null,
                                'LAST ALLSTATS +peeked_binds',
                                'inst_id=' || i.inst_id || ' and sql_id=''' ||
                                i.sql_id || ''' and CHILD_NUMBER=' ||
                                i.CHILD_NUMBER)) y
 where sql_id = '&SQLID'
;