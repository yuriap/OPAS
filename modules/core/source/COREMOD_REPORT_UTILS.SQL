create or replace PACKAGE COREMOD_REPORT_UTILS AS

  type t_output_lines is table of varchar2(32767) index by pls_integer;

  procedure execute_plsql_remotelly(p_sql varchar2, p_dblink varchar2, p_output out clob, p_is_output boolean default true);
  procedure execute_plsql_remotelly(p_sql varchar2, p_dblink varchar2, p_output out t_output_lines);
  procedure print_table_html_remotelly(p_query in varchar2,
                                       p_width number,
                                       p_summary varchar2,
                                       p_search varchar2 default null,
                                       p_replacement varchar2 default null,
                                       p_style1 varchar2 default 'awrc1',
                                       p_style2  varchar2 default 'awrnc1',
                                       p_header number default 0,
                                       p_break_col varchar2 default null,
                                       p_dblink varchar2,
                                       p_output out t_output_lines);
  procedure print_table_html(p_query in varchar2,
                             p_width number,
                             p_summary varchar2,
                             p_search varchar2 default null,
                             p_replacement varchar2 default null,
                             p_style1 varchar2 default 'awrc1',
                             p_style2  varchar2 default 'awrnc1',
                             p_header number default 0,
                             p_break_col varchar2 default null,
                             p_output in out t_output_lines);

  procedure print_table_html_new
                            (p_query in varchar2,
                             p_width number,
                             p_summary varchar2,
                             p_style_tab varchar2,
                             p_style_head varchar2, --head
                             p_style_r1 varchar2,   --odd rows
                             p_style_r2  varchar2, --even rows
                             p_style_finrow  varchar2, --final row
                             p_search varchar2 default null,
                             p_replacement varchar2 default null,
                             p_header number default 0,
                             p_break_col varchar2 default null,
                             p_output in out t_output_lines);

  procedure print_text_as_table(p_text clob, p_t_header varchar2, p_width number, p_search varchar2 default null, p_replacement varchar2 default null, p_comparison boolean default false, p_output out t_output_lines);
  
  procedure print_text_as_table_new(p_text clob, 
                                    p_t_header varchar2, 
                                    p_width number, 
                                    p_search varchar2 default null,                                     
                                    p_replacement varchar2 default null, 
                                    p_comparison boolean default false, 
                                    p_style_tab varchar2,
                                    p_style_head varchar2, --head
                                    p_style_r1 varchar2,   --odd rows
                                    p_style_r2  varchar2, --even rows                                    
                                    p_output in out t_output_lines);
                                    
  procedure save_report_for_download(p_filename varchar2, p_report t_output_lines, p_id in number, p_parent_id number default null);

  --long ops for reports
  procedure set_report_timing(p_timing boolean);
  procedure init_lo_report(p_op_name varchar2, p_target_desc varchar2, p_units varchar2, p_totalwork number);
  procedure start_lo_section(p_module_name varchar2, p_action_name varchar2);
  function  end_lo_section(p_is_finished boolean default false) return varchar2;
end;
/
 
--------------------------------------------------------
show errors
--------------------------------------------------------
 
create or replace PACKAGE BODY COREMOD_REPORT_UTILS AS

  --long ops for reports
