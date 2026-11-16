# Domain Documentation: Single-Context

This repository uses a **single-context** domain documentation layout:

- **Glossary**: `GLOSSARY.md` at the repository root
- **ADRs**: `docs/adr/` at the repository root

## Glossary (`GLOSSARY.md`)

The glossary defines domain terms, acronyms, and concepts used across the codebase. It is the single source of truth for domain language.

### Consumer Rules

1. **Read before writing**: Any agent working on domain code MUST read `GLOSSARY.md` first.
2. **Update on change**: When adding new domain concepts, types, or changing existing ones, update `GLOSSARY.md` in the same change.
3. **Cross-reference**: Use `[[Term]]` wiki-links in code comments, ADRs, and docs to link to glossary entries.
4. **No duplicates**: Do not redefine terms in ADRs or code comments — link to the glossary instead.

### Format

```markdown
## Term Name

**Definition**: One-sentence definition.

**Context**: Which module/service uses this (e.g., `backend:auth`, `frontend:attendance`, `ai-service:rag`).

**Related**: [[OtherTerm]], [[AnotherTerm]]
```

## ADRs (`docs/adr/`)

Architecture Decision Records capture significant architectural decisions.

### Consumer Rules

1. **Read before deciding**: Check existing ADRs before proposing a new architectural direction.
2. **Immutable once merged**: ADRs are append-only. To supersede, write a new ADR linking to the old one.
3. **Status field**: Every ADR must have a `Status: Proposed | Accepted | Superseded | Deprecated` frontmatter field.

### Format

```markdown
---
title: Short descriptive title
status: Accepted
date: YYYY-MM-DD
deciders: [@username]
tags: [backend, database, auth]
---

## Context

What problem are we solving?

## Decision

What did we decide?

## Consequences

### Positive
- ...

### Negative
- ...

### Neutral
- ...
```

### Naming

Files: `NNNN-short-title.md` (zero-padded 4-digit sequence).

## Index Files

If the glossary or ADR count grows large (>50 entries), create index files:
- `GLOSSARY-INDEX.md` — alphabetical list of terms with one-line summaries
- `docs/adr/INDEX.md` — table of ADRs with status and one-line summaries

## Current State

As of setup: neither `GLOSSARY.md` nor `docs/adr/` exist yet. They will be created on first use.