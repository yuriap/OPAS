declare
  procedure p(msg varchar2) is begin dbms_output.put_line(msg);end;
  procedure print_text_as_table(p_text clob) is
  l_line varchar2(32765);  l_eof number;  l_iter number := 1; 
  l_text clob := p_text||chr(10);
begin
  loop
    l_eof:=instr(l_text,chr(10));
	p(rtrim(rtrim(substr(l_text,1,l_eof),chr(13)),chr(10)));
    l_text:=substr(l_text,l_eof+1);  l_iter:=l_iter+1;
    exit when l_iter>1000 or dbms_lob.getlength(l_text)=0;
  end loop;
end;
begin
  for i in (select dbms_sqltune.report_sql_monitor(sql_id=>'&1',report_level=>'ALL') x from dual) loop
    print_text_as_table(i.x);
  end loop;
end;