/*
    g_rindex    BINARY_INTEGER;
    g_slno      BINARY_INTEGER;
    g_totalwork number;
    g_sofar     number;
    g_obj       BINARY_INTEGER;
    g_op_name   varchar2(100);
    g_target_desc varchar2(100);
    g_units     varchar2(100);
*/
    g_timing    boolean := false;
    g_time number; g_tot_tim number;
    g_cpu_tim number; g_tot_cpu_tim number;
    g_lops_ind number;

    procedure set_report_timing(p_timing boolean) is begin g_timing:=p_timing; end;

    procedure start_tim is
    begin
      if g_timing then
        g_time:=DBMS_UTILITY.GET_TIME;
        g_cpu_tim:=DBMS_UTILITY.GET_CPU_TIME;
      end if;
    end;

    function end_tim(p_is_finished boolean default false) return varchar2 is
      l_delta_t number;
      l_delta_c number;
    begin
      if g_timing then
        l_delta_t:=DBMS_UTILITY.GET_TIME-g_time;
        l_delta_c:=DBMS_UTILITY.GET_CPU_TIME-g_cpu_tim;
        g_tot_tim:=g_tot_tim+l_delta_t;
        g_tot_cpu_tim:=g_tot_cpu_tim+l_delta_c;

        if not p_is_finished then
          return HTF.header (6,cheader=>'Elapsed (sec): '||to_char(round((l_delta_t)/100,2))||'; CPU (sec): '||to_char(round((l_delta_c)/100,2)),cattributes=>'class="awr"');
        else
          return HTF.header (6,cheader=>'Totals: Elapsed (sec): '||to_char(round((g_tot_tim)/100,2))||'; CPU (sec): '||to_char(round((g_tot_cpu_tim)/100,2)),cattributes=>'class="awr"');
          null;
        end if;
      end if;
    end;


  procedure init_lo_report(p_op_name varchar2, p_target_desc varchar2, p_units varchar2, p_totalwork number)
  is
  begin
    COREMOD_API.init_longops(p_op_name,p_target_desc,p_units,p_totalwork,g_lops_ind);

    g_tot_tim := 0;
    g_tot_cpu_tim := 0;
  end;

  procedure start_lo_section(p_module_name varchar2, p_action_name varchar2)
  is
  begin
    COREMOD_API.start_longops_section ( p_module_name, p_action_name);
    start_tim();
  end;
  function end_lo_section(p_is_finished boolean default false) return varchar2
  is
  begin
    COREMOD_API.end_longops_section(1,g_lops_ind);
    return end_tim(p_is_finished);
  end;

  procedure execute_plsql_remotelly(p_sql varchar2, p_dblink varchar2, p_output out clob, p_is_output boolean default true)
  is
    l_theCursor     integer;
    l_status        integer;
    l_line          varchar2(32767);
    l_output        varchar2(32767);
    l_open          boolean;
    l_sql2exec      varchar2(32767);
    l_sql clob:=
q'[declare
l_out clob; l_len number;
l_chunk varchar2(32767);
l_status integer;
l_pos number;
l_chunk_length number := 32767;
l_r raw(32767);
l_rc raw(32767);
begin
DBMS_OUTPUT.ENABLE(NULL);
<PLSQL_BLOCK>
]'||
case when p_is_output then
q'[loop
  DBMS_OUTPUT.GET_LINE(l_chunk,l_status);
  exit when l_status=1;
  l_out:=l_out||l_chunk||chr(10);
end loop;
if l_out is null then l_out:='No data found.';end if;
l_pos:=1;l_len:=length(l_out);
loop
  l_chunk:=substr(l_out,l_pos,l_chunk_length);
  l_pos:=l_pos+l_chunk_length;
  l_r:=utl_raw.cast_to_raw(l_chunk);
  l_rc:=UTL_COMPRESS.LZ_COMPRESS(l_r);
  dbms_output.put(l_rc);
  DBMS_OUTPUT.NEW_LINE;
  exit when l_len<l_pos;
end loop;
end;]'
else q'[end;]' end;
    l_time number := 0;
  begin
    coremod_log.log(p_sql,'DEBUG');
    l_sql:=replace(l_sql,'<PLSQL_BLOCK>',p_sql);
    if length(l_sql) > 32767 then raise_application_error(-20000,'SQL <'||substr(l_sql,1,100)||'...> too long for remote table printing.');end if;
    l_sql2exec:=l_sql;
