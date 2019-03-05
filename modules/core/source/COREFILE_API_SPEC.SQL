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

  procedure  get_locator_for_storage(p_file_id opas_files.file_id%type, p_locator out opas_files.file_contentb%type);
  procedure  get_locator_for_storage(p_file_id opas_files.file_id%type, p_locator out opas_files.file_contentc%type);

  procedure store_content(p_file_id opas_files.file_id%type,
                          p_content opas_files.file_contentb%type);

  procedure store_content(p_file_id opas_files.file_id%type,
                          p_content opas_files.file_contentc%type);

  procedure delete_file(p_file_id opas_files.file_id%type);

  function get_filec_size(p_file_id opas_files.file_id%type) return number;
  function get_fileb_size(p_file_id opas_files.file_id%type) return number;
  function get_file_size(p_file_id opas_files.file_id%type) return number;

  --FS
  procedure put_file_to_fs(p_blob blob, p_filename varchar2, p_dir varchar2, p_uncompress boolean default false);
  procedure get_file_from_fs(p_file_id opas_files.file_id%type, p_filename varchar2, p_dir varchar2, p_compress boolean default false);
  procedure remove_file_from_fs(p_filename varchar2, p_dir varchar2);

END COREFILE_API;
/
