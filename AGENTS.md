# AGENTS.MD - System Directives & Rules

## 1. Core Philosophy

- **Zero Maintenance:** If a process requires daily terminal commands or manual tweaking, prefer an automated, documented alternative.
- **Portability:** The system is cloned across multiple desktops. Keep scripts relative to the repository root and avoid machine-specific paths.
- **100% Free Infrastructure:** Use free/open-source Quartz, GitHub Pages, Git, and community tooling. Obsidian is the user-selected free-to-use authoring application; no paid runtime APIs or subscriptions are required.
- **Public Source Warning:** This repository is public. Notes excluded from the rendered Quartz site remain visible in GitHub source history.

## 2. Operating Procedures: Tool-First Execution

- **Discover and Use Tools:** Use available filesystem, shell, GitHub, and desktop tools before asking the user to perform ordinary project work manually.
- **Think Before Acting:** Before file changes, scripts, UI actions, commits, or pushes, provide a concise user-visible plan and identify the tool and scope. Do not expose private chain-of-thought or require `<thought>` tags.
- **Security Handoffs:** Never automate authentication, password entry, or Obsidian's community-plugin trust decision. Pause for the user where required.

## 3. The "Do / Understand / Undo" Framework

Every deliverable must include:

- **Do:** The actions taken and files or external settings affected.
- **Understand:** A brief explanation of the result (120 words or fewer).
- **Undo:** Exact rollback steps, or an explicit statement when the user selected an irreversible action.

## 4. Tech Stack Constraints

- **Notes:** Obsidian, standard Markdown, and Live Preview with Editing Toolbar.
- **Diagrams:** Excalidraw, with SVG exports for publication.
- **Static Site Generator:** Quartz 4, pinned to the repository's documented upstream commit.
- **Hosting:** Public GitHub Pages through GitHub Actions.
- **AI Formatting:** A reusable Codex prompt in `prompts/`; do not install a local LLM or AI community plugin.

## 5. Automation & Continuous Version Control

- **1-Click Sync:** `sync.bat` and `sync.sh` stage non-ignored files, commit with an ISO timestamp, rebase from `origin/main`, and push.
- **Automated CI/CD:** Pushing to `main` triggers the Quartz build and GitHub Pages deployment.
- **Medium Updates:** After each milestone, inspect the diff, stage only intended files, and commit with a clear message.
- **Confirm Push:** Agent-initiated pushes require explicit user confirmation immediately before pushing. Running the user's sync script is itself the user's push approval.
- **No Destructive Pushes Without Scope:** The initial reset of `AshbyWiki/main` is user-authorized but must use a verified `--force-with-lease` and clearly state that no backup exists.

## 6. Memory & Context Management

- **Context Monitoring:** Track task state and verification evidence throughout the session.
- **95% Rule:** If context capacity is nearing exhaustion, halt normal work and write `memory.md` at the repository root before continuing.
- **State Backup:** `memory.md` must summarize completed work, active tasks, architectural decisions, blockers, and exact next steps. Keep it local and do not publish secrets.
- **Session Reset:** After writing `memory.md`, tell the user to start a new session and command: "Read memory.md to resume."
