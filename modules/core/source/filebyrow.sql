create or replace function page_clob(
    p_file_id    opas_files.file_id%type
)
return clob_page
pipelined
as

    m_c1            clob;
    m_length        number(12);

    l_eof       number;  
    l_iter      number;
    l_off       number;    
    
    l_chunk_off number := 1;
    l_chunk     varchar2(32765);
begin
    select file_contentc, length(file_contentc)
    into   m_c1, m_length
    from   opas_files
    where  file_id = p_file_id;

    if (m_c1 is null or m_length = 0) then
        pipe row(clob_line(1,to_char(null)));
    else
      l_iter:=1;
      m_c1:=m_c1||chr(10);
      loop
        l_chunk:=substr(m_c1,l_chunk_off,32765);
        l_chunk:=substr(l_chunk,1,instr(l_chunk,chr(10),-1));
        exit when nvl(length(l_chunk),0)=0;
        l_chunk_off:=l_chunk_off+length(l_chunk);
        l_off:=1;
        loop
          l_eof:=instr(l_chunk,chr(10),l_off);
          if l_eof=0 then
            pipe row (clob_line( l_iter, substr(rtrim(rtrim(substr(l_chunk,l_off),chr(13)),chr(10)),1,4000)));
          else
            pipe row (clob_line( l_iter, substr(rtrim(rtrim(substr(l_chunk,l_off,l_eof-l_off+1),chr(13)),chr(10)),1,4000)));
          end if;
          l_off:=1+l_eof;
          l_iter:=l_iter+1;
          exit when l_eof=0;
        end loop;
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
