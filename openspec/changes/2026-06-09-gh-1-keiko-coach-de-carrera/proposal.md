# GH-1 — Keiko Coach de Carrera

**Change ID:** 2026-06-09-gh-1-keiko-coach-de-carrera
**Fecha de decisión:** 2026-06-09
**Estado:** Diseño aprobado — pendiente de implementación
**Épica de tracking:** [#1](https://github.com/keikolatam/dapp-monorepo/issues/1) · Milestone "Keiko Coach de Carrera v1"

## Qué

El **main feature** de Keiko: un agente IA **Coach de Carrera** que prepara entrevistas para un rol objetivo, conduce un **mock interview calificado**, produce un **Competency Assessment**, y de los gaps genera **recomendaciones de tutores/mentores** (marketplace) + un **match de empleo** — alimentando el LifeLearningPassport (xAPI on-chain).

Se entrega como **thin vertical** con peso **A ≫ C ≫ B ≫ D**, precedido de una **Fase 0** de migración del monorepo a la convención `apps/*` + `libs/` bajo Explicit Architecture.

## Por qué

- Es el **selling point diferenciador** de Keiko, learner-driven, frente a la gestión instructor-céntrica de cursos de Dojo OS (`InstructionManagementTab`) — con la que evitamos conflicto de interés.
- Reutiliza base funcional existente (patrón GenUI `genui_chat_page` sobre `agentic-core`) como **adapter**, no fork.
- Da carne a scaffolds que ya existen en Keiko (`selfstudy_guides`, `marketplace`, `reputation`, `learning_passport`).
- Convierte el desempeño en entrevistas en **evidencia verificable** en el Passport (la tesis de producto de Keiko).
- Extiende el Instructional Design Toolkit (Irby 2018: tutoría vs mentoría) design-time + runtime.

## Alcance

### Incluido
- **Fase 0** — migración a `apps/*` + `libs/{domain,application,adapters,proto}` + `packages/keiko_ui`; limpieza de deuda `polkadot_dart`/`web3dart` → `starknet.dart`.
- **A** — Coach (persona + tools) + contrato `CompetencyAssessment` (keystone) + persistencia Rust + UI en `apps/mobile`.
- **C** — Recomendación: clasificación Irby (tutoría/mentoría) + plan de sesión IDT runtime + query de marketplace con reputación.
- **B (delgado)** — Puente xAPI al Passport; escritura on-chain stubbed.
- **D (delgado)** — Job matching estilo Mappa sobre vacantes seed.
- **IDT (cross-repo)** — tipo de sesión `interview-prep-session` en `DojoCodingLabs/instructional-design-toolkit`.

### Pendiente (fuera de este change)
- Escritura real a Keikochain (Merkle-batched xAPI) — consolidación Starknet (ver ADR-0004).
- Integración real con Mappa.ai.
- Autenticación multiusuario (este change asume un usuario demo).
- Pulido design-time completo del IDT.

## Entrada (inputs del coach)

**Vacante-first**: rol objetivo + descripción de vacante (texto/URL). El CV es **opcional y schema-agnóstico** (texto/Markdown/Reactive Resume JSON/PDF) — nunca se exige JSON Resume (ver ADR-0007).

## Etiquetas
- Tipo: feature (épica)
- Tamaño: XL → descompuesto (ver `tasks.md`)
- Prioridad: alta · 🔥 Critical Path
