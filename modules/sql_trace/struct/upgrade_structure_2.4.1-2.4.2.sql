create table trc_lobcall (
lobcall_id          NUMBER GENERATED ALWAYS AS IDENTITY primary key,
stmt_id             NUMBER NOT NULL REFERENCES trc_statement ( stmt_id ) on delete cascade,
trc_file_id         NUMBER NOT NULL REFERENCES trc_files ( trc_file_id ) on delete cascade,
call_type           varchar2(100), -- LOBREAD, LOBPGSIZE, LOBARRTMPFRE
lob_type            varchar2(100), -- TEMPORARY, PERSISTENT
row_num             number,
trc_slot            number,
bytes               number,
c                   number,
e                   number,
p                   number,
cr                  number,
cu                  number,
tim                 number
);

create index idx_trc_lobcall_fid on trc_lobcall(trc_file_id);
create index idx_trc_lobcall_stmt on trc_lobcall(stmt_id);

