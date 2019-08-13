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