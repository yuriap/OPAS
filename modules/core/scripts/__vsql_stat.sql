
declare
l_on varchar2(512);
procedure p(msg varchar2) is begin dbms_output.put_line(msg);end;
  /*---------------------------------------------------
    -- function for converting large numbers to human-readable format
    ---------------------------------------------------*/
    function tptformat( p_num in number,
                        p_stype in varchar2 default 'STAT',
                        p_precision in number default 2,
                        p_base in number default 10,    -- for KiB/MiB formatting use
                        p_grouplen in number default 3  -- p_base=2 and p_grouplen=10
                      )
                      return varchar2
    is
    begin
        if p_num=0 then return '0'; end if;
        if p_stype in ('WAIT','TIME') then
            return
                round(
                    p_num / power( p_base , trunc(log(p_base,abs(p_num)))-trunc(mod(log(p_base,abs(p_num)),p_grouplen)) ), p_precision
                )
                || case trunc(log(p_base,abs(p_num)))-trunc(mod(log(p_base,abs(p_num)),p_grouplen))
                       when 0            then 'us'
                       when 1            then 'us'
                       when p_grouplen*1 then 'ms'
                       when p_grouplen*2 then 's'
                       when p_grouplen*3 then 'ks'
                       when p_grouplen*4 then 'Ms'
                       else '*'||p_base||'e'||to_char( trunc(log(p_base,abs(p_num)))-trunc(mod(log(p_base,abs(p_num)),p_grouplen)) )||' us'
                    end;
        else
            return
                round(
                    p_num / power( p_base , trunc(log(p_base,abs(p_num)))-trunc(mod(log(p_base,abs(p_num)),p_grouplen)) ), p_precision
                )
                || case trunc(log(p_base,abs(p_num)))-trunc(mod(log(p_base,abs(p_num)),p_grouplen))
                       when 0            then ''
                       when 1            then ''
                       when p_grouplen*1 then 'k'
                       when p_grouplen*2 then 'M'
                       when p_grouplen*3 then 'G'
                       when p_grouplen*4 then 'T'
                       when p_grouplen*5 then 'P'
                       when p_grouplen*6 then 'E'
                       else '*'||p_base||'e'||to_char( trunc(log(p_base,abs(p_num)))-trunc(mod(log(p_base,abs(p_num)),p_grouplen)) )
                    end;
        end if;
    end; -- tptformat
