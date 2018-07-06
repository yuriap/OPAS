create or replace package coremod_tasks as

  cttSYSTEM constant varchar2(10):='SYSTEM';
  cttPURGE  constant varchar2(10):='PURGE';
  cttPERM   constant varchar2(10):='PERM'; --permanent task
  cttSINGLE constant varchar2(10):='SINGLE'; --single run

  procedure create_task(p_taskname   opas_task.taskname%type,
                        p_modname    opas_task.modname%type,
                        p_owner      opas_task.owner%type default 'PUBLIC',
                        p_task_type  opas_task.task_type%type default cttSINGLE,
                        p_max_thread opas_task.max_thread%type default 1,
                        p_schedule   opas_task.schedule%type default null,
                        p_async opas_task.async%type default 'Y');

  procedure set_task_body(p_taskname opas_task.taskname%type,p_task_body clob);
  
  function prep_execute_task(p_taskname opas_task.taskname%type) return opas_task_exec.texec_id%type;
  
  procedure set_task_param(p_texec_id opas_task_exec.texec_id%type, p_name opas_task_pars.par_name%type, p_num_par number);
  procedure set_task_param(p_texec_id opas_task_exec.texec_id%type, p_name opas_task_pars.par_name%type, p_varchar_par varchar2);
  procedure set_task_param(p_texec_id opas_task_exec.texec_id%type, p_name opas_task_pars.par_name%type, p_date_par date);
  
  procedure execute_task(p_taskname opas_task.taskname%type, p_texec_id opas_task_exec.texec_id%type default null);
  procedure drop_task(p_taskname opas_task.taskname%type);
  procedure purge_old_tasks;

  procedure execute_task(p_texec_id opas_task_exec.texec_id%type);
end;
/

--------------------------------------------------------
show errors
--------------------------------------------------------

