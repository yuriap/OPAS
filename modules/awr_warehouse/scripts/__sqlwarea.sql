column CHLD# format 999
column POLICY format a10
column OPER format 999
column OPERATION format a30 word_wrap
column LST_EXE format a10
column LST_DEGREE format 999
column TOT_EXE format 999g999g999
column OPT_EXE format 999g999g999
column ONEP_EXE format 999g999g999
column MULT_EXE format 999g999g999

BREAK on inst_id ON CHLD# on policy

select inst_id,
       child_number "CHLD#",
       policy,
       operation_id "OPER",
       operation_type "OPERATION",
       estimated_optimal_size "EST_OPTIM",
       estimated_onepass_size "EST_ONEPA",
       last_memory_used "MEM_USED",
       last_execution "LST_EXE",
       last_degree "LST_DEGREE",
       total_executions "TOT_EXE",
       optimal_executions "OPT_EXE",
       onepass_executions "ONEP_EXE",
       multipasses_executions "MULT_EXE",
       active_time "ACTIVE_TIM",
       max_tempseg_size "MAX_TMP",
       last_tempseg_size "LAST_TMP"
  from gv$sql_workarea
 where sql_id = '&1'
 order by inst_id, child_number, operation_id;

