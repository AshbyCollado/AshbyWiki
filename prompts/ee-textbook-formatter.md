# EE textbook formatter for Codex

Use this prompt when converting one rough engineering note into a publishable Ashby Wiki textbook chapter.

## Inputs and output

1. Read the specified source note under `content/_inbox/` (or another path the user explicitly names).
2. Preserve the source note. Only delete or move it when the user explicitly asks.
3. Write the finished chapter to `content/textbook/<topic>.md`, using a lowercase kebab-case filename unless the user supplies a filename.
4. Return Markdown only in the created chapter; do not add HTML, generated site files, or files outside the requested chapter and any explicitly requested diagram placeholder.

## Required chapter shape

Use YAML frontmatter with `title`, `description`, and `tags`. Then include:

- A short `> [!tldr]` callout answering what the reader should remember.
- A motivating introduction and a clearly scoped learning objective.
- Definitions before first use, explicit assumptions, and SI units on every physical quantity.
- Headings that move from concept to derivation to application.
- LaTeX equations for mathematical relationships. Put a bold label immediately before important formulas, for example `**Ohm's law:**` followed by the equation.
- At least one worked example when the source contains enough information to support one. Show units through each meaningful calculation and state the result with appropriate precision.
- A concise recap and links to related Ashby Wiki notes when those notes exist.

## Fidelity and uncertainty

- Preserve the source's meaning and technical intent; explain unclear wording rather than silently changing it.
- Do not invent measurements, citations, component values, standards, or historical claims.
- If a claim, value, or unit cannot be established from the source or a supplied authoritative reference, keep it but mark it inline as `[VERIFY: explain what must be checked]`.
- Do not create citations or links that were not supplied or verified.
- Resolve contradictions by stating the competing assumptions and marking the unresolved choice `[VERIFY]`.

## Diagrams and links

- Keep Obsidian wikilinks and relative Markdown links portable within the vault.
- If a diagram would improve the explanation, add a short placeholder such as `<!-- EXCALIDRAW: describe the circuit or geometry to draw -->` and, when an SVG exists, embed it with a relative path such as `![[attachments/diagrams/<name>.svg]]`.
- Never publish an `.excalidraw.md` source file as a chapter asset; Quartz excludes those files while retaining synchronized SVG exports.

Before finishing, check frontmatter validity, heading order, equation delimiters, unit consistency, and every `[VERIFY]` marker. Mention any unresolved verification items after the chapter is written.
