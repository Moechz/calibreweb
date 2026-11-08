# calibreweb-for-tos

> TerraMaster TOS 7 App Center — **Docker application** package for
> [Calibre-Web](https://github.com/janeczku/calibre-web).

## Important / 重要提示

- **Initial login / 初始账号**: `admin` / `admin123` — change the password immediately after the first sign-in. / 首次登录后请立即修改密码。
- **Bring your own Calibre library / 必须自备书库**: Calibre-Web does not create a Calibre library. Put the folder that contains `metadata.db` and the book files into `/Volume1/DockerAppData/calibrewebdocker/books`, then enter `/books` as the library path in the web UI. / 本应用不创建 Calibre 书库；请把含 `metadata.db` 的书库放到上述目录，并在网页里把书库路径填为 `/books`。
- **No File Manager access / 文件管理器不可见**: `DockerAppData` is not listed in TOS File Manager; upload the library with SSH/SFTP. / 请用 SSH/SFTP 上传书库。
- **Backup / 备份**: copy both `config/` and `books/` before uninstalling with data removal. / 卸载并删除数据前请备份 `config/` 与 `books/`。
- **Plain HTTP / 明文 HTTP**: the app is served over LAN HTTP; do not expose port 8012 to the internet without a TLS reverse proxy. / 不要在没有 TLS 反代的情况下把 8012 暴露到公网。
- **DockerEngine / 依赖**: DockerEngine is required; add a Docker Hub mirror if Docker Hub is unreachable. / 需要 DockerEngine；无法访问 Docker Hub 时请先配置镜像加速。

## What this is

A four-file TOS Docker application archive (`calibrewebdocker.tar.gz`) that installs
Calibre-Web on TOS 7 through the App Center:

- `config.ini` — TOS application metadata (`application_type: docker`, id `calibrewebdocker`)
- `calibrewebdocker.lang` — 23-language superset (TOS requires 14)
- `calibrewebdocker.svg` — application icon (568 bytes, 2 SVG elements)
- `docker-compose.yml` — one service, image `linuxserver/calibre-web:0.6.27-ls409`

## How it works

| | |
|---|---|
| Container image | `linuxserver/calibre-web:0.6.27-ls409` (Docker Hub, used unmodified) |
| Open | `http://<NAS-IP>:8012/` (container port 8083) |
| Runs as | non-root, `user: "1000:1000"` |
| Persistent data | `/config` → `/Volume1/DockerAppData/calibrewebdocker/config`, `/books` → `/Volume1/DockerAppData/calibrewebdocker/books` |
| Logs | `docker logs calibrewebdocker` (stdout/stderr) |

Everything persistent lives in two mounted folders: `config` holds the settings database (`app.db`), the Google Drive database (`gdrive.db`), the encryption key for stored service credentials (`.key`) and the thumbnail cache; `books` is the Calibre library itself - the folder that contains `metadata.db` and the ebook files Calibre-Web serves. Copying those two folders is a complete backup.

## Design highlights

- **Non-root by construction.** `user: "1000:1000"`; the container reports uid 1000 on real hardware.
- **Entrypoint wrapper for privileges.** The upstream image starts s6-overlay as root and drops to its internal `abc` user, which cannot work inside a non-root container. `src/entrypoint.sh` bypasses s6 and starts Calibre-Web directly, keeping the `/app` code unmodified and read-only.
- **Cache and log stay in the data volume.** `CACHE_DIRECTORY=/config/cache` and `-o /dev/stdout` mean nothing under `/app` has to be writable; only the container-internal `/tmp` is used for transient files.
- **Two volumes, one published port.** `config` keeps the application state, `books` is the Calibre library the user brings; only the web UI publishes a host port.
- **Health check** probes `/` on container port 8083; Calibre-Web answers with a 302 to its login or first-run page, which `curl` treats as success.
- **Fixed image tag, never `:latest`**, Docker Hub only, no `privileged`, no `network_mode: host`, no `cap_add`, no Docker socket. The archive is built deterministically (uid/gid 0, zeroed timestamps, no gzip timestamp).

## Runtime file manifest

Everything the application writes on the NAS lives inside its own data
directory; the container-internal `/tmp` is discarded with the container. The
table lists what is created and how it behaves. Nothing else is written.

| Path | Purpose | Created when | Growth bound | Lifecycle |
|---|---|---|---|---|
| `config/app.db` | settings, users, passwords and the configured Calibre library path (SQLite database) | first start | grows with settings and user accounts | never overwritten; back it up with the config folder |
| `config/gdrive.db` | Google Drive integration database (empty unless that feature is used) | first start | only when Google Drive is configured | never overwritten; keep it with app.db |
| `config/.key` | Fernet key used to encrypt stored service credentials | first start | static | never overwritten; without it saved credentials can no longer be decrypted |
| `config/cache` | generated book cover and thumbnail cache | on demand | grows with the library, safe to delete | managed by Calibre-Web; rebuilds automatically |
| `books` | the Calibre library folder with metadata.db and the ebook files | by the user | grows with every added book | owned by the user; back it up before uninstalling with data removal |
| `/Volume1/DockerAppData/calibrewebdocker/config` | Calibre-Web application data (everything the container writes outside /tmp) | on first start / on demand | bounded by your own data | persistent; kept on uninstall unless you ask to delete it |
| `/Volume1/DockerAppData/calibrewebdocker/books` | Calibre-Web application data (everything the container writes outside /tmp) | on first start / on demand | bounded by your own data | persistent; kept on uninstall unless you ask to delete it |

## Build

```bash
scripts/build.sh                  # -> out/calibrewebdocker.tar.gz + .sha256
scripts/build.sh 0.6.27-3   # packaging iteration bump
scripts/build.sh 0.6.27-2 aarch64
```

The build stages the four files, substitutes the version/platform placeholders,
embeds `src/entrypoint.sh` into the compose file (escaping every `$` as `$$`), removes CRLF/BOM/AppleDouble, then runs
`tools/verify.py`, a review-standards self-check (archive layout, JSON validity,
required fields, 14+ language coverage, version consistency, Docker-Hub-only
images, fixed tag, reserved/recommended host ports, non-root user, per-service
healthcheck/TZ/restart, data path below the application data root, never the
`/Volume*` wildcard, comment-free sequence blocks, `x-app-meta` position, no
literal secrets and the SVG size/element limits).

## Local verification

```bash
./TOSAppSelfTestingTool -c out/calibrewebdocker.tar.gz   # official spec check
bash test/install-and-verify.sh                  # on-device E2E (needs root)
```

> Docker applications cannot be side-loaded through the App Center's manual
> install page (it accepts `.deb` only); the official self-testing tool's `-i`
> mode or `docker compose` are the only ways to install one for testing.

## Store submission checklist

1. Public GitHub repo (code + README only).
2. Release **tag `v0.6.27-2`**, assets `calibrewebdocker.tar.gz` +
   `calibrewebdocker.tar.gz.sha256` (Docker asset naming: `<app_id>.tar.gz`, **no
   platform suffix**).
3. Developer platform → Add Application: ID `calibrewebdocker`, package type Docker,
   repository URL, architecture `x86_64`.
4. Version Management → Add Version `0.6.27-2` → automated validation → review.

## License / branding

Calibre-Web is distributed by its upstream authors under **GPL-3.0**. The container image is the official image from Docker Hub (`linuxserver/calibre-web:0.6.27-ls409`) and is used unmodified; no upstream source code is redistributed here. This packaging is an independent community submission by Moechz and is not affiliated with the upstream project or TerraMaster.

## Limitations

Calibre-Web does not create a Calibre library. You must copy an existing library (the folder that contains `metadata.db` and the book files) into `DockerAppData/calibrewebdocker/books` before the first-run wizard can open it; `/books` is the path to enter in the UI.
TOS File Manager cannot browse `DockerAppData`, so the library has to be uploaded over SSH/SFTP or copied on the NAS itself.
The app is served over plain HTTP on the LAN. Do not expose the published port to the internet without a TLS reverse proxy.
One Calibre library per instance: the container mounts a single `books` folder and Calibre-Web is configured with one library path.
Book conversion and some optional features depend on tools shipped by the upstream image; they are used as-is and are not modified by this package.

---

Packaged for TOS 7 by Moechz. Upstream image used unmodified from Docker Hub.
