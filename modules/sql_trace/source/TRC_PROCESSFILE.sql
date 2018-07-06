create or replace PACKAGE TRC_PROCESSFILE AS

  procedure parse_file(p_trc_file_id TRC_FILE.trc_file_id%type);

END TRC_PROCESSFILE;
/

--------------------------------------------------------
show errors
--------------------------------------------------------

create or replace PACKAGE BODY TRC_PROCESSFILE AS

  cursor g_file_crsr(p_fname TRC_FILE.filename%type) is
    select line_number rn, payload frow from trc$tmp_file_content order by line_number;
    
  subtype t_row_type is varchar2(100);
  type t_trc_row_type is table of number index by t_row_type;
  
  subtype t_token_type is varchar2(100);
  type t_token_type_indx is table of number index by t_token_type;
  type t_token_type_indx_v is table of t_token_type_indx index by t_token_type;
  g_stat_token_indx t_token_type_indx_v;

  g_trc_row_type t_trc_row_type;

  cHeader  constant t_row_type := 'Trace file';
  cSession constant t_row_type := '*** SESSION ID';

  cWait    constant t_row_type := 'WAIT';
  cParse   constant t_row_type := 'PARSE';
  cExec    constant t_row_type := 'EXEC';
  cBinds   constant t_row_type := 'BINDS';
  cFetch   constant t_row_type := 'FETCH';
  cClose   constant t_row_type := 'CLOSE';

  cTrans   constant t_row_type := 'XCTEND';
  cStat    constant t_row_type := 'STAT';
  cQuery   constant t_row_type := 'PARSING IN CURSOR';
  cParseErr   constant t_row_type := 'PARSE ERROR';

  g_version number;
  g_release number;

  g_delim   varchar2(1):=',';
  
  g_longops_step number := 100;

  procedure init
  is
  begin
    g_trc_row_type(cHeader):=1;
    g_trc_row_type(cSession):=1;

    g_trc_row_type(cWait):=1;
    g_trc_row_type(cParse):=1;
    g_trc_row_type(cExec):=1;
    g_trc_row_type(cBinds):=1;
    g_trc_row_type(cFetch):=1;
    g_trc_row_type(cClose):=1;

    g_trc_row_type(cTrans):=1;
    g_trc_row_type(cStat):=1;
    g_trc_row_type(cQuery):=1;
    g_trc_row_type(cParseErr):=1;
  end;

  procedure p(p_msg varchar2) is begin dbms_output.put_line(p_msg); end;

  function trimrow(p_row varchar2) return varchar2
  is
  begin
    return rtrim(rtrim(trim(p_row),chr(13)),chr(10));
  end;

  function is_row_empty(p_row varchar2) return boolean
  is
  begin
    return rtrim(trimrow(p_row),'=') is null;
  end;

  function get_in_brakets(p_row varchar2) return varchar2
  is
  begin
    return substr(p_row,instr(p_row,'(')+1,instr(p_row,')')-instr(p_row,'(')-1);
  end;

  function get_rowtype(p_row varchar2) return t_row_type
  is
    l_idx t_row_type;
  begin
    if is_row_empty(p_row) then
      return null;
    end if;
    l_idx:=g_trc_row_type.first;
    loop
      if cParse=l_idx then
        if p_row like l_idx||' #%' then
          return l_idx;
        end if;      
      else
        if p_row like l_idx||'%'  then
          return l_idx;
        end if;
      end if;
      l_idx:=g_trc_row_type.next(l_idx);
      exit when l_idx is null;
    end loop;
    return null;
  end;

  function get_trc_slot(p_row varchar2, p_row_type t_row_type) return number
  is
    l_result number;
  begin
    case
      when p_row_type in (cWAIT,cPARSE,cEXEC,cBINDS,cFETCH,cCLOSE,cParseErr) then
        l_result:=substr(p_row,instr(p_row,'#')+1,instr(p_row,':')-instr(p_row,'#')-1);
      when p_row_type in (cTrans,cSTAT,cQuery) then
        l_result:=substr(p_row,instr(p_row,'#')+1,instr(p_row,' ',instr(p_row,'#'))-instr(p_row,'#')-1);
      else
        raise_application_error(-20000,'Unknown slot: '||p_row_type||' '||p_row);
    end case;
    return l_result;
  exception
    when others then raise_application_error(-20000,'Error slot: '||p_row_type||' '||p_row||' '||sqlerrm);
  end;

  function gs(p_row varchar2, p_statnm varchar2, p_delim varchar2 default ' ') return varchar2
  is
    l_statnmlngth number := length(p_statnm);
  begin
    if instr(p_row,p_statnm)>0 then
      if instr(p_row,p_delim,instr(p_row,p_statnm)) = 0 then
        return trim(both q'[']' from substr(p_row,instr(p_row,p_statnm)+l_statnmlngth));
      else
        return trim(both q'[']' from substr(p_row,instr(p_row,p_statnm)+l_statnmlngth, instr(p_row,p_delim,instr(p_row,p_statnm))-instr(p_row,p_statnm)-l_statnmlngth));
      end if;
    else
      raise_application_error(-20000,'Token not found: "'||p_statnm||'" "'||p_row||'"');
    end if;
  end;
  procedure set_version(p_db_ver varchar2, p_trc_ver in out number, p_trc_release in out number)
  is
  begin

    if p_db_ver is null then p_trc_ver:=12;p_trc_release:=2;
    else
      p_trc_ver:=substr(p_db_ver,1,instr(p_db_ver,'.')-1);
      p_trc_release:=substr(p_db_ver,instr(p_db_ver,'.')+1,instr(p_db_ver,'.',2)-1);
--raise_application_error(-20000,p_db_ver||':'||p_trc_ver||':'||p_trc_release);
    end if;
  end;

  function getntoken(p_row varchar2, p_ntoken number, p_delim varchar2 default ',') return varchar2
  is
  begin
    return regexp_substr(p_row,'[^'||p_delim||']+', 1, p_ntoken);
    /* it works but slightly slower then regexp
    if p_ntoken = 1 then
      return substr(p_row,1,instr(p_row,p_delim)-length(p_delim));
    elsif p_ntoken > 1 then
      return substr(p_row,instr(p_row,p_delim,1,p_ntoken-1)+length(p_delim),instr(p_row,p_delim,1,p_ntoken)-instr(p_row,p_delim,1,p_ntoken-1)-length(p_delim));
    end if;
    */
  end;

  procedure parse_call_row(p_row varchar2,p_rowtp varchar2, p_call out trc_call%rowtype)
  is
    l_row varchar2(32765);
  begin
    if g_version='12' then
      case
        when p_rowtp in (cPARSE,cEXEC,cFETCH) then
        begin
          l_row:=rtrim(rtrim(
                 replace(replace(
                 replace(replace(
                 replace(replace(
                 replace(replace(
                 replace(replace(replace(replace(
                 replace(replace(p_row,'PARSE #',''),'EXEC #',''),'FETCH #','')
                                      ,':c=',','),'e=','')
                                      ,'dep=',''),'cr=',''),'cu=','')
                                      ,'r=',''),'p=',''),'og=','')
                                      ,'plh=',''),'tim=',''),'mis=',''),chr(10)), chr(13))||g_delim;
        end;
        when p_rowtp in (cCLOSE) then
        begin
          l_row:=rtrim(rtrim(
                 replace(replace(
                 replace(replace(
                 replace(replace(p_row,'CLOSE #','')
                                      ,':c=',','),'type=','')
                                      ,'dep=',''),'e=','')
                                      ,'tim=',''),chr(10)), chr(13))||g_delim;
        end;
      end case;
        if p_rowtp in (cPARSE,cEXEC,cFETCH) then
          p_call.trc_slot:=getntoken(l_row,1);
          p_call.c:=getntoken(l_row,2);
          p_call.e:=getntoken(l_row,3);
          p_call.p:=getntoken(l_row,4);
          p_call.cr:=getntoken(l_row,5);
          p_call.cu:=getntoken(l_row,6);
          p_call.mis:=getntoken(l_row,7);
          p_call.r:=getntoken(l_row,8);
          p_call.dep:=getntoken(l_row,9);
          p_call.og:=getntoken(l_row,10);
          p_call.plh:=getntoken(l_row,11);
          p_call.tim:=getntoken(l_row,12);
        elsif p_rowtp in (cCLOSE) then
          p_call.trc_slot:=getntoken(l_row,1);
          p_call.c:=getntoken(l_row,2);
          p_call.e:=getntoken(l_row,3);
          p_call.dep:=getntoken(l_row,4);
          p_call.typ:=getntoken(l_row,5);
          p_call.tim:=getntoken(l_row,6);
        end if;
    end if;
    exception
      when others then
        COREMOD_LOG.log('parse_call_row: '||sqlerrm);
        COREMOD_LOG.log(DBMS_UTILITY.FORMAT_ERROR_STACK);
        COREMOD_LOG.log(DBMS_UTILITY.FORMAT_ERROR_BACKTRACE);
        COREMOD_LOG.log(p_row);
        COREMOD_LOG.log(l_row);
        raise_application_error(-20000, 'parse_call_row: '||sqlerrm);
  end;

  procedure parse_stmt_row(p_row varchar2, p_rowtp varchar2, p_stmt out trc_statement%rowtype)
  is
    l_row varchar2(32765);
  begin

    if g_version='12' then
        begin
          l_row:=rtrim(rtrim(
                 replace(replace(replace(
                 replace(replace(replace(replace(
                 replace(replace(replace(replace(
                 replace(replace(p_row,'PARSING IN CURSOR #',''),'PARSE ERROR #',''),':len=',',')
                                      ,' len=',','),' dep=',',')
                                      ,' uid=',','),' oct=',','),' lid=',',')
                                      ,' tim=',','),' hv=',','),' ad=',',')
                                      ,' sqlid=',',')
                                      ,' err=',','),chr(10)), chr(13))||g_delim;
        end;
        if p_rowtp = cQuery then
          p_stmt.trc_slot:=getntoken(l_row,1);
          p_stmt.len:=getntoken(l_row,2);
          p_stmt.dep:=getntoken(l_row,3);
          p_stmt.uid#:=getntoken(l_row,4);
          p_stmt.oct:=getntoken(l_row,5);
          p_stmt.lid:=getntoken(l_row,6);
          p_stmt.tim:=getntoken(l_row,7);
          p_stmt.hv:=getntoken(l_row,8);
          p_stmt.ad:=trim(both q'[']' from getntoken(l_row,9));
          p_stmt.sqlid:=trim(both q'[']' from getntoken(l_row,10));
        elsif p_rowtp = cParseErr then
          p_stmt.trc_slot:=getntoken(l_row,1);
          p_stmt.len:=getntoken(l_row,2);
          p_stmt.dep:=getntoken(l_row,3);
          p_stmt.uid#:=getntoken(l_row,4);
          p_stmt.oct:=getntoken(l_row,5);
          p_stmt.lid:=getntoken(l_row,6);
          p_stmt.tim:=getntoken(l_row,7);
          p_stmt.err:=getntoken(l_row,8);
        end if;
    end if;
    if p_stmt.trc_slot is null then raise_application_error(-20000,'slot is null: '||p_rowtp);end if;
    exception
      when others then
        COREMOD_LOG.log('parse_stmt_row: '||sqlerrm);
        COREMOD_LOG.log(DBMS_UTILITY.FORMAT_ERROR_STACK);
        COREMOD_LOG.log(DBMS_UTILITY.FORMAT_ERROR_BACKTRACE);
        COREMOD_LOG.log(p_row);
        COREMOD_LOG.log(l_row);
        raise_application_error(-20000, 'parse_stmt_row: '||sqlerrm);
  end;

  procedure parse_wait_row(p_row varchar2, p_wait out trc_wait%rowtype)
  is
    l_row varchar2(32765);
  begin
--WAIT #1713596288: nam='PGA memory operation' ela= 37 p1=65536 p2=1 p3=0 obj#=-1 tim=329665255654
--WAIT #1705153128: nam='row cache lock' ela= 13149 cache id=15 mode=0 request=3 obj#=-1 tim=329666200581
--WAIT #1629483784: nam='asynch descriptor resize' ela= 17 outstanding #aio=0 current aio limit=0 new aio limit=128 obj#=83 tim=329666287338
--WAIT #1629483784: nam='Disk file operations I/O' ela= 169 FileOperation=2 fileno=1 filetype=2 obj#=83 tim=329666287491
--WAIT #1629483784: nam='db file sequential read' ela= 17 file#=1 block#=115518 blocks=1 obj#=83 tim=329666287556
    if g_version='12' then
        begin
          l_row:=rtrim(rtrim(
                 replace(replace(replace(
                 replace(replace(p_row,'WAIT #','')
                                      ,': nam=',','),' ela= ',',')
                                      ,' obj#=',','),' tim=',','),chr(10)), chr(13))||g_delim;
        end;
--dbms_output.put_line(p_row);
--dbms_output.put_line(l_row);
       l_row:=substr(l_row,1,instr(l_row,' ',instr(l_row,g_delim,1,2))-1)||','||substr(l_row,instr(l_row,' ',instr(l_row,g_delim,1,2))+1);
       p_wait.trc_slot:=getntoken(l_row,1);
       p_wait.nam:=trim(both q'[']' from getntoken(l_row,2));
       p_wait.ela:=getntoken(l_row,3);
       p_wait.pars:=getntoken(l_row,4);
       p_wait.obj#:=getntoken(l_row,5);
       p_wait.tim:=getntoken(l_row,6);
    end if;
    exception
      when others then
        COREMOD_LOG.log('parse_wait_row: '||sqlerrm);
        COREMOD_LOG.log(DBMS_UTILITY.FORMAT_ERROR_STACK);
        COREMOD_LOG.log(DBMS_UTILITY.FORMAT_ERROR_BACKTRACE);
        COREMOD_LOG.log(p_row);
        COREMOD_LOG.log(l_row);
        raise_application_error(-20000, 'parse_wait_row: '||sqlerrm);
  end;

  procedure init_version_dependencies
  is
  begin
    g_stat_token_indx('trc_slot')('12.2'):=1;
    g_stat_token_indx('id')('12.2'):=2;
    g_stat_token_indx('cnt')('12.2'):=3;
    g_stat_token_indx('pid')('12.2'):=4;
    g_stat_token_indx('pos')('12.2'):=5;
    g_stat_token_indx('obj')('12.2'):=6;
    g_stat_token_indx('op')('12.2'):=7;
    g_stat_token_indx('cr')('12.2'):=8;
    g_stat_token_indx('pr')('12.2'):=9;
    g_stat_token_indx('pw')('12.2'):=10;
    g_stat_token_indx('str')('12.2'):=11;
    g_stat_token_indx('tim')('12.2'):=12;
    g_stat_token_indx('cost')('12.2'):=13;
    g_stat_token_indx('sz')('12.2'):=14;
    g_stat_token_indx('card')('12.2'):=15;  

    g_stat_token_indx('trc_slot')('12.1'):=1;
    g_stat_token_indx('id')('12.1'):=2;
    g_stat_token_indx('cnt')('12.1'):=3;
    g_stat_token_indx('pid')('12.1'):=4;
    g_stat_token_indx('pos')('12.1'):=5;
    g_stat_token_indx('obj')('12.1'):=6;
    g_stat_token_indx('op')('12.1'):=7;
    g_stat_token_indx('cr')('12.1'):=8;
    g_stat_token_indx('pr')('12.1'):=9;
    g_stat_token_indx('pw')('12.1'):=10;
    g_stat_token_indx('tim')('12.1'):=11;
    g_stat_token_indx('cost')('12.1'):=12;
    g_stat_token_indx('sz')('12.1'):=13;
    g_stat_token_indx('card')('12.1'):=14;   
  end;
  
  procedure parse_stat_row(p_row varchar2, p_stat out trc_stat%rowtype)
  is
    l_row varchar2(32765);
  begin
--STAT #139705803211616 id=1 cnt=1 pid=0 pos=1 obj=0 op='VIEW  (cr=0 pr=0 pw=0 time=38 us)'
--STAT #140556341179024 id=1 cnt=0 pid=0 pos=1 obj=0 op='UPDATE  T1 (cr=160 pr=0 pw=0 time=149301 us)'
    --if g_version='12' then
