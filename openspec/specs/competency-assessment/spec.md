# Spec: competency-assessment (keystone)

**Dominio:** assessment · **Issue:** #3 · **ADR:** 0006 · **Estado:** target (pre-poblado, change 2026-06-09-gh-1-keiko-coach-de-carrera)

## Requirements

### Requirement: Contrato CompetencyAssessment único
El sistema DEBE definir `CompetencyAssessment` una sola vez en `libs/proto`, generando modelos GraphQL, Dart y Pydantic desde la misma fuente.

#### Scenario: Round-trip del contrato
- **Given** un `CompetencyAssessment` de ejemplo
- **When** se serializa proto → GraphQL → Dart → Pydantic y de vuelta
- **Then** el objeto es idéntico (round-trip test verde)

### Requirement: Estructura del assessment
Un `CompetencyAssessment` DEBE contener `id`, `user_id`, `target_role`, `job_source`, una lista de `Competency` (con `key`, `label`, `score` 0..100, `band`, `confidence`, `evidence[]`, `gap?`), y un `overall`.

#### Scenario: Competencia con gap clasificado
- **Given** una competencia con score bajo
- **When** se ensambla el assessment
- **Then** su `gap` incluye `severity`, `summary` y `recommended_support` ∈ {tutoring, mentoring}

### Requirement: Persistencia como sistema de registro
El assessment DEBE persistirse vía GraphQL en `apps/backend` (Rust), que es el sistema de registro.

#### Scenario: Persistir tras el mock
- **Given** un assessment ensamblado en el sidecar
- **When** se llama `persist_assessment`
- **Then** queda almacenado y recuperable por `GetAssessment`
