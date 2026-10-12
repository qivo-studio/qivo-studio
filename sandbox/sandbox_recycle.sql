-- Rebuild one sandbox from the clean template (what the pool does after every job, python/qivo/upload/pool.py).
-- Run as SYSDBA (or C##LINEAGE_POOL) in the container root:
--   (echo "DEFINE pdb = LINEAGE_SANDBOX"; cat sandbox/sandbox_recycle.sql) | sqlplus -s / as sysdba
SET VERIFY OFF
WHENEVER SQLERROR EXIT FAILURE
DECLARE
  n NUMBER;
  m VARCHAR2(20);
BEGIN
  SELECT COUNT(*) INTO n FROM v$pdbs WHERE name = '&&pdb';
  IF n > 0 THEN
    SELECT open_mode INTO m FROM v$pdbs WHERE name = '&&pdb';
    IF m <> 'MOUNTED' THEN
      EXECUTE IMMEDIATE 'ALTER PLUGGABLE DATABASE &&pdb CLOSE IMMEDIATE';
    END IF;
    EXECUTE IMMEDIATE 'DROP PLUGGABLE DATABASE &&pdb INCLUDING DATAFILES';
  END IF;
  EXECUTE IMMEDIATE q'[CREATE PLUGGABLE DATABASE &&pdb FROM lineage_sandbox_tpl
    FILE_NAME_CONVERT = ('/opt/oracle/oradata/FREE/LINEAGE_SANDBOX_TPL/', '/opt/oracle/oradata/FREE/&&pdb/')
    STORAGE (MAXSIZE 4G)]';
  EXECUTE IMMEDIATE 'ALTER PLUGGABLE DATABASE &&pdb OPEN';
END;
/
PROMPT sandbox &&pdb rebuilt
EXIT
