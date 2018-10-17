CREATE OR REPLACE
package body coremod_cleanup as

  procedure register_cleanup_tasks(p_taskname   opas_cleanup_tasks.taskname%type,
                                   p_modname    opas_cleanup_tasks.modname%type,
                                   p_task_body  opas_cleanup_tasks.task_body%type)
  is
  begin
    insert into opas_cleanup_tasks ( taskname, modname, created, task_body ) values (p_taskname, p_modname, systimestamp, p_task_body);
  end;

  procedure create_cleanup_job is
  begin
    dbms_scheduler.create_job(job_name => 'OPAS_CLEANUP_JOB',
                              job_type => 'PLSQL_BLOCK',
                              job_action => 'begin coremod_cleanup.cleanup_job_proc; end;',
                              start_date => trunc(systimestamp,'hh'),
                              repeat_interval => 'FREQ=MINUTELY; INTERVAL=15',
                              enabled => true);
  end;


  procedure cleanup_job_proc is
  begin
    for i in (select * from opas_cleanup_tasks)
    loop
      begin
        coremod_log.log('Executing cleanup task: '||i.modname||'.'||i.taskname);
        execute immediate i.task_body;
      exception
        when others then
          rollback;
          coremod_log.log('Cleanup job error ('||i.modname||'.'||i.taskname||'): '||sqlerrm);
          coremod_log.log(DBMS_UTILITY.FORMAT_ERROR_STACK);
          coremod_log.log(DBMS_UTILITY.FORMAT_ERROR_BACKTRACE);
      end;
    end loop;
  end;

end;
/
