alter table trc_wait add call_id NUMBER REFERENCES trc_call ( call_id ) on delete cascade;
create index idx_trc_wait_call on trc_wait(call_id);

alter table trc_stat add call_id NUMBER REFERENCES trc_call ( call_id ) on delete cascade;
create index idx_trc_stat_call on trc_stat(call_id);

CREATE INDEX IDX_TRC_CALL_BINDING ON TRC_CALL (TRC_FILE_ID,trc_slot,row_num,call_id);
