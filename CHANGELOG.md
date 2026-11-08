# Changelog

All notable user-visible changes to the Calibre-Web TOS application package.

## 0.6.27-2 — 2026-11-08

### Changed
- Dual-architecture release: `calibrewebdocker_x86_64.tar.gz` and
  `calibrewebdocker_aarch64.tar.gz`, both built and checked with the official
  `TOSAppSelfTestingTool -c`, published to the same GitHub Release and submitted as
  two developer-platform App records with the same `app_id` and different `platform`.
- The store "Important notice" now leads with the initial login (`admin` / `admin123`),
  followed by the Calibre library path, backup and plain-HTTP notes, so the password
  is visible even in the store's shortened preview.
- The English description was shortened to fit the store preview without being cut
  mid-sentence.

## 0.6.27-1 — 2026-11-08 (withdrawn before review completed)

### Added
- First release. Calibre-Web (`linuxserver/calibre-web:0.6.27-ls409`, Docker Hub official image, unmodified)
  packaged as a TOS 7 Docker application, published on port 8012 and running
  as a non-root user (1000:1000).
- Persistent data is kept under `/Volume1/DockerAppData/calibrewebdocker/`.
