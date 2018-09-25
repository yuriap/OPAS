create or replace package coremod_tasks as

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

end;
/

--------------------------------------------------------
show errors
--------------------------------------------------------

create or replace package body coremod_tasks as

  g_time number;
  g_cpu_tim number;

  gtqNEW       constant varchar2(10):='NEW';
  gtqQUEUED    constant varchar2(10):='QUEUED';
  gtqSTARTED   constant varchar2(10):='STARTED';
  gtqRUNNING   constant varchar2(10):='RUNNING';
  gtqSUCCEEDED constant varchar2(10):='SUCCEEDED';
  gtqFAILED    constant varchar2(10):='FAILED';

  gJOBNMPREF   constant varchar2(10):='OPASTASK';

  procedure log(p_msg opas_log.msg%type, p_tq_id opas_task_queue.tq_id%type default null)
  is
    PRAGMA AUTONOMOUS_TRANSACTION;
  begin
    insert into opas_log (created, msg, tq_id) values (default, p_msg, p_tq_id);
    commit;
  end;

  procedure cleanup_tasks is
    l_rows_processed number;  
  begin
    delete from opas_task_queue where systimestamp - finished > TO_DSINTERVAL(COREMOD_API.getconf('TASKRETENTION',COREMOD_API.gCOREMOD)||' 00:00:00');
    l_rows_processed:=sql%rowcount;
    commit;
    coremod_log.log('Cleanup task queue: deleted '||l_rows_processed||' row(s).');
  end;


  procedure create_task(p_taskname   opas_task.taskname%type,
                        p_modname    opas_task.modname%type,
                        p_is_public  opas_task.is_public%type default 'Y',
                        p_task_body  opas_task.task_body%type)
  is
  begin
    INSERT INTO opas_task (taskname, modname, is_public, created, task_body)
                   VALUES (upper(p_taskname),p_modname,p_is_public,default,p_task_body);
  end;


  function prep_execute_task(p_taskname opas_task.taskname%type) return opas_task_queue.tq_id%type
  is
    l_tq_id opas_task_queue.tq_id%type;
  begin
    INSERT INTO opas_task_queue (taskname, owner, status) VALUES (p_taskname, nvl(V('APP_USER'),'PUBLIC'), gtqNEW) returning tq_id into l_tq_id;
    return l_tq_id;
  end;

  procedure set_task_param(p_tq_id opas_task_queue.tq_id%type, p_name opas_task_pars.par_name%type, p_num_par number)
  is
  begin
    merge into OPAS_TASK_PARS t using (select p_tq_id id, p_name nm, p_num_par val from dual) s
    on (t.tq_id = s.id and t.par_name=s.nm)
    when matched then update set num_par = s.val
    when not matched then insert (tq_id,par_name,num_par) values (s.id, s.nm, s.val);
  end;

  procedure set_task_param(p_tq_id opas_task_queue.tq_id%type, p_name opas_task_pars.par_name%type, p_varchar_par varchar2)
  is
  begin
    merge into OPAS_TASK_PARS t using (select p_tq_id id, p_name nm, p_varchar_par val from dual) s
    on (t.tq_id = s.id and t.par_name=s.nm)
    when matched then update set varchar_par = s.val
    when not matched then insert (tq_id,par_name,varchar_par) values (s.id, s.nm, s.val);
  end;

  procedure set_task_param(p_tq_id opas_task_queue.tq_id%type, p_name opas_task_pars.par_name%type, p_date_par date)
  is
  begin
    merge into OPAS_TASK_PARS t using (select p_tq_id id, p_name nm, p_date_par val from dual) s
    on (t.tq_id = s.id and t.par_name=s.nm)
    when matched then update set date_par = s.val
    when not matched then insert (tq_id,par_name,date_par) values (s.id, s.nm, s.val);
  end;

  procedure queue_task(p_tq_id opas_task_queue.tq_id%type)
  is
  begin
    update opas_task_queue set status=gtqQUEUED, queued=systimestamp where tq_id = p_tq_id;
  end;

  procedure set_task_started(p_tq_id opas_task_queue.tq_id%type)
  is
  begin
    update opas_task_queue set status=gtqSTARTED where tq_id = p_tq_id;
  end;

  procedure set_task_running(p_tq_id opas_task_queue.tq_id%type)
  is
    PRAGMA AUTONOMOUS_TRANSACTION;
  begin
    g_time:=DBMS_UTILITY.GET_TIME;
    g_cpu_tim:=DBMS_UTILITY.GET_CPU_TIME;
    update opas_task_queue set
           started=systimestamp,
           sid=SYS_CONTEXT('USERENV','SID'),
           serial#=(select serial# from gv$session where sid=SYS_CONTEXT('USERENV','SID') and inst_id=SYS_CONTEXT('USERENV','INSTANCE')),
           inst_id=SYS_CONTEXT('USERENV','INSTANCE'),
           status=gtqRUNNING
     where tq_id=p_tq_id;
    commit;
  end;
  procedure set_task_finished(p_tq_id opas_task_queue.tq_id%type, p_status opas_task_queue.status%type)
  is
    PRAGMA AUTONOMOUS_TRANSACTION;
  begin
      g_time:=DBMS_UTILITY.GET_TIME-g_time;
      g_cpu_tim:=DBMS_UTILITY.GET_CPU_TIME-g_cpu_tim;
      update opas_task_queue set
             finished=systimestamp,
             cpu_time=g_cpu_tim/100,
             elapsed_time=g_time/100,
             status=p_status
       where tq_id=p_tq_id;
    commit;
  end;

  procedure execute_task_proc is  --job coordinator
    l_running_jobs number;
    l_freeslots    number;
    type t_task_tbl is table of opas_task_queue%rowtype;
    l_tasks   t_task_tbl;
    l_2run    t_task_tbl := t_task_tbl();
  begin
    select count(1) into l_running_jobs from USER_SCHEDULER_RUNNING_JOBS where job_name like gJOBNMPREF||'%';
    if l_running_jobs < to_number(COREMOD_API.getconf('MAXTHREADS',COREMOD_API.gCOREMOD)) then
      l_freeslots:= to_number(COREMOD_API.getconf('MAXTHREADS',COREMOD_API.gCOREMOD)) - l_running_jobs;
      select * bulk collect into l_tasks from opas_task_queue where status=gtqQUEUED for update skip locked order by queued;
      for i in 1..least(l_freeslots,l_tasks.count) loop
        l_2run.extend;
        l_2run(l_2run.count):=l_tasks(i);
        set_task_started(l_tasks(i).tq_id);
      end loop;
    end if;
    
    commit;
    
    for i in 1..l_2run.count 
    loop
      begin
        dbms_scheduler.create_job(job_name => gJOBNMPREF||'_'||upper(l_2run(i).taskname)||'_'||to_char(systimestamp,'FF6'),
                                  job_type => 'PLSQL_BLOCK',
                                  job_action => 'begin coremod_tasks.execute_task('||l_2run(i).tq_id||'); end;',
                                  start_date => systimestamp,
                                  enabled => true,
                                  auto_drop=> true);
      exception
        when others then
          log('Execute task error: '||sqlerrm,l_2run(i).tq_id);
          log(DBMS_UTILITY.FORMAT_ERROR_STACK,l_2run(i).tq_id);
          log(DBMS_UTILITY.FORMAT_ERROR_BACKTRACE,l_2run(i).tq_id);
      end;
    end loop;
  end;

  procedure create_task_job is
  begin
    dbms_scheduler.create_program(
                              program_name             => 'OPAS_TASK_COORD_PRG',
                              program_type             => 'PLSQL_BLOCK',
                              program_action           => 'begin coremod_tasks.execute_task_proc; end;',
                              enabled                  => true,
                              comments                 => 'OPAS Task job coordinator program');  
    dbms_scheduler.create_job(job_name                 => 'OPAS_TASK_COORD',
                              program_name             => 'OPAS_TASK_COORD_PRG',
                              start_date               => trunc(systimestamp,'mi'),
                              repeat_interval          => 'FREQ=SECONDLY; INTERVAL=10',
                              job_style                => 'LIGHTWEIGHT',
                              job_class                => 'OPASLIGHTJOBS',
                              enabled                  => true);
  end;

  procedure execute_task(p_tq_id opas_task_queue.tq_id%type)
  is
    l_task opas_task%rowtype;
    l_task_body clob;
  begin
    set_task_running(p_tq_id);
    select * into l_task from opas_task where taskname=(select taskname from opas_task_queue where tq_id = p_tq_id);
    l_task_body:=l_task.task_body;
    for i in (select * from opas_task_pars where tq_id = p_tq_id) loop
      case
        when i.num_par is not null then
          l_task_body:=replace(l_task_body,'<'||i.par_name||'>',i.num_par);
        when i.varchar_par is not null then
          l_task_body:=replace(l_task_body,'<'||i.par_name||'>',q'[']'||i.varchar_par||q'[']');
        when i.date_par is not null then
          raise_application_error(-20000,'Not implemented parameter type: DATE');
      end case;
    end loop;
    execute immediate l_task_body;
    set_task_finished(p_tq_id,gtqSUCCEEDED);
  exception
    when others then
      set_task_finished(p_tq_id,gtqFAILED);
      log('Execute task error: '||sqlerrm,p_tq_id);
      log(DBMS_UTILITY.FORMAT_ERROR_STACK,p_tq_id);
      log(DBMS_UTILITY.FORMAT_ERROR_BACKTRACE,p_tq_id);
      raise_application_error(-20000, 'Execute task error: '||sqlerrm);
  end;


  procedure drop_task(p_taskname opas_task.taskname%type) is
  begin
    delete from opas_task where taskname=upper(p_taskname);
    commit;
  end;

end;
/

--------------------------------------------------------
show errors
--------------------------------------------------------