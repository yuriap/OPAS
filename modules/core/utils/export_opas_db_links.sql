set feedback off
set timing off
set lines 1000
set serveroutput on
spool ../data/opas_db_links.sql
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
  exception 
    when others then dbms_output.put_line('<P_DB_LINK_NAME>: '||sqlerrm);
  end;
]';

l_body1 varchar2(32765) :=q'[
  begin
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
  for i in (select * from opas_db_links where DB_LINK_NAME<>'$LOCAL$') loop
    p(replace(replace(replace(replace(replace(replace(replace(l_body,'<P_DB_LINK_NAME>',i.DB_LINK_NAME)
                                                            ,'<P_DB_LINK_DISPL_NAME>',i.DISPLAY_NAME)
                                                            ,'<P_OWNER>',i.OWNER)
                                                            ,'<P_IS_PUBLIC>',i.IS_PUBLIC)
                                                            ,'<P_USERNAME>',i.USERNAME)
                                                            ,'<P_PASSWORD>',i.PASSWORD)
                                                            ,'<P_CONNECTSTRING>',i.CONNSTR)
                                                            );
    if i.status='CREATED' then
	p(replace(l_body1,'<P_DB_LINK_NAME>',i.DB_LINK_NAME));
	end if;
  end loop;
  p('end;');
  p('/');
end;
/
spool off