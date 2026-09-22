# Full readable project snapshot

This branch contains the complete readable source snapshot needed to analyze
the Anomalies feature across the Dofus client UI and the Giny server.

## Included

- Giny server source tree and project files.
- Local server source, launch scripts, migrations, SQL, tests and editors.
- Anomalies module ActionScript, Berilia XML, CSS and image assets.
- Reproducible JPEXS patch sources and diagnostic packages.
- Project specifications and investigation notes.

## Intentionally excluded

- The 17 GB installed Dofus client and proprietary client binaries.
- Generated `DofusInvoker.swf` candidates and binary backups.
- MariaDB executables and live `db-data`.
- Apache Flex and JPEXS binary distributions.
- Build outputs (`bin`, `obj`, `.vs`), logs, caches and downloads.
- Nested Git metadata and local configuration files that may contain secrets.

These exclusions are required by GitHub file/repository limits and do not
remove the source files needed to understand or reproduce the Anomalies work.

