package COREMOD as

  procedure register(p_modname opas_modules.MODNAME%type, p_moddescr opas_modules.MODDESCR%type, p_modver opas_modules.MODVER%type, p_installed opas_modules.INSTALLED%type default sysdate);

end;
/
