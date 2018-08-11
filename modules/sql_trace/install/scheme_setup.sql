-- SQL Trace setup

grant select on V_$DIAG_TRACE_FILE_CONTENTS to &localscheme.;
grant select on V_$EVENT_NAME to &localscheme.;
