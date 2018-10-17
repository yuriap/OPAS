CREATE OR REPLACE PACKAGE AWRTOOLS_CACHE AS 

  function get_sql_qry_txt(p_srcdb varchar2, p_sql_id varchar2) return clob;
  procedure put_sql_qry_txt(p_srcdb varchar2, p_sql_id varchar2, p_sql_text clob);
  procedure CLEANUP_CACHE;

END AWRTOOLS_CACHE;
/

CREATE OR REPLACE PACKAGE BODY AWRTOOLS_CACHE AS
  
  procedure CLEANUP_CACHE
  is
  begin
    delete from cube_qry_cache where ts < (systimestamp - to_number(awrtools_api.getconf('CUBE_EXPIRE_TIME'))/24/60);
    dbms_output.put_line('Deleted '||sql%rowcount||' query text(s).');
    commit;
  exception
    when others then rollback;dbms_output.put_line(sqlerrm);
  end;
  
  function get_sql_qry_txt(p_srcdb varchar2, p_sql_id varchar2) return clob AS
    l_txt clob;
  BEGIN
    select sql_text into l_txt from cube_qry_cache where src_db=p_srcdb and sql_id=p_sql_id;
--    AWRTOOLS_LOGGING.log (userenv('SID')||': Cache Hit: '||p_srcdb||';'||p_sql_id, P_LOGLEVEL => 'INFO') ;
    return l_txt;
  exception
    when no_data_found then
--      AWRTOOLS_LOGGING.log (userenv('SID')||': Cache Miss: '||p_srcdb||';'||p_sql_id, P_LOGLEVEL => 'INFO') ;
      return null;
  END get_sql_qry_txt;
  
  procedure put_sql_qry_txt(p_srcdb varchar2, p_sql_id varchar2, p_sql_text clob) AS
    pragma autonomous_transaction;
    l_cnt number;
  BEGIN
    select count(1) into l_cnt from cube_qry_cache where src_db=p_srcdb and sql_id=p_sql_id;
    if l_cnt=0 then
      INSERT INTO cube_qry_cache (src_db,sql_id,sql_text,ts) VALUES (p_srcdb,p_sql_id,p_sql_text,default);
      commit;
--      AWRTOOLS_LOGGING.log (userenv('SID')||': Cache put: '||p_srcdb||';'||p_sql_id, P_LOGLEVEL => 'INFO') ;  
    end if;      
  END put_sql_qry_txt;

END AWRTOOLS_CACHE;
/