# AGENTS — Instrucciones OpenSpec para Keiko

## Flujo OpenSpec

Los cambios siguen el ciclo **propose → apply → archive**:

1. **Propose** — `openspec/changes/{change-id}/` con:
   - `proposal.md` — el PDR (Product/Proposal Decision Record): Qué, Por qué, Alcance, Etiquetas.
   - `design.md` — Arquitectura + **ADRs** (Architecture Decision Records numerados).
   - `tasks.md` — checklist atómico con IDs, ejecutable por `/make-no-mistakes:spec-recommend`.
   El change folder es PDR/ADR/tasks **puro** (modelo dojo-os) — las capability specs NO van dentro del change.
   - `openspec/specs/{capability}/spec.md` — current/target state de cada capability, formato `### Requirement:` + `#### Scenario:` (Given/When/Then). Se pre-pueblan como target y se consolidan al archivar.
2. **Apply** — implementar según `tasks.md`, bajo el protocolo make-no-mistakes.
3. **Archive** — al mergear, consolidar el current-state en `openspec/specs/{capability}/spec.md` y reemplazar el change por un `archived.md` pointer.

## Reglas de la casa

- **Explicit Architecture** (DDD+Hexagonal+Onion+Clean+CQRS) en backend y mobile. Dominio puro; transportes como adapters.
- `agentic-core` se consume como dependencia pinneada (adapter), **nunca se forkea**.
- CV del usuario es **schema-agnóstico**: nunca forzar JSON Resume ni ningún schema único.
- Appchain: **Starknet/Madara**. No reintroducir Polkadot (`polkadot_dart`/`web3dart` son deuda a eliminar).
- **Todo PR de migración estructural pasa por `/make-no-mistakes:domain-driven-advisor` antes de merge.**
- UI compartida (`packages/keiko_ui`) vía `/atomic-design-toolkit:generate` con Material 3.

## Capabilities (dominios de spec)

`interview-coach` · `competency-assessment` (keystone) · `support-recommendation` · `passport-xapi` · `job-matching`.
