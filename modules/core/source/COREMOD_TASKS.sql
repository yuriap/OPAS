create or replace package coremod_tasks as

  cttSYSTEM constant varchar2(10):='SYSTEM';
  cttPURGE  constant varchar2(10):='PURGE';
  cttUSER   constant varchar2(10):='USER';
  
  procedure create_task(p_taskname opas_task.taskname%type,
                        p_modname opas_task.modname%type,
                        p_owner opas_task.owner%type default 'PUBLIC',
                        p_task_type opas_task.task_type%type default cttUSER,
                        p_max_thread opas_task.max_thread%type default 1,
                        p_async opas_task.async%type default 'Y');
  
  procedure set_task_body(p_taskname opas_task.taskname%type,p_task_body clob);
  procedure execute_task(p_taskname opas_task.taskname%type);
  procedure drop_task(p_taskname opas_task.taskname%type);
  procedure purge_old_tasks;

end;
/

--------------------------------------------------------
show errors
--------------------------------------------------------

create or replace package body coremod_tasks as

  procedure log(p_taskname opas_task.taskname%type, p_msg opas_task_log.msg%type)
  is
    PRAGMA AUTONOMOUS_TRANSACTION;
  begin
    insert into opas_task_log values (p_taskname,default, p_msg);
    commit;
  end;

  procedure create_task(p_taskname opas_task.taskname%type,
                        p_modname opas_task.modname%type,
                        p_owner opas_task.owner%type default 'PUBLIC',
                        p_task_type opas_task.task_type%type default cttUSER,
                        p_max_thread opas_task.max_thread%type default 1,
                        p_async opas_task.async%type default 'Y')
  is
  begin
    INSERT INTO opas_task (taskname,modname,owner,task_type,created,status,task_body,max_thread,async)
                   VALUES (upper(p_taskname),p_modname,p_owner,p_task_type,default,default,null,p_max_thread,p_async);
    commit;
  end;

  procedure set_task_body(p_taskname opas_task.taskname%type,p_task_body clob) is
  begin
    update opas_task set task_body = p_task_body where taskname=upper(p_taskname);
    commit;
  end;

  procedure execute_task(p_taskname opas_task.taskname%type) is
    l_task opas_task%rowtype;
  begin
    select * into l_task from opas_task where taskname=upper(p_taskname);
    if l_task.task_type=cttPURGE then
      log(p_taskname,'Started: '||upper(p_taskname));
      execute immediate l_task.task_body;
      log(p_taskname,'Finished: '||upper(p_taskname));
    end if;
  exception
    when others then
      log(p_taskname,'Execute task error: '||sqlerrm);
      log(p_taskname,DBMS_UTILITY.FORMAT_ERROR_STACK);
      log(p_taskname,DBMS_UTILITY.FORMAT_ERROR_BACKTRACE);
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
    delete from opas_task where task_type not in (cttSYSTEM,cttPURGE) and systimestamp - created > TO_DSINTERVAL(COREMOD_API.getconf('TASKRETENTION')||' 00:00:00');
    commit;
  end;

end;
/

--------------------------------------------------------
show errors
--------------------------------------------------------