--dbms_output.put_line(l_sql2exec);
    l_time:=DBMS_UTILITY.GET_TIME;
    execute immediate 'begin :p_theCursor:=dbms_sql.open_cursor@'||p_dblink||'; end;' using out l_theCursor;
    execute immediate 'begin dbms_sql.parse@'||p_dblink||'(:p_theCursor, :p_stmt , :p_flg ); end;' using l_theCursor, l_sql2exec, dbms_sql.native;
    execute immediate 'begin :a:=dbms_sql.execute@'||p_dblink||'(:p_theCursor); end;' using out l_status, in l_theCursor;
    execute immediate 'begin dbms_sql.close_cursor@'||p_dblink||'(:p_theCursor); end;' using in out l_theCursor;
    l_time:=DBMS_UTILITY.GET_TIME-l_time;
    coremod_log.log('Executing: '||(l_time/100),'DEBUG');
    l_time:=DBMS_UTILITY.GET_TIME;
    loop
      execute immediate 'begin DBMS_OUTPUT.GET_LINE@'||p_dblink||'(line => :p_line, status => :p_status); end;' using out l_line, out l_status;
      exit when l_status=1;
      --p_output:=p_output||l_line||chr(10);
      p_output:=p_output||utl_raw.cast_to_varchar2(UTL_COMPRESS.LZ_UNCOMPRESS(l_line));
    end loop;
    l_time:=DBMS_UTILITY.GET_TIME-l_time;
    coremod_log.log('Getting output: '||(l_time/100),'DEBUG');
  exception
    when others then
       execute immediate 'begin :p_open:=dbms_sql.IS_OPEN@'||p_dblink||'(:p_theCursor); end;' using out l_open, in l_theCursor;
      if l_open then
        execute immediate 'begin dbms_sql.close_cursor@'||p_dblink||'(:p_theCursor); end;' using in out l_theCursor;
      end if;
      coremod_log.log(sqlerrm);
      coremod_log.log(l_sql2exec);
      raise_application_error(-20000, sqlerrm||chr(10)||l_sql2exec);
  end;

  procedure execute_plsql_remotelly(p_sql varchar2, p_dblink varchar2, p_output out t_output_lines)
  is
    l_output        clob;
    l_line varchar2(32767);
    l_eof  number;
    l_iter number := 1;
    l_off  number:=1;
  begin
    execute_plsql_remotelly(p_sql, p_dblink, l_output);
    loop
      l_eof:=instr(l_output,chr(10),l_off);
      if l_eof=0 then
        p_output(l_iter):=rtrim(rtrim(substr(l_output,l_off),chr(13)),chr(10));
      else
        p_output(l_iter):=rtrim(rtrim(substr(l_output,l_off,l_eof-l_off+1),chr(13)),chr(10));
      end if;
      l_off:=1+l_eof;
      l_iter:=l_iter+1;
      exit when l_eof=0;
    end loop;
  end;

  procedure print_table_html_remotelly(p_query in varchar2,
                                       p_width number,
                                       p_summary varchar2,
                                       p_search varchar2 default null,
                                       p_replacement varchar2 default null,
                                       p_style1 varchar2 default 'awrc1',
                                       p_style2  varchar2 default 'awrnc1',
                                       p_header number default 0,
                                       p_break_col varchar2 default null,
                                       p_dblink varchar2,
                                       p_output out t_output_lines)
  is
    l_sql clob:=  q'[declare
  l_sql varchar2(32767) := q'^<SQL_QUERY>^';
  <PRN_HTML_TBL_PROC>
begin
  print_table_html(
   p_query => l_sql
   ,p_width => ]'||p_width||q'[
   ,p_summary => q'^]'||p_summary||q'[^' <p_search> <p_replacement> <p_style1> <p_style2> <p_header> <p_break_col>);
