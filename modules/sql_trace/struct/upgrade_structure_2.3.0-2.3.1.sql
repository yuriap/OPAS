CREATE GLOBAL TEMPORARY TABLE TRC$TMP_WAIT_HIST
   (    SQLID VARCHAR2(100 BYTE), 
    WAIT_CLASS VARCHAR2(64 BYTE), 
    NAM VARCHAR2(100 BYTE), 
    CNT NUMBER, 
    ELA NUMBER, 
    ELA_32 NUMBER,
    ELA_64 NUMBER,
    ELA_128 NUMBER,
    ELA_256 NUMBER, 
    ELA_512 NUMBER, 
    ELA_1024 NUMBER,
    ELA_2048 NUMBER,
    ELA_4096 NUMBER,
    ELA_8192 NUMBER,
    ELA_16384 NUMBER,
    ELA_32768 NUMBER,
    ELA_65536 NUMBER,
    ELA_131072 NUMBER,
    ELA_262144 NUMBER,
    ELA_524288 NUMBER,
    ELA_1048576 NUMBER,
    ELA_2097152 NUMBER,
    ELA_4194304 NUMBER,
    ELA_8388608 NUMBER,
    ELA_16777216 NUMBER,
    ELA_33554432 NUMBER,
    ELA_GR_32S   number
   ) ON COMMIT DELETE ROWS ;

CREATE INDEX TRC$TMP_WAIT_HIST_SQLID ON TRC$TMP_WAIT_HIST (SQLID) ;
  
  
alter table trc_files add (source_retention number default null, parsed_retention number default null);

update trc_files
set 
  source_retention=decode(SOURCE_KEEP_FOREVER,'Y',0,null),
  parsed_retention=decode(PARSED_KEEP_FOREVER,'Y',0,null);

commit;

alter table trc_files drop column SOURCE_KEEP_FOREVER;
alter table trc_files drop column PARSED_KEEP_FOREVER;