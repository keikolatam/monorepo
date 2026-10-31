# gRPC Gateway Layer - Keiko DApp

El gRPC Gateway Layer actúa como traductor entre los microservicios Rust y Keikochain (Starknet Appchain), manejando la comunicación con contratos Cairo y proporcionando servicios gRPC para los microservicios.

## 🚀 Quick Start

### Configuración Automática

Ejecuta el script de configuración automática para instalar todas las dependencias necesarias:

```bash
./quick-start.sh
```

Este script instalará automáticamente:
- **asdf**: Gestor de versiones de herramientas
- **Scarb**: Herramienta de build para Cairo
- **Starknet Foundry**: Framework de testing para contratos Cairo

### Configuración Manual

Si prefieres instalar las herramientas manualmente:

#### 1. Instalar asdf

```bash
# Ubuntu/Debian
sudo apt-get install git bash curl gawk dirmngr gpg
git clone https://github.com/asdf-vm/asdf.git ~/.asdf --branch v0.18.0

# macOS
brew install asdf

# Configurar shell (agregar a ~/.bashrc o ~/.zshrc)
echo 'export PATH="${ASDF_DATA_DIR:-$HOME/.asdf}/shims:$PATH"' >> ~/.bashrc
echo '. <(asdf completion bash)' >> ~/.bashrc
```

#### 2. Instalar Scarb

```bash
asdf plugin add scarb https://github.com/software-mansion/asdf-scarb.git
asdf install scarb latest
asdf global scarb latest
```

#### 3. Instalar Starknet Foundry

```bash
asdf plugin add starknet-foundry https://github.com/swmansion/asdf-starknet-foundry.git
asdf install starknet-foundry latest
asdf global starknet-foundry latest
```

## 🏗️ Arquitectura

```
┌─────────────────────────────────────────────────────────────┐
│                  gRPC Gateway Layer                        │
├─────────────────────────────────────────────────────────────┤
│  ┌─────────────┐  ┌─────────────┐  ┌─────────────┐        │
│  │   Client    │  │  Translator │  │   Server    │        │
│  │ Starknet RPC│  │ Rust ↔ Cairo│  │   gRPC      │        │
│  └─────────────┘  └─────────────┘  └─────────────┘        │
└─────────────────────┬───────────────────────────────────────┘
                      │ Starknet RPC + Transacciones
┌─────────────────────▼───────────────────────────────────────┐
│                  Keikochain Layer                          │
│         Cairo Smart Contracts (Starknet Appchain)         │
└─────────────────────────────────────────────────────────────┘
```

## 📁 Estructura del Proyecto

```
grpc-gateway/
├── client/                       # Cliente Starknet RPC
│   ├── src/                      # Código fuente Rust
│   └── Cargo.toml               # Dependencias del cliente
├── proto/                        # Definiciones gRPC (Protocol Buffers)
│   ├── learning.proto           # Servicio de interacciones
│   ├── passport.proto           # Servicio de pasaportes
│   ├── reputation.proto         # Servicio de reputación
│   ├── identity.proto           # Servicio de identidad
│   └── governance.proto         # Servicio de gobernanza
├── server/                       # Servidor gRPC Gateway
│   ├── src/                      # Código fuente Rust
│   └── Cargo.toml               # Dependencias del servidor
├── translator/                   # Traductor Rust ↔ Cairo
│   ├── src/                      # Código fuente Rust
│   └── Cargo.toml               # Dependencias del traductor
├── config/                       # Configuración del gateway
│   ├── development.toml         # Configuración para desarrollo
│   └── production.toml          # Configuración para producción
├── quick-start.sh               # Script de configuración automática
└── README.md                    # Este archivo
```

## 🔧 Funcionalidades

### Cliente Starknet RPC
- Conexión WebSocket a Keikochain (wss://keikochain.karnot.xyz)
- Circuit breaker y retry policies
- Pool de conexiones con load balancing

### Traductor Rust ↔ Cairo
- Conversión de tipos Rust a FieldElement (Cairo)
- Conversión de respuestas Cairo a tipos Rust
- Mapeo de funciones gRPC a funciones de contratos Cairo
- Validación de tipos y manejo de errores

### Servidor gRPC Gateway
- Servicios gRPC para todos los contratos Cairo
- Protocol Buffers para comunicación con microservicios
- Manejo de transacciones y consultas
- Propagación de eventos a microservicios

## 🚀 Desarrollo

### Compilar el proyecto

```bash
# Compilar todos los componentes
cargo build

# Compilar en modo release
cargo build --release
```

### Ejecutar tests

```bash
# Ejecutar todos los tests
cargo test

# Ejecutar tests con output detallado
cargo test -- --nocapture
```

### Ejecutar el servidor gRPC Gateway

```bash
# Modo desarrollo
cargo run --bin grpc_gateway_server

# Modo producción
cargo run --release --bin grpc_gateway_server
```

## 🔗 Integración con Keikochain

### Configuración de conexión

```toml
# config/development.toml
[starknet]
rpc_url = "wss://keikochain.karnot.xyz"
chain_id = "SN_MAIN"

[contracts]
learning_interactions = "0x..."
life_learning_passport = "0x..."
reputation_system = "0x..."
governance = "0x..."
learning_marketplace = "0x..."
```

### Ejemplo de uso

```rust
use grpc_gateway::GrpcGateway;

#[tokio::main]
async fn main() -> Result<(), Box<dyn std::error::Error>> {
    let gateway = GrpcGateway::new().await?;
    
    // Llamar contrato Cairo
    let result = gateway.call_contract(
        "learning_interactions",
        "get_interactions",
        vec![user_id, limit, offset]
    ).await?;
    
    println!("Resultado: {:?}", result);
    Ok(())
}
```

## 📚 Recursos

- [Documentación asdf](https://asdf-vm.com/guide/)
- [Documentación Scarb](https://docs.swmansion.com/scarb/)
- [Documentación Starknet Foundry](https://foundry-rs.github.io/starknet-foundry/)
- [Documentación Starknet](https://docs.starknet.io/)
- [Documentación Cairo](https://cairo-book.github.io/)

## 🤝 Contribuir

1. Fork el repositorio
2. Crea un branch para tu feature (`git checkout -b feature/nueva-funcionalidad`)
3. Commit tus cambios (`git commit -am 'Agregar nueva funcionalidad'`)
4. Push al branch (`git push origin feature/nueva-funcionalidad`)
5. Crea un Pull Request

## 📄 Licencia

Este proyecto está licenciado bajo Business Source License 1.1. Ver [LICENSE](../../LICENSE) para más detalles.
