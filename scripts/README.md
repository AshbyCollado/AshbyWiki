# Obsidian community plugins

`obsidian-plugins.lock.json` pins the two approved plugins and their official GitHub release assets:

- Editing Toolbar `editing-toolbar` `4.0.11` (`PKM-er/obsidian-editing-toolbar`)
- Excalidraw `obsidian-excalidraw-plugin` `2.25.3` (`zsviczian/obsidian-excalidraw-plugin`)

The URLs are pinned to the official release tags [`4.0.11`](https://github.com/PKM-er/obsidian-editing-toolbar/releases/tag/4.0.11) and [`2.25.3`](https://github.com/zsviczian/obsidian-excalidraw-plugin/releases/tag/2.25.3) in the lock file.

Run `scripts/install-obsidian-plugins.ps1` on Windows or `scripts/install-obsidian-plugins.sh` on macOS/Linux. Pass `-Check` (PowerShell) or `--check` (shell) to validate the lock manifest without downloading. The installer downloads to a temporary directory, validates every plugin manifest (`id` and `version`), then atomically swaps plugin directories and updates `content/.obsidian/community-plugins.json`. A failed validation or move rolls back the previous installation and leaves no staged files.

The lock file records SHA-256 checksums for each exact release asset. Installers verify those checksums before validating the plugin manifest, so a changed or substituted download fails before any vault files are replaced.

Do: run the platform installer from the repository root (or pass the vault path), then open `content/` in Obsidian and enable the pinned plugins.

Understand: only the two pinned community plugins are installed. Existing community plugin IDs are preserved and the two IDs are added exactly once.

Undo: delete `content/.obsidian/plugins/editing-toolbar` and `content/.obsidian/plugins/obsidian-excalidraw-plugin`, then remove their IDs from `content/.obsidian/community-plugins.json`. Before a successful installation the script automatically restores prior files if any swap fails.
