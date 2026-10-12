# QiVo Studio

**Deterministic column-level lineage for Oracle SQL and PL/SQL.** See where every column comes from, what a change
will hit, and what the code really does, including dynamic SQL. What cannot be decided from the code is reported as a
gap with its reason; nothing is guessed.

[Website](https://qivo.studio) · [Documentation](https://qivo.studio/docs) · [Install guide](https://qivo.studio/docs/install) ·
[Requirements](https://qivo.studio/docs/requirements) · [Pricing](https://qivo.studio/pricing) ·
[Docker Hub](https://hub.docker.com/r/qivostudio/qivo-studio) · [PyPI](https://pypi.org/project/qivo-studio/)

This repository holds the files to install QiVo Studio yourself, the release notes and the issue tracker. QiVo Studio
is free to use under its [licence agreement](LICENSE.md); it is not open source.

## What it does

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
qivo serve            # then open http://127.0.0.1:8000/app
```

## A sandbox for probing (optional)

Lineage needs no database at all. A sandbox adds probing of dynamic SQL the code cannot decide by itself; it must be
an Oracle database you control that is not production: [sandbox/README.md](sandbox/README.md).

## Help

[Open an issue](https://github.com/qivo-studio/qivo-studio/issues) or write to admin@qivo.studio. Enterprise plans
and support: [qivo.studio/pricing](https://qivo.studio/pricing). Open-source components are listed in
[THIRD_PARTY_NOTICES.md](THIRD_PARTY_NOTICES.md).
