# GH-1 — Keiko Coach de Carrera · Diseño (ADRs)

**Change ID:** 2026-06-09-gh-1-keiko-coach-de-carrera

## Arquitectura

*Principio rector: Python razona y transmite; Rust registra y verifica. No se reconstruye nada que ya funcione.*

```
apps/mobile (Flutter)
   │  WebSocket (A2UI stream)        │ GraphQL (datos no-stream)
   ▼                                 ▼
apps/coach-sidecar (ADAPTER)     apps/api-gateway (GraphQL)
  main.py (boota AgentRuntime)        │ gRPC + Redis Streams
  agents/interview-coach.yaml         ▼
  tools/ (adapters a Keiko)       apps/backend (Rust = registro)
  dep pinneada: agentic-core         interview_coach · learning_passport
  (NO fork)                          marketplace · reputation
                                  apps/appchain (Cairo/Starknet)
libs/{domain,application,adapters,proto}  ← Explicit Architecture compartida
cross-repo: DojoCodingLabs/instructional-design-toolkit (interview-prep-session)
```

## Capas (Explicit Architecture)

- **Domain** (`libs/domain`, cero deps): `CompetencyAssessment`, `Competency`, `Gap`, statements xAPI.
- **Application** (`libs/application`): casos de uso/CQRS — Commands (`PersistAssessment`, `EmitXapi`), Queries (`GetAssessment`, `QueryTutors`, `MatchJobs`); puertos.
- **Adapters** (`libs/adapters`): persistencia, marketplace, `OnChainWriter` (Starknet, stub), `agentic-core` gRPC.
- **Proto** (`libs/proto`): `competency_assessment.proto` — modelo de dominio compartido.

## Flujo del agente (coach-sidecar)

`normalize_profile(cv?)` → `derive_rubric(job,role)` → prep brief (GenUI) → loop[`score_answer`] → `assemble_assessment` → `persist_assessment` → `emit_xapi` (B) → por gap: `classify_support`+`generate_session_plan`+`query_tutors` (C) → `match_jobs` (D).

---

## Decisiones de Arquitectura (ADRs)

### ADR-0001 — Migrar el monorepo a `apps/*` + `libs/` + `packages/`
- **Estado:** Aceptada (2026-06-09).
- **Contexto:** Keiko es el único monorepo de Andrés fuera de la convención `apps/*` que usan vertivo/altrupets/aduanext/habitanexus. `frontend/` está prácticamente vacío y los módulos backend son scaffolds.
- **Decisión:** Migrar todo a `apps/{mobile,backend,api-gateway,grpc-gateway,appchain,coach-sidecar,widgetbook}` + `packages/keiko_ui` + `libs/{domain,application,adapters,proto}` como **Fase 0**, antes del vertical.
- **Consecuencias:** (+) Convergencia barata ahora; tooling consistente. (−) Toca Cargo workspace, Makefile, docker-compose, CI, Scarb → barrera serial con build verde obligatorio. Gate: `/make-no-mistakes:domain-driven-advisor` en el PR.

### ADR-0002 — Explicit Architecture en backend y mobile
- **Estado:** Aceptada.
- **Contexto:** Directiva del usuario; precedente `aduanext` (`libs/{domain,application,adapters,proto}`).
- **Decisión:** DDD + Hexagonal + Onion + Clean + CQRS (Herberto Graça). Dominio puro al centro; transportes (WebSocket/GraphQL/Starknet RPC) como adapters de infraestructura. `CompetencyAssessment` vive en `libs/proto`, mapeado (no filtrado) a cada capa.
- **Consecuencias:** (+) Aislamiento, testabilidad, bounded contexts claros. (−) Más ceremonia de capas; requiere disciplina de no filtrar adapters al dominio.