end;]';
    l_sql_to_exec varchar2(32767);
  BEGIN
    if p_dblink is null then raise_application_error(-20000, 'Parameter p_dblink must be specified'); end if;

    l_sql:=replace(replace(l_sql,'<PRN_HTML_TBL_PROC>',coremod_api.getscript('PROC_PRNHTMLTBL')),'<SQL_QUERY>',p_query);

    if p_search is not null then l_sql:=replace(l_sql,'<p_search>',q'[,p_search => q'^]'||p_search||q'[^']'||chr(10)); else l_sql:=replace(l_sql,'<p_search>'); end if;
    if p_replacement is not null then l_sql:=replace(l_sql,'<p_replacement>',q'[,p_replacement => q'^]'||p_replacement||q'[^']'||chr(10)); else l_sql:=replace(l_sql,'<p_replacement>'); end if;
    if p_style1 is not null then l_sql:=replace(l_sql,'<p_style1>',q'[,p_style1 => q'^]'||p_style1||q'[^']'||chr(10)); else l_sql:=replace(l_sql,'<p_style1>'); end if;
    if p_style2 is not null then l_sql:=replace(l_sql,'<p_style2>',q'[,p_style2 => q'^]'||p_style2||q'[^']'||chr(10)); else l_sql:=replace(l_sql,'<p_style2>'); end if;
    if p_header is not null then l_sql:=replace(l_sql,'<p_header>',q'[,p_header => ]'||p_header||chr(10)); else l_sql:=replace(l_sql,'<p_header>'); end if;
    if p_break_col is not null then l_sql:=replace(l_sql,'<p_break_col>',q'[,p_break_col => q'^]'||p_break_col||q'[^']'||chr(10)); else l_sql:=replace(l_sql,'<p_break_col>'); end if;

    if length(L_SQL) > 32767 then raise_application_error(-20000,'SQL <'||substr(p_query,1,100)||'...> too long for remote table printing.');end if;
    --dbms_output.put_line('length(P_SQL): '||length(L_SQL));
    l_sql_to_exec:=l_sql;
    --dbms_output.put_line(l_sql_to_exec);
    execute_plsql_remotelly
       (  P_SQL => l_sql_to_exec,
          P_DBLINK => P_DBLINK,
          P_OUTPUT => P_OUTPUT) ;
  END;

  procedure print_text_as_table(p_text clob, p_t_header varchar2, p_width number, p_search varchar2 default null, p_replacement varchar2 default null, p_comparison boolean default false, p_output out t_output_lines) is
    l_line varchar2(32765);  l_eof number;  l_iter number; l_length number;
    l_text clob;
    l_style1 varchar2(10) := 'awrc1';
    l_style2 varchar2(10) := 'awrnc1';

    l_style_comp1 varchar2(10) := 'awrcc1';
    l_style_comp2 varchar2(10) := 'awrncc1';

    l_pref varchar2(10) := 'z';

    l_indx   number := 1;
    procedure p(p_line varchar2) is
    begin
      p_output(l_indx):=p_line;
      l_indx := l_indx + 1;
    end;
  begin

    p(HTF.TABLEOPEN(cborder=>0,cattributes=>'width="'||p_width||'" class="tdiff" summary="'||p_t_header||'"'));
    if p_t_header<>'#FIRST_LINE#' then
      p(HTF.TABLEROWOPEN);
      p(HTF.TABLEHEADER(cvalue=>replace(p_t_header,' ','&nbsp;'),calign=>'left',cattributes=>'class="awrbg" scope="col"'));
      p(HTF.TABLEROWCLOSE);
    end if;

    if instr(p_text,chr(10))=0 then
      l_iter := 1;
      l_length:=dbms_lob.getlength(p_text);
      loop
        l_text := l_text||substr(p_text,l_iter,200)||chr(10);
        l_iter:=l_iter+200;
        exit when l_iter>=l_length;
      end loop;
    else
      l_text := p_text||chr(10);
    end if;

    l_iter := 1;
    loop
      l_eof:=instr(l_text,chr(10));
      l_line:=substr(l_text,1,l_eof);

      if p_t_header='#FIRST_LINE#' and l_iter = 1 then
        p(HTF.TABLEROWOPEN);
        p(HTF.TABLEHEADER(cvalue=>replace(l_line,' ','&nbsp;'),calign=>'left',cattributes=>'class="awrbg" scope="col"'));
        p(HTF.TABLEROWCLOSE);
      else
        p(HTF.TABLEROWOPEN);

        if p_comparison and substr(l_line,1,3)='~~*' then
          l_pref:=substr(l_line,1,7);
          l_line:=substr(l_line,8);
          l_pref:=substr(l_pref,4,1);
        end if;

        if p_search is not null and regexp_instr(l_line,p_search)>0 then
          l_line:=REGEXP_REPLACE(l_line,p_search,p_replacement);
        else
          l_line:=replace(l_line,' ','&nbsp;');
        end if;
        l_line:=replace(l_line,'`',' ');
        if p_comparison and l_pref in ('-') then
          p(HTF.TABLEDATA(cvalue=>l_line,calign=>'left',cattributes=>'class="'|| case when mod(l_iter,2)=0 then l_style_comp1 else l_style_comp2 end ||'"'));
        else
          p(HTF.TABLEDATA(cvalue=>l_line,calign=>'left',cattributes=>'class="'|| case when mod(l_iter,2)=0 then l_style1 else l_style2 end ||'"'));
        end if;

        p(HTF.TABLEROWCLOSE);
      end if;
      l_text:=substr(l_text,l_eof+1);  l_iter:=l_iter+1;
      exit when l_iter>10000 or dbms_lob.getlength(l_text)=0;
    end loop;

    p(HTF.TABLECLOSE);
  end;

  procedure print_table_html(p_query in varchar2,
                             p_width number,
                             p_summary varchar2,
                             p_search varchar2 default null,
                             p_replacement varchar2 default null,
                             p_style1 varchar2 default 'awrc1',
                             p_style2  varchar2 default 'awrnc1',
                             p_header number default 0,
                             p_break_col varchar2 default null,
                             p_output in out t_output_lines) is
    l_theCursor   integer default dbms_sql.open_cursor;
    l_columnValue varchar2(32767);
    l_status      integer;
    l_descTbl     dbms_sql.desc_tab2;
    l_colCnt      number;
    l_rn          number := 0;
    l_style       varchar2(100);
    l_break_value varchar2(4000) := null;
    l_break_cnt   number := 1;
    l_indx   number := p_output.count + 1;

    procedure p(p_line varchar2) is
    begin
      p_output(l_indx):=p_line;
      l_indx := l_indx + 1;
    end;
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

  procedure save_report_for_download(p_filename varchar2, p_report t_output_lines, p_id in number, p_parent_id number default null)
  is
    PRAGMA AUTONOMOUS_TRANSACTION;
    l_rpt clob;
    l_pref clob;
    l_brpt blob;
    l_doff number := 1;
    l_soff number := 1;
    l_cont integer := DBMS_LOB.DEFAULT_LANG_CTX;
    l_warn integer;
  begin

    l_pref:=l_pref||HTF.HTMLOPEN||chr(10);
    l_pref:=l_pref||HTF.HEADOPEN||chr(10);
    l_pref:=l_pref||HTF.TITLE('SQL runtime statistics report')||chr(10);

    l_pref:=l_pref||'<style type="text/css">'||chr(10);
    l_pref:=l_pref||coremod_api.getscript('PROC_AWRCSS')||chr(10);
    l_pref:=l_pref||'</style>'||chr(10);
    l_pref:=l_pref||HTF.HEADCLOSE||chr(10);
    l_pref:=l_pref||HTF.BODYOPEN(cattributes=>'class="awr"')||chr(10);

    for i in 1..p_report.count loop
      l_rpt:=l_rpt||p_report(i)||chr(10);
    end loop;

