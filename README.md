# sitesync

Sync local site folders to remote servers with rsync over SSH, or with lftp over
SFTP.

Each site lives under `~/Sites/SITE/` with a small set of config files.
`sitesync` reads those and runs sync with consistent options, filtered output,
and a reliable exit code.

## Requirements

- `zsh`
- `rsync` (SSH sites)
- SSH access to the remote host (rsync over SSH)

For **SFTP-only** hosts (no shell), also install:

```bash
brew install lftp
```

No kernel extension or filesystem mount required.

### SSH authentication

Use **public-key login**, not passwords. `sitesync` runs non-interactively;
password prompts will block or fail.

1. Create a key pair locally if needed (e.g. `~/.ssh/id_ed25519`).
2. Add the **public** key to the remote account’s `~/.ssh/authorized_keys` (the
user named in `.rsync-remote`).
3. Confirm login works before syncing:

```bash
ssh user@host.example
```

For SFTP-only accounts, test with your SFTP client or:

```bash
sftp -P 22 user@host.example
```

## Install

Clone the repo, then symlink the script into your `PATH`:

```bash
git clone git@github.com:koenige/sitesync.git ~/Applications/sitesync
cd ~/Applications/sitesync
./install.sh
```

By default this creates `/usr/local/bin/sitesync` → the repo’s `sitesync`
script. Override the target directory:

```bash
BINDIR="$HOME/bin" ./install.sh
```

## Site setup

For a site named `example.org`, create config files in `~/Sites/example.org/`:

### `.rsync-remote`

One line: destination and remote path.

```
admin@example.org:/home/www/doc/123456/example.org
```

### `.rsync-filter`

Exclude rules. For SSH sites these are rsync filter rules (`--filter=merge …`).
For SFTP sites, lines starting with `-` are converted to lftp `--exclude-glob`
patterns.

Typical entries:

```
- .git
- .gitignore
- .rsync-filter
- .rsync-remote
- .DS_Store
```

Include rules (`+ …`) are only supported for SSH/rsync sites.

### `.rsync-port` (optional)

SSH port, one line. Defaults to `22` if omitted.

```
2222
```

### `.rsync-identity` (optional)

SSH private key path, one line. Use when the key is not picked up automatically
(e.g. non-default filename, or agent not loaded in lftp’s ssh subprocess).

```
~/.ssh/id_ed25519_schmitzknoth
```

### `.rsync-sftp` (SFTP-only hosts)

Create an **empty** marker file for hosts that offer SFTP but no shell
(rsync-over-SSH is not available).

`sitesync` uses **lftp mirror** over SFTP — no mount point, no macFUSE.

**Path in `.rsync-remote`:** use the path **as SFTP sees it** after login (`sftp
user@host`, then `pwd` / `ls`), not the full filesystem path from hosting docs.
Chrooted SFTP accounts often start at `/` with something like `public_html/` —
not `/usr/www/users/…`.

**Scope:** `--exclude-glob` in `.rsync-filter` skips subtrees from sync, but
`lftp` still starts at the path in `.rsync-remote`. To scan only `public_html`,
set that path directly — do not rely on excludes from `/`:

```
user@host.example:public_html
```

`sitesync` then uses `lcd ~/Sites/SITE/public_html` to match.

**SFTP dry-run (`test` / `inittest`):** uses `mirror --dry-run` (no uploads)
with the same `--only-newer --delete` options as a real sync (`go` / `init`), so
it also lists files that would be deleted. Output is shortened to one line per
action (`upload`, `update`, `mkdir`, `delete`), e.g. `update  
_inc/custom/settings.cfg` or `delete   old/file.php`.

```
touch ~/Sites/example.org/.rsync-sftp
```

Example `.rsync-remote` for a chrooted SFTP account:

```
user@host.example:/
```

or:

```
user@host.example:public_html
```

## Usage

```bash
sitesync SITE COMMAND
sitesync help
```

### Commands

| Command | Description |
|---------|-------------|
| `help` | Show usage (`sitesync help` or `sitesync SITE help`) |
| `test` | Dry-run: sync local → remote |
| `go` | Sync local → remote |
| `init` | Pull remote → local |
| `inittest` | Dry-run: pull remote → local |
| `command` | Print the sync command (push) |
| `commandinit` | Print the sync command (pull) |
| `status` | Show transport (SSH vs SFTP) and remote path |

### Typical workflow (SSH)

```bash
sitesync example.org test    # see what would change
sitesync example.org go      # deploy
```

### Typical workflow (SFTP)

```bash
sitesync example.org test    # dry-run over SFTP
sitesync example.org go      # deploy
sitesync example.org status  # show transport and remote path
```

Pull from the server (first checkout or reset):

```bash
sitesync example.org inittest
sitesync example.org init
```

On failure, `sitesync` exits non-zero, so this works:

```bash
sitesync example.org go && echo "Deploy OK"
```

## License

MIT — see [LICENSE](LICENSE).