begin
  p(' ');
  p('DB: &_USER.@&_CONNECT_IDENTIFIER.');
  for i in (select * from &VSQL. where sql_id='&1.' order by inst_id) loop
    p(' ');
    p('-------------------------------------------------------------------------------------------------');
    p('SQL_ID='||i.sql_id||'; CHILD_NUMBER='||i.child_number||'; PLAN HASH: '||i.PLAN_HASH_VALUE||'; Opt Env Hash: '||i.OPTIMIZER_ENV_HASH_VALUE||';'||' INST_ID: '||i.inst_id);
	p('FORCE_MATCHING_SIGN: '||i.force_matching_signature||'; OLD_HASH_VALUE: '||i.OLD_HASH_VALUE);
	begin
	  select object_type||': '||owner||'.'||object_name into l_on from dba_objects s where s.object_id=i.program_id;
	  p(l_on||', line number: '||i.program_line#);
	  exception when no_data_found then null;
	end;
    p('=================================================================================================');
    p('Parsing Schema, Module, Action: '||nvl(i.parsing_schema_name,'<NULL>')||', '||nvl(i.module,'<NULL>')||', '||nvl(i.action,'<NULL>'));
    p('Load_time, First: '||i.first_load_time||', Last: '||i.last_load_time||', Active: '||to_char(i.last_active_time,'dd/mm/yyyy hh24:mi:ss'));
    $IF DBMS_DB_VERSION.version<11 $THEN
      p('SQL Profile: '||nvl(i.sql_profile,'<NULL>'));
    $ELSE
      p('IS_OBSOLETE, IS_BIND_SENSITIVE,IS_BIND_AWARE, IS_SHARABLE: '||nvl(i.IS_OBSOLETE,'<NULL>')||','||nvl(i.IS_BIND_SENSITIVE,'<NULL>')||','||nvl(i.IS_BIND_AWARE,'<NULL>')||','||nvl(i.is_shareable,'<NULL>'));
      p('SQL Profile, SQL Patch, SQL Plan BaseLine: '||nvl(i.sql_profile,'<NULL>')||','||nvl(i.sql_patch,'<NULL>')||','||nvl(i.sql_plan_baseline,'<NULL>'));
    $END    
	p('PX_SERVERS_EXECUTIONS: '||tptformat(i.PX_SERVERS_EXECUTIONS));
    p('PHY_READ_REQ, PHY_READ_BYTES: '||tptformat(i.physical_read_requests)||'; '||tptformat(i.physical_read_bytes));
	p('PHY_WRI_REQ, PHY_WRI_BYTES: '||tptformat(i.physical_write_requests)||'; '||tptformat(i.physical_write_bytes));
    p('Calls: Parse, Exec, Fetch, Rows, EndOfFetch '||i.parse_calls||'; '||i.executions||'; '||i.fetches||'; '||i.ROWS_PROCESSED||'; '||i.end_of_fetch_count);
    p('CPU Time, Elapsed Time: '||tptformat(i.cpu_time,'TIME')||'; '||tptformat(i.elapsed_time,'TIME'));
    p('PIO, LIO, Direct WR: '||tptformat(i.disk_reads)||'; '||tptformat(i.buffer_gets)||'; '||tptformat(i.DIRECT_WRITES));
	p('WAIT: APP, CONCURR, CLUSTER, USER_IO, PL/SQL, JAVA: '||tptformat(i.application_wait_time,'TIME')||'; '||tptformat(i.concurrency_wait_time,'TIME')||'; '||tptformat(i.cluster_wait_time,'TIME')||'; '||tptformat(i.user_io_wait_time,'TIME')||'; '||tptformat(i.PLSQL_EXEC_TIME,'TIME')||'; '||tptformat(i.JAVA_EXEC_TIME,'TIME'));
	if i.disk_reads>0 then p('Awg IO time: '||tptformat(i.user_io_wait_time/i.disk_reads,'TIME'));end if;
	if i.buffer_gets>0 then p('CPU sec/1M LIO: '||tptformat(i.cpu_time/i.buffer_gets));end if;
    p('=================================================================================================');    
    if i.executions>0 then 
      p('LIO/Exec, PIO/Exec, CPU/EXEC, ROWS/EXEC, ELA/EXEC: '||tptformat(round(i.buffer_gets/i.executions,3))||'; '||
	                                                tptformat(round((i.disk_reads+i.DIRECT_WRITES)/i.executions,3))||'; '||
													tptformat(round(i.cpu_time/i.executions,3),'TIME')||'; '||
													tptformat(round(i.ROWS_PROCESSED/i.executions,3))||'; '||
													tptformat(round(i.elapsed_time/i.executions,3),'TIME'));	
    else
      p('LIO/Exec, PIO/Exec, CPU/EXEC, ELA/EXEC: '||tptformat(round(i.buffer_gets))||'; '||tptformat(round(i.disk_reads+i.DIRECT_WRITES))||'; '||tptformat(round(i.cpu_time),'TIME')||'; '||tptformat(round(i.elapsed_time),'TIME'));	
    end if;
    if i.ROWS_PROCESSED>0 then 
      p('LIO/Row, PIO/Row, CPU/Row, ELA/Row, Rows/Sec: '||tptformat(round(i.buffer_gets/i.ROWS_PROCESSED,3))||'; '||tptformat(round((i.disk_reads+i.DIRECT_WRITES)/i.ROWS_PROCESSED,3))||'; '||tptformat(round(i.cpu_time/i.ROWS_PROCESSED,3),'TIME')||'; '||tptformat(round(i.elapsed_time/i.ROWS_PROCESSED,3),'TIME')||'; '||tptformat(round(1e6*i.ROWS_PROCESSED/case when i.elapsed_time=0 then 1 else i.elapsed_time end,3)));	
    else
      p('LIO/Row, PIO/Row, CPU/Row, ELA/Row: '||tptformat(round(i.buffer_gets))||'; '||tptformat(round(i.disk_reads+i.DIRECT_WRITES))||'; '||tptformat(round(i.cpu_time),'TIME')||'; '||tptformat(round(i.elapsed_time),'TIME'));	
    end if;  
    $IF DBMS_DB_VERSION.version>=11 $THEN
	  if i.IO_CELL_OFFLOAD_ELIGIBLE_BYTES>0 then
	    p('=================================================================================================');
		p('Saved %: '||round(100 * (i.IO_CELL_OFFLOAD_ELIGIBLE_BYTES - i.IO_INTERCONNECT_BYTES) / case when i.IO_CELL_OFFLOAD_ELIGIBLE_BYTES=0 then 1 else i.IO_CELL_OFFLOAD_ELIGIBLE_BYTES end,2));
        p('IO_CELL_OFFLOAD_ELIGIBLE_BYTES: '||tptformat(i.IO_CELL_OFFLOAD_ELIGIBLE_BYTES));
	    p('IO_INTERCONNECT_BYTES:          '||tptformat(i.IO_INTERCONNECT_BYTES));
	    p('OPTIMIZED_PHY_READ_REQUESTS:    '||tptformat(i.OPTIMIZED_PHY_READ_REQUESTS));
	    p('IO_CELL_UNCOMPRESSED_BYTES:     '||tptformat(i.IO_CELL_UNCOMPRESSED_BYTES));
	    p('IO_CELL_OFFLOAD_RETURNED_BYTES: '||tptformat(i.IO_CELL_OFFLOAD_RETURNED_BYTES));
        p('=================================================================================================');    	  
	  end if;
    $END 
  end loop;
end;
