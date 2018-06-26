create or replace function page_clob(
    p_file_id    opas_files.file_id%type,
    p_delim      varchar2 default 'AUTO'
)
return clob_page
pipelined
-- deterministic  -- included incorrectly, see comment #3
as
 
    m_c1            clob;
    m_length        number(12);
 
    l_delim         varchar2(10);
	
	l_line varchar2(32765);  l_eof number;  l_iter number;
begin
    select
        file_contentc, length(file_contentc)
    into
        m_c1, m_length
    from
        opas_files
    where
        file_id = p_file_id
    ;
 
    if p_delim = 'AUTO' then
	  if instr(m_c1,chr(13)||chr(10))>0 then 
	    l_delim:=chr(13)||chr(10); 
	  elsif instr(m_c1,chr(10))>0 then 
	    l_delim:=chr(10); 
	  else 
	    raise_application_error(-20000, 'Unknown delimiter: '||p_delim); 
	  end if;
	elsif instr(m_c1,p_delim)>0 then 
	  l_delim:=p_delim; 
	else
      raise_application_error(-20000, 'Unknown delimiter: '||p_delim);
	end if;
	
    if (m_c1 is null or m_length = 0) then 
        pipe row(clob_line(1,to_char(null)));
    else
	  l_iter := 1;
      loop
        l_eof:=instr(m_c1,chr(10));
        l_line:=substr(m_c1,1,l_eof);
        --for i in 1..ceil(m_length/i_chunk) loop
            pipe row (
                clob_line( l_iter, l_line )
            );
        m_c1:=substr(m_c1,l_eof+1);  l_iter:=l_iter+1;
        exit when l_iter>100000 or dbms_lob.getlength(m_c1)=0;
       end loop;
    end if;
    return;
end;
/

create or replace view file_contentbyrow
as
select
    /*+ cardinality(p1 10) */
    opas_files.file_id,
    p1.line_number,
    p1.payload
from
    opas_files,
    table(page_clob(opas_files.file_id)) p1
;
