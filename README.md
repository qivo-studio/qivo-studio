# QiVo Studio

**Turn your Oracle code base into business knowledge.** QiVo Studio connects jobs, SQL, PL/SQL, variables, tables
and columns, with their configuration, logs and scripts, into **QiVo MetaGraph**, a code ontology built on
code, config, logs and scripts. On it: column-level lineage, impact, code-quality rules and answers for Claude, Copilot
and any MCP client. What cannot be decided from the code is reported as a gap with its reason; nothing is guessed.

[Website](https://qivo.studio) · [Documentation](https://qivo.studio/docs) · [Install guide](https://qivo.studio/docs/install) ·
[Requirements](https://qivo.studio/docs/requirements) · [Pricing](https://qivo.studio/pricing) ·
[Docker Hub](https://hub.docker.com/r/qivostudio/qivo-studio) · [PyPI](https://pypi.org/project/qivo-studio/)

This repository holds the files to install QiVo Studio yourself, the release notes and the issue tracker. QiVo Studio
is free to use under its [licence agreement](LICENSE.md); it is not open source.

## What it does

- **QiVo MetaGraph, the CodeBase Ontology**: every table, column, unit, statement, job and dynamic SQL site as one
  graph, each fact with its evidence (code, config, log or script), built after every analysis.
- **AI tools (MCP)**: Claude, Copilot and any MCP client ask the MetaGraph through thirteen read-only tools.
- **QiVo Rules**: 24 code-quality and security rules that use the whole estate (`qivo check`, SARIF for CI).
- **Column-level lineage** across tables, views, materialized views, packages, procedures, functions, triggers and
  object types, through PL/SQL variables, records, collections, cursors and parameters.
- **Dynamic SQL resolved**, not ignored: built from constants, CASE/DECODE branches, control tables, call sites and the
  dictionary; optionally probed in an isolated Oracle sandbox.
- **Impact study**: rename, retype or drop a column and see every unit, column and job it reaches.
- **Proof on every link**, and a named gap where there is none.
- **Schedulers**: Oracle Scheduler, Control-M and IBM Workload Scheduler, linked to the code they run.
- **Read-only** against your databases: no recompiles, no PL/Scope, no Diagnostics Pack. Oracle 12.2 to 23ai/26ai.
- OpenLineage export; single sign-on (Microsoft Entra ID, Okta, any OpenID Connect provider).

## Three ways to use it

| | For | How |
|---|---|---|
| **QiVo Cloud** | Nothing to install: Free, Personal, Team and Enterprise plans | Sign up at [qivo.studio](https://qivo.studio) |
| **Self-hosted** | Teams and whole estates on your own servers: live read-only Oracle connections, Git, schedulers, your own sandbox | Docker Compose or Kubernetes (below) |
| **Explorer** | One person on a laptop, no database | `pip install qivo-studio` then `qivo serve` |

## Requirements (self-hosted)

| | Minimum | Recommended | Large estates |
|---|---|---|---|
| CPU | 2 cores | 4 cores | 8+ cores |
| Memory | 4 GB | 8 GB | 16+ GB |
| Disk | 20 GB | 50 GB SSD | 100+ GB SSD |

- **Linux** (x86-64 or ARM64): Docker Engine 24+ with the Compose plugin.
- **macOS** 11+ (Apple silicon or Intel): Docker Desktop (or OrbStack, Colima).
- **Windows** 10/11: Docker Desktop with the WSL 2 backend and Linux containers.
- **Kubernetes** 1.27+ with Helm 3.
- **Explorer**: Python 3.12+ on Linux, macOS or Windows.

Details: [qivo.studio/docs/requirements](https://qivo.studio/docs/requirements).

## Install with Docker Compose

### Linux and macOS

```sh
git clone https://github.com/qivo-studio/qivo-studio.git
cd qivo-studio/compose
./install.sh
```

The guided installer asks for the first administrator, an Oracle database to scan (optional) and whether you want a
sandbox for probing (optional), writes `.env` and starts QiVo Studio. Open http://localhost:8000 and sign in.

On macOS, install and start [Docker Desktop](https://www.docker.com/products/docker-desktop/) first, and give it at
least 4 GB of memory (Settings → Resources).

### Windows

Install [Docker Desktop](https://www.docker.com/products/docker-desktop/) (WSL 2 backend, Linux containers) and
[Git for Windows](https://git-scm.com/download/win). Then either run `./install.sh` in a WSL terminal, or in
PowerShell:

```powershell
git clone https://github.com/qivo-studio/qivo-studio.git
cd qivo-studio\compose
copy .env.example .env
notepad .env          # set POSTGRES_PASSWORD, QIVO_ADMIN_EMAIL, QIVO_ADMIN_PASSWORD, QIVO_ORGANISATION
docker compose up -d
```

The administrator password needs at least 12 characters with upper and lower case letters and a digit.

Upgrades, workers, backups and single sign-on: [compose/README.md](compose/README.md) and
[qivo.studio/docs/docker](https://qivo.studio/docs/docker).

## Install on Kubernetes

```sh
git clone https://github.com/qivo-studio/qivo-studio.git
helm install qivo ./qivo-studio/helm/qivo-studio --namespace qivo --create-namespace \
  --set admin.email=you@example.com --set admin.password='Choose-a-long-passw0rd'
```

Settings: [helm/qivo-studio/values.yaml](helm/qivo-studio/values.yaml). Air-gapped installs: ask us for the offline
bundle ([qivo.studio/docs/kubernetes](https://qivo.studio/docs/kubernetes)).

## Explorer on your laptop

```sh
pip install qivo-studio
qivo serve            # then open the address it prints, usually http://127.0.0.1:8000/app
```

If port 8000 is busy, `qivo serve` uses the next free port (8001, 8002, ...) and says so. To choose a port, run
`qivo serve --port 8080` or set `QIVO_PORT=8080`. A port you choose is used as it is: if it is busy, the command
stops with a one-line message.

## Free tools: ParseOra and ScanOra

Two small packages, free to use, no QiVo Studio server needed:

```sh
pip install qivo-parseora      # the parser on its own: Oracle SQL, PL/SQL, SQL*Plus scripts (12.2 to 26ai)
parseora parse --json src/     # one JSON line per statement: kind, errors, tables
parseora parse --errors --version 19c install.sql
parseora lab                   # ParseOra Lab in your browser: tree, outline, tokens, problems, profile, downloads
parseora report src/ --out report/   # report.html plus CSV and JSON files

pip install qivo-scanora       # a read-only export of a database you cannot reach from QiVo Studio
scanora export --dsn db:1521/ORCLPDB --user QIVO_READER --schemas ETL,DW -o finance.scanora
qivo import-scan finance.scanora --analyse      # then, wherever QiVo Studio runs
```

`scanora queries` prints every query ScanOra sends (all SELECT, in a read-only transaction), for your DBA to review.
No Oracle client is needed for either.

## Use with AI tools (MCP)

AI tools (Claude, Copilot in VS Code, your own agents) can ask **QiVo MetaGraph**, the CodeBase Ontology, about your
estate through MCP: lineage, impact, join paths, the context to write SQL, code, dynamic SQL, gaps, findings and the
glossary. Every fact names its witnesses (code, config, log), its proof level and its evidence; what could not be
proven comes back as a gap. It only reads, never touches your databases, and each user sees only their own projects.
Every call is in the audit log.

Since 0.1.2 **every analysis builds the MetaGraph** (projects, uploads, playground sessions). A project analysed by an
older version gets one with **Build MetaGraph** in its header, or `qivo graph build <scan>` on the server.

| Edition | Address | Sign-in |
|---|---|---|
| QiVo Cloud | `https://qivo.studio/mcp` | a personal access token from **Settings → AI tools (MCP)** |
| Self-hosted | `https://your-server/mcp` | a token from **Settings → AI tools (MCP)**, or made by an administrator (below) |
| Explorer | none: the AI tool starts `qivo mcp` on your laptop | none |

Each user creates, copies (once) and revokes their own tokens in **Settings → AI tools (MCP)**, which also shows
ready-to-copy snippets for Claude Code, Claude Desktop and VS Code. An administrator can make one on the server:

```sh
docker compose exec app qivo token create you@example.com --name "Claude" --days 90     # printed once
docker compose exec app qivo token list
docker compose exec app qivo token revoke <id>
kubectl exec -n qivo deploy/qivo-qivo-studio-app -- qivo token create you@example.com --name "Claude"   # Helm release "qivo"
```

Claude Code: `claude mcp add --transport http qivo https://your-server/mcp --header "Authorization: Bearer <token>"`.
On a laptop (Explorer): `claude mcp add qivo -- qivo mcp`. Claude Desktop and VS Code:
[qivo.studio/docs/mcp](https://qivo.studio/docs/mcp).

## Ask QiVo (chat in the app)

**Ask QiVo** answers questions about a project in the app, from the same MetaGraph tools, with your own model. An
administrator connects the organisation's model in **Settings → AI model**: Anthropic (Claude), OpenAI, Azure OpenAI,
or an OpenAI-compatible endpoint inside your network (Ollama, vLLM) for air-gapped installs. Keys are stored
encrypted and never shown again. The model is called only when someone asks, and sees only what that person may see;
it has no tool that writes or runs SQL. Optional settings: `QIVO_ASK_PERSONAL_MODELS=on` lets users add their own
keys; `QIVO_ASK_PER_MINUTE` (default 10) limits questions per user. Guide: [qivo.studio/docs/ask](https://qivo.studio/docs/ask).

## A sandbox for probing (optional)

Lineage needs no database at all. A sandbox adds probing of dynamic SQL the code cannot decide by itself; it must be
an Oracle database you control that is not production: [sandbox/README.md](sandbox/README.md).

## Help

[Open an issue](https://github.com/qivo-studio/qivo-studio/issues) or write to admin@qivo.studio. Enterprise plans
and support: [qivo.studio/pricing](https://qivo.studio/pricing). Open-source components are listed in
[THIRD_PARTY_NOTICES.md](THIRD_PARTY_NOTICES.md).
