BREAK on inst_id ON child_number
column name format a40

select inst_id,child_number,name,isdefault,value from gv$sql_optimizer_env where sql_id='&1.' order by inst_id,child_number,name;