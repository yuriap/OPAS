CREATE OR REPLACE
package body COREMOD as

  procedure register(p_modname opas_modules.MODNAME%type, p_moddescr opas_modules.MODDESCR%type, p_modver opas_modules.MODVER%type, p_installed opas_modules.INSTALLED%type default sysdate)
  is
  begin
    merge into opas_modules t using (select p_modname modname, p_moddescr moddescr, p_modver modver, p_installed installed from dual) s
    on (t.modname = s.modname)
    when matched then update set
      t.moddescr = s.moddescr, t.modver = s.modver, t.installed = s.installed
    when not matched then insert
      (t.modname, t.moddescr, t.modver, t.installed)
    values
      (s.modname, s.moddescr, s.modver, s.installed);
    commit;
  end;

end;
/
