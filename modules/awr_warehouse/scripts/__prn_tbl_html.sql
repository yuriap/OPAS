procedure print_table_html(p_query in varchar2, 
                           p_width number, 
                           p_summary varchar2, 
                           p_search varchar2 default null, 
                           p_replacement varchar2 default null, 
                           p_style1 varchar2 default 'awrc1', 
                           p_style2  varchar2 default 'awrnc1',
                           p_header number default 0,
                           p_break_col varchar2 default null) is
  l_theCursor   integer default dbms_sql.open_cursor;
  l_columnValue varchar2(32767);
  l_status      integer;
  l_descTbl     dbms_sql.desc_tab2;
  l_colCnt      number;
  l_rn          number := 0;
  l_style       varchar2(100);
  l_break_value varchar2(4000) := null;
  l_break_cnt   number := 1;
procedure p(p_msg varchar2) is begin dbms_output.put_line(p_msg); end;  
begin
  p(HTF.TABLEOPEN(cborder=>0,cattributes=>'width="'||p_width||'" class="tdiff" summary="'||p_summary||'"'));

  dbms_sql.parse(l_theCursor, p_query, dbms_sql.native);
  dbms_sql.describe_columns2(l_theCursor, l_colCnt, l_descTbl);

  for i in 1 .. l_colCnt loop
    dbms_sql.define_column(l_theCursor, i, l_columnValue, 4000);
  end loop;

  l_status := dbms_sql.execute(l_theCursor);

  --column names
  p(HTF.TABLEROWOPEN);
  for i in 1 .. l_colCnt loop
    p(HTF.TABLEHEADER(cvalue=>l_descTbl(i).col_name,calign=>'left',cattributes=>'class="awrbg" scope="col"'));
  end loop;
  p(HTF.TABLEROWCLOSE);

  while (dbms_sql.fetch_rows(l_theCursor) > 0) loop
    p(HTF.TABLEROWOPEN);
    l_rn := l_rn + 1;
    --coloring for rows for breaking column value
    if p_break_col is null then
      l_style := case when mod(l_rn,2)=0 then p_style1 else p_style2 end;
    else
      for i in 1 .. l_colCnt loop
        dbms_sql.column_value(l_theCursor, i, l_columnValue);
      
        if p_break_col is not null and upper(p_break_col)=upper(l_descTbl(i).col_name) then
          if nvl(l_break_value,'$~') <> nvl(l_columnValue,'$~') then
            l_break_value:=l_columnValue;
            l_break_cnt:=l_break_cnt+1;
          end if;
        end if;      
      
        if p_break_col is not null then
          l_style := case when mod(l_break_cnt,2)=0 then p_style1 else p_style2 end;
        end if; 
      end loop;
    end if;    
    -----------------------------------------------------------------------------
    for i in 1 .. l_colCnt loop
      dbms_sql.column_value(l_theCursor, i, l_columnValue);
      
      l_columnValue:=replace(replace(l_columnValue,chr(13)||chr(10),chr(10)||'<br/>'),chr(10),chr(10)||'<br/>');
      if p_search is not null then
        if instr(l_descTbl(i).col_name,p_search)>0 then
          l_columnValue:=REGEXP_REPLACE(l_columnValue,'(.*)',p_replacement);
          p(HTF.TABLEDATA(cvalue=>l_columnValue,calign=>'left',cattributes=>'class="'|| l_style ||'"'));
        elsif regexp_instr(l_columnValue,p_search)>0 then
          l_columnValue:=REGEXP_REPLACE(l_columnValue,p_search,p_replacement);
          p(HTF.TABLEDATA(cvalue=>l_columnValue,calign=>'left',cattributes=>'class="'|| l_style ||'"'));
        else
          p(HTF.TABLEDATA(cvalue=>replace(l_columnValue,'  ','&nbsp;&nbsp;'),calign=>'left',cattributes=>'class="'|| l_style ||'"'));
        end if;
      else
        p(HTF.TABLEDATA(cvalue=>replace(l_columnValue,'  ','&nbsp;&nbsp;'),calign=>'left',cattributes=>'class="'|| l_style ||'"'));
      end if;
    end loop;
    p(HTF.TABLEROWCLOSE);
    if p_header > 0 then
      if mod(l_rn,p_header)=0 then
        p(HTF.TABLEROWOPEN);
        for i in 1 .. l_colCnt loop
          p(HTF.TABLEHEADER(cvalue=>l_descTbl(i).col_name,calign=>'left',cattributes=>'class="awrbg" scope="col"'));
        end loop;
        p(HTF.TABLEROWCLOSE);
      end if;
    end if;
  end loop;
  dbms_sql.close_cursor(l_theCursor);
  p(HTF.TABLECLOSE);
exception
  when others then   
    if DBMS_SQL.IS_OPEN(l_theCursor) then dbms_sql.close_cursor(l_theCursor);end if;
    p(p_query);
    raise_application_error(-20000, 'print_table_html'||chr(10)||sqlerrm||chr(10));
end;