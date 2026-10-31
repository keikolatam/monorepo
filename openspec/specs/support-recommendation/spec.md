# Spec: support-recommendation

**Dominio:** recommendation · **Issue:** #4 · **ADR:** 0005 · **Estado:** target (pre-poblado, change 2026-06-09-gh-1-keiko-coach-de-carrera)

## Requirements

### Requirement: Clasificación tutoría vs mentoría (Irby)
Por cada gap, el sistema DEBE clasificar el soporte recomendado como tutoría (topic puntual, corto plazo) o mentoría (desarrollo integral, largo plazo) según Irby (2018).

#### Scenario: Gap puntual → tutoría
- **Given** un gap de severidad acotada en una competencia técnica concreta
- **When** `classify_support` lo evalúa
- **Then** retorna `tutoring`

### Requirement: Plan de sesión IDT en runtime
El sistema DEBE generar un plan de sesión embebiendo la estructura IDT (7 pasos) con topic = competencia y success criterion = umbral de re-assessment.

#### Scenario: Generar plan desde gap
- **Given** un gap clasificado
- **When** `generate_session_plan` corre
- **Then** produce un plan con objetivos, agenda y criterio de éxito

### Requirement: Match de tutores/mentores desde marketplace
El sistema DEBE consultar el marketplace por competencia y tipo, rankeando candidatos por reputación. La interfaz DEBE ser seed-agnóstica.

#### Scenario: Candidatos para un gap
- **Given** un marketplace con tutores seed etiquetados por competencia
- **When** `query_tutors(competency, type)` corre
- **Then** retorna candidatos rankeados por reputación con CTA "solicitar sesión"

#### Scenario: Assessment sin gaps
- **Given** un assessment sin gaps significativos
- **When** corre la fase de recomendación
- **Then** se omite sin generar recomendaciones
