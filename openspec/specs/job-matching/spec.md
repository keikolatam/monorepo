# Spec: job-matching

**Dominio:** matching · **Issue:** #6 · **ADR:** 0008 · **Estado:** target (pre-poblado, change 2026-06-09-gh-1-keiko-coach-de-carrera)

## Requirements

### Requirement: Match de empleo por fit de competencias
El sistema DEBE producir al menos un job match rankeando vacantes seed por fit contra el `CompetencyAssessment` y el `Profile`. La interfaz DEBE ser seed-agnóstica (swap por matching real, p.ej. Mappa, sin cambio de UI).

#### Scenario: Match desde assessment
- **Given** un assessment y un conjunto de vacantes seed
- **When** `match_jobs(assessment, profile)` corre
- **Then** retorna ≥1 vacante rankeada por fit de competencias, renderizada como card con CTA aplicar

### Requirement: Sin integración externa en este change
El matching NO DEBE integrar un proveedor externo (Mappa) en este change; solo ranking sobre seeds detrás de un puerto.

#### Scenario: Stub sin proveedor externo
- **Given** la fase D del thin vertical
- **When** se ejecuta el matching
- **Then** usa solo datos seed y deja el puerto listo para integración futura
