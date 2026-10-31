# GH-1 — Keiko Coach de Carrera · Tasks

**Change ID:** 2026-06-09-gh-1-keiko-coach-de-carrera

Orden: Fase 0 (barrera, build verde) → A → C → B → D · IDT en paralelo tras A.
Cada fase mapea a un GitHub issue (ver columna).

## Fase 0 — Migración apps/* + libs/ (issue #2) · chore/L/worktree
- [ ] **F0-01** `git mv` `frontend|backend|api-gateway|grpc-gateway|appchain` → `apps/*` (preservar historia)
- [ ] **F0-02** Crear `libs/{domain,application,adapters,proto}`, `packages/keiko_ui`, `apps/widgetbook`
- [ ] **F0-03** Extraer theme `frontend/lib/presentation/theme` → `packages/keiko_ui` (path-dependency)
- [ ] **F0-04** Actualizar `Cargo.toml` members, `.cargo/`, `Makefile`, `docker-compose.yml`, `.github/workflows`, Scarb paths
- [ ] **F0-05** Borrar `polkadot_dart`/`web3dart` de `apps/mobile/pubspec.yaml`; añadir `starknet.dart`; limpiar imports huérfanos
- [ ] **F0-06** `cargo build --workspace` + `flutter analyze` + CI verdes
- [ ] **F0-07** Actualizar diagrama de arquitectura del README
- [ ] **F0-08** PR revisado vía `/make-no-mistakes:domain-driven-advisor` (gate obligatorio)

## A — Interview Coach + contrato (issue #3) · feature/L/team
- [ ] **A-01** `libs/proto/competency_assessment.proto` + tipo GraphQL + modelos Dart/Pydantic
- [ ] **A-02** Round-trip test del contrato proto↔GraphQL↔Dart↔Pydantic
- [ ] **A-03** `apps/coach-sidecar`: `main.py` + `agents/interview-coach.yaml` con `agentic-core` pinneado
- [ ] **A-04** Tools: `normalize_profile`, `derive_rubric`, `score_answer`, `assemble_assessment`, `persist_assessment`
- [ ] **A-05** `apps/backend` persistencia del assessment (capas Explicit Architecture)
- [ ] **A-06** `apps/mobile`: feature coach (patrón genui chat portado) + cards en `packages/keiko_ui` (Atomic Design + M3)

## C — Recomendación Irby + IDT runtime + marketplace (issue #4) · feature/M/team
- [ ] **C-01** Tool `classify_support(gap)` (heurística Irby tutoría/mentoría, documentada)
- [ ] **C-02** Tool `generate_session_plan(gap,type)` (estructura IDT 7-pasos como template)
- [ ] **C-03** `apps/backend` marketplace+reputation: seed tutores/mentores con tags de competencia
- [ ] **C-04** Query `query_tutors(competency,type)` (CQRS read, seed-agnóstica)
- [ ] **C-05** Cards de recomendación con CTA "solicitar sesión" (jitsi/agora ya en pubspec)
- [ ] **C-06** Assessment sin gaps salta C limpiamente

## B — Puente xAPI al Passport (issue #5) · feature/M/solo
- [ ] **B-01** `emit_xapi(assessment)` en `learning_passport`: cada `Competency` → statement xAPI (verb=assessed)
- [ ] **B-02** IRIs de verb/object estables y documentadas
- [ ] **B-03** Persistencia a store local; puerto `OnChainWriter` stubbed (swap Starknet futuro)
- [ ] **B-04** Path de fallo on-chain degrada sin pérdida de datos

## D — Job matching (issue #6) · feature/S/solo
- [ ] **D-01** `match_jobs(assessment, profile)`: vacantes seed + ranking por fit
- [ ] **D-02** Interface matcher seed-agnóstica (swap Mappa futuro)
- [ ] **D-03** Card de match con CTA aplicar (keiko_ui, M3)

## IDT cross-repo — interview-prep-session (issue #7) · feature/S/solo
- [ ] **IDT-01** `commands/new-interview-prep-session.md` + skill en `DojoCodingLabs/instructional-design-toolkit`
- [ ] **IDT-02** Consume gap del `CompetencyAssessment` (schema alineado con design §ADR-0006)
- [ ] **IDT-03** `session-type-detector` rutea gap → tutoría/mentoría
