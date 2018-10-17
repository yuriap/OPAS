CREATE OR REPLACE
PACKAGE COREFILE_API AS

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
