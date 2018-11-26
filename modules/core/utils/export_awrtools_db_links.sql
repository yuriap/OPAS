set feedback off
set timing off
set lines 1000
set serveroutput on
spool ../data/awrtools_db_links.sql

declare
l_body varchar2(32765) :=q'[
  begin
    COREMOD_API.register_dblink (  P_DB_LINK_NAME => '<P_DB_LINK_NAME>',
                                   P_DB_LINK_DISPL_NAME => '<P_DB_LINK_DISPL_NAME>',
                                   P_OWNER => '<P_OWNER>',
                                   P_IS_PUBLIC => '<P_IS_PUBLIC>',
                                   P_USERNAME => '<P_USERNAME>',
                                   P_PASSWORD => '<P_PASSWORD>',
                                   P_CONNECTSTRING => '<P_CONNECTSTRING>') ;  
    COREMOD_API.create_dblink   (  P_DB_LINK_NAME => '<P_DB_LINK_NAME>',
                                   P_RECREATE => true) ;  
    COREMOD_API.test_dblink     (  P_DB_LINK_NAME => '<P_DB_LINK_NAME>') ;  
  exception 
    when others then dbms_output.put_line('<P_DB_LINK_NAME>: '||sqlerrm);
  end;
]';
procedure p(p_msg varchar2) is begin dbms_output.put_line(p_msg);end;
begin
  p('set serveroutput on');
  p('begin');
  for i in (select * from user_db_links where DB_LINK not like 'DBAWR%') loop
    p(replace(replace(replace(replace(replace(replace(replace(l_body,'<P_DB_LINK_NAME>',substr(i.DB_LINK,1,instr(i.DB_LINK,'.')-1))
                                                            ,'<P_DB_LINK_DISPL_NAME>',substr(i.DB_LINK,1,instr(i.DB_LINK,'.')-1))
                                                            ,'<P_OWNER>','PUBLIC')
                                                            ,'<P_IS_PUBLIC>','Y')
                                                            ,'<P_USERNAME>',i.USERNAME)
                                                            ,'<P_PASSWORD>',i.USERNAME)
                                                            ,'<P_CONNECTSTRING>',i.HOST)
                                                            );
  end loop;
  p('end;');
  p('/');
end;
/

spool off