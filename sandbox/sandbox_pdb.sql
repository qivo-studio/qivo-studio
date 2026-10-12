-- One-time: a separate pluggable database for uploaded code and probe runs, isolated from every other database.
-- Run as SYSDBA in the container root, once per sandbox (LINEAGE_SANDBOX, LINEAGE_SANDBOX2... listed in SANDBOX_POOL)
-- and once for the template (LINEAGE_SANDBOX_TPL, see sandbox_lockdown.sql), naming the PDB and the passwords of its
-- admin, of the read-only extractor account (LINEAGE) and of the loader (SANDBOX_LOADER):
--   (echo "DEFINE pdb = LINEAGE_SANDBOX"; echo "DEFINE admin_password = ..."; echo "DEFINE extractor_password = ...";
--    echo "DEFINE loader_password = ..."; cat sandbox/sandbox_pdb.sql) | sqlplus -s / as sysdba
SET VERIFY OFF
WHENEVER SQLERROR EXIT FAILURE
DECLARE
  n NUMBER;
BEGIN
  SELECT COUNT(*) INTO n FROM v$pdbs WHERE name = '&&pdb';
  IF n = 0 THEN
    EXECUTE IMMEDIATE q'[CREATE PLUGGABLE DATABASE &&pdb
      ADMIN USER sandbox_admin IDENTIFIED BY "&&admin_password"
      FILE_NAME_CONVERT = ('/opt/oracle/oradata/FREE/pdbseed/', '/opt/oracle/oradata/FREE/&&pdb/')]';
    EXECUTE IMMEDIATE 'ALTER PLUGGABLE DATABASE &&pdb OPEN';
    EXECUTE IMMEDIATE 'ALTER PLUGGABLE DATABASE &&pdb SAVE STATE';
  END IF;
END;
/
ALTER SESSION SET CONTAINER = &&pdb;
-- Tablespace for uploaded schemas, and the read-only extractor account (same grants as production).
DECLARE
  n NUMBER;
BEGIN
  SELECT COUNT(*) INTO n FROM dba_tablespaces WHERE tablespace_name = 'USERS';
  IF n = 0 THEN
    EXECUTE IMMEDIATE q'[CREATE TABLESPACE users DATAFILE '/opt/oracle/oradata/FREE/&&pdb/users01.dbf'
                         SIZE 50M AUTOEXTEND ON NEXT 50M MAXSIZE 2G]';
  END IF;
  SELECT COUNT(*) INTO n FROM dba_users WHERE username = 'LINEAGE';
  IF n = 0 THEN
    EXECUTE IMMEDIATE 'CREATE USER lineage IDENTIFIED BY "&&extractor_password"';
    EXECUTE IMMEDIATE 'GRANT CREATE SESSION, SELECT ANY DICTIONARY, SELECT_CATALOG_ROLE TO lineage';
  END IF;
  -- The account that loads uploads: creates and drops the uploaded schemas.
  SELECT COUNT(*) INTO n FROM dba_users WHERE username = 'SANDBOX_LOADER';
  IF n = 0 THEN
    EXECUTE IMMEDIATE 'CREATE USER sandbox_loader IDENTIFIED BY "&&loader_password"';
    EXECUTE IMMEDIATE 'GRANT DBA TO sandbox_loader';
  END IF;
END;
/
PROMPT sandbox ready
EXIT
