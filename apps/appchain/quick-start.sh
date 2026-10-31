#!/bin/bash

# Script de configuración rápida para el Appchain Layer - Keiko DApp
# Basado en Madara para ejecutar Keikochain (Starknet Appchain)
# Documentación: https://docs.madara.build/quickstart/run_appchain

set -e  # Salir si cualquier comando falla

# Colores para output
RED='\033[0;31m'
GREEN='\033[0;32m'
YELLOW='\033[1;33m'
BLUE='\033[0;34m'
NC='\033[0m' # No Color

# Variables de configuración
MADARA_CLI_REPO="https://github.com/madara-alliance/madara-cli.git"
MADARA_CLI_DIR="madara-cli"
APPCHAIN_NAME="keikochain"
BLOCKS_TO_WAIT=55
WAIT_TIME_MINUTES=10
# Seeding PoH
SEED_POH=false
FIXTURES_PATH_DEFAULT="appchain/fixtures/poh/humanity_proof_samples.json"
CUSTOM_FIXTURES_PATH=""

# Variables de control
FORCE_RECREATE=false
SKIP_INTERACTION=false
PROVIDER="auto"       # auto|podman|docker
USE_EXISTING=false
NO_DEPS_CHECK=false
STARTED_BACKGROUND=false
USED_EXISTING=false

# Función de ayuda
show_help() {
    echo "Uso: $0 [OPCIONES]"
    echo
    echo "Configura e inicia la devnet de Madara para Keikochain"
    echo
    echo "Opciones:"
    echo "  -f, --force-recreate         Forzar recreación de la devnet existente"
    echo "  -y, --yes, --non-interactive Ejecutar sin confirmaciones (modo automático)"
    echo "      --use-existing           Usar devnet existente si está disponible (falla si no hay)"
    echo "      --provider <p>           Seleccionar proveedor: auto|podman|docker (default: auto)"
    echo "      --wait-blocks <n>        Esperar n bloques (default: $BLOCKS_TO_WAIT)"
    echo "      --wait-minutes <m>       Esperar m minutos aprox (default: $WAIT_TIME_MINUTES)"
    echo "      --no-deps-check          Omitir verificación de dependencias"
    echo "      --seed-poh               Sembrar datos PoH (humanity_proof_key) tras levantar devnet"
    echo "      --custom-fixtures-path <ruta>  Ruta alternativa para fixtures PoH (default: $FIXTURES_PATH_DEFAULT)"
    echo "  -h, --help                   Mostrar esta ayuda"
    echo
    echo "Ejemplos:"
    echo "  $0 --non-interactive                         # Configuración automática"
    echo "  $0 --force-recreate --non-interactive        # Recrear devnet sin preguntar"
    echo "  $0 --use-existing                            # Usar devnet existente (falla si no hay)"
    echo "  $0 --provider podman                         # Forzar Podman"
    echo "  $0 --wait-blocks 20 --wait-minutes 3         # Ajustar tiempos de espera"
    echo
}

# Función para procesar parámetros
process_arguments() {
    while [[ $# -gt 0 ]]; do
        case $1 in
            -f|--force-recreate)
                FORCE_RECREATE=true
                shift
                ;;
            -y|--yes|--non-interactive)
                SKIP_INTERACTION=true
                shift
                ;;
            --use-existing)
                USE_EXISTING=true
                shift
                ;;
            --provider)
                PROVIDER="$2"
                shift 2
                ;;
            --wait-blocks)
                BLOCKS_TO_WAIT="$2"
                shift 2
                ;;
            --wait-minutes)
                WAIT_TIME_MINUTES="$2"
                shift 2
                ;;
            --no-deps-check)
                NO_DEPS_CHECK=true
                shift
                ;;
            --seed-poh)
                SEED_POH=true
                shift
                ;;
            --custom-fixtures-path)
                CUSTOM_FIXTURES_PATH="$2"
                shift 2
                ;;
            -h|--help)
                show_help
                exit 0
                ;;
            *)
                print_error "Opción desconocida: $1"
                show_help
                exit 1
                ;;
        esac
    done
}

# Funciones de logging
print_status() {
    echo -e "${BLUE}[INFO]${NC} $1"
}

print_success() {
    echo -e "${GREEN}[SUCCESS]${NC} $1"
}

print_warning() {
    echo -e "${YELLOW}[WARNING]${NC} $1"
}

print_error() {
    echo -e "${RED}[ERROR]${NC} $1"
}

# Función para detectar sistema operativo
detect_os() {
    if [[ "$OSTYPE" == "linux-gnu"* ]]; then
        if [ -f /etc/os-release ]; then
            . /etc/os-release
            case "$ID" in
                ubuntu|debian)
                    OS="ubuntu"
                    ;;
                centos|rhel|fedora)
                    OS="centos"
                    ;;
                arch)
                    OS="arch"
                    ;;
                *)
                    OS="linux"
                    ;;
            esac
        else
            OS="linux"
        fi
    elif [[ "$OSTYPE" == "darwin"* ]]; then
        OS="macos"
    else
        OS="unknown"
    fi
}

# Función para configurar Podman como Docker
setup_podman_docker() {
    print_status "Configurando Podman como Docker..."
    
    # Si el proveedor es docker, no configurar podman
    if [ "$PROVIDER" = "docker" ]; then
        print_status "Proveedor forzado: Docker"
        return 0
    fi
    
    # Si el proveedor es auto o podman, intentar configurar podman
    if command -v podman &> /dev/null; then
        print_success "Podman encontrado: $(podman --version)"
        
        # Crear directorio bin local si no existe
        mkdir -p ~/.local/bin
        
        # Crear wrapper de docker
        cat > ~/.local/bin/docker << 'EOF'
#!/bin/bash
exec podman "$@"
EOF
        
        # Verificar si podman-compose está instalado
        if ! command -v podman-compose &> /dev/null; then
            print_status "Instalando podman-compose..."
            if command -v pip3 &> /dev/null; then
                # Crear entorno virtual si no existe
                if [ ! -d "venv" ]; then
                    python3 -m venv venv
                fi
                source venv/bin/activate
                pip install podman-compose
            else
                print_warning "pip3 no está disponible, podman-compose no se puede instalar automáticamente"
            fi
        fi
        
        # Crear wrapper de docker-compose
        cat > ~/.local/bin/docker-compose << 'EOF'
#!/bin/bash
exec podman-compose "$@"
EOF
        
        # Hacer ejecutables
        chmod +x ~/.local/bin/docker
        chmod +x ~/.local/bin/docker-compose
        
        # Agregar al PATH si no está
        if ! echo "$PATH" | grep -q "$HOME/.local/bin"; then
            export PATH="$HOME/.local/bin:$PATH"
        fi
        
        # Configurar DOCKER_HOST para Podman (preferir rootless de usuario)
        USER_PODMAN_SOCK="/run/user/$(id -u)/podman/podman.sock"
        SYSTEM_PODMAN_SOCK="/run/podman/podman.sock"
        if [ -S "$USER_PODMAN_SOCK" ]; then
            export DOCKER_HOST="unix://$USER_PODMAN_SOCK"
        elif [ -S "$SYSTEM_PODMAN_SOCK" ]; then
            export DOCKER_HOST="unix://$SYSTEM_PODMAN_SOCK"
        fi
        # Variables equivalentes que algunas herramientas leen
        export CONTAINER_HOST="$DOCKER_HOST"
        export PODMAN_HOST="$DOCKER_HOST"
        
        if [ -n "$DOCKER_HOST" ]; then
            print_success "DOCKER_HOST configurado para Podman: $DOCKER_HOST"
        else
            print_warning "No se encontró socket de Podman en $USER_PODMAN_SOCK ni $SYSTEM_PODMAN_SOCK"
        fi
        
        # Verificar que funciona
        if docker ps &> /dev/null; then
            print_success "Docker wrapper configurado correctamente con Podman"
        else
            print_warning "Docker wrapper configurado pero Podman no responde"
        fi
    else
        if [ "$PROVIDER" = "podman" ]; then
            print_error "Proveedor forzado a Podman pero no está instalado"
            exit 1
        fi
        print_warning "Podman no está instalado, usando Docker nativo si está disponible"
    fi
}

# Función para verificar dependencias del sistema
check_system_dependencies() {
    print_status "Verificando dependencias del sistema..."
    
    local missing_deps=()
    
    # Verificar dependencias básicas (comandos ejecutables)
    for dep in git curl gcc make pkg-config; do
        if ! command -v $dep &> /dev/null; then
            missing_deps+=($dep)
        fi
    done
    
    # Verificar Rust (requerido para Madara)
    if ! command -v rustc &> /dev/null; then
        missing_deps+=("rust")
    fi
    
    # Verificar Cargo
    if ! command -v cargo &> /dev/null; then
        missing_deps+=("cargo")
    fi
    
    # Verificar dependencias específicas según el OS
    case $OS in
        "ubuntu")
            for dep in build-essential libssl-dev; do
                if ! dpkg -l | grep -q "^ii.*$dep"; then
                    missing_deps+=($dep)
                fi
            done
            ;;
        "centos")
            for dep in gcc-c++ openssl-devel; do
                if ! rpm -q $dep &> /dev/null; then
                    missing_deps+=($dep)
                fi
            done
            ;;
        "arch")
            for dep in base-devel openssl; do
                if ! pacman -Q $dep &> /dev/null; then
                    missing_deps+=($dep)
                fi
            done
            ;;
        "macos")
            if ! command -v xcode-select &> /dev/null; then
                missing_deps+=("xcode-select")
            fi
            ;;
    esac
    
    if [ ${#missing_deps[@]} -eq 0 ]; then
        print_success "Todas las dependencias del sistema están instaladas"
        return 0
    else
        print_warning "Faltan las siguientes dependencias: ${missing_deps[*]}"
        print_status "Por favor instala las dependencias faltantes manualmente:"
        
        case $OS in
            "ubuntu")
                echo "  sudo apt-get update && sudo apt-get install -y ${missing_deps[*]}"
                ;;
            "centos")
                echo "  sudo yum install -y ${missing_deps[*]}"
                ;;
            "arch")
                echo "  sudo pacman -S --noconfirm ${missing_deps[*]}"
                ;;
            "macos")
                echo "  xcode-select --install"
                echo "  brew install ${missing_deps[*]}"
                ;;
            *)
                echo "  Instala manualmente: ${missing_deps[*]}"
                ;;
        esac
        
        print_warning "Continuando con la instalación de Madara..."
        return 1
    fi
}

# Función para instalar Rust si no está presente
install_rust() {
    if ! command -v rustc &> /dev/null; then
        print_status "Instalando Rust..."
        curl --proto '=https' --tlsv1.2 -sSf https://sh.rustup.rs | sh -s -- -y
        source ~/.cargo/env
        print_success "Rust instalado correctamente"
    else
        print_success "Rust ya está instalado: $(rustc --version)"
    fi
}

# Función para instalar Madara CLI
install_madara_cli() {
    print_status "Instalando Madara CLI..."
    
    # Verificar si ya existe el directorio
    if [ -d "$MADARA_CLI_DIR" ]; then
        print_warning "Directorio $MADARA_CLI_DIR ya existe. Actualizando..."
        cd "$MADARA_CLI_DIR"
        git pull origin main
        cd ..
    else
        print_status "Clonando repositorio de Madara CLI..."
        git clone "$MADARA_CLI_REPO"
    fi
    
    # Verificar que el clon fue exitoso
    if [ ! -d "$MADARA_CLI_DIR" ]; then
        print_error "Error al clonar el repositorio de Madara CLI"
        exit 1
    fi
    
    print_success "Madara CLI instalado correctamente"
}

# Función para compilar Madara CLI
build_madara_cli() {
    print_status "Compilando Madara CLI..."
    
    cd "$MADARA_CLI_DIR"
    
    # Compilar en modo release para mejor rendimiento
    if cargo build --release; then
        print_success "Madara CLI compilado correctamente"
    else
        print_error "Error al compilar Madara CLI"
        exit 1
    fi
    
    cd ..
}

# Función para crear configuración de la Appchain
create_appchain_config() {
    print_status "Creando configuración de Keikochain..."
    
    # Crear directorio de configuración
    mkdir -p config
    
    # Crear archivo de configuración básico
    cat > config/keikochain.toml << EOF
# Configuración de Keikochain (Madara Appchain)
# Basado en la documentación: https://docs.madara.build/quickstart/run_appchain

[appchain]
name = "keikochain"
description = "Keiko DApp - Starknet Appchain para Proof-of-Humanity y Life Learning Passport"
version = "0.1.0"

[sequencer]
host = "127.0.0.1"
port = 9944
rpc_port = 9945
ws_port = 9946

[orchestrator]
host = "127.0.0.1"
port = 8080

[prover]
type = "mock"
host = "127.0.0.1"
port = 8081

[settlement]
chain = "ethereum"
rpc_url = "http://127.0.0.1:8545"
private_key = "0xac0974bec39a17e36ba4a6b4d238ff944bacb478cbed5efcae784d7bf4f2ff80"

[consensus]
algorithm = "proof_of_stake"
block_time = 2
finality_threshold = 1

[storage]
type = "rocksdb"
path = "./data"

[logging]
level = "info"
format = "json"
EOF

    print_success "Configuración de Keikochain creada"
}

# Función para verificar si Madara ya se está ejecutando
check_madara_running() {
    print_status "Verificando si Madara ya se está ejecutando..."
    
    # Verificar contenedores de Madara
    local containers=$(docker ps --format "table {{.Names}}\t{{.Status}}" | grep -i madara || true)
    if [ -n "$containers" ]; then
        print_success "Madara ya se está ejecutando:"
        echo "$containers"
        return 0
    fi
    
    # Verificar puertos de Madara
    local ports=(9944 9945 9946)
    local services=("P2P" "RPC" "WebSocket")
    local running_ports=()
    
    for i in "${!ports[@]}"; do
        if netstat -tuln 2>/dev/null | grep -q ":${ports[$i]} "; then
            running_ports+=("${services[$i]}:${ports[$i]}")
        fi
    done
    
    if [ ${#running_ports[@]} -gt 0 ]; then
        print_success "Servicios de Madara detectados en puertos:"
        for port in "${running_ports[@]}"; do
            echo "  • $port"
        done
        return 0
    fi
    
    print_status "Madara no se está ejecutando"
    return 1
}

# Función para verificar si la devnet ya existe
check_devnet_exists() {
    print_status "Verificando si la devnet ya existe..."
    
    cd "$MADARA_CLI_DIR"
    
    # Verificar si hay archivos de configuración de devnet
    if [ -d "deps/madara" ] && [ -f "deps/madara/compose.yaml" ]; then
        print_success "Configuración de devnet encontrada"
        cd ..
        return 0
    fi
    
    # Verificar si hay contenedores de devnet
    local devnet_containers=$(docker ps -a --format "table {{.Names}}\t{{.Status}}" | grep -i madara || true)
    if [ -n "$devnet_containers" ]; then
        print_success "Contenedores de devnet encontrados:"
        echo "$devnet_containers"
        cd ..
        return 0
    fi
    
    print_status "No se encontró devnet existente"
    cd ..
    return 1
}

# Diagnóstico y aseguramiento de entorno de contenedores
print_container_env() {
    echo "DOCKER_HOST=${DOCKER_HOST:-<no-set>}"
    echo "PATH contains ~/.local/bin: $(echo "$PATH" | grep -q "$HOME/.local/bin" && echo yes || echo no)"
    if [ -S "/run/podman/podman.sock" ]; then
        echo "Podman socket: /run/podman/podman.sock (exists)"
    else
        echo "Podman socket: /run/podman/podman.sock (missing)"
    fi
    if [ -S "/run/docker.sock" ]; then
        echo "Docker socket: /run/docker.sock (exists)"
    else
        echo "Docker socket: /run/docker.sock (missing)"
    fi
    command -v docker &>/dev/null && docker --version || echo "docker wrapper not found in PATH"
    command -v docker-compose &>/dev/null && docker-compose --version || true
}

ensure_container_env() {
    # Preferir Podman si está disponible y provider != docker
    if [ "$PROVIDER" != "docker" ] && command -v podman &> /dev/null; then
        USER_PODMAN_SOCK="/run/user/$(id -u)/podman/podman.sock"
        SYSTEM_PODMAN_SOCK="/run/podman/podman.sock"
        if [ -S "$USER_PODMAN_SOCK" ]; then
            export DOCKER_HOST="unix://$USER_PODMAN_SOCK"
        elif [ -S "$SYSTEM_PODMAN_SOCK" ]; then
            export DOCKER_HOST="unix://$SYSTEM_PODMAN_SOCK"
        fi
        export CONTAINER_HOST="$DOCKER_HOST"
        export PODMAN_HOST="$DOCKER_HOST"
    fi
    # Asegurar ~/.local/bin en PATH para que el wrapper docker funcione en nohup
    case ":$PATH:" in
        *":$HOME/.local/bin:"*) ;;
        *) export PATH="$HOME/.local/bin:$PATH" ;;
    esac
}

# Función para iniciar la Devnet
start_appchain_devnet() {
    print_status "Iniciando Keikochain..."
    
    # Verificar si Madara ya se está ejecutando
    if check_madara_running; then
        if [ "$SKIP_INTERACTION" = true ]; then
            print_warning "Madara ya se está ejecutando. Continuando automáticamente..."
            if [ "$FORCE_RECREATE" = true ]; then
                print_status "Forzando recreación aunque ya esté corriendo..."
            else
                print_status "No se forzó recreación; se usará la instancia en ejecución."
                return 0
            fi
        else
            print_warning "Madara ya se está ejecutando. ¿Deseas continuar de todos modos?"
            print_status "Si continúas, se intentará crear una nueva instancia."
            echo
            read -p "¿Continuar? (y/N): " -n 1 -r
            echo
            if [[ ! $REPLY =~ ^[Yy]$ ]]; then
                print_status "Operación cancelada. Madara ya está ejecutándose."
                return 0
            fi
        fi
    fi
    
    # Verificar si la devnet ya existe
    if check_devnet_exists; then
        if [ "$FORCE_RECREATE" = true ]; then
            print_status "Forzando recreación de devnet..."
            print_status "Limpiando devnet existente..."
            docker stop $(docker ps -q --filter "ancestor=madara") 2>/dev/null || true
            docker stop $(docker ps -q --filter "name=madara") 2>/dev/null || true
            docker rm $(docker ps -aq --filter "ancestor=madara") 2>/dev/null || true
            docker rm $(docker ps -aq --filter "name=madara") 2>/dev/null || true
            print_success "Devnet anterior limpiada"
        elif [ "$USE_EXISTING" = true ] || [ "$SKIP_INTERACTION" = true ]; then
            print_status "Usando devnet existente"
            USED_EXISTING=true
            return 0
        else
            print_warning "Configuración de devnet encontrada. ¿Deseas recrear la devnet?"
            echo
            read -p "¿Recrear devnet? (y/N): " -n 1 -r
            echo
            if [[ ! $REPLY =~ ^[Yy]$ ]]; then
                print_status "Usando devnet existente."
                USED_EXISTING=true
                return 0
            else
                print_status "Limpiando devnet existente..."
                docker stop $(docker ps -q --filter "ancestor=madara") 2>/dev/null || true
                docker stop $(docker ps -q --filter "name=madara") 2>/dev/null || true
                docker rm $(docker ps -aq --filter "ancestor=madara") 2>/dev/null || true
                docker rm $(docker ps -aq --filter "name=madara") 2>/dev/null || true
                print_success "Devnet anterior limpiada"
            fi
        fi
    fi
    
    cd "$MADARA_CLI_DIR"
    
    # Crear la Appchain
    print_status "Creando Appchain con Madara CLI..."
    # Asegurar entorno antes de nohup
    ensure_container_env
    LOG_DIR="../logs"
    mkdir -p "$LOG_DIR"
    if nohup env DOCKER_HOST="$DOCKER_HOST" CONTAINER_HOST="$CONTAINER_HOST" PODMAN_HOST="$PODMAN_HOST" PATH="$PATH" bash -lc 'docker --version && docker-compose --version && cargo run --release create devnet' > "$LOG_DIR/devnet.out" 2> "$LOG_DIR/devnet.err" & then
        STARTED_BACKGROUND=true
        print_success "Devnet iniciada en segundo plano (nohup). Logs en $LOG_DIR/devnet.out"
        print_container_env
    else
        print_error "Error al iniciar la devnet en segundo plano"
        print_container_env
        exit 1
    fi
    
    cd ..
}

# Función para esperar a que la Appchain esté lista
wait_for_appchain() {
    print_status "Esperando a que Keikochain esté configurada..."
    print_warning "Esto puede tomar aproximadamente $WAIT_TIME_MINUTES minutos ($BLOCKS_TO_WAIT bloques)"
    
    ensure_container_env

    # Primero validar entorno de sockets/CLI
    if ! command -v docker &> /dev/null; then
        print_error "No se encuentra 'docker' en PATH (wrapper a podman). Agrega $HOME/.local/bin al PATH."
        return 1
    fi

    # Intentos de ver contenedores y puertos
    max_loops=$BLOCKS_TO_WAIT
    i=0
    while [ $i -lt $max_loops ]; do
        # 1) Socket correcto
        if [ "$PROVIDER" != "docker" ] && [ ! -S "/run/podman/podman.sock" ]; then
            print_warning "Socket de Podman no encontrado en /run/podman/podman.sock"
        fi

        # 2) docker ps accesible
        if ! docker ps &> /dev/null; then
            if grep -q "/run/docker.sock" logs/devnet.err 2>/dev/null; then
                print_error "Se está intentando usar /run/docker.sock."
                echo "Solución: export DOCKER_HOST=unix:///run/podman/podman.sock y reintenta."
                echo "         o ejecuta: ./quick-start.sh --provider podman --non-interactive"
                return 1
            fi
        fi

        # 3) Contenedores de madara levantados
        MADARA_CONTAINERS=$(docker ps --format '{{.Names}}' | grep -i madara || true)
        if [ -n "$MADARA_CONTAINERS" ]; then
            print_success "Contenedores de Madara activos:"
            echo "$MADARA_CONTAINERS"
            # 4) Puertos
            if command -v ss &> /dev/null; then
                if ss -tuln | grep -qE ':(9944|9945|9946)'; then
                    print_success "Puertos 9944/9945/9946 activos"
                    return 0
                fi
            else
                if netstat -tuln 2>/dev/null | grep -qE ':(9944|9945|9946) '; then
                    print_success "Puertos 9944/9945/9946 activos"
                    return 0
                fi
            fi
        fi

        # 5) Mensaje progresivo
        printf "\r${BLUE}[INFO]${NC} Esperando servicios... intento $((i+1))/$max_loops"
        sleep 6
        i=$((i+1))
    done

    echo
    print_error "La devnet no expuso puertos ni contenedores en el tiempo esperado."
    echo "Revisa logs: tail -n +1 -v logs/devnet.out logs/devnet.err | sed -n '1,200p'"
    print_container_env
    return 1
}

# Función para verificar el estado de la Appchain
verify_appchain() {
    print_status "Verificando estado de Keikochain..."
    
    # Verificar que los puertos estén abiertos
    local ports=(9944 9945 9946 8080 8081)
    local services=("Sequencer" "RPC" "WebSocket" "Orchestrator" "Prover")
    
    for i in "${!ports[@]}"; do
        if netstat -tuln 2>/dev/null | grep -q ":${ports[$i]} "; then
            print_success "${services[$i]} está ejecutándose en puerto ${ports[$i]}"
        else
            print_warning "${services[$i]} no está disponible en puerto ${ports[$i]}"
        fi
    done
}

# Función para mostrar información de conexión
show_connection_info() {
    echo
    print_success "¡Keikochain está ejecutándose correctamente!"
    echo
    print_status "Información de conexión:"
    echo "  • Sequencer RPC: http://127.0.0.1:9945"
    echo "  • WebSocket: ws://127.0.0.1:9946"
    echo "  • Orchestrator: http://127.0.0.1:8080"
    echo "  • Prover: http://127.0.0.1:8081"
    echo
    print_status "Componentes desplegados:"
    echo "  • Madara Sequencer - Nodo para recibir transacciones y construir bloques"
    echo "  • Orchestrator - Gestiona comunicaciones desde el sequencer"
    echo "  • Mock Prover - Genera pruebas mock para los bloques"
    echo "  • Ethereum Local - Blockchain local para settlement"
    echo
    print_status "Próximos pasos:"
    echo "  1. Interactúa con tu Appchain usando las URLs de conexión"
    echo "  2. Monitorea la Appchain para asegurar que funcione correctamente"
    echo "  3. Despliega contratos Cairo en Keikochain"
    echo "  4. Configura el gRPC Gateway para comunicación con microservicios"
    echo
    print_warning "Nota: Esta Appchain es solo para testing local"
}

# Función para crear scripts de utilidad
create_utility_scripts() {
    print_status "Creando scripts de utilidad..."
    
    # Script para detener la Appchain
    cat > stop-appchain.sh << 'EOF'
#!/bin/bash
echo "Deteniendo Keikochain..."
pkill -f "madara"
pkill -f "app-chain"
echo "Keikochain detenida"
EOF
    chmod +x stop-appchain.sh
    
    # Script para verificar estado
    cat > check-status.sh << 'EOF'
#!/bin/bash
echo "Verificando estado de Keikochain..."
echo "Puertos activos:"
netstat -tuln | grep -E ":(9944|9945|9946|8080|8081) "
echo
echo "Procesos de Madara:"
ps aux | grep -E "(madara|app-chain)" | grep -v grep
EOF
    chmod +x check-status.sh
    
    # Script para logs
    cat > view-logs.sh << 'EOF'
#!/bin/bash
echo "Mostrando logs de Keikochain..."
if [ -d "madara-cli/logs" ]; then
    tail -f madara-cli/logs/*.log
else
    echo "No se encontraron logs en madara-cli/logs/"
fi
EOF
    chmod +x view-logs.sh
    
    print_success "Scripts de utilidad creados"
}

# Función para mostrar información post-instalación
show_post_installation_info() {
    echo
    print_success "¡Configuración de Keikochain completada exitosamente!"
    echo
    if [ "$STARTED_BACKGROUND" = true ]; then
        print_status "La devnet fue iniciada en segundo plano con nohup."
        echo "  • Logs stdout: logs/devnet.out"
        echo "  • Logs stderr: logs/devnet.err"
        echo "  • Ver proceso: ps aux | grep madara | grep -v grep"
    fi
    if [ "$USED_EXISTING" = true ]; then
        print_status "Se detectó una devnet existente y se usó tal cual."
    fi
    print_status "Archivos creados:"
    echo "  • config/keikochain.toml - Configuración de la Appchain"
    echo "  • stop-appchain.sh - Script para detener la Appchain"
    echo "  • check-status.sh - Script para verificar estado"
    echo "  • view-logs.sh - Script para ver logs"
    if [ "$SEED_POH" = true ]; then
        local fp
        fp="${CUSTOM_FIXTURES_PATH:-$FIXTURES_PATH_DEFAULT}"
        echo "  • (seed) PoH desde: $fp"
    fi
    echo
    print_status "Comandos útiles:"
    echo "  • ./stop-appchain.sh     - Detener Keikochain"
    echo "  • ./check-status.sh      - Verificar estado"
    echo "  • ./view-logs.sh         - Ver logs en tiempo real"
    echo "  • cd madara-cli && cargo run --release create app-chain - Reiniciar Appchain"
    echo
    print_status "Recursos útiles:"
    echo "  • Documentación Madara: https://docs.madara.build/"
    echo "  • Madara CLI GitHub: https://github.com/madara-alliance/madara-cli"
    echo "  • Starknet Docs: https://docs.starknet.io/"
    echo "  • Cairo Book: https://book.cairo-lang.org/"
    echo
    print_warning "Importante: Mantén esta terminal abierta para que Keikochain siga ejecutándose"
}

# Función principal
main() {
    # Procesar argumentos
    process_arguments "$@"
    
    echo "=========================================="
    echo "  Keiko DApp - Appchain Layer Setup"
    echo "  Basado en Madara para Keikochain"
    echo "=========================================="
    echo
    
    # Mostrar configuración actual
    if [ "$FORCE_RECREATE" = true ]; then
        print_status "Modo: Forzar recreación de devnet"
    fi
    if [ "$SKIP_INTERACTION" = true ]; then
        print_status "Modo: Automático (sin confirmaciones)"
    fi
    print_status "Proveedor: $PROVIDER"
    echo
    
    # Detectar sistema operativo
    detect_os
    print_status "Sistema operativo detectado: $OS"
    
    # Configurar Podman como Docker (según proveedor)
    setup_podman_docker
    
    # Verificar dependencias del sistema (si no se omite)
    if [ "$NO_DEPS_CHECK" = true ]; then
        print_warning "Omitiendo verificación de dependencias (--no-deps-check)"
    else
        check_system_dependencies
    fi
    
    # Instalar Rust si es necesario
    install_rust
    
    # Instalar Madara CLI
    install_madara_cli
    
    # Compilar Madara CLI
    build_madara_cli
    
    # Crear configuración de la Appchain
    create_appchain_config
    
    # Iniciar la Devnet
    if [ "$USE_EXISTING" = true ]; then
        print_status "Flag --use-existing activo: usaremos devnet existente si está disponible"
    fi
    start_appchain_devnet
    
    # Esperar a que esté lista
    wait_for_appchain
    
    # Verificar estado
    verify_appchain
    
    # Sembrar PoH si se solicita
    if [ "$SEED_POH" = true ]; then
        print_status "Sembrando datos PoH (humanity_proof_key)..."
        FIXTURES_PATH="${CUSTOM_FIXTURES_PATH:-$FIXTURES_PATH_DEFAULT}"
        if [ ! -f "$FIXTURES_PATH" ]; then
            print_warning "Fixtures no encontrados en $FIXTURES_PATH. Creando ejemplo mínimo..."
            mkdir -p "$(dirname "$FIXTURES_PATH")"
            cat > "$FIXTURES_PATH" << 'EOF'
[
  {
    "user_id": "devnet_demo_user_001",
    "iris_hash_hex": "3f1a9c2e5b7d4f1a3c6e9b2d5f7a1c3e6b9d2f4a7c1e3b5d7f9a2c4e6b8d0f2",
    "genome_hash_hex": "7e2b5d8f1a3c6e9b2d5f7a1c3e6b9d2f4a7c1e3b5d7f9a2c4e6b8d0f23f1a9c2",
    "salt_hex": "9fa1b2c3d4e5f60789abcdef01234567",
    "humanity_proof_key_hex": "1a2b3c4d5e6f708192a3b4c5d6e7f8091a2b3c4d5e6f708192a3b4c5d6e7f809"
  },
  {
    "user_id": "devnet_demo_user_002",
    "iris_hash_hex": "a9c23f1e5d7b4f1a3e6c9b2d5f7a1c3e6b9d2f4a7c1e3b5d7f9a2c4e6b8d0f21",
    "genome_hash_hex": "2b5d8f1a3c6e9b2d5f7a1c3e6b9d2f4a7c1e3b5d7f9a2c4e6b8d0f23f1a9c27e",
    "salt_hex": "abcdef012345679fa1b2c3d4e5f60789",
    "humanity_proof_key_hex": "9c8d7e6f5a4b3c2d1e0f9a8b7c6d5e4f3a2b1c0d9e8f7a6b5c4d3e2f1a0b9c8d"
  },
  {
    "user_id": "devnet_demo_user_003",
    "iris_hash_hex": "5d8f1a3c6e9b2d5f7a1c3e6b9d2f4a7c1e3b5d7f9a2c4e6b8d0f23f1a9c27e2b",
    "genome_hash_hex": "1a3c6e9b2d5f7a1c3e6b9d2f4a7c1e3b5d7f9a2c4e6b8d0f23f1a9c27e2b5d8f",
    "salt_hex": "0123456789abcdef9fa1b2c3d4e5f607",
    "humanity_proof_key_hex": "0f1e2d3c4b5a69788796a5b4c3d2e1f0aa99bb88cc77dd66ee55ff4411223344"
  },
  {
    "user_id": "devnet_demo_user_004",
    "iris_hash_hex": "9b2d5f7a1c3e6b9d2f4a7c1e3b5d7f9a2c4e6b8d0f23f1a9c27e2b5d8f1a3c6e",
    "genome_hash_hex": "3e6b9d2f4a7c1e3b5d7f9a2c4e6b8d0f23f1a9c27e2b5d8f1a3c6e9b2d5f7a1c",
    "salt_hex": "7766554433221100ffeeddccbbaa9988",
    "humanity_proof_key_hex": "abcdefabcdefabcdefabcdefabcdefabcdefabcdefabcdefabcdefabcdefabcdef"
  },
  {
    "user_id": "devnet_demo_user_005",
    "iris_hash_hex": "2d5f7a1c3e6b9d2f4a7c1e3b5d7f9a2c4e6b8d0f23f1a9c27e2b5d8f1a3c6e9b",
    "genome_hash_hex": "6b9d2f4a7c1e3b5d7f9a2c4e6b8d0f23f1a9c27e2b5d8f1a3c6e9b2d5f7a1c3e",
    "salt_hex": "11223344556677889900aabbccddeeff",
    "humanity_proof_key_hex": "1234567890abcdef1234567890abcdef1234567890abcdef1234567890abcdef"
  }
]
EOF
            print_success "Fixture de ejemplo creado en $FIXTURES_PATH"
        fi
        if [ -x "appchain/seeds/seed_poh.sh" ]; then
            bash appchain/seeds/seed_poh.sh "$FIXTURES_PATH" || print_warning "Seeding PoH retornó con advertencias"
        else
            print_warning "seed_poh.sh no encontrado o no ejecutable. Crea appchain/seeds/seed_poh.sh"
        fi
    fi

    # Crear scripts de utilidad
    create_utility_scripts
    
    # Mostrar información de conexión
    show_connection_info
    
    # Mostrar información post-instalación
    show_post_installation_info
}

# Ejecutar función principal
main "$@"
