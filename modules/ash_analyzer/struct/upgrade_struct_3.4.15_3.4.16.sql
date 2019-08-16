CREATE GLOBAL TEMPORARY TABLE ASHA_CUBE$TMP_STATISTICS
   (SAMPLE_ID   NUMBER, 
    SID         NUMBER,
    INST_ID     NUMBER,
	STATISTIC#  NUMBER, 
	VALUE       NUMBER
   ) ON COMMIT PRESERVE ROWS ;
   
CREATE GLOBAL TEMPORARY TABLE ASHA_CUBE$TMP_WAITS
   (SAMPLE_ID         NUMBER, 
    SID               NUMBER,
    INST_ID           NUMBER,
	EVENT_ID          NUMBER, 
	TOTAL_WAITS       NUMBER,
    TIME_WAITED_MICRO NUMBER
   ) ON COMMIT PRESERVE ROWS ;   
   
CREATE TABLE ASHA_CUBE_STAT_PARS
   (sess_id      number references asha_cube_sess(sess_id) on delete cascade,
    SAMPLE_ID1   NUMBER, 
	SAMPLE_TIME1 TIMESTAMP (6), 
    SAMPLE_ID2   NUMBER, 
	SAMPLE_TIME2 TIMESTAMP (6)
   )
ROW STORE COMPRESS ADVANCED;

create index idx_asha_cube_stats_p_sess on ASHA_CUBE_STAT_PARS(sess_id);
	
CREATE TABLE ASHA_CUBE_STATISTICS
   (sess_id      number references asha_cube_sess(sess_id) on delete cascade,
    SID          NUMBER,
    INST_ID      NUMBER,
	STATISTIC#   NUMBER, 
	VALUE        NUMBER
   )
ROW STORE COMPRESS ADVANCED;
   
create index idx_asha_cube_stats_sess on ASHA_CUBE_STATISTICS(sess_id);

CREATE TABLE ASHA_CUBE_WAITS
   (sess_id           number references asha_cube_sess(sess_id) on delete cascade,
    SID               NUMBER,
    INST_ID           NUMBER,
	EVENT_ID          NUMBER, 
	TOTAL_WAITS       NUMBER,
    TIME_WAITED_MICRO NUMBER
   )
ROW STORE COMPRESS ADVANCED;
   
create index idx_asha_cube_waits_sess on ASHA_CUBE_WAITS(sess_id);

alter table ASHA_CUBE_BLOCK add min_ts timestamp;
alter table ASHA_CUBE_BLOCK add max_ts timestamp;

CREATE TABLE ASHA_CUBE_TOP_SESS_CMPRS
   (SESS_ID NUMBER references asha_cube_sess(sess_id) on delete cascade, 
	SID VARCHAR2(122 BYTE), 
	IDENTITY$ VARCHAR2(1002 BYTE), 
	SEC NUMBER
   );

create index idx_asha_cube_top_sess_c_ss on ASHA_CUBE_TOP_SESS_CMPRS(sess_id);

begin
  for i in (select sess_id from asha_cube_sess) loop
insert into asha_cube_top_sess_cmprs (sess_id, sid, identity$, sec)
select * from (
select sess_id,
    session_id||';'||session_serial#||';'||inst_id sid,
    substr(
    case when module='; ' then null else 'MOD: '||module||'; ' end ||
    case when action='; ' then null else 'ACT: '||action||'; ' end ||
    case when program='; ' then null else 'PRG: '||program||'; ' end ||
    case when client_id='; ' then null else 'CLI: '||client_id||'; ' end ||
    case when machine is null then null else 'MACH: '||machine||'; ' end ||
    case when ecid='; ' then null else 'ECID: '||ecid||'; ' end ||
    case when username is null then null else 'UID: '||username||'; ' end,1,240) || ' ' || round(100*smpls/sum(smpls)over(),2) ||'%'
    identity$,
    smpls sec
from (
SELECT
    sess_id,
    session_id,
    session_serial#,
    inst_id,
    case when min(module)=max(module) then max(module) else min(module)||'; '||max(module) end module,
    case when min(action)=max(action) then max(action) else min(action)||'; '||max(action) end action,
    case when min(program)=max(program) then max(program) else min(program)||'; '||max(program) end program,
    case when min(client_id)=max(client_id) then max(client_id) else min(client_id)||'; '||max(client_id) end client_id,
    max(machine) machine,
    case when min(ecid)=max(ecid) then max(ecid) else min(ecid)||'; '||max(ecid) end ecid,
    max(username) username,
    sum(smpls) smpls
FROM
    asha_cube_top_sess
where sess_id=i.sess_id
group by     sess_id,
    session_id,
    session_serial#,
    inst_id)
    order by smpls desc) where rownum <21;
end loop;
end;
/

truncate table asha_cube_top_sess;

create global temporary table asha_cube$tmp_top_sess
on commit delete rows
as select * from asha_cube_top_sess;

drop table asha_cube_top_sess;