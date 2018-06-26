create or replace package coremod_purge as

  procedure create_purge_job;
  procedure register_entity;
  procedure purge_job_proc;
  
end;
/

--------------------------------------------------------
show errors
--------------------------------------------------------

create or replace package body coremod_purge as

  procedure create_purge_job is
  begin
    dbms_scheduler.create_job(job_name => 'OPAS_PURGE_JOB',
                              job_type => 'PLSQL_BLOCK',
                              job_action => 'begin coremod_purge.purge_job_proc; end;',
                              start_date => trunc(systimestamp,'hh'),
                              repeat_interval => 'FREQ=MINUTELY; INTERVAL=15',
                              enabled => true);
  end;

  procedure register_entity is
  begin
    null;
  end;

  procedure purge_job_proc is
  begin
    for i in (select taskname from opas_task where task_type=COREMOD_TASKS.cttPURGE)
    loop
      COREMOD_TASKS.execute_task(i.taskname);
    end loop;
  end;

end;
/

--------------------------------------------------------
show errors
--------------------------------------------------------