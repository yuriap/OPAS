package coremod_tasks as

  procedure cleanup_tasks;

  procedure create_task(p_taskname   opas_task.taskname%type,
                        p_modname    opas_task.modname%type,
                        p_is_public  opas_task.is_public%type default 'Y',
                        p_task_body  opas_task.task_body%type);
  procedure drop_task(p_taskname opas_task.taskname%type);

  function prep_execute_task(p_taskname opas_task.taskname%type) return opas_task_queue.tq_id%type;
  procedure queue_task(p_tq_id opas_task_queue.tq_id%type);

  procedure set_task_param(p_tq_id opas_task_queue.tq_id%type, p_name opas_task_pars.par_name%type, p_num_par number);
  procedure set_task_param(p_tq_id opas_task_queue.tq_id%type, p_name opas_task_pars.par_name%type, p_varchar_par varchar2);
  procedure set_task_param(p_tq_id opas_task_queue.tq_id%type, p_name opas_task_pars.par_name%type, p_date_par date);

  procedure create_task_job;
  procedure execute_task_proc; --job coord proc
  procedure execute_task(p_tq_id opas_task_queue.tq_id%type);

  procedure log(p_msg opas_log.msg%type, p_tq_id opas_task_queue.tq_id%type default null);

end;
/