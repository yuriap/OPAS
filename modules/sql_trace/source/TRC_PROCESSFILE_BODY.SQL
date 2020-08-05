CREATE OR REPLACE
PACKAGE BODY TRC_PROCESSFILE AS

  cursor g_file_crsr(p_fname trc_files.filename%type) is
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

  cLOB_READ      constant t_row_type := 'LOBREAD';
  cLOB_PG_SIZE   constant t_row_type := 'LOBPGSIZE';
  cLOB_TMP_FREE  constant t_row_type := 'LOBARRTMPFRE';

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

    g_trc_row_type(cLOB_READ):=1;
    g_trc_row_type(cLOB_PG_SIZE):=1;
    g_trc_row_type(cLOB_TMP_FREE):=1;
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
    end if;
  end;

  procedure check_supported_versions
  is
  begin
    if not(g_version||'.'||g_release in ('12.1','12.2','18.0')) then
      raise_application_error(-20000,'Unsupported trace file version: '||g_version||'.'||g_release);
    end if;
  end;

  function getntoken(p_row varchar2, p_ntoken number, p_delim varchar2 default ',') return varchar2
  is
  begin
    return regexp_substr(p_row,'[^'||p_delim||']+', 1, p_ntoken);
  end;

  procedure parse_call_row(p_row varchar2,p_rowtp varchar2, p_call out trc_call%rowtype)
  is
    l_row varchar2(32765);
  begin
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
    exception
      when others then
        COREMOD_LOG.log('parse_call_row: '||sqlerrm);
        COREMOD_LOG.log(DBMS_UTILITY.FORMAT_ERROR_STACK);
        COREMOD_LOG.log(DBMS_UTILITY.FORMAT_ERROR_BACKTRACE);
        COREMOD_LOG.log(p_row);
        COREMOD_LOG.log(l_row);
        raise_application_error(-20000, 'parse_call_row: '||sqlerrm);
  end;

--LOBREAD: type=TEMPORARY LOB,bytes=316,c=0,e=182,p=0,cr=1,cu=0,tim=615032960996
--LOBPGSIZE: type=TEMPORARY LOB,bytes=8132,c=0,e=16,p=0,cr=0,cu=0,tim=615032962102
--LOBREAD: type=TEMPORARY LOB,bytes=32528,c=0,e=2541,p=0,cr=8,cu=0,tim=615032965468
--LOBREAD: type=TEMPORARY LOB,bytes=32528,c=15625,e=3378,p=0,cr=8,cu=4,tim=615032971273
--LOBREAD: type=TEMPORARY LOB,bytes=32528,c=0,e=11018,p=0,cr=8,cu=10,tim=615032986252
--LOBREAD: type=TEMPORARY LOB,bytes=199,c=0,e=164,p=0,cr=1,cu=3,tim=615032991545
--LOBARRTMPFRE: type=PERSISTENT LOB,c=0,e=2011,p=0,cr=0,cu=143,tim=615033003554

  procedure parse_lob_row(p_row varchar2,p_rowtp varchar2, p_lobcall out trc_lobcall%rowtype)
  is
    l_row varchar2(32765);
  begin
    l_row:=rtrim(rtrim(
                 replace(replace(
                 replace(replace(
                 replace(replace(replace(replace(
                 replace(replace(p_row,'LOBREAD: type=',''),'LOBPGSIZE: type=',''),'LOBARRTMPFRE: type=','')
                                      ,',bytes=',','),',c=',',')
                                      ,',e=',','),',p=',','),',cr=',',')
                                      ,',cu=',','),',tim=',','),chr(10)), chr(13))||g_delim;
     p_lobcall.lob_type:=getntoken(l_row,1);
     if p_rowtp = cLOB_TMP_FREE then
       p_lobcall.c:=getntoken(l_row,2);
       p_lobcall.e:=getntoken(l_row,3);
       p_lobcall.p:=getntoken(l_row,4);
       p_lobcall.cr:=getntoken(l_row,5);
       p_lobcall.cu:=getntoken(l_row,6);
       p_lobcall.tim:=getntoken(l_row,7);
     else
       p_lobcall.bytes:=getntoken(l_row,2);
       p_lobcall.c:=getntoken(l_row,3);
       p_lobcall.e:=getntoken(l_row,4);
       p_lobcall.p:=getntoken(l_row,5);
       p_lobcall.cr:=getntoken(l_row,6);
       p_lobcall.cu:=getntoken(l_row,7);
       p_lobcall.tim:=getntoken(l_row,8);
     end if;
  exception
      when others then
        COREMOD_LOG.log('parse_lob_row: '||sqlerrm);
        COREMOD_LOG.log(DBMS_UTILITY.FORMAT_ERROR_STACK);
        COREMOD_LOG.log(DBMS_UTILITY.FORMAT_ERROR_BACKTRACE);
        COREMOD_LOG.log(p_row);
        COREMOD_LOG.log(l_row);
        raise_application_error(-20000, 'parse_lob_row: '||sqlerrm);
  end;

  procedure parse_stmt_row(p_row varchar2, p_rowtp varchar2, p_stmt out trc_statement%rowtype)
  is
    l_row varchar2(32765);
  begin
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
--WAIT #140485731055920: nam='SQL*Net message to client' ela= 0 driver id=1413697536 #bytes=1 p3=0 obj#=-1 tim=11902236206633
--18.3
--WAIT #2856586288: nam='SQL*Net message to client' ela= 29 driver id=1297371904 #bytes=1 p3=0 obj#=-1 tim=1172931705409
        begin
          l_row:=rtrim(rtrim(
                 replace(replace(replace(
                 replace(replace(p_row,'WAIT #','')
                                      ,': nam=',','),' ela= ',',')
                                      ,' obj#=',','),' tim=',','),chr(10)), chr(13))||g_delim;
        end;

       l_row:=substr(l_row,1,instr(l_row,' ',instr(l_row,g_delim,1,2))-1)||','||substr(l_row,instr(l_row,' ',instr(l_row,g_delim,1,2))+1);
       p_wait.trc_slot:=getntoken(l_row,1);
       p_wait.nam:=trim(both q'[']' from getntoken(l_row,2));
       p_wait.ela:=getntoken(l_row,3);
       p_wait.pars:=getntoken(l_row,4);
       p_wait.obj#:=getntoken(l_row,5);
       p_wait.tim:=getntoken(l_row,6);
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

    g_stat_token_indx('trc_slot')('18.0'):=1;
    g_stat_token_indx('id')('18.0'):=2;
    g_stat_token_indx('cnt')('18.0'):=3;
    g_stat_token_indx('pid')('18.0'):=4;
    g_stat_token_indx('pos')('18.0'):=5;
    g_stat_token_indx('obj')('18.0'):=6;
    g_stat_token_indx('op')('18.0'):=7;
    g_stat_token_indx('cr')('18.0'):=8;
    g_stat_token_indx('pr')('18.0'):=9;
    g_stat_token_indx('pw')('18.0'):=10;
    g_stat_token_indx('str')('18.0'):=11;
    g_stat_token_indx('tim')('18.0'):=12;
    g_stat_token_indx('cost')('18.0'):=13;
    g_stat_token_indx('sz')('18.0'):=14;
    g_stat_token_indx('card')('18.0'):=15;

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


    exception
      when others then
        COREMOD_LOG.log('parse_stat_row: '||g_version||'.'||g_release||':'||sqlerrm);
        COREMOD_LOG.log(DBMS_UTILITY.FORMAT_ERROR_STACK);
        COREMOD_LOG.log(DBMS_UTILITY.FORMAT_ERROR_BACKTRACE);
        COREMOD_LOG.log(p_row);
        COREMOD_LOG.log(l_row);
        raise_application_error(-20000, 'parse_stat_row: '||sqlerrm);
  end;

  procedure parse_trans_row(p_row varchar2, p_trans out trc_trans%rowtype)
  is
    l_row varchar2(32765);
  begin
        begin
          l_row:=rtrim(rtrim(
                 replace(
                 replace(replace(p_row,'XCTEND rlbk=','')
                                      ,', rd_only=',','),', tim=',','),chr(10)), chr(13))||g_delim;
        end;
          p_trans.rlbk:=getntoken(l_row,1);
          p_trans.rd_only:=getntoken(l_row,2);
          p_trans.tim:=getntoken(l_row,3);

    exception
      when others then
        COREMOD_LOG.log('parse_trans_row: '||sqlerrm);
        COREMOD_LOG.log(DBMS_UTILITY.FORMAT_ERROR_STACK);
        COREMOD_LOG.log(DBMS_UTILITY.FORMAT_ERROR_BACKTRACE);
        COREMOD_LOG.log(p_row);
        COREMOD_LOG.log(l_row);
        raise_application_error(-20000, 'parse_trans_row: '||sqlerrm);
  end;

  procedure parse_file_i(p_trc_file_id trc_files.trc_file_id%type, p_file sys_refcursor, p_num_rows varchar2, p_filename trc_files.filename%type)
  is
    l_file_rec g_file_crsr%rowtype;

    l_file_id    trc_files.trc_file_id%type := p_trc_file_id;
    l_header     trc_files.FILE_HEADER%type;
    l_db_ver     trc_files.DB_VERSION%type;
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
    l_lobcall    trc_lobcall%rowtype;
    l_row_num    number;

    l_curr_XCTEND_stmt_id    TRC_STATEMENT.stmt_id%type;

    l_str     varchar2(4000);
    l_strlong varchar2(32765);
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

    l_lops_idx_global pls_integer;
    l_lops_idx_rows pls_integer;

    l_modnm varchar2(64):='SQL_TRACE: File processing';
    l_cnt number;
  begin
    COREMOD_LOG.log('Start parsing: p_trc_file_id='||p_trc_file_id);

    COREMOD_API.init_longops(p_op_name=>'Processing: '||p_filename,p_target_desc=>'step',p_units=>'steps',p_totalwork=> 8 ,p_lops_ind=>l_lops_idx_global);
    COREMOD_API.init_longops(p_op_name=>'Step: Parsing: '||p_filename,p_target_desc=>'row',p_units=>'rows',p_totalwork=>p_num_rows,p_lops_ind=>l_lops_idx_rows);
    COREMOD_API.start_longops_section(p_module_name => l_modnm, p_action_name => 'Step: Parsing');

    set_version(null,g_version,g_release); --default trace file version
    COREMOD_LOG.log('Trace file default DB version: '||g_version||'.'||g_release);
    l_curr_XCTEND_stmt_id:=null;

    INSERT INTO trc_session (trc_file_id,row_num,sid,serial#,start_ts,end_ts) VALUES (l_file_id,0,null,null,null,null) returning session_id into l_session_id;
    --open p_file;
    loop
      if l_file_rec.rn is not null then
        COREMOD_API.end_longops_section(p_sofar=>l_file_rec.rn-1, p_lops_ind=>l_lops_idx_rows);
        COREMOD_API.start_longops_section(p_module_name => l_modnm, p_action_name => 'Rows processed: '||l_file_rec.rn);
      end if;

      if not l_new_loop_wo_fetch then
        fetch p_file into l_file_rec;
        exit when p_file%notfound;
      end if;
      l_new_loop_wo_fetch:=false;


      l_curr_row_type:=get_rowtype(l_file_rec.frow);

      --=============================
      if l_curr_row_type=cHeader then
        l_header:=l_file_rec.frow||chr(10);
        l_str:=substr(l_file_rec.frow,instr(replace(l_file_rec.frow,'\','/'),'/',-1)+1); --'\
        loop
          fetch p_file into l_file_rec;
          exit when p_file%notfound;
          exit when is_row_empty(l_file_rec.frow);
          if l_db_ver is null and instr(l_file_rec.frow,'Release ')>0 then
            l_db_ver:=substr(l_file_rec.frow,instr(l_file_rec.frow,'Release')+8,instr(l_file_rec.frow,' ',instr(l_file_rec.frow,'Release')+8)-instr(l_file_rec.frow,'Release')-8);
            set_version(l_db_ver,g_version,g_release);
            check_supported_versions();
            COREMOD_LOG.log('Trace file DB version: '||g_version||'.'||g_release);
          end if;
          l_header:=l_header||l_file_rec.frow||chr(10);
        end loop;
        --todo file version
        update trc_files set FILE_HEADER=l_header, filename=nvl(filename,l_str), db_version=l_db_ver where trc_file_id=l_file_id;
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
      end if;

      -- #0 cursor
      if l_stmt_id_zero is null then
        INSERT INTO trc_statement
                   (cli_ident,session_id,trc_slot,sqlid,sql_text,trc_file_id)
            VALUES (l_curr_cl_id,l_session_id,0,'N/A','N/A',l_file_id)
         returning stmt_id into l_stmt_id_zero;
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
        l_sql_text:=null;
        l_row_num:=l_file_rec.rn;
        parse_stmt_row(l_file_rec.frow,l_curr_row_type,l_stmt);
        loop
          fetch p_file into l_file_rec;
          exit when p_file%notfound;
          exit when trimrow(l_file_rec.frow)='END OF STMT';
          exit when trimrow(l_file_rec.frow) like 'CLOSE #'||l_stmt.trc_slot||'%';
          l_sql_text:=l_sql_text|| case when l_sql_text is not null then chr(10) else null end ||l_file_rec.frow;
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
          l_strlong := null;
          loop
            fetch p_file into l_file_rec;
            exit when p_file%notfound;
            l_curr_row_type:=get_rowtype(l_file_rec.frow);
            if l_file_rec.frow like '==========%' or
               g_trc_row_type.exists(l_curr_row_type)
            then
              l_new_loop_wo_fetch:=true;
              exit;
            end if;
            l_strlong := l_strlong || chr(10) || l_file_rec.frow;
          end loop;
          INSERT INTO trc_binds (stmt_id,trc_file_id,row_num,trc_slot,call_id,bind#,value) VALUES (l_sess2slot(l_trc_slot), l_file_id, l_row_num, l_trc_slot, null, -1, substr(l_strlong,1,4000)) returning rowid into l_rowid;
        end if;
      end if;
      if l_new_loop_wo_fetch then continue; end if;

      --=============================

      if l_curr_row_type in (cParse,cExec,cFetch,cClose) then
        parse_call_row(l_file_rec.frow,l_curr_row_type,l_call);
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
        INSERT INTO trc_call
                    (stmt_id, call_type, row_num, trc_slot, trc_file_id,
                     c, e, p, cr, cu, mis, r, dep, og, plh, tim, typ )
             VALUES (l_sess2slot(l_trc_slot), l_curr_row_type, l_file_rec.rn, l_trc_slot, l_file_id,
                     l_call.c, l_call.e, l_call.p, l_call.cr, l_call.cu, l_call.mis, l_call.r, l_call.dep, l_call.og, l_call.plh, l_call.tim, l_call.typ)
          returning call_id into l_call_id;
         --update only if consecutive EXEC
         if l_rowid is not null and l_curr_row_type = cExec then
           update trc_binds set call_id=l_call_id where rowid=l_rowid;
         end if;
      end if;
      l_rowid:=null;

      --LOB OPs trace
      if l_curr_row_type in (cLOB_READ, cLOB_PG_SIZE, cLOB_TMP_FREE) then
        parse_lob_row(l_file_rec.frow,l_curr_row_type,l_lobcall);
        l_trc_slot:=0;
        INSERT INTO trc_lobcall
                    (stmt_id,        call_type,       row_num,       trc_slot,   trc_file_id,
                               lob_type,           bytes,           c,           e,           p,           cr,           cu,           tim)
             VALUES (l_stmt_id_zero, l_curr_row_type, l_file_rec.rn, l_trc_slot, l_file_id,
                     l_lobcall.lob_type, l_lobcall.bytes, l_lobcall.c, l_lobcall.e, l_lobcall.p, l_lobcall.cr, l_lobcall.cu, l_lobcall.tim);
      end if;

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
          if l_file_rec.frow not like 'STAT%' or l_trc_slot<>get_trc_slot(l_file_rec.frow, l_curr_row_type) then
            l_new_loop_wo_fetch:=true;
            exit;
          end if;
        end loop;
      end if;
      if l_new_loop_wo_fetch then continue; end if;

    end loop;

    COREMOD_LOG.log('Finished "Rows processing"');
    COREMOD_API.end_longops_section(p_sofar => 1, p_lops_ind => l_lops_idx_global);

    COREMOD_API.start_longops_section(p_module_name => l_modnm, p_action_name => 'Delete empty CALLs');

    --remove CLOSE calls with empty statements
    delete /*+ qb_name(main) USE_HASH(C@S1)*/ from trc_statement o where o.trc_file_id=p_trc_file_id and o.err is null and trc_slot<>0
       and not exists(select /*+ qb_name(s1)*/ 1 from trc_call c where c.trc_file_id=p_trc_file_id and o.stmt_id=c.stmt_id and c.call_type<>'CLOSE');

    COREMOD_LOG.log('Finished "Delete empty CALLs"');
    COREMOD_API.end_longops_section(p_sofar => 1, p_lops_ind => l_lops_idx_global);

    COREMOD_API.start_longops_section(p_module_name => l_modnm, p_action_name => 'Create CALLs tree');
    --create call tree
    declare
      type t_call_tree is table of number index by pls_integer; --!
      type t_arrayofnumbers is table of number;
      l_call_tree t_call_tree;
      l_call_prnt t_call_tree;
      l_idx_main pls_integer;
      l_idx      pls_integer;
      l_idx_prev pls_integer;

      l_call_ids   t_arrayofnumbers := t_arrayofnumbers();
      l_call_prnts t_arrayofnumbers := t_arrayofnumbers();
    begin

      COREMOD_LOG.log('Create CALLs tree: 1','DEBUG');

      for i in (select call_id, dep from trc_call where trc_file_id=l_file_id and call_type<>'CLOSE' order by call_id)
      loop
        l_call_tree(i.call_id):=i.dep;
      end loop;

      COREMOD_LOG.log('Create CALLs tree: 2','DEBUG');

      l_idx_main:=l_call_tree.first;
      l_idx_prev:=null;
      loop
        if l_call_tree(l_idx_main)>0 then --searching for parent call only for non top level calls
          l_idx:=l_call_tree.next(l_idx_main); --i.call_id
          if l_idx is not null then
            if l_idx_prev is not null and l_call_tree(l_idx_main)=l_call_tree(l_idx_prev) and l_call_prnt.exists(l_idx_prev) then -- consecutive calls on the same level have the same parent call
              l_call_prnt(l_idx_main):=l_call_prnt(l_idx_prev);
            else
              loop
                if l_call_tree(l_idx)<l_call_tree(l_idx_main) then -- i.dep
                  l_call_prnt(l_idx_main):=l_idx; --i.call_id
                  exit;
                end if;
                l_idx:=l_call_tree.next(l_idx);
                exit when l_idx is null;
              end loop;
            end if;
          end if;
        end if;
        l_idx_prev:=l_idx_main;
        l_idx_main:=l_call_tree.next(l_idx_main);
        exit when l_idx_main is null;
      end loop;

      COREMOD_LOG.log('Create CALLs tree: 3','DEBUG');

      l_idx := l_call_prnt.first;
      loop
        exit when l_idx is null; -- exit if all calls are dep=0
        l_call_ids.extend;
        l_call_ids(l_call_ids.last):=l_idx;
        l_call_prnts.extend;
        l_call_prnts(l_call_prnts.last):=l_call_prnt(l_idx);
        l_idx:=l_call_prnt.next(l_idx);
        exit when l_idx is null;
      end loop;

      COREMOD_LOG.log('Create CALLs tree: 4;'||l_call_ids.first||';'||l_call_ids.last||';'||l_call_prnts.first||';'||l_call_prnts.last,'DEBUG');

      forall i in l_call_ids.first..l_call_ids.last
        update trc_call set parent_id=l_call_prnts(i) where call_id=l_call_ids(i);

      COREMOD_LOG.log('Create CALLs tree: 5','DEBUG');
    exception
      when others then raise_application_error(-20000,'l_idx_main:l_idx_prev:l_idx '||nvl(to_char(l_idx_main),'NULL')||':'||nvl(to_char(l_idx_prev),'NULL')||':'||nvl(to_char(l_idx),'NULL')
                                                    ||': '||sqlerrm||chr(10)||DBMS_UTILITY.FORMAT_ERROR_BACKTRACE);
    end;

    COREMOD_LOG.log('Finished "Create CALLs tree"');
    COREMOD_API.end_longops_section(p_sofar => 1, p_lops_ind => l_lops_idx_global);

    COREMOD_API.start_longops_section(p_module_name => l_modnm, p_action_name => 'Create dictionary');

    --load object dictionary
    insert into trc_obj_dic (trc_file_id,object_id, object_name)
      select unique l_file_id, obj, substr(op,instr(op,' ',-1)+1) from trc_stat where trc_file_id=l_file_id and obj<>0;

    COREMOD_LOG.log('Finished "Create dictionary"');
    COREMOD_API.end_longops_section(p_sofar => 1, p_lops_ind => l_lops_idx_global);

    COREMOD_API.start_longops_section(p_module_name => l_modnm, p_action_name => 'Calc SELF statistics');

    -- self statistics calculation
    for i in (select * from trc_call where trc_file_id = p_trc_file_id) loop
      INSERT INTO trc_call_self (call_id, c, e, p, cr, cu)
          select * from (
             select /*+ index(c idx_trc_call_file)*/ i.call_id, i.c - sum(c.c) cs, i.e - sum(c.e) es, i.p - sum(c.p) ps, i.cr - sum(c.cr) crs, i.cu - sum(c.cu) cus
               from trc_call c where trc_file_id = p_trc_file_id and c.parent_id=i.call_id)
               where cs is not null or es is not null or ps is not null or crs is not null or cus is not null;
    end loop;

    COREMOD_LOG.log('Finished "Calc SELF statistics"');
    COREMOD_API.end_longops_section(p_sofar => 1, p_lops_ind => l_lops_idx_global);

    COREMOD_API.start_longops_section(p_module_name => l_modnm, p_action_name => 'Calc WAITs to CALLs binding');
    update trc_wait w
      set call_id=(select min(call_id) from trc_call c where c.trc_file_id=p_trc_file_id and w.trc_slot=c.trc_slot and w.row_num<c.row_num)
      where trc_file_id=p_trc_file_id;
    COREMOD_LOG.log('Finished "Calc WAITs to CALLs binding"');
    COREMOD_API.end_longops_section(p_sofar => 1, p_lops_ind => l_lops_idx_global);

    COREMOD_API.start_longops_section(p_module_name => l_modnm, p_action_name => 'Calc STATs to CALLs binding');
    update trc_stat s
      set call_id=(select max(call_id) from trc_call c where c.trc_file_id=p_trc_file_id and s.trc_slot=c.trc_slot and s.row_num>c.row_num)
      where trc_file_id=p_trc_file_id;
    COREMOD_LOG.log('Finished "Calc STATs to CALLs binding"');
    COREMOD_API.end_longops_section(p_sofar => 1, p_lops_ind => l_lops_idx_global);

    COREMOD_API.start_longops_section(p_module_name => l_modnm, p_action_name => 'Searching for similar queries');
    declare
      type r_sim_sqls is record (
        stmt_id  number,
        plh      number,
        sqlid    varchar2(100),
        sql_text clob
      );
      type t_sim_sqls is table of r_sim_sqls index by varchar2(500);
      l_sim_sqls t_sim_sqls;
      l_sim_sqls1 t_sim_sqls;
      l_sql      clob;
      l_curr_idx varchar2(500);
      l_idx varchar2(500);
      l_curr_stmt number;
    begin
      -- get list of plan hash values which have more than configured similar queries
      for i in (SELECT c.plh
                  FROM trc_statement st, trc_call c
                 WHERE st.trc_file_id = p_trc_file_id
                   AND st.trc_file_id= c.trc_file_id
                   AND st.stmt_id = c.stmt_id
                   AND c.call_type = 'FETCH'
                   AND st.uid#<> 0
                   AND c.plh<>0
                 GROUP BY c.plh
                HAVING COUNT(UNIQUE st.sqlid) >= to_number(coremod_api.getconf('SIMILARNUM',TRC_FILE_API.gMODNAME)))
      loop
        -- fill up the list of simial qieries for a given plan hash value
        for x1 in (SELECT st.stmt_id||':'||c.plh||':'||st.sqlid idx, st.stmt_id, c.plh, st.sqlid, st.sql_text
                     FROM trc_statement st, trc_call c
                    WHERE st.trc_file_id = p_trc_file_id
                      AND st.trc_file_id = c.trc_file_id
                      AND st.stmt_id = c.stmt_id
                      AND c.call_type = 'FETCH'
                      AND st.uid# <> 0
                      and c.plh = i.plh
        )
        loop
          l_sim_sqls(x1.idx).stmt_id:=x1.stmt_id;
          l_sim_sqls(x1.idx).plh:=x1.plh;
          l_sim_sqls(x1.idx).sqlid:=x1.sqlid;
          l_sim_sqls(x1.idx).sql_text:=x1.sql_text;
        end loop;

        loop
          exit when l_sim_sqls.count=0;
          -- compare the firts sql from the list with others
          l_curr_idx := l_sim_sqls.first;
          l_sql := substr(l_sim_sqls(l_curr_idx).sql_text,1,4000);
          l_curr_stmt := l_sim_sqls(l_curr_idx).stmt_id;
          for x2 in (
            select stmt_id||':'||plh||':'||sqlid idx from (
            SELECT st.stmt_id, c.plh, st.sqlid, UTL_MATCH.jaro_winkler_similarity(substr(st.sql_text,1,4000),l_sql) matching_pct
              FROM trc_statement st, trc_call c
                     WHERE st.trc_file_id = p_trc_file_id
                       AND st.trc_file_id = c.trc_file_id
                       AND st.stmt_id = c.stmt_id
                       AND c.call_type = 'FETCH'
                       AND st.uid# <> 0
                       and c.plh = i.plh)
                       where matching_pct > to_number(coremod_api.getconf('SIMILARPCT',TRC_FILE_API.gMODNAME)))
          loop
            --move those who similar to another list
            if l_sim_sqls.exists(x2.idx) then
              l_sim_sqls1(x2.idx):=l_sim_sqls(x2.idx);
              l_sim_sqls.delete(x2.idx);
            end if;
          end loop;
          --save references from base statement to all similar
          l_idx := l_sim_sqls1.first;
          loop
            exit when l_idx is null;
            insert into trc_similar_stmt(stmt_id_sim,stmt_id_base, trc_file_id) values (l_sim_sqls1(l_idx).stmt_id,l_curr_stmt, p_trc_file_id);
            l_idx:=l_sim_sqls1.next(l_idx);
            exit when l_idx is null;
          end loop;
          l_sim_sqls1.delete;
          exit when l_sim_sqls.count=0;
        end loop;
        --cleanup list
        l_sim_sqls.delete;
      end loop;
    end;

    delete from trc_similar_stmt where trc_file_id = p_trc_file_id
      and stmt_id_base in (select stmt_id_base
                             from trc_similar_stmt
                            where trc_file_id = p_trc_file_id
                            group by stmt_id_base
                           having count(1)<to_number(coremod_api.getconf('SIMILARNUM',TRC_FILE_API.gMODNAME))) ;

    COREMOD_LOG.log('Finished "Searching for similar queries"');
    COREMOD_API.end_longops_section(p_sofar => 1, p_lops_ind => l_lops_idx_global);


    COREMOD_LOG.log('Finished file processing');
  exception
    when others then
      rollback;
      COREMOD_LOG.log('row: '||l_file_rec.frow);
      COREMOD_LOG.log(DBMS_UTILITY.FORMAT_ERROR_STACK);
      COREMOD_LOG.log(DBMS_UTILITY.FORMAT_ERROR_BACKTRACE);
      raise_application_error(-20000, 'Parsing file error: '||sqlerrm);
  end;

  procedure parse_file_i(p_trc_file_id trc_files.trc_file_id%type)
  is
    l_trc_file         trc_files%rowtype;
    l_dblink           varchar2(100);
    l_file_crsr        sys_refcursor;
    l_total_rows       number;
    l_tq_id            opas_task_queue.tq_id%type;
  begin
    l_trc_file:=TRC_FILE_API.get_file(p_trc_file_id, true); --with locking

    if l_trc_file.file_content is not null then
      insert into trc$tmp_file_content select line_number, payload from table(page_clob(l_trc_file.file_content));
      l_total_rows:=sql%rowcount;
    elsif l_trc_file.filename is not null and l_trc_file.file_source = '$LOCAL$' then
      insert into trc$tmp_file_content select rownum, payload from V$DIAG_TRACE_FILE_CONTENTS where trace_filename=l_trc_file.filename order by line_number;
      l_total_rows:=sql%rowcount;
    elsif l_trc_file.filename is not null and l_trc_file.file_source != '$LOCAL$' then
      if nvl(l_trc_file.file_source,'$LOCAL$') <> '$LOCAL$' then
        select ora_db_link into l_dblink from v$opas_db_links where db_link_name=l_trc_file.file_source;
      end if;
      execute immediate 'insert into trc$tmp_file_content select rownum, payload from V$DIAG_TRACE_FILE_CONTENTS@'||l_dblink||' where trace_filename=:p1 order by line_number' using l_trc_file.filename;
      l_total_rows:=sql%rowcount;
    else
      raise_application_error(-20000, 'File ID: '||p_trc_file_id||' can not be processed: unknown source ('||l_trc_file.filename||':'||nvl(l_trc_file.file_source,'N/A')||')');
    end if;

    open l_file_crsr for select * from trc$tmp_file_content;
    parse_file_i(p_trc_file_id,l_file_crsr, l_total_rows,l_trc_file.filename);
    close l_file_crsr;
  exception
    when others then
      if l_file_crsr%isopen then close l_file_crsr; end if;
      raise;
  end;

  procedure parse_file(p_trc_file_id trc_files.trc_file_id%type)
  is
  begin
    COREMOD_LOG.Start_SQL_GATHER_STAT('TRC_PROCESSFILE.PARSE_FILE.GATHER_SQL_STAT');
    COREMOD_LOG.Start_SQL_TRACE('TRC_PROCESSFILE.PARSE_FILE.SQL_TRACE');

    parse_file_i(p_trc_file_id);

    COREMOD_LOG.Stop_SQL_TRACE('TRC_PROCESSFILE.PARSE_FILE.SQL_TRACE');
    COREMOD_LOG.Stop_SQL_GATHER_STAT('TRC_PROCESSFILE.PARSE_FILE.GATHER_SQL_STAT');
  end;


begin
  init();
  init_version_dependencies();
END TRC_PROCESSFILE;
/
