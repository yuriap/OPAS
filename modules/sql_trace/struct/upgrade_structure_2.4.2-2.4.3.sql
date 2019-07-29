create table trc_similar_stmt (
stmt_id_sim         NUMBER primary key, 
stmt_id_base        NUMBER REFERENCES trc_statement ( stmt_id ) on delete set null,
trc_file_id         NUMBER NOT NULL REFERENCES trc_files ( trc_file_id ) on delete cascade
) organization index;

alter table trc_similar_stmt add constraint FK_STMT_SIM foreign key (stmt_id_sim) REFERENCES trc_statement ( stmt_id ) on delete cascade;

create index idx_similar_stmt_file on trc_similar_stmt(trc_file_id);