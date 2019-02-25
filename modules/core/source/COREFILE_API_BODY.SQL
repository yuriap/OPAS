CREATE OR REPLACE
PACKAGE BODY COREFILE_API AS

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
    select file_contentb into p_locator from opas_files where file_id=p_file_id;
  end;

  procedure  get_locator(p_file_id opas_files.file_id%type, p_locator out opas_files.file_contentc%type) is
  begin
    select file_contentc into p_locator from opas_files where file_id=p_file_id;
  end;

  procedure  get_locator_for_storage(p_file_id opas_files.file_id%type, p_locator out opas_files.file_contentb%type) is
  begin
    update opas_files set file_contentb=empty_blob() where file_id=p_file_id returning file_contentb into p_locator;
  end;
  procedure  get_locator_for_storage(p_file_id opas_files.file_id%type, p_locator out opas_files.file_contentc%type) is
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
    select nvl(dbms_lob.getlength(file_contentc),0) into l_size from opas_files where file_id=p_file_id;
    return l_size;
  end;

  function get_fileb_size(p_file_id opas_files.file_id%type) return number
  is
    l_size number;
  begin
    select nvl(dbms_lob.getlength(file_contentb),0) into l_size from opas_files where file_id=p_file_id;
    return l_size;
  end;

  function get_file_size(p_file_id opas_files.file_id%type) return number
  is
    l_size number;
  begin
    select nvl(dbms_lob.getlength(file_contentb),0)+nvl(dbms_lob.getlength(file_contentc),0) into l_size from opas_files where file_id=p_file_id;
    return l_size;
  end;

  procedure put_file_to_fs(p_blob blob, p_filename varchar2, p_dir varchar2)
  is
    l_file      UTL_FILE.FILE_TYPE;
    l_buffer    RAW(32767);
    l_amount    BINARY_INTEGER := 32767;
    l_pos       INTEGER := 1;
    l_blob_len  INTEGER;
  BEGIN
    coremod_log.log('COREFILE_API.put_file_to_fs: '||p_filename||';'||p_dir,'DEBUG');
    l_blob_len := DBMS_LOB.getlength(p_blob);

    -- Open the destination file.
    l_file := UTL_FILE.fopen(p_dir,p_filename,'wb', 32767);

    -- Read chunks of the BLOB and write them to the file
    -- until complete.
    WHILE l_pos < l_blob_len LOOP
      DBMS_LOB.read(p_blob, l_amount, l_pos, l_buffer);
      UTL_FILE.put_raw(l_file, l_buffer, TRUE);
      l_pos := l_pos + l_amount;
    END LOOP;

    -- Close the file.
    UTL_FILE.fclose(l_file);

  EXCEPTION
    WHEN OTHERS THEN
      -- Close the file if something goes wrong.
      IF UTL_FILE.is_open(l_file) THEN
        UTL_FILE.fclose(l_file);
      END IF;
      RAISE;
  END;

  procedure get_file_from_fs(p_file_id opas_files.file_id%type, p_filename varchar2, p_dir varchar2)
  is
    l_bfile             bfile := bfilename(p_dir, p_filename);
    l_blob              blob;
  begin
    get_locator_for_storage(p_file_id,l_blob);
    dbms_lob.open(l_bfile, dbms_lob.lob_readonly);
    dbms_lob.open(l_blob, dbms_lob.lob_readwrite);
    dbms_lob.loadfromfile(dest_lob      => l_blob,
                          src_lob       => l_bfile,
                          amount        => dbms_lob.getlength(l_bfile));
    dbms_lob.close(l_bfile);
    dbms_lob.close(l_blob);
  end;

  procedure remove_file_from_fs(p_filename varchar2,
                                p_dir varchar2)
  is
    l_exists       BOOLEAN;
    l_file_length  NUMBER;
    l_blocksize    NUMBER;
  begin
    coremod_log.log('COREFILE_API.remove_file_from_fs: '||p_filename||';'||p_dir,'DEBUG');
    UTL_FILE.fgetattr(p_dir, p_filename, l_exists, l_file_length, l_blocksize);
    if l_exists then
      UTL_FILE.FREMOVE ( location => p_dir, filename => p_filename);
    end if;
  end;
END COREFILE_API;
/