--    INSERT INTO awrtools_online_rpt (id,ts,file_mimetype,file_name,report, reportc, parent_id)
--         VALUES (p_id,default,default,p_filename,empty_blob(),l_rpt, p_parent_id) return report into l_brpt;

    l_rpt:=l_pref||chr(10)||l_rpt;
    l_rpt:=l_rpt||(HTF.BODYCLOSE)||chr(10);
    l_rpt:=l_rpt||(HTF.HTMLCLOSE);

    DBMS_LOB.CONVERTTOBLOB(
      dest_lob       => l_brpt,
      src_clob       => l_rpt,
      amount         => DBMS_LOB.LOBMAXSIZE,
      dest_offset    => l_doff,
      src_offset     => l_soff,
      blob_csid      => DBMS_LOB.DEFAULT_CSID,
      lang_context   => l_cont,
      warning        => l_warn);
    commit;
  end;

  procedure print_table_html_new
                            (p_query in varchar2,
                             p_width number,
                             p_summary varchar2,
                             p_style_tab varchar2,
                             p_style_head varchar2, --head
                             p_style_r1 varchar2,   --odd rows
                             p_style_r2  varchar2, --even rows
                             p_style_finrow  varchar2, --final row
                             p_search varchar2 default null,
                             p_replacement varchar2 default null,
                             p_header number default 0,
                             p_break_col varchar2 default null,
                             p_output in out t_output_lines) is
    l_theCursor   integer default dbms_sql.open_cursor;
    l_columnValue varchar2(32767);
    l_status      integer;
    l_descTbl     dbms_sql.desc_tab2;
    l_colCnt      number;
    l_rn          number := 0;
    l_style       varchar2(100);
    l_break_value varchar2(4000) := null;
    l_break_cnt   number := 1;
    l_indx   number := p_output.count + 1;

    l_final_row_col number;

    procedure p(p_line varchar2) is
    begin
      p_output(l_indx):=p_line;
      l_indx := l_indx + 1;
    end;
  begin
    p(HTF.TABLEOPEN(cborder=>0,cattributes=>'width="'||p_width||'" class="'||p_style_tab||'" summary="'||p_summary||'"'));

    dbms_sql.parse(l_theCursor, p_query, dbms_sql.native);
    dbms_sql.describe_columns2(l_theCursor, l_colCnt, l_descTbl);

    for i in 1 .. l_colCnt loop
      dbms_sql.define_column(l_theCursor, i, l_columnValue, 4000);
    end loop;

    l_status := dbms_sql.execute(l_theCursor);

    --column names
    if p_style_head is not null then
      p(HTF.TABLEROWOPEN);
      for i in 1 .. l_colCnt loop
        if instr(upper(l_descTbl(i).col_name),'NOPRN')=0 then
          p(HTF.TABLEHEADER(cvalue=>l_descTbl(i).col_name,calign=>'left',cattributes=>'class="'||p_style_head||'" scope="col"'));
        elsif instr(upper(l_descTbl(i).col_name),'LASTROW')>0 then
          l_final_row_col:=i;
        end if;
      end loop;
      p(HTF.TABLEROWCLOSE);
    end if;

    while dbms_sql.fetch_rows(l_theCursor) > 0 loop
      p(HTF.TABLEROWOPEN);
      l_rn := l_rn + 1;
      --coloring for rows for breaking column value
      if p_break_col is null then
        l_style := case when mod(l_rn,2)=0 then p_style_r1 else p_style_r2 end;
      else
        for i in 1 .. l_colCnt loop
          if instr(upper(l_descTbl(i).col_name),'NOPRN')=0 then
            dbms_sql.column_value(l_theCursor, i, l_columnValue);

            if p_break_col is not null and upper(p_break_col)=upper(l_descTbl(i).col_name) then
              if nvl(l_break_value,'$~') <> nvl(l_columnValue,'$~') then
                l_break_value:=l_columnValue;
                l_break_cnt:=l_break_cnt+1;
              end if;
            end if;

            if p_break_col is not null then
              l_style := case when mod(l_break_cnt,2)=0 then p_style_r1 else p_style_r2 end;
            end if;
          end if;
        end loop;
      end if;
      if p_style_finrow is not null then
        dbms_sql.column_value(l_theCursor, l_final_row_col, l_columnValue);
        if l_columnValue = 1 then l_style:=p_style_finrow; end if;
      end if;
      -----------------------------------------------------------------------------
      for i in 1 .. l_colCnt loop
        if instr(upper(l_descTbl(i).col_name),'NOPRN')=0 then
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
        end if;
      end loop;
      p(HTF.TABLEROWCLOSE);
      if p_header > 0 and p_style_head is not null then
        if mod(l_rn,p_header)=0 then
          p(HTF.TABLEROWOPEN);
          for i in 1 .. l_colCnt loop
            if instr(upper(l_descTbl(i).col_name),'NOPRN')=0 then
              p(HTF.TABLEHEADER(cvalue=>l_descTbl(i).col_name,calign=>'left',cattributes=>'class="'||p_style_head||'" scope="col"'));
            end if;
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
      raise_application_error(-20000, 'print_table_html'||chr(10)||sqlerrm||chr(10)||chr(10)||DBMS_UTILITY.FORMAT_ERROR_BACKTRACE);
  end print_table_html_new;


  procedure print_text_as_table_new(p_text clob, 
                                    p_t_header varchar2, 
                                    p_width number, 
                                    p_search varchar2 default null, 
                                    p_replacement varchar2 default null, 
                                    p_comparison boolean default false, 
                                    p_style_tab varchar2,
                                    p_style_head varchar2, --head
                                    p_style_r1 varchar2,   --odd rows
                                    p_style_r2  varchar2, --even rows                                    
                                    p_output in out t_output_lines) is
    l_line varchar2(32765);  l_eof number;  l_iter number; l_length number;
    l_text clob;
    --l_style1 varchar2(10) := 'awrc1';
    --l_style2 varchar2(10) := 'awrnc1';

    --l_style_comp1 varchar2(10) := 'awrcc1';
    --l_style_comp2 varchar2(10) := 'awrncc1';

    l_pref varchar2(10) := 'z';

    l_indx   number := p_output.count + 1;
    procedure p(p_line varchar2) is
    begin
      p_output(l_indx):=p_line;
      l_indx := l_indx + 1;
    end;
  begin

    p(HTF.TABLEOPEN(cborder=>0,cattributes=>'width="'||p_width||'" class="'||p_style_tab||'" summary="'||p_t_header||'"'));
    if p_t_header<>'#FIRST_LINE#' then
      p(HTF.TABLEROWOPEN);
      p(HTF.TABLEHEADER(cvalue=>replace(p_t_header,' ','&nbsp;'),calign=>'left',cattributes=>'class="'||p_style_head||'" scope="col"'));
      p(HTF.TABLEROWCLOSE);
    end if;

    if instr(p_text,chr(10))=0 then
      l_iter := 1;
      l_length:=dbms_lob.getlength(p_text);
      loop
        l_text := l_text||substr(p_text,l_iter,200)||chr(10);
        l_iter:=l_iter+200;
        exit when l_iter>=l_length;
      end loop;
    else
      l_text := p_text||chr(10);
    end if;

    l_iter := 1;
    loop
      l_eof:=instr(l_text,chr(10));
      l_line:=substr(l_text,1,l_eof);

      if p_t_header='#FIRST_LINE#' and l_iter = 1 then
        p(HTF.TABLEROWOPEN);
        p(HTF.TABLEHEADER(cvalue=>replace(l_line,' ','&nbsp;'),calign=>'left',cattributes=>'class="awrbg" scope="col"'));
        p(HTF.TABLEROWCLOSE);
      else
        p(HTF.TABLEROWOPEN);

        if p_comparison and substr(l_line,1,3)='~~*' then
          l_pref:=substr(l_line,1,7);
          l_line:=substr(l_line,8);
          l_pref:=substr(l_pref,4,1);
        end if;

        if p_search is not null and regexp_instr(l_line,p_search)>0 then
          l_line:=REGEXP_REPLACE(l_line,p_search,p_replacement);
        else
          l_line:=replace(l_line,' ','&nbsp;');
        end if;
        l_line:=replace(l_line,'`',' ');
        if p_comparison and l_pref in ('-') then
          p(HTF.TABLEDATA(cvalue=>l_line,calign=>'left',cattributes=>'class="'|| case when mod(l_iter,2)=0 then p_style_r1 else p_style_r2 end ||'"'));
        else
          p(HTF.TABLEDATA(cvalue=>l_line,calign=>'left',cattributes=>'class="'|| case when mod(l_iter,2)=0 then p_style_r1 else p_style_r2 end ||'"'));
        end if;

        p(HTF.TABLEROWCLOSE);
      end if;
      l_text:=substr(l_text,l_eof+1);  l_iter:=l_iter+1;
      exit when l_iter>10000 or dbms_lob.getlength(l_text)=0;
    end loop;

    p(HTF.TABLECLOSE);
  end print_text_as_table_new;

end;
/

--------------------------------------------------------
show errors
--------------------------------------------------------