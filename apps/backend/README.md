# 🦀 Backend Layer - Keiko DApp

El Backend Layer implementa una **aplicación monolítica modular** en Rust que gestiona toda la lógica de negocio de la Keiko DApp. Siguiendo la arquitectura híbrida de cinco capas, este backend se organiza en módulos por dominio, cada uno con su propio esquema de base de datos y responsabilidades específicas.

## 🎯 Arquitectura Monolítica Modular

La arquitectura sigue los principios de **Domain-Driven Design (DDD)** y **Modular Monolith**:

- **Modular**: Cada módulo es independiente y cohesivo
- **Monolithic**: Un solo proceso con comunicación in-memory
- **Database per Module**: Cada módulo gestiona su propio esquema de base de datos
- **Event-Driven**: Comunicación asíncrona a través de Redis Streams
- **Shared Kernel**: Componentes compartidos para cross-cutting concerns
- **Graceful Shutdown**: Inicialización y cierre ordenado de módulos

## 🏗️ Módulos del Backend

### 1. **Identity Module** (`modules/identity/`)
- **Responsabilidad**: Autenticación, autorización y gestión de usuarios
- **Tecnologías**: FIDO2, JWT, Proof-of-Humanity con zkProofs
- **Esquema**: `identity_schema` separado
- **Funcionalidades**:
  - Registro con Proof-of-Humanity (iris, genome)
  - Autenticación FIDO2/WebAuthn
  - Generación de `humanity_proof_key`
  - Verificación de Ed25519 signatures
  - Gestión de sesiones JWT

### 2. **Learning Passport Module** (`modules/learning_passport/`)
- **Responsabilidad**: Interacciones de aprendizaje xAPI y pasaportes de aprendizaje
- **Tecnologías**: xAPI (Tin Can), SCORM, OpenCV, BioPython, Cairo smart contracts
- **Esquema**: `learning_passport_schema` separado
- **Funcionalidades**:
  - Procesamiento de interacciones de aprendizaje atómicas
  - Integración con SCORM y xAPI
  - Generación y gestión de Life Learning Passport
  - Firma de interacciones con Ed25519
  - Verificación biométrica (iris, genome)
  - Agregación de interacciones en pasaportes
  - Sincronización con Keikochain

### 3. **Reputation Module** (`modules/reputation/`)
- **Responsabilidad**: Sistema de reputación y gamificación
- **Tecnologías**: Algoritmos de reputación, Cairo smart contracts
- **Esquema**: `reputation_schema` separado
- **Funcionalidades**:
  - Cálculo de reputación basado en aprendizaje
  - Sistema de badges y achievements
  - Gamificación y leaderboards
  - Verificación de reputación en Keikochain

### 4. **Governance Module** (`modules/governance/`)
- **Responsabilidad**: Herramientas de gobernanza comunitaria
- **Tecnologías**: Sistemas de votación, Cairo smart contracts
- **Esquema**: `governance_schema` separado
- **Funcionalidades**:
  - Procesos de votación comunitaria
  - Gestión de propuestas
  - Ejecución de decisiones
  - Integración con Keikochain

### 5. **Marketplace Module** (`modules/marketplace/`)
- **Responsabilidad**: Gestión de espacios de aprendizaje seguros
- **Tecnologías**: WebSockets, Cairo smart contracts
- **Esquema**: `marketplace_schema` separado
- **Funcionalidades**:
  - Gestión de espacios de aprendizaje
  - Transacciones de tokens
  - Verificación de acceso
  - Comunicación en tiempo real

### 6. **Self Study Guides Module** (`modules/selfstudy_guides/`)
- **Responsabilidad**: Guías de auto-estudio evaluadas por agente IA
- **Tecnologías**: OpenCV, BioPython, IA/ML
- **Esquema**: `selfstudy_schema` separado
- **Funcionalidades**:
  - Generación de guías personalizadas
  - Evaluación automática con IA
  - Adaptación de contenido
  - Monitoreo de progreso

## 🔄 Flujo de Datos

### Escritura
```
API Gateway → HTTP/REST → Backend Module → gRPC Gateway → Keikochain → Redis Stream → GraphQL Subscription
```

### Lectura
```
API Gateway → HTTP/REST → Backend Module → Cache/DB → (fallback) gRPC Gateway → Keikochain
```

### Tiempo Real
```
Keikochain → gRPC Gateway → Backend Module → Redis Streams → API Gateway → GraphQL Subscription
```

## 🛠️ Estructura del Proyecto

```
backend-modules/
├── modules/                           # Módulos organizados por dominio
│   ├── identity/                      # Autenticación y usuarios
│   │   ├── src/
│   │   │   ├── domain/                # Entidades de dominio
│   │   │   ├── repository/            # Persistencia
│   │   │   ├── service/               # Lógica de aplicación
│   │   │   └── lib.rs                 # API pública del módulo
│   │   └── Cargo.toml                 # Dependencias del módulo
│   ├── learning_passport/             # Interacciones xAPI y pasaportes
│   ├── reputation/                    # Sistema de reputación
│   ├── governance/                    # Herramientas de gobernanza
│   ├── marketplace/                   # Gestión de espacios
│   └── selfstudy_guides/              # Guías de auto-estudio
├── shared/                            # Componentes compartidos del backend
├── src/
│   └── main.rs                        # Punto de entrada monolítico
└── Cargo.toml                         # Configuración principal
```

## 🚀 Configuración Rápida

### Prerrequisitos
- Rust 1.70+
- PostgreSQL 14+
- Redis 6+
- Podman/Docker

### Instalación
```bash
# Configuración automática
./scripts/backend-quick-start.sh

# O manualmente
cd backend
cargo build
```

### Ejecución
```bash
# Iniciar backend completo
cargo run

# O usando make
make backend-start
```

## 🔧 Desarrollo

### Agregar Nuevo Módulo
1. Crear directorio en `modules/nuevo_modulo/`
2. Configurar `Cargo.toml` con dependencias específicas
3. Implementar estructura básica: `domain/`, `repository/`, `service/`
4. Agregar a `main.rs` para inicialización/shutdown
5. Actualizar workspace en `Cargo.toml` raíz

### Estructura de Módulo
```rust
// modules/ejemplo/src/lib.rs
pub mod domain;      // Entidades de dominio
pub mod repository;  // Persistencia
pub mod service;     // Lógica de aplicación

pub async fn init() -> Result<()> { /* inicialización */ }
pub async fn shutdown() -> Result<()> { /* limpieza */ }
```

## 📊 Monitoreo y Observabilidad

- **Logging**: Structured logging con `tracing`
- **Métricas**: Prometheus metrics por módulo
- **Trazas**: OpenTelemetry con Jaeger
- **Health Checks**: Endpoints de salud por módulo

## 🔐 Seguridad

- **Autenticación**: FIDO2/WebAuthn
- **Autorización**: JWT con roles y permisos
- **Criptografía**: Ed25519 para firmas
- **Privacidad**: Zero-knowledge proofs

## 🌐 Integración

- **gRPC Gateway**: Comunicación con Keikochain
- **API Gateway**: Exposición de APIs REST/GraphQL
- **Redis Streams**: Eventos de dominio
- **PostgreSQL**: Cache local por módulo

---

**Nota**: Esta arquitectura permite la extracción gradual de módulos a microservicios cuando sea necesario, manteniendo la simplicidad operacional de un monolito durante el desarrollo inicial.