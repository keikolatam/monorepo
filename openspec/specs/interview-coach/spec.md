# Spec: interview-coach

**Dominio:** coach · **Issue:** #3 · **Estado:** target (pre-poblado, change 2026-06-09-gh-1-keiko-coach-de-carrera)

## Requirements

### Requirement: Intake vacante-first con CV opcional
El coach DEBE iniciar una sesión con un rol objetivo y una descripción de vacante (texto o URL). El CV es opcional y se acepta en cualquier formato sin imponer un schema.

#### Scenario: Inicio solo con vacante
- **Given** un usuario sin CV
- **When** provee rol objetivo + descripción de vacante
- **Then** el coach deriva una rúbrica de competencias y arranca el prep

#### Scenario: CV en formato heterogéneo
- **Given** un usuario que pega su CV como texto, Markdown, Reactive Resume JSON o PDF
- **When** el coach lo recibe
- **Then** `normalize_profile` produce un `Profile` interno sin exigir JSON Resume schema

#### Scenario: CV ausente o ilegible
- **Given** un CV vacío o corrupto
- **When** `normalize_profile` lo procesa
- **Then** degrada a un `Profile` vacío sin abortar la sesión

### Requirement: Mock interview calificado
El coach DEBE conducir un mock interview turn-by-turn y calificar cada respuesta contra la rúbrica, transmitiendo score cards como surfaces GenUI.

#### Scenario: Calificación por respuesta
- **Given** una rúbrica de competencias derivada de la vacante
- **When** el usuario responde una pregunta
- **Then** `score_answer` emite un score con evidencia y se renderiza como surface en streaming

### Requirement: Runtime adapter sobre agentic-core
El coach DEBE correr en `apps/coach-sidecar` consumiendo `agentic-core` como dependencia pinneada (sin fork).

#### Scenario: Boot del sidecar
- **Given** `agents/interview-coach.yaml` + tools registradas
- **When** `main.py` ejecuta `AgentRuntime(settings).start()`
- **Then** el WebSocket A2UI queda disponible para `apps/mobile`
