# The sandbox: compiling and running code in your own Oracle

Most analysis needs no database at all: QiVo Studio reads the code (ParseOra) and the catalogue it extracts with a
read-only account. A sandbox adds two things on top:

- **verification**: uploaded code is compiled with PL/Scope in a sandbox and compared with what ParseOra worked out;
- **probes**: dynamic SQL that the code alone cannot decide is run in the sandbox with instrumentation, and the SQL
  it builds is recorded as evidence (labelled "probed", never as proof).

The sandbox is a set of pluggable databases (PDBs) in a container database **that you control and that is not
production**. Code from uploads runs there, so it is isolated three ways: a lockdown profile, a separate PDB per
job, and a rebuild from a clean template after every job.

## What you need

- Oracle Database 19c or later, multitenant (a CDB you can create PDBs in). Oracle Database Free 23ai works.
- About 4 GB of disk per sandbox (each is capped at 4 GB) and one for the template.
- SYSDBA in that CDB, once, to run the setup scripts.

## Set it up

All scripts are in this folder and are idempotent. Run them as SYSDBA in the CDB root.

1. **The template and the sandboxes.** One run per PDB: `LINEAGE_SANDBOX_TPL` (the template), then
   `LINEAGE_SANDBOX`, `LINEAGE_SANDBOX2`... (one job runs in each at a time):

   ```sh
   (echo "DEFINE pdb = LINEAGE_SANDBOX_TPL"; echo "DEFINE admin_password = ..."
    echo "DEFINE extractor_password = ..."; echo "DEFINE loader_password = ..."
    cat sandbox_pdb.sql) | sqlplus -s / as sysdba
   ```

   Use the same three passwords for every PDB. The script assumes datafiles under `/opt/oracle/oradata/FREE`;
   change the `FILE_NAME_CONVERT` paths to your layout, or remove them if the CDB uses Oracle-managed files.

2. **Lockdown and the pool account.**

   ```sh
   (echo "DEFINE pool_password = ..."; cat sandbox_lockdown.sql) | sqlplus -s / as sysdba
   ```

3. **Rebuild each sandbox from the template once** (the app does this after every job from then on):

   ```sh
   (echo "DEFINE pdb = LINEAGE_SANDBOX"; cat sandbox_recycle.sql) | sqlplus -s / as sysdba
   ```

4. **Tell QiVo Studio**: in the app, **Settings → Sandbox for probing → Plug in a sandbox** (an administrator; saved
   encrypted, for your organisation), or for the whole installation in `.env`:

   ```sh
   SANDBOX_POOL=dbhost:1521/LINEAGE_SANDBOX,dbhost:1521/LINEAGE_SANDBOX2
   SANDBOX_DSN=dbhost:1521/LINEAGE_SANDBOX
   SANDBOX_LOADER_USER=sandbox_loader
   SANDBOX_LOADER_PASSWORD=...            # loader_password
   SANDBOX_CDB_DSN=dbhost:1521/FREE       # the CDB root's service
   SANDBOX_POOL_USER=c##lineage_pool
   SANDBOX_POOL_PASSWORD=...              # pool_password
   SANDBOX_DATAFILES=/opt/oracle/oradata/FREE    # where PDB datafiles live, or "omf"
   ```

5. **Check it:** `qivo sandbox-check` (with Compose: `docker compose exec app qivo sandbox-check`). It signs in to
   every sandbox, confirms the lockdown profile, runs a small job and confirms nothing of it is left.

## The accounts and what they can do

| Account | Where | Can | Cannot |
|---|---|---|---|
| `SANDBOX_LOADER` | each sandbox PDB | create and drop schemas and objects, run code (DBA inside its PDB) | reach the network (UTL_HTTP, UTL_TCP, UTL_SMTP...), the OS (UTL_FILE, external tables, BFILE, external jobs), Java, database links, common schemas: the lockdown profile |
| `LINEAGE` | each sandbox PDB | read the dictionary (what QiVo Studio extracts after a compile) | write anything |
| `C##LINEAGE_POOL` | CDB root | close, drop, clone and open sandbox PDBs (CREATE PLUGGABLE DATABASE, SYSOPER) | read any data |

## What is left behind

Nothing. After every job the sandbox it used is dropped and cloned again from the template (about 3 seconds), so
no user, object, trigger, grant or directory a job created survives into the next job. A sandbox that cannot be
rebuilt is taken out of the pool (its reason is shown in the app) instead of serving another job unclean.