### ADR-0003 — `agentic-core` como ADAPTER, no port/fork
- **Estado:** Aceptada.
- **Contexto:** `agentic-core` es una librería Python (LangGraph, WebSocket, A2UI). Copiarla = fork divergente que mantener a mano.
- **Decisión:** Consumirla como **dependencia pinneada** en `apps/coach-sidecar` (persona YAML + tools custom + `main.py` con `AgentRuntime`). Precedente canónico: `altrupets/apps/agent-sidecar` (`agentic-core @ file:///...`).
- **Consecuencias:** (+) Cero reimplementación del runtime; bumps de versión en vez de merges de fork. (−) Dependencia de un upstream **BUSL-1.1** → confirmar derechos de uso en producción.

### ADR-0004 — Appchain: Starknet/Madara (no Polkadot)
- **Estado:** Aceptada (análisis de tradeoffs 2026-06-09, veredicto 5-3).
- **Contexto:** Histórico Polkadot (`polkadot_dart` en pubspec), pero el repo ya está comprometido con Starknet (README, `keikochain.toml`, madara-cli, gateway Rust↔Cairo).
- **Decisión:** Consolidar en Starknet/Madara. Borrar `polkadot_dart`/`web3dart`, adoptar `starknet.dart`.
- **Consecuencias:** (+) Verificabilidad STARK nativa per-batch (tesis de producto); batch-proving barato para microescrituras LATAM; Account Abstraction nativa (onboarding sin seed phrase). (−) Madara inmaduro (mitigar: settle a Starknet L2, pin de `madara-alliance`, validar SNOS en Sepolia); curva Cairo.

### ADR-0005 — Extensión IDT doble-vía (design-time + runtime)
- **Estado:** Aceptada.
- **Contexto:** Las skills del IDT son design-time (Claude Code), no invocables en producción; viven en otro repo.
- **Decisión:** (runtime) tool `generate_session_plan` en coach-sidecar que embebe la metodología Irby; (design-time) nuevo tipo `interview-prep-session` en `DojoCodingLabs/instructional-design-toolkit` que consume un gap del assessment. Schema de gap compartido para evitar drift.
- **Consecuencias:** (+) Honra "extender el IDT"; una sola metodología en dos superficies. (−) Coordinación cross-repo; mantener schemas alineados.

### ADR-0006 — `CompetencyAssessment` como contrato keystone
- **Estado:** Aceptada.
- **Contexto:** B, C y D consumen el mismo artefacto del coach.
- **Decisión:** Definirlo UNA vez en `libs/proto` + GraphQL + Dart + Pydantic, con round-trip test. Mapea 1:1 a xAPI (cada `Competency` → statement `assessed`, `result.score.scaled`).
- **Consecuencias:** (+) Una sola fuente de verdad; consumidores desacoplados. (−) Cambios al contrato ripplean a 4 consumidores → congelarlo temprano.

### ADR-0007 — Inputs vacante-first; CV opcional y schema-agnóstico
- **Estado:** Aceptada.
- **Contexto:** El usuario tuvo que hand-authorear su CV en Reactive Resume JSON; forzar JSON Resume schema fue fricción real.
- **Decisión:** Entrada por vacante; CV opcional aceptado en cualquier formato (texto/Markdown/Reactive Resume JSON/PDF) y normalizado por el agente. Nunca gate por schema.
- **Consecuencias:** (+) Menos fricción de adopción (protege el funnel). (−) `normalize_profile` debe ser robusto a inputs heterogéneos/incompletos.

### ADR-0008 — Thin vertical con stubs deliberados (B/D)
- **Estado:** Aceptada.
- **Contexto:** Disciplina de alcance; 80% del valor con 20% de complejidad.
- **Decisión:** REAL: migración, coach+assessment, recomendación, marketplace seed. STUB: escritura on-chain (B), Mappa real (D), IDT design-time completo, auth. Los stubs van detrás de puertos para swap futuro sin cambio de contrato.
- **Consecuencias:** (+) Narrativa demostrable rápido sin over-engineering. (−) Deuda explícita rastreada en `tasks.md` y en los issues.

## Pendiente
Consolidación Starknet (contratos Cairo en git, pin Madara, SNOS testnet, Merkle-batching xAPI, AA onboarding) — ver ADR-0004.
