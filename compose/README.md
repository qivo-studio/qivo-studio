# QiVo Studio Enterprise with Docker Compose

One image runs everything: the API and UI (`qivo serve`, with task threads of its own) and extra workers
(`qivo worker`). The store is PostgreSQL. Nothing else is needed: Oracle is reached over the network with a
read-only account, and code can be analysed with no database at all (uploads, Git).

## Install

The guided way: `./install.sh` asks for the first administrator, an Oracle database to scan (optional) and
**whether you want a sandbox for probing** (optional; see below), writes `.env` and starts the stack.

By hand:

```sh
docker pull qivostudio/qivo-studio:latest      # air-gapped: docker load the image from the offline bundle
cp .env.example .env                              # set POSTGRES_PASSWORD, the first administrator, Oracle
docker compose up -d
docker compose ps                                 # app "healthy" after about 20 seconds
```

Open http://localhost:8000 and sign in as `QIVO_ADMIN_EMAIL`. The store is created or upgraded on every start;
the administrator is created on the first start only (change the password in the app afterwards; the
environment never resets it).

## Scan an Oracle database

In the app: **Connections** → add the database (Easy Connect `host:port/service`, the read-only account), then
**Projects** → new project → add the connection as a source and pick the schemas. Extraction and analysis run as
tasks; the task panel shows progress.

From the command line instead, with `ORACLE_*` set in `.env` and the schemas in `lineage.toml`:

```sh
docker compose exec app qivo preflight   # checks the account can read what it needs (read-only)
docker compose exec app qivo extract
docker compose exec app qivo analyse
```

The account needs read access to the dictionary (`SELECT_CATALOG_ROLE` or the views listed by `qivo preflight`);
it never writes to the scanned database.

## Single sign-on

QiVo Studio signs users in through any OpenID Connect provider: Microsoft Entra ID, Okta, Keycloak, Google
Workspace. Register a web application at the provider with the redirect URI
`<QIVO_PUBLIC_URL>/api/auth/oidc/callback`, then set in `.env`:

| Setting | Entra ID | Okta |
|---|---|---|
| `QIVO_OIDC_ISSUER` | `https://login.microsoftonline.com/<tenant id>/v2.0` | `https://<org>.okta.com` (or an authorization server's issuer) |
| `QIVO_OIDC_CLIENT_ID`, `QIVO_OIDC_CLIENT_SECRET` | the app registration's | the app integration's |
| `QIVO_PUBLIC_URL` | the address users open, e.g. `https://qivo.example.com` | same |

Optional: `QIVO_OIDC_DOMAINS` (accepted email domains), `QIVO_OIDC_AUTO_CREATE=true` (a first sign-in creates
the account as a member of `QIVO_ORGANISATION`; otherwise an administrator adds accounts first),
`QIVO_OIDC_ADMIN_GROUP` (a group id in the token's `groups` claim that makes its members administrators; in Entra
ID add the groups claim to the token). The sign-in page then offers "Sign in with `QIVO_OIDC_NAME`" above the
password form. The ID token's signature, issuer, audience, expiry and nonce are checked on every sign-in.

## Operations

| Task | Command |
|---|---|
| More workers | `QIVO_WORKERS=3` in `.env`, then `docker compose up -d` |
| Logs | `docker compose logs -f app worker` |
| Backup | `docker compose exec postgres pg_dump -U qivo qivo > qivo.sql`, and the `secrets` volume (the master key that decrypts stored connection passwords) unless `LINEAGE_MASTER_KEY` comes from your key vault |
| Restore | `docker compose exec -T postgres psql -U qivo qivo < qivo.sql` |
| Upgrade | load the new image, set `QIVO_IMAGE` if its tag changed, `docker compose up -d` (migrations run on start) |
| Accounts | `docker compose exec app qivo user list`; `qivo user add EMAIL --role admin --tenant ORG` (password on stdin with `--password-stdin`) |

Sign-in is required. Set `LINEAGE_AUTH=off` only on a single-user machine that no one else can reach.
