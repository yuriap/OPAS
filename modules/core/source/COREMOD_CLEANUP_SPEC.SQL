package coremod_cleanup as

  procedure create_cleanup_job;
  procedure cleanup_job_proc;

  procedure register_cleanup_tasks(p_taskname   opas_cleanup_tasks.taskname%type,
                                   p_modname    opas_cleanup_tasks.modname%type,
                                   p_task_body  opas_cleanup_tasks.task_body%type);

end;
/
