-- Hardening of the sandbox pool, so code from anyone (registrants included) can run there. Run as SYSDBA in the
-- container root after sandbox_pdb.sql has created the sandboxes, naming the pool account's password:
--   (echo "DEFINE pool_password = <password>"; cat sandbox/sandbox_lockdown.sql) | sqlplus -s / as sysdba
-- then rebuild every sandbox from the template once (sandbox_recycle.sql); the pool does it after every job.
--
--   1. a lockdown profile for every sandbox: no network (UTL_HTTP, UTL_TCP, ...), no OS files (UTL_FILE, external
--      tables, BFILE, external jobs), no Java, no database links. Uploaded code runs as the loader, which is DBA
--      inside its sandbox; the profile keeps that DBA inside the PDB.
--   2. LINEAGE_SANDBOX_TPL: a clean sandbox, read-only, with the profile. After every job the pool drops the
--      sandbox it used and clones it again from the template (about 3 s), so nothing a job created (users,
--      triggers, directories, ACLs) is there for the next job.
--   3. C##LINEAGE_POOL: the account that does that (CREATE PLUGGABLE DATABASE and SYSOPER; it reads no data).
--   4. a startup trigger that opens every PDB but the template (a rebuilt sandbox has no saved state).
-- Idempotent.
SET VERIFY OFF
WHENEVER SQLERROR EXIT FAILURE
DECLARE
  n NUMBER;
BEGIN
  SELECT COUNT(*) INTO n FROM cdb_lockdown_profiles WHERE profile_name = 'LINEAGE_SANDBOX_LOCKDOWN';
  IF n = 0 THEN
    EXECUTE IMMEDIATE 'CREATE LOCKDOWN PROFILE lineage_sandbox_lockdown';
  END IF;
  SELECT COUNT(*) INTO n FROM cdb_users WHERE username = 'C##LINEAGE_POOL' AND con_id = 1;
  IF n = 0 THEN
    EXECUTE IMMEDIATE 'CREATE USER c##lineage_pool IDENTIFIED BY "&&pool_password" CONTAINER = ALL';
  ELSE
    EXECUTE IMMEDIATE 'ALTER USER c##lineage_pool IDENTIFIED BY "&&pool_password" CONTAINER = ALL';
  END IF;
END;
/
ALTER LOCKDOWN PROFILE lineage_sandbox_lockdown DISABLE FEATURE = ('NETWORK_ACCESS', 'OS_ACCESS', 'JAVA', 'JAVA_RUNTIME',
  'COMMON_SCHEMA_ACCESS');
ALTER LOCKDOWN PROFILE lineage_sandbox_lockdown DISABLE STATEMENT = ('CREATE DATABASE LINK', 'ALTER DATABASE LINK');
GRANT CREATE SESSION, CREATE PLUGGABLE DATABASE TO c##lineage_pool CONTAINER = ALL;
GRANT SYSOPER TO c##lineage_pool CONTAINER = ALL;

-- The template: a fresh sandbox (sandbox_pdb.sql must have run with pdb = LINEAGE_SANDBOX_TPL), locked, read-only.
ALTER SESSION SET CONTAINER = LINEAGE_SANDBOX_TPL;
ALTER SYSTEM SET PDB_LOCKDOWN = lineage_sandbox_lockdown;
ALTER SESSION SET CONTAINER = CDB$ROOT;
DECLARE
  mode_now VARCHAR2(20);
BEGIN
  SELECT open_mode INTO mode_now FROM v$pdbs WHERE name = 'LINEAGE_SANDBOX_TPL';
  IF mode_now <> 'READ ONLY' THEN
    IF mode_now <> 'MOUNTED' THEN
      EXECUTE IMMEDIATE 'ALTER PLUGGABLE DATABASE lineage_sandbox_tpl CLOSE IMMEDIATE';
    END IF;
    EXECUTE IMMEDIATE 'ALTER PLUGGABLE DATABASE lineage_sandbox_tpl OPEN READ ONLY';
  END IF;
  EXECUTE IMMEDIATE 'ALTER PLUGGABLE DATABASE lineage_sandbox_tpl SAVE STATE';
END;
/
-- Rebuilt sandboxes have no saved open state (SAVE STATE needs SYSDBA): open every PDB but the template at startup.
CREATE OR REPLACE TRIGGER lineage_open_pdbs AFTER STARTUP ON DATABASE
BEGIN
  EXECUTE IMMEDIATE 'ALTER PLUGGABLE DATABASE ALL EXCEPT lineage_sandbox_tpl OPEN';
EXCEPTION WHEN OTHERS THEN NULL;     -- some were open already
END;
/
PROMPT sandbox lockdown ready
EXIT