create or replace package body coremod_tasks as

  g_time number;
  g_cpu_tim number;
    
  procedure log(p_taskname opas_task.taskname%type, p_msg opas_task_log.msg%type, p_texec_id opas_task_exec.texec_id%type default null)
  is
    PRAGMA AUTONOMOUS_TRANSACTION;
  begin
    insert into opas_task_log (taskname, created, msg, texec_id) values (p_taskname,default, p_msg, p_texec_id);
    commit;
  end;

  procedure create_task(p_taskname   opas_task.taskname%type,
                        p_modname    opas_task.modname%type,
                        p_owner      opas_task.owner%type default 'PUBLIC',
                        p_task_type  opas_task.task_type%type default cttSINGLE,
                        p_max_thread opas_task.max_thread%type default 1,
                        p_schedule   opas_task.schedule%type default null,
                        p_async      opas_task.async%type default 'Y')
  is
  begin
    INSERT INTO opas_task (taskname,modname,owner,task_type,created,status,task_body,max_thread,async,schedule)
                   VALUES (upper(p_taskname),p_modname,p_owner,p_task_type,default,default,null,p_max_thread,p_async,p_schedule);
    commit;
  end;

  procedure set_task_body(p_taskname opas_task.taskname%type,p_task_body clob) is
  begin
    update opas_task set task_body = p_task_body where taskname=upper(p_taskname);
    commit;
  end;

  function prep_execute_task(p_taskname opas_task.taskname%type) return opas_task_exec.texec_id%type
  is
    l_texec_id opas_task_exec.texec_id%type;
  begin
    INSERT INTO opas_task_exec (taskname,owner) VALUES (p_taskname,nvl(V('APP_USER'),'PUBLIC')) returning texec_id into l_texec_id;
    return l_texec_id;
  end;
  
  procedure set_task_param(p_texec_id opas_task_exec.texec_id%type, p_name opas_task_pars.par_name%type, p_num_par number)
  is
  begin
    merge into OPAS_TASK_PARS t using (select p_texec_id id, p_name nm, p_num_par val from dual) s
    on (t.texec_id = s.id and t.par_name=s.nm)
    when matched then update set num_par = s.val
    when not matched then insert (texec_id,par_name,num_par) values (s.id, s.nm, s.val);
  end;
  
  procedure set_task_param(p_texec_id opas_task_exec.texec_id%type, p_name opas_task_pars.par_name%type, p_varchar_par varchar2)
  is
  begin
    merge into OPAS_TASK_PARS t using (select p_texec_id id, p_name nm, p_varchar_par val from dual) s
    on (t.texec_id = s.id and t.par_name=s.nm)
    when matched then update set varchar_par = s.val
    when not matched then insert (texec_id,par_name,varchar_par) values (s.id, s.nm, s.val);
  end;
  
  procedure set_task_param(p_texec_id opas_task_exec.texec_id%type, p_name opas_task_pars.par_name%type, p_date_par date)
  is
  begin
    merge into OPAS_TASK_PARS t using (select p_texec_id id, p_name nm, p_date_par val from dual) s
    on (t.texec_id = s.id and t.par_name=s.nm)
    when matched then update set date_par = s.val
    when not matched then insert (texec_id,par_name,date_par) values (s.id, s.nm, s.val);
  end;
  
  procedure set_exec_status(p_texec_id opas_task_exec.texec_id%type, p_status opas_task_exec.status%type)
  is
    PRAGMA AUTONOMOUS_TRANSACTION;
  begin
    if p_status = 'STARTED' then
      g_time:=DBMS_UTILITY.GET_TIME;
      g_cpu_tim:=DBMS_UTILITY.GET_CPU_TIME;    
      update opas_task_exec set 
             status=p_status,
             started=systimestamp,
             sid=SYS_CONTEXT('USERENV','SID'),
             serial#=(select serial# from v$session where sid=SYS_CONTEXT('USERENV','SID'))
       where texec_id=p_texec_id;
    elsif p_status = 'FINISHED' then
      g_time:=DBMS_UTILITY.GET_TIME-g_time;
      g_cpu_tim:=DBMS_UTILITY.GET_CPU_TIME-g_cpu_tim;   
      update opas_task_exec set 
             status=p_status,
             finished=systimestamp,
             cpu_time=g_cpu_tim/100,
             elapsed_time=g_time/100
       where texec_id=p_texec_id;      
    end if;
    
    update opas_task_exec set status=p_status where texec_id=p_texec_id;
    commit;
  end;

  procedure execute_task(p_taskname opas_task.taskname%type, p_texec_id opas_task_exec.texec_id%type default null) is
    l_task opas_task%rowtype;
    l_running_jobs number;
  begin
    select * into l_task from opas_task where taskname=upper(p_taskname);

    if p_texec_id is null then
      if l_task.task_type=cttPURGE then
        log(p_taskname,'Started: '||upper(p_taskname));
        execute immediate l_task.task_body;
        log(p_taskname,'Finished: '||upper(p_taskname));
      end if;
    else
      if l_task.async = 'Y' then
        select count(1) into l_running_jobs from USER_SCHEDULER_RUNNING_JOBS where job_name like upper(p_taskname)||'%';
        if l_running_jobs < l_task.max_thread then
          dbms_scheduler.create_job(job_name => upper(p_taskname)||'_'||to_char(l_running_jobs+1),
                                    job_type => 'PLSQL_BLOCK',
                                    job_action => 'begin coremod_tasks.execute_task('||p_texec_id||'); end;',
                                    start_date => systimestamp,
                                    enabled => true,
                                    auto_drop=> true);    
          set_exec_status(p_texec_id,'JOB_CREATED');
        else
          set_exec_status(p_texec_id,'JOB_FAILED');
          raise_application_error(-20000,'Maximum thread number reached: '||l_task.max_thread);
      end if;
      else
        raise_application_error(-20000,'Sync exec to be implemented');
      end if;
    end if;
  exception
    when others then
      log(p_taskname,'Execute task error: '||sqlerrm,p_texec_id);
      log(p_taskname,DBMS_UTILITY.FORMAT_ERROR_STACK,p_texec_id);
      log(p_taskname,DBMS_UTILITY.FORMAT_ERROR_BACKTRACE,p_texec_id);
      raise_application_error(-20000, 'Execute task error: '||sqlerrm);
  end;

  procedure execute_task(p_texec_id opas_task_exec.texec_id%type) --inside async job
  is
    l_task opas_task%rowtype;
    l_task_body clob;
  begin
    set_exec_status(p_texec_id,'STARTED');
    select * into l_task from opas_task where taskname=(select taskname from opas_task_exec where texec_id = p_texec_id);
    l_task_body:=l_task.task_body;
    for i in (select * from opas_task_pars where texec_id = p_texec_id) loop
      case 
        when i.num_par is not null then
          l_task_body:=replace(l_task_body,'<'||i.par_name||'>',i.num_par);
        when i.num_par is not null or i.date_par is not null then
          raise_application_error(-20000,'Not implemented parameter type');
      end case;
    end loop;
    execute immediate l_task_body;
    set_exec_status(p_texec_id,'FINISHED');
  exception
    when others then
      set_exec_status(p_texec_id,'FINISHED');
      set_exec_status(p_texec_id,'JOB_FAILED');
      log(l_task.taskname,'Execute task error: '||sqlerrm,p_texec_id);
      log(l_task.taskname,DBMS_UTILITY.FORMAT_ERROR_STACK,p_texec_id);
      log(l_task.taskname,DBMS_UTILITY.FORMAT_ERROR_BACKTRACE,p_texec_id);
      raise_application_error(-20000, 'Execute task error: '||sqlerrm);  
  end;
  
  procedure drop_task(p_taskname opas_task.taskname%type) is
  begin
    delete from opas_task where taskname=upper(p_taskname);
    commit;
  end;

  procedure purge_old_tasks is
  begin
    delete from opas_task_log where systimestamp - created > TO_DSINTERVAL(COREMOD_API.getconf('LOGS_EXPIRE_TIME')||' 00:00:00');
    delete from opas_task_exec where systimestamp - finished > TO_DSINTERVAL(COREMOD_API.getconf('TASKRETENTION')||' 00:00:00');
    delete from opas_task where task_type in (cttSINGLE) and systimestamp - created > TO_DSINTERVAL(COREMOD_API.getconf('TASKRETENTION')||' 00:00:00');
    commit;
  end;

end;
/

--------------------------------------------------------
show errors
--------------------------------------------------------