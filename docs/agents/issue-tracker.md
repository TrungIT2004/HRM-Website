# Issue Tracker: GitHub

Issues for this repository live in **GitHub Issues** at:
https://github.com/TrungIT2004/HRM-Website/issues

## Operations

| Action | Command |
|--------|---------|
| Create issue | `gh issue create --title "..." --body "..."` |
| List issues | `gh issue list --state open` |
| Get issue | `gh issue view <number>` |
| Close issue | `gh issue close <number>` |
| Add label | `gh issue edit <number> --add-label "..."` |

## Labels

Labels are managed in `docs/agents/triage-labels.md` (if the `triage` skill is installed). The `triage` skill will create any missing labels via `gh label create`.

## PRs as Request Surface

**Disabled.** This repo does not treat external pull requests as a triage input. If you want to enable it, set `prs_as_requests: true` in this file and re-run the triage skill.

## Authentication

Uses the `gh` CLI. Ensure you're authenticated:

```bash
gh auth status
gh auth login  # if needed
```

## Notes

- This is a monorepo containing backend (Spring Boot), frontend (Next.js), AI service (FastAPI), and biometric attendance (Python) services.
- Issues should be tagged with the relevant component: `backend`, `frontend`, `ai-service`, `attendance`, `infra`, `docs`.