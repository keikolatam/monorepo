# libs/ — Explicit Architecture (compartido)

Capas compartidas bajo **Explicit Architecture** (DDD + Hexagonal + Onion + Clean + CQRS). Ver `openspec/changes/2026-06-09-gh-1-keiko-coach-de-carrera/design.md` ADR-0002.

- **`domain/`** — entidades, value objects, eventos de dominio (cero dependencias). Ej.: `CompetencyAssessment`, `Competency`, `Gap`, statements xAPI.
- **`application/`** — casos de uso / CQRS (Commands, Queries), puertos (interfaces).
- **`adapters/`** — implementaciones de puertos: persistencia, marketplace, `OnChainWriter` (Starknet), `agentic-core` gRPC.
- **`proto/`** — contratos proto compartidos (incl. `competency_assessment.proto`).

> Scaffolding inicial (Fase 0). El contenido se llena en los issues A/C/B/D.
