# sitesync

Sync local site folders to remote servers with rsync over SSH.

Each site lives under `~/Sites/SITE/` with a small set of config files. `sitesync` reads those and runs rsync with consistent options, filtered output, and a reliable exit code.

## Requirements

- `zsh`
- `rsync`
- SSH access to the remote host (rsync over SSH)

### SSH authentication

Use **public-key login**, not passwords. `sitesync` runs non-interactively; password prompts will block or fail.

1. Create a key pair locally if needed (e.g. `~/.ssh/id_ed25519`).
2. Add the **public** key to the remote account’s `~/.ssh/authorized_keys` (the user named in `.rsync-remote`).
3. Confirm login works before syncing:

```bash
ssh user@host.example
```

## Install

Clone the repo, then symlink the script into your `PATH`:

```bash
git clone git@github.com:koenige/sitesync.git ~/Applications/sitesync
cd ~/Applications/sitesync
./install.sh
```

By default this creates `/usr/local/bin/sitesync` → the repo’s `sitesync` script. Override the target directory:

```bash
BINDIR="$HOME/bin" ./install.sh
```

## Site setup

For a site named `example.org`, create config files in `~/Sites/example.org/`:

### `.rsync-remote`

One line: SSH destination and remote document root.

```
admin@example.org:/home/www/doc/123456/example.org
```

### `.rsync-filter`

Rsync filter rules (excludes, etc.). Passed to rsync via `--filter=merge …`. Typical entries:

```
- .git
- .gitignore
- .rsync-filter
- .rsync-remote
- .DS_Store
```

### `.rsync-port` (optional)

SSH port, one line. Defaults to `22` if omitted.

```
2222
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
| `command` | Print the rsync command (push) |
| `commandinit` | Print the rsync command (pull) |

### Typical workflow

```bash
sitesync example.org test    # see what would change
sitesync example.org go      # deploy
```

Pull from the server (first checkout or reset):

```bash
sitesync example.org inittest
sitesync example.org init
```

On failure, `sitesync` exits non-zero (rsync/SSH error), so this works:

```bash
sitesync example.org go && echo "Deploy OK"
```

## License

MIT — see [LICENSE](LICENSE).