--        begin
          l_row:=rtrim(rtrim(replace(replace(
                 replace(replace(replace(replace(
                 replace(replace(replace(replace(
                 replace(replace(replace(replace(
                 replace(replace(p_row,'STAT #','')
                                      ,' id=',','),' cnt=',',')
                                      ,' pid=',','),' pos=',','),' obj=',',')
                                      ,q'[ op=']',','),' (cr=',','),' pr=',',')
                                      ,' pw=',','),' str=',','),' time=',','),' cost=',','),' size=',','),' card=',','),q'[)']')
                                      ,chr(10)), chr(13))||g_delim;
--        end;
/*
          p_stat.trc_slot:=getntoken(l_row,1);
          p_stat.id:=getntoken(l_row,2);
          p_stat.cnt:=getntoken(l_row,3);
          p_stat.pid:=getntoken(l_row,4);
          p_stat.pos:=getntoken(l_row,5);
          p_stat.obj:=getntoken(l_row,6);
          p_stat.op:=getntoken(l_row,7);
          p_stat.cr:=getntoken(l_row,8);
          p_stat.pr:=getntoken(l_row,9);
          p_stat.pw:=getntoken(l_row,10);
          if g_release=2 then
            p_stat.str:=getntoken(l_row,11);
            p_stat.tim:=replace(getntoken(l_row,12),' us');--assuming the only measurement is us and it means 1e-6 sec as all other times
            p_stat.cost:=getntoken(l_row,13);
            p_stat.sz:=getntoken(l_row,14);
            p_stat.card:=getntoken(l_row,15);
          elsif g_release=1 then
            p_stat.tim:=replace(getntoken(l_row,11),' us');--assuming the only measurement is us and it means 1e-6 sec as all other times
            p_stat.cost:=getntoken(l_row,12);
            p_stat.sz:=getntoken(l_row,13);
            p_stat.card:=getntoken(l_row,14);
          end if;
*/          
      if g_stat_token_indx.exists('trc_slot') and g_stat_token_indx('trc_slot').exists(g_version||'.'||g_release) then p_stat.trc_slot:=getntoken(l_row,g_stat_token_indx('trc_slot')(g_version||'.'||g_release)); end if;   
      if g_stat_token_indx.exists('id') and g_stat_token_indx('id').exists(g_version||'.'||g_release) then p_stat.id:=getntoken(l_row,g_stat_token_indx('id')(g_version||'.'||g_release)); end if;
      if g_stat_token_indx.exists('cnt') and g_stat_token_indx('cnt').exists(g_version||'.'||g_release) then p_stat.cnt:=getntoken(l_row,g_stat_token_indx('cnt')(g_version||'.'||g_release)); end if;
      if g_stat_token_indx.exists('pid') and g_stat_token_indx('pid').exists(g_version||'.'||g_release) then p_stat.pid:=getntoken(l_row,g_stat_token_indx('pid')(g_version||'.'||g_release)); end if;
      if g_stat_token_indx.exists('pos') and g_stat_token_indx('pos').exists(g_version||'.'||g_release) then p_stat.pos:=getntoken(l_row,g_stat_token_indx('pos')(g_version||'.'||g_release)); end if;
      if g_stat_token_indx.exists('obj') and g_stat_token_indx('obj').exists(g_version||'.'||g_release) then p_stat.obj:=getntoken(l_row,g_stat_token_indx('obj')(g_version||'.'||g_release)); end if;
      if g_stat_token_indx.exists('op') and g_stat_token_indx('op').exists(g_version||'.'||g_release) then p_stat.op:=getntoken(l_row,g_stat_token_indx('op')(g_version||'.'||g_release)); end if;
      if g_stat_token_indx.exists('cr') and g_stat_token_indx('cr').exists(g_version||'.'||g_release) then p_stat.cr:=getntoken(l_row,g_stat_token_indx('cr')(g_version||'.'||g_release)); end if;
      if g_stat_token_indx.exists('pr') and g_stat_token_indx('pr').exists(g_version||'.'||g_release) then p_stat.pr:=getntoken(l_row,g_stat_token_indx('pr')(g_version||'.'||g_release)); end if;
      if g_stat_token_indx.exists('pw') and g_stat_token_indx('pw').exists(g_version||'.'||g_release) then p_stat.pw:=getntoken(l_row,g_stat_token_indx('pw')(g_version||'.'||g_release)); end if;
      if g_stat_token_indx.exists('str') and g_stat_token_indx('str').exists(g_version||'.'||g_release) then p_stat.str:=getntoken(l_row,g_stat_token_indx('str')(g_version||'.'||g_release)); end if;
      if g_stat_token_indx.exists('tim') and g_stat_token_indx('tim').exists(g_version||'.'||g_release) then p_stat.tim:=replace(getntoken(l_row,g_stat_token_indx('tim')(g_version||'.'||g_release)),' us'); end if;--assuming the only measurement is us and it means 1e-6 sec as all other times
      if g_stat_token_indx.exists('cost') and g_stat_token_indx('cost').exists(g_version||'.'||g_release) then p_stat.cost:=getntoken(l_row,g_stat_token_indx('cost')(g_version||'.'||g_release)); end if;
      if g_stat_token_indx.exists('sz') and g_stat_token_indx('sz').exists(g_version||'.'||g_release) then p_stat.sz:=getntoken(l_row,g_stat_token_indx('sz')(g_version||'.'||g_release)); end if;
      if g_stat_token_indx.exists('card') and g_stat_token_indx('card').exists(g_version||'.'||g_release) then p_stat.card:=getntoken(l_row,g_stat_token_indx('card')(g_version||'.'||g_release)); end if;
      
--    end if;
    exception
      when others then
        COREMOD_LOG.log('parse_stat_row: '||g_version||'.'||g_release||':'||sqlerrm);
        COREMOD_LOG.log(DBMS_UTILITY.FORMAT_ERROR_STACK);
        COREMOD_LOG.log(DBMS_UTILITY.FORMAT_ERROR_BACKTRACE);
        COREMOD_LOG.log(p_row);
        COREMOD_LOG.log(l_row);
        --COREMOD_LOG.log(g_stat_token_indx('tim')(g_version||'.'||g_release)||':'||getntoken(l_row,g_stat_token_indx('tim')(g_version||'.'||g_release)));
        raise_application_error(-20000, 'parse_stat_row: '||sqlerrm);
  end;

  procedure parse_trans_row(p_row varchar2, p_trans out trc_trans%rowtype)
  is
    l_row varchar2(32765);
  begin

--    if g_version='12' then
        begin
          l_row:=rtrim(rtrim(
                 replace(
                 replace(replace(p_row,'XCTEND rlbk=','')
                                      ,', rd_only=',','),', tim=',','),chr(10)), chr(13))||g_delim;
        end;
          p_trans.rlbk:=getntoken(l_row,1);
          p_trans.rd_only:=getntoken(l_row,2);
          p_trans.tim:=getntoken(l_row,3);

--    end if;
    exception
      when others then
        COREMOD_LOG.log('parse_trans_row: '||sqlerrm);
        COREMOD_LOG.log(DBMS_UTILITY.FORMAT_ERROR_STACK);
        COREMOD_LOG.log(DBMS_UTILITY.FORMAT_ERROR_BACKTRACE);
        COREMOD_LOG.log(p_row);
        COREMOD_LOG.log(l_row);
        raise_application_error(-20000, 'parse_trans_row: '||sqlerrm);
  end;

  procedure parse_file_i(p_trc_file_id TRC_FILE.trc_file_id%type, p_file sys_refcursor)
  is
    l_file_rec g_file_crsr%rowtype;

    l_file_id    trc_file.trc_file_id%type := p_trc_file_id;
    l_header     TRC_FILE.FILE_HEADER%type;
    l_db_ver     TRC_FILE.DB_VERSION%type;
    l_session_id trc_session.session_id%type;
    l_stmt_id    TRC_STATEMENT.stmt_id%type;
    l_stmt       trc_statement%rowtype;
    l_stmt_id_zero   TRC_STATEMENT.stmt_id%type;
    l_trc_slot   TRC_STATEMENT.trc_slot%type;
    l_sql_text   TRC_STATEMENT.SQL_TEXT%type;
    l_call_id    trc_call.call_id%type;
    l_call       trc_call%rowtype;
    l_wait       trc_wait%rowtype;
    l_stat       trc_stat%rowtype;
    l_trans      trc_trans%rowtype;
    l_row_num    number;
    
    l_curr_XCTEND_stmt_id    TRC_STATEMENT.stmt_id%type;

    l_str     varchar2(4000);
    l_rowid   rowid;

    l_updcli        boolean := false;
    l_curr_cl_id    TRC_CLIENT_IDENTITY.cli_id%type;
    l_client_id     TRC_CLIENT_IDENTITY.client_id%type;
    l_service_name  TRC_CLIENT_IDENTITY.service_name%type;
    l_module        TRC_CLIENT_IDENTITY.module%type;
    l_action        TRC_CLIENT_IDENTITY.action%type;
    l_client_driver TRC_CLIENT_IDENTITY.client_driver%type;

    l_curr_row_type t_row_type;
    l_new_loop_wo_fetch boolean := false;
    l_sess2slot t_trc_row_type;
    l_sess_not_found boolean := false;
  begin
    COREMOD_LOG.log('Start parsing: p_trc_file_id='||p_trc_file_id);
    
    set_version(null,g_version,g_release); --default trace file version
    l_curr_XCTEND_stmt_id:=null;
    
    INSERT INTO trc_session (trc_file_id,row_num,sid,serial#,start_ts,end_ts) VALUES (l_file_id,0,null,null,null,null) returning session_id into l_session_id;
    --open p_file;
    loop
      --if mod(l_file_rec.rn,g_longops_step)=0 then
        COREMOD_API.end_longops_section(l_file_rec.rn-1);
        COREMOD_API.start_longops_section(p_module_name => 'TRC:Parse', p_action_name => 'Rows processed: '||l_file_rec.rn);
      --end if;
      if not l_new_loop_wo_fetch then
        fetch p_file into l_file_rec;
        exit when p_file%notfound;
      end if;
      l_new_loop_wo_fetch:=false;

      
      l_curr_row_type:=get_rowtype(l_file_rec.frow);
      
      --=============================
      if l_curr_row_type=cHeader then
        l_header:=l_file_rec.frow;
        l_str:=substr(l_file_rec.frow,instr(replace(l_file_rec.frow,'\','/'),'/',-1)+1); --'\
        loop
          fetch p_file into l_file_rec;
          exit when p_file%notfound;
          exit when is_row_empty(l_file_rec.frow);
          if l_db_ver is null and instr(l_file_rec.frow,'Release ')>0 then
            l_db_ver:=substr(l_file_rec.frow,instr(l_file_rec.frow,'Release')+8,instr(l_file_rec.frow,' ',instr(l_file_rec.frow,'Release')+8)-instr(l_file_rec.frow,'Release')-8);
--raise_application_error(-20000,l_file_rec.frow||':'||l_db_ver);            
            set_version(l_db_ver,g_version,g_release);
          end if;
          l_header:=l_header||l_file_rec.frow||chr(10);
        end loop;
        --todo file version
        update trc_file set FILE_HEADER=l_header, filename=nvl(filename,l_str), db_version=l_db_ver where trc_file_id=l_file_id;
      end if;

      --=============================
      if l_curr_row_type=cSession  then
        l_str:=get_in_brakets(l_file_rec.frow);
        INSERT INTO trc_session (trc_file_id,row_num,
                                 sid,serial#,start_ts,end_ts)
            VALUES (l_file_id,l_file_rec.rn,
                    to_number(substr(l_str,1,instr(l_str,'.')-1)),
                    to_number(substr(l_str,instr(l_str,'.')+1)),
                    to_timestamp_tz(replace(substr(l_file_rec.frow,instr(l_file_rec.frow,')')+2),'T',' '),'yyyy-mm-dd hh24:mi:ss.ff6 tzh:tzm'),
                    null)
          returning session_id into l_session_id;

        -- #0 cursor
        if l_stmt_id_zero is null then
          INSERT INTO trc_statement
                     (cli_ident,session_id,trc_slot,sqlid,sql_text,trc_file_id)
              VALUES (l_curr_cl_id,l_session_id,0,'N/A','N/A',l_file_id)
           returning stmt_id into l_stmt_id_zero;
        end if;
      end if;


      if l_file_rec.frow like '***%' then
        if instr(l_file_rec.frow,'*** CLIENT ID')>0     then l_client_id:= get_in_brakets(l_file_rec.frow); l_updcli:=true; end if;
        if instr(l_file_rec.frow,'*** SERVICE NAME')>0  then l_service_name:= get_in_brakets(l_file_rec.frow); l_updcli:=true; end if;
        if instr(l_file_rec.frow,'*** MODULE NAME')>0   then l_module:= get_in_brakets(l_file_rec.frow); l_updcli:=true; end if;
        if instr(l_file_rec.frow,'*** ACTION NAME')>0   then l_action:= get_in_brakets(l_file_rec.frow); l_updcli:=true; end if;
        if instr(l_file_rec.frow,'*** CLIENT DRIVER')>0 then l_client_driver:= get_in_brakets(l_file_rec.frow); l_updcli:=true; end if;
        if l_updcli then
          INSERT INTO trc_client_identity
                     (session_id,trc_file_id,client_id,service_name,module,action,client_driver)
              VALUES (l_session_id,l_file_id,l_client_id,l_service_name,l_module,l_action,l_client_driver) returning cli_id into l_curr_cl_id;
          l_updcli:=false;
        end if;
      end if;

      --=============================
      if l_curr_row_type = cWait then
        --l_trc_slot:=get_trc_slot(l_file_rec.frow, l_curr_row_type);
        parse_wait_row(l_file_rec.frow,l_wait);
        l_trc_slot:=l_wait.trc_slot;
        if l_trc_slot = 0 then
          INSERT INTO trc_wait
                      (stmt_id,trc_slot,row_num,trc_file_id,
                       nam,ela,obj#,tim,pars)
               VALUES (l_stmt_id_zero,l_trc_slot,l_file_rec.rn,l_file_id,
                       l_wait.nam,l_wait.ela,l_wait.obj#,l_wait.tim,l_wait.pars);
        else
          if not l_sess2slot.exists(l_trc_slot) then
            --for unknown statement (trace does not contain PARSING IN for the slot
            INSERT INTO trc_statement
                       (cli_ident,session_id,row_num,trc_slot,trc_file_id,
                        len,dep,uid#,oct,lid,tim,hv,ad,         sqlid,sql_text)
                VALUES (l_curr_cl_id,l_session_id,l_file_rec.rn,l_trc_slot,l_file_id,
                        null,null,null,null,null,null,null,null,'N/A','N/A')
             returning stmt_id into l_stmt_id;
             l_sess2slot(l_trc_slot):=l_stmt_id;
           end if;
           INSERT INTO trc_wait
                      (stmt_id,trc_slot,row_num,trc_file_id,
                       nam,ela,obj#,tim,pars)
               VALUES (l_sess2slot(l_trc_slot),l_trc_slot,l_file_rec.rn,l_file_id,
                       l_wait.nam,l_wait.ela,l_wait.obj#,l_wait.tim,l_wait.pars);
        end if;
      end if;

      --=============================
      if l_curr_row_type in ( cQuery, cParseErr ) then
        --l_trc_slot:=get_trc_slot(l_file_rec.frow, l_curr_row_type);
        --l_stmt.dep:=gs(l_file_rec.frow,'dep=');
        l_sql_text:=null;
        l_row_num:=l_file_rec.rn;
        parse_stmt_row(l_file_rec.frow,l_curr_row_type,l_stmt);
        loop
          fetch p_file into l_file_rec;
          exit when p_file%notfound;
          exit when trimrow(l_file_rec.frow)='END OF STMT';
          exit when trimrow(l_file_rec.frow) like 'CLOSE #'||l_stmt.trc_slot||'%';
          l_sql_text:=l_sql_text||l_file_rec.frow;
        end loop;
        
        if trimrow(l_file_rec.frow) like 'CLOSE #'||l_stmt.trc_slot||'%' then l_new_loop_wo_fetch:=true; end if;
        
        INSERT INTO trc_statement
                   (cli_ident,session_id,row_num,trc_slot,trc_file_id,
                    len,dep,uid#,oct,lid,tim,hv,ad,sqlid,sql_text,err)
            VALUES (l_curr_cl_id,l_session_id,l_row_num,l_stmt.trc_slot,l_file_id,
                    l_stmt.len,l_stmt.dep,l_stmt.uid#,l_stmt.oct,l_stmt.lid,l_stmt.tim,l_stmt.hv,l_stmt.ad,l_stmt.sqlid,l_sql_text,l_stmt.err)
         returning stmt_id into l_stmt_id;
        l_sess2slot(l_stmt.trc_slot):=l_stmt_id;
        if l_stmt.oct=44 then l_curr_XCTEND_stmt_id:=l_stmt_id; end if;
      end if;
      if l_new_loop_wo_fetch then continue; end if;
      
      --=============================
      if l_curr_row_type = cBinds then
        if l_stmt_id is not null then
          l_trc_slot:=get_trc_slot(l_file_rec.frow, l_curr_row_type);
          l_row_num:=l_file_rec.rn;
          loop
            fetch p_file into l_file_rec;
            exit when p_file%notfound;
            if l_file_rec.frow like '==========%' or
               l_file_rec.frow like 'PARSING IN CURSOR%' or
               l_file_rec.frow like 'EXEC%' then
              l_new_loop_wo_fetch:=true;
              exit;
            end if;
          end loop;
          INSERT INTO trc_binds (stmt_id,trc_file_id,row_num,trc_slot,call_id,bind#,value) VALUES (l_sess2slot(l_trc_slot), l_file_id, l_row_num, l_trc_slot, null, null, null) returning rowid into l_rowid;
        end if;
      end if;
      if l_new_loop_wo_fetch then continue; end if;

      --=============================
--      l_curr_row_type:=get_rowtype(l_file_rec.frow);

      if l_curr_row_type in (cParse,cExec,cFetch,cClose) then
      
--COREMOD_LOG.log(l_file_rec.frow);
--COREMOD_LOG.log(l_curr_row_type);
      
        parse_call_row(l_file_rec.frow,l_curr_row_type,l_call);
        --l_trc_slot:=get_trc_slot(l_file_rec.frow, l_curr_row_type);
        l_trc_slot:=l_call.trc_slot;
        if not l_sess2slot.exists(l_trc_slot) then
          --for unknown statement (trace does not contain PARSING IN for the slot
          INSERT INTO trc_statement
                     (cli_ident,session_id,row_num,trc_slot,trc_file_id,
                      len,dep,uid#,oct,lid,tim,hv,ad,         sqlid,sql_text)
              VALUES (l_curr_cl_id,l_session_id,l_file_rec.rn,l_trc_slot,l_file_id,
                      null,l_call.dep,null,null,null,null,null,null,'N/A','N/A')
           returning stmt_id into l_stmt_id;
           l_sess2slot(l_trc_slot):=l_stmt_id;
        end if;
        --begin
        --parse_call_row(l_file_rec.frow,l_curr_row_type,l_call);
        INSERT INTO trc_call
                    (stmt_id, call_type, row_num, trc_slot, trc_file_id,
                     c, e, p, cr, cu, mis, r, dep, og, plh, tim, typ )
             VALUES (l_sess2slot(l_trc_slot), l_curr_row_type, l_file_rec.rn, l_trc_slot, l_file_id,
                     l_call.c, l_call.e, l_call.p, l_call.cr, l_call.cu, l_call.mis, l_call.r, l_call.dep, l_call.og, l_call.plh, l_call.tim, l_call.typ)
          returning call_id into l_call_id;
--         exception
           --when others then raise_application_error(-20000,gs(l_file_rec.frow,'dep=')||' '||l_file_rec.frow);
         --end;
         --update only if consecutive EXEC
         if l_rowid is not null and l_curr_row_type = cExec then
           update trc_binds set call_id=l_call_id where rowid=l_rowid;
         end if;
         
         --if l_curr_row_type=cClose then
         --  l_sess2slot.delete(l_trc_slot);
         --end if;
      end if;
      l_rowid:=null;

      if l_curr_row_type in (cTrans) then
        parse_trans_row(l_file_rec.frow,l_trans);
        INSERT INTO trc_trans
                    (session_id,trc_file_id,row_num,rlbk,rd_only,tim, stmt_id)
             VALUES (l_session_id,l_file_id,l_file_rec.rn,l_trans.rlbk,l_trans.rd_only,l_trans.tim, l_curr_XCTEND_stmt_id);
      end if;

      --=============================
      if l_curr_row_type in (cStat) then
        l_trc_slot:=get_trc_slot(l_file_rec.frow, l_curr_row_type);
        if not l_sess2slot.exists(l_trc_slot) then
          --for unknown statement (trace does not contain PARSING IN for the slot
          INSERT INTO trc_statement
                     (cli_ident, session_id,row_num,trc_slot,trc_file_id,
                      len,dep,uid#,oct,lid,tim,hv,ad,         sqlid,sql_text)
              VALUES (l_curr_cl_id,l_session_id,l_file_rec.rn,l_trc_slot,l_file_id,
                      null,null,null,null,null,null,null,null,'N/A','N/A')
           returning stmt_id into l_stmt_id;
           l_sess2slot(l_trc_slot):=l_stmt_id;
        end if;
        loop
          parse_stat_row(l_file_rec.frow,l_stat);
          INSERT INTO trc_stat
                     (stmt_id,row_num,trc_slot,trc_file_id,
                      id,cnt,pid,pos,obj,op,cr,pr,pw,str,tim,cost,sz,card)
              VALUES (l_sess2slot(l_trc_slot),l_file_rec.rn,l_trc_slot,l_file_id,
                      l_stat.id,l_stat.cnt,l_stat.pid,l_stat.pos,l_stat.obj,l_stat.op,l_stat.cr,l_stat.pr,l_stat.pw,l_stat.str,l_stat.tim,l_stat.cost,l_stat.sz,l_stat.card);
          fetch p_file into l_file_rec;
          exit when p_file%notfound;
          if l_file_rec.frow not like 'STAT%' then
            l_new_loop_wo_fetch:=true;
            exit;
          end if;
        end loop;
      end if;
      if l_new_loop_wo_fetch then continue; end if;

    end loop;

    COREMOD_LOG.log('Finished "Rows processing"');
    COREMOD_API.start_longops_section(p_module_name => 'TRC:Parse', p_action_name => 'Delete empty CALLs');

    --remove CLOSE calls with empty statements
    delete from trc_statement o where o.trc_file_id=p_trc_file_id and o.err is null and trc_slot<>0
       and not exists(select 1 from trc_call c where c.trc_file_id=p_trc_file_id and o.stmt_id=c.stmt_id and c.call_type<>'CLOSE');  

    COREMOD_LOG.log('Finished "Delete empty CALLs"');
    COREMOD_API.end_longops_section;
    COREMOD_API.start_longops_section(p_module_name => 'TRC:Parse', p_action_name => 'Create CALLs tree');
    --create call tree
    declare
      type t_call_tree is table of number index by pls_integer;
      l_call_tree t_call_tree;
      l_idx varchar2(100);
    begin
      for i in (select call_id, dep from trc_call where trc_file_id=l_file_id order by 1)
      loop
        l_call_tree(i.call_id):=i.dep;
      end loop;

      for i in (select * from trc_call where trc_file_id=l_file_id order by call_id)
      loop
        l_idx:=l_call_tree.next(i.call_id);
        if l_idx is not null then
          loop
            if l_call_tree(l_idx)<i.dep then
              update trc_call set parent_id=l_idx where call_id=i.call_id;
              exit;
            end if;
            l_idx:=l_call_tree.next(l_idx);
            exit when l_idx is null;
          end loop;
        end if;
      end loop;
    end;

    COREMOD_LOG.log('Finished "Create CALLs tree"');
    COREMOD_API.end_longops_section;
    COREMOD_API.start_longops_section(p_module_name => 'TRC:Parse', p_action_name => 'Create dictionary');

    --load object dictionary
    insert into trc_obj_dic (trc_file_id,object_id, object_name)
      select unique l_file_id, obj, substr(op,instr(op,' ',-1)+1) from trc_stat where trc_file_id=l_file_id and obj<>0;
 
    COREMOD_LOG.log('Finished "Create dictionary"');
    COREMOD_API.end_longops_section;
    COREMOD_API.start_longops_section(p_module_name => 'TRC:Parse', p_action_name => 'Calc SELF statistics');
      
    -- self statistics calculation
    for i in (select * from trc_call where trc_file_id = p_trc_file_id) loop
      INSERT INTO trc_call_self (call_id, c, e, p, cr, cu) 
          select * from (
             select i.call_id, i.c - sum(c) cs, i.e - sum(e) es, i.p - sum(p) ps, i.cr - sum(cr) crs, i.cu - sum(cu) cus
               from trc_call where trc_file_id = p_trc_file_id and parent_id=i.call_id)
               where cs is not null or es is not null or ps is not null or crs is not null or cus is not null;
    end loop;    

    COREMOD_LOG.log('Finished "Calc SELF statistics"');
    COREMOD_API.end_longops_section;
    COREMOD_LOG.log('Finished file provrssing');
  exception
    when others then
      COREMOD_LOG.log(l_file_rec.frow);
      raise;
  end;

  procedure parse_file(p_trc_file_id TRC_FILE.trc_file_id%type)
  is
    l_trc_file         TRC_FILE%rowtype;
    l_trc_file_source  TRC_FILE_SOURCE%rowtype;
    l_dblink           varchar2(100);
    l_file_crsr        sys_refcursor;
    l_total_rows       number;
  begin
    TRC_UTILS.get_file(p_trc_file_id,l_trc_file,l_trc_file_source);

    if l_trc_file.status<>'NEW' then
      raise_application_error(-20000, 'File ID:'||p_trc_file_id||' already parsed ('||l_trc_file.status||')');
    end if;

    delete from trc$tmp_file_content;

    if l_trc_file_source.file_content is not null then
      insert into trc$tmp_file_content select line_number, payload from table(page_clob(l_trc_file_source.file_content));
      l_total_rows:=sql%rowcount;
    elsif l_trc_file.filename is not null and l_trc_file_source.file_db_source = '$LOCAL$' then
      insert into trc$tmp_file_content select rownum, payload from V$DIAG_TRACE_FILE_CONTENTS where trace_filename=l_trc_file.filename order by line_number;
      l_total_rows:=sql%rowcount;
    elsif l_trc_file.filename is not null and l_trc_file_source.file_db_source != '$LOCAL$' then
      if nvl(l_trc_file_source.file_db_source,'$LOCAL$') <> '$LOCAL$' then
        select ora_db_link into l_dblink from v$opas_db_links where db_link_name=l_trc_file_source.file_db_source;
      end if;    
      execute immediate 'insert into trc$tmp_file_content select rownum, payload from V$DIAG_TRACE_FILE_CONTENTS@'||l_dblink||' where trace_filename=:p1 order by line_number' using l_trc_file.filename;
      l_total_rows:=sql%rowcount;      
    else
      raise_application_error(-20000, 'File ID: '||p_trc_file_id||' can not be processed: unknown source ('||l_trc_file.filename||':'||nvl(l_trc_file_source.file_db_source,'N/A')||')');
    end if;

    COREMOD_API.init_longops(p_op_name=>'Parsing '||l_trc_file.filename,p_target_desc=>'row',p_units=>'rows',p_totalwork=>l_total_rows);
    
    open l_file_crsr for select * from trc$tmp_file_content;
    parse_file_i(p_trc_file_id,l_file_crsr);
    close l_file_crsr;
    
    update TRC_FILE set status = 'PARSED' where trc_file_id = p_trc_file_id;
  exception
    when others then
      if l_file_crsr%isopen then close l_file_crsr; end if;
      raise;
  end;

begin
  init();
  init_version_dependencies();
END TRC_PROCESSFILE;
/

--------------------------------------------------------
show errors
--------------------------------------------------------