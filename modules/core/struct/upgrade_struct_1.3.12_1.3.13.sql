CREATE OR REPLACE FORCE VIEW V$OPAS_DB_LINKS AS 
with gn as (select value from v$parameter where name like '%domain%')
select DB_LINK_NAME,
       case
         when DB_LINK_NAME = '$LOCAL$' then DB_LINK_NAME
         else l.db_link
       end ORA_DB_LINK,
       case
         when DB_LINK_NAME = '$LOCAL$' then DISPLAY_NAME
         else 
           case when l.username is not null then DISPLAY_NAME||' ('||l.username||'@'||l.host||')' else DISPLAY_NAME||' (SUSPENDED)' end
         end DISPLAY_NAME,
       OWNER,
       STATUS,
       IS_PUBLIC
  from OPAS_DB_LINKS o, user_db_links l, gn
 where owner =
       decode(owner,
              'PUBLIC',
              owner,
              decode(is_public, 'Y', owner, nvl(V('APP_USER'), '~^')))
   and l.db_link(+) = case when gn.value is null then upper(o.DB_LINK_NAME) else upper(o.DB_LINK_NAME ||'.'|| gn.value) end;