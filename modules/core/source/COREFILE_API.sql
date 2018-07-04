create or replace PACKAGE COREFILE_API AS

  function create_file(p_modname   opas_files.modname%type,
                       p_file_type opas_files.file_type%type,
                       p_file_name opas_files.file_name%type,
                       p_mimetype  opas_files.file_mimetype%type,
                       p_owner     opas_files.owner%type default 'PUBLIC'
                      ) return     opas_files.file_id%type;

  procedure  get_locator(p_file_id opas_files.file_id%type, p_locator out opas_files.file_contentb%type);
  procedure  get_locator(p_file_id opas_files.file_id%type, p_locator out opas_files.file_contentc%type);

  procedure store_content(p_file_id opas_files.file_id%type,
                          p_content opas_files.file_contentb%type);

  procedure store_content(p_file_id opas_files.file_id%type,
                          p_content opas_files.file_contentc%type);
                          
  procedure delete_file(p_file_id opas_files.file_id%type);
  
  function get_filec_size(p_file_id opas_files.file_id%type) return number;
  function get_fileb_size(p_file_id opas_files.file_id%type) return number;

END COREFILE_API;
/

--------------------------------------------------------
show errors
--------------------------------------------------------

create or replace PACKAGE BODY COREFILE_API AS

  function create_file(p_modname   opas_files.modname%type,
                       p_file_type opas_files.file_type%type,
                       p_file_name opas_files.file_name%type,
                       p_mimetype  opas_files.file_mimetype%type,
                       p_owner     opas_files.owner%type default 'PUBLIC'
                      ) return     opas_files.file_id%type AS
    l_file_id opas_files.file_id%type;
  BEGIN
    INSERT INTO opas_files (  modname,  file_type,  file_name,  file_mimetype,file_contentb,file_contentc,created,owner)
                    VALUES (p_modname,p_file_type,p_file_name,p_mimetype,     null,         null,         default,p_owner) returning file_id into l_file_id;
    return l_file_id;
  END create_file;

  procedure  get_locator(p_file_id opas_files.file_id%type, p_locator out opas_files.file_contentb%type) is
  begin
    update opas_files set file_contentb=empty_blob() where file_id=p_file_id returning file_contentb into p_locator;
  end;
  procedure  get_locator(p_file_id opas_files.file_id%type, p_locator out opas_files.file_contentc%type) is
  begin
    update opas_files set file_contentc=empty_clob() where file_id=p_file_id returning file_contentc into p_locator;
  end;

  procedure store_content(p_file_id opas_files.file_id%type,
                          p_content opas_files.file_contentb%type) AS
  BEGIN
    update opas_files set file_contentb=p_content where file_id=p_file_id;
  END store_content;

  procedure store_content(p_file_id opas_files.file_id%type,
                          p_content opas_files.file_contentc%type) AS
  BEGIN
    update opas_files set file_contentc=p_content where file_id=p_file_id;
  END store_content;

  procedure delete_file(p_file_id opas_files.file_id%type)
  is
  begin
    delete from opas_files where file_id = p_file_id;
  end;
  
  function get_filec_size(p_file_id opas_files.file_id%type) return number
  is
    l_size number;
  begin
    select dbms_lob.getlength(file_contentc) into l_size from opas_files where file_id=p_file_id;
    return l_size;
  end;
  
  function get_fileb_size(p_file_id opas_files.file_id%type) return number
  is
    l_size number;
  begin
    select dbms_lob.getlength(file_contentb) into l_size from opas_files where file_id=p_file_id;
    return l_size;
  end;  
  
END COREFILE_API;
/

--------------------------------------------------------
show errors
--------------------------------------------------------