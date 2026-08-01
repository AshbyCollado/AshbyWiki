# Ashby Wiki operations

## What is published

`content/` is the Obsidian vault. Quartz 4 builds only the rendered site; the repository itself is public. Files in `_inbox/`, `_drafts/`, `_unpublished/`, `_templates/`, `.obsidian/`, and `*.excalidraw.md` are excluded from the generated site, but excluded notes remain visible in GitHub source and history. Do not store secrets or confidential material in this repository.

## Folder layout

- `content/index.md` — public landing page.
- `content/textbook/` — reviewed textbook chapters.
- `content/attachments/diagrams/` — synchronized SVG diagram exports.
- `content/_inbox/` — rough notes awaiting formatting.
- `content/_drafts/` and `content/_unpublished/` — tracked, non-rendered working notes.
- `content/_templates/` — tracked authoring templates.
- `content/.obsidian/` — portable settings and the enabled-plugin list; workspaces, caches, and plugin binaries stay local.
- `prompts/` — reusable Codex authoring prompts; not published by Quartz.

## Setup, authoring, and sync

Run `setup.bat` on Windows or `./setup.sh` on macOS/Linux. The script verifies the pinned Node/Git tooling, installs dependencies, and prepares the checkout. Open `content/` as the Obsidian vault, accept Obsidian's community-plugin trust prompt yourself, and use Editing Toolbar plus Excalidraw for authoring.

Run `sync.bat` or `./sync.sh` from the repository root when you want the documented one-click flow: it stages non-ignored files, commits an ISO-timestamped sync commit when needed, rebases on `origin/main`, and pushes `main`. Resolve conflicts locally before retrying. Agent-created milestone pushes require an explicit confirmation immediately before the push.

## Do / Understand / Undo

**Do:** edit notes in `content/`, export diagrams to `content/attachments/diagrams/`, run the build, inspect the diff, and sync through the approved script.

**Understand:** pushes to `main` trigger `.github/workflows/deploy.yml`; GitHub Actions runs `npm ci`, builds `public/` with Quartz, and deploys it to GitHub Pages at `Ashby.wiki` after the custom domain is configured.

**Undo:** for note or configuration mistakes, use `git revert <commit>` and sync the revert. For an uncommitted mistake, restore only the named file with `git restore -- <path>`. DNS and GitHub Pages settings must be restored manually from the pre-change DNS snapshot; the initial repository reset is intentionally irreversible because no backup was requested.
