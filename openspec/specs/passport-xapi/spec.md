# Spec: passport-xapi

**Dominio:** passport · **Issue:** #5 · **ADR:** 0004, 0008 · **Estado:** target (pre-poblado, change 2026-06-09-gh-1-keiko-coach-de-carrera)

## Requirements

### Requirement: Mapeo Competency → xAPI statement
El sistema DEBE mapear cada `Competency` del assessment a un statement xAPI válido (`verb=assessed`, `object`=IRI de competencia, `result.score.scaled`).

#### Scenario: Emitir statements desde assessment
- **Given** un `CompetencyAssessment` persistido
- **When** `emit_xapi(assessment)` corre
- **Then** se genera un statement xAPI por competencia con IRIs estables

### Requirement: Escritura on-chain tras puerto swappable
La escritura on-chain DEBE estar detrás de un puerto `OnChainWriter`. En este change el adapter es un stub local; la implementación Starknet es futura (ADR-0004).

#### Scenario: Persistencia con on-chain stubbed
- **Given** statements xAPI generados
- **When** se invoca el `OnChainWriter` stub
- **Then** se persisten en store local y el statement queda listo para una escritura Starknet futura sin cambiar el contrato

#### Scenario: Fallo on-chain sin pérdida de datos
- **Given** un `OnChainWriter` que falla
- **When** se intenta la escritura
- **Then** los datos permanecen en el store local (degradación sin pérdida)
