# OpenSpec — keiko/dapp-monorepo

This directory holds active and recently-shipped decision records (PDRs / ADRs) for the Keiko monorepo. Lifecycle, naming, and per-change file structure live in [`project.md`](./project.md) and [`AGENTS.md`](./AGENTS.md).

## Active changes (`changes/`)

Each change has its own folder named `YYYY-MM-DD-<tracker-id>-<slug>` (date = decision date, tracker-id = GitHub issue ref e.g. `gh-1`, slug = kebab-case description).

| Change | Domain | Files | Status |
|---|---|---|---|
| [`2026-06-09-gh-1-keiko-coach-de-carrera`](./changes/2026-06-09-gh-1-keiko-coach-de-carrera/) | Coach de Carrera (main feature) | `proposal.md` (PDR) + `design.md` (ADR-0001…0008) + `tasks.md` | Design approved — pending implementation (epic [#1](https://github.com/keikolatam/dapp-monorepo/issues/1)) |

## Capability specs (`specs/`)

Capability spec files describe the **current/target state** of a capability — the destination once a change archives. Pre-populated (2026-06-09) as target state for the active change:

- [`interview-coach`](./specs/interview-coach/spec.md) · [`competency-assessment`](./specs/competency-assessment/spec.md) (keystone) · [`support-recommendation`](./specs/support-recommendation/spec.md) · [`passport-xapi`](./specs/passport-xapi/spec.md) · [`job-matching`](./specs/job-matching/spec.md)

## Adding a new change

1. Create `changes/YYYY-MM-DD-<tracker-id>-<slug>/` with `proposal.md` (PDR side), `design.md` (ADR side), and/or `tasks.md` (implementation checklist). Capability specs (current/target state, `Requirement` + `Scenario`) live in `specs/{capability}/spec.md` — not inside the change folder.
2. Track via GitHub Issues (`/make-no-mistakes:spike-recommend` epic + `/make-no-mistakes:spec-recommend` sub-issues).
3. Migration/structural PRs pass `/make-no-mistakes:domain-driven-advisor` before merge.
4. When the change ships, archive: merge deltas into `specs/{capability}/spec.md` and replace the change folder with an `archived.md` pointer.

## Migration notes

The original design lived at `docs/superpowers/specs/2026-06-09-keiko-coach-de-carrera-design.md`; it was migrated here (2026-06-09) and the legacy file left as a "Moved to OpenSpec" pointer for backward-compat.

## Cross-references

- [`DojoCodingLabs/instructional-design-toolkit`](https://github.com/DojoCodingLabs/instructional-design-toolkit) — sibling repo; the `interview-prep-session` IDT extension (issue #7) lands there.
- Convention mirrors `dojocoding/dojo-os/openspec` (date-prefixed PDR/ADR decision records).
