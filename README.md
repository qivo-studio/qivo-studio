# QiVo Studio

Deterministic column-level lineage for Oracle SQL and PL/SQL: where every column comes from, what a change will hit,
and what the code really does, including dynamic SQL. What cannot be decided from the code is reported as a gap, with
its reason; nothing is guessed.

Website and cloud: **https://qivo.studio**. This repository holds the files to install QiVo Studio yourself, release
notes and the issue tracker. QiVo Studio is free to use under its [licence agreement](LICENSE.md); it is not open
source.

## Three ways to use it

| | What | How |
|---|---|---|
| **QiVo Cloud** | Nothing to install. Free tier, Personal, Team, Enterprise | Sign up at https://qivo.studio |
| **Self-hosted** | Teams and whole estates on your own servers: live read-only Oracle connections, Git, schedulers, your own sandbox for probing, single sign-on | Docker Compose or Kubernetes (below) |
| **Explorer** | One person, one laptop, no database | `pip install qivo-studio` then `qivo serve` (Python 3.12+) |

## Docker Compose

```sh
git clone https://github.com/qivo-studio/qivo-studio.git
cd qivo-studio/compose
./install.sh          # asks for the first administrator, an Oracle database (optional), a sandbox (optional)
```

Then open http://localhost:8000. The image is `qivostudio/qivo-studio` on Docker Hub (Intel and ARM). Manual setup,
upgrades, backups and single sign-on: [compose/README.md](compose/README.md).

## Kubernetes (Helm)

```sh
helm install qivo ./helm/qivo-studio --namespace qivo --create-namespace \
  --set admin.email=you@example.com --set admin.password='a long password'
```

Settings: [helm/qivo-studio/values.yaml](helm/qivo-studio/values.yaml).

## A sandbox for probing (optional)

Lineage needs no database at all. A sandbox adds probing of dynamic SQL the code cannot decide by itself; it must be
an Oracle database you control that is not production: [sandbox/README.md](sandbox/README.md).

## Questions

Open an issue here, or write to admin@qivo.studio. Open-source components are listed in
[THIRD_PARTY_NOTICES.md](THIRD_PARTY_NOTICES.md).
