#!/bin/bash

# Script para configurar devnet de Madara con Podman - Keiko DApp
# Versión interactiva que permite ejecutar comandos sudo manualmente
# Basado en: https://docs.madara.build/quickstart/run_devnet
# Optimizado para Ubuntu 24.04 LTS en WSL2

set -e  # Salir si cualquier comando falla

# Colores para output
RED='\033[0;31m'
GREEN='\033[0;32m'
YELLOW='\033[1;33m'
BLUE='\033[0;34m'
NC='\033[0m' # No Color

# Variables de configuración
MADARA_CLI_DIR="madara-cli"

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
                ubuntu)
                    OS="ubuntu"
                    VERSION="$VERSION_ID"
                    ;;
                *)
                    OS="linux"
                    ;;
            esac
        else
            OS="linux"
        fi
    else
        OS="unknown"
    fi
}

# Función para verificar dependencias del sistema
check_system_dependencies() {
    print_status "Verificando dependencias del sistema..."
    
    local missing_deps=()
    
    # Verificar dependencias básicas
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
    
    if [ ${#missing_deps[@]} -eq 0 ]; then
        print_success "Todas las dependencias del sistema están instaladas"
        return 0
    else
        print_warning "Faltan las siguientes dependencias: ${missing_deps[*]}"
        print_status "Necesitarás instalar estas dependencias manualmente con sudo"
        echo
        echo "Ejecuta estos comandos en tu terminal:"
        echo "sudo apt-get update"
        echo "sudo apt-get install -y ${missing_deps[*]}"
        echo
        read -p "¿Has instalado las dependencias? (y/n): " -n 1 -r
        echo
        if [[ ! $REPLY =~ ^[Yy]$ ]]; then
            print_error "Por favor instala las dependencias y ejecuta el script nuevamente"
            exit 1
        fi
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

# Función para instalar Podman
install_podman() {
    print_status "Verificando Podman..."
    
    if command -v podman &> /dev/null; then
        print_success "Podman ya está instalado: $(podman --version)"
        return 0
    fi
    
    case $OS in
        "ubuntu")
            print_status "Podman no está instalado. Necesitarás instalarlo manualmente."
            echo
            echo "Ejecuta estos comandos en tu terminal:"
            echo
            echo "# Agregar repositorio de Podman"
            echo "sudo sh -c \"echo 'deb http://download.opensuse.org/repositories/devel:/kubic:/libcontainers:/stable/xUbuntu_${VERSION}/ /' > /etc/apt/sources.list.d/devel:kubic:libcontainers:stable.list\""
            echo
            echo "# Agregar clave GPG"
            echo "wget -nv https://download.opensuse.org/repositories/devel:kubic:libcontainers:stable/xUbuntu_${VERSION}/Release.key -O Release.key"
            echo "sudo apt-key add Release.key"
            echo "rm Release.key"
            echo
            echo "# Actualizar e instalar"
            echo "sudo apt-get update"
            echo "sudo apt-get install -y podman"
            echo
            echo "# Configurar Podman para rootless"
            echo "podman system migrate"
            echo
            read -p "¿Has instalado Podman? (y/n): " -n 1 -r
            echo
            if [[ ! $REPLY =~ ^[Yy]$ ]]; then
                print_error "Por favor instala Podman y ejecuta el script nuevamente"
                exit 1
            fi
            
            # Verificar que Podman se instaló correctamente
            if ! command -v podman &> /dev/null; then
                print_error "Podman no se encuentra en el PATH. Verifica la instalación."
                exit 1
            fi
            
            print_success "Podman instalado correctamente: $(podman --version)"
            ;;
        *)
            print_error "Sistema operativo no soportado para instalación automática de Podman"
            print_status "Instala Podman manualmente: https://podman.io/getting-started/installation"
            return 1
            ;;
    esac
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
        git clone https://github.com/madara-alliance/madara-cli.git
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

# Función para configurar Podman como alias de Docker
setup_podman_docker_alias() {
    print_status "Configurando Podman como alias de Docker..."
    
    # Crear alias para que Madara CLI use Podman
    cat > ~/.bashrc_podman << 'EOF'
# Alias para usar Podman como Docker
alias docker='podman'
alias docker-compose='podman-compose'
EOF
    
    # Agregar al bashrc si no existe
    if ! grep -q "podman" ~/.bashrc; then
        echo "source ~/.bashrc_podman" >> ~/.bashrc
    fi
    
    # Cargar alias en la sesión actual
    source ~/.bashrc_podman
    
    print_success "Podman configurado como alias de Docker"
}

# Función para iniciar la devnet con Podman
start_devnet() {
    print_status "Iniciando devnet de Madara con Podman..."
    
    cd "$MADARA_CLI_DIR"
    
    print_status "Creando devnet con Madara CLI (usando Podman)..."
    print_warning "Esto descargará las imágenes requeridas y puede tomar unos minutos..."
    
    # Usar Podman en lugar de Docker
    if DOCKER_HOST=unix:///run/user/$(id -u)/podman/podman.sock cargo run --release create devnet; then
        print_success "¡Devnet ejecutándose correctamente con Podman!"
    else
        print_error "Error al crear la devnet"
        exit 1
    fi
    
    cd ..
}

# Función para verificar el estado de la devnet
verify_devnet() {
    print_status "Verificando estado de la devnet..."
    
    # Verificar que Podman esté ejecutándose
    if ! podman ps &> /dev/null; then
        print_error "Podman no está ejecutándose"
        return 1
    fi
    
    # Verificar contenedores de Madara
    local containers=$(podman ps --format "table {{.Names}}\t{{.Status}}" | grep -i madara || true)
    if [ -n "$containers" ]; then
        print_success "Contenedores de Madara ejecutándose:"
        echo "$containers"
    else
        print_warning "No se encontraron contenedores de Madara ejecutándose"
    fi
    
    # Verificar puertos comunes
    local ports=(9944 9945 9946)
    local services=("P2P" "RPC" "WebSocket")
    
    for i in "${!ports[@]}"; do
        if netstat -tuln 2>/dev/null | grep -q ":${ports[$i]} "; then
            print_success "${services[$i]} está disponible en puerto ${ports[$i]}"
        else
            print_warning "${services[$i]} no está disponible en puerto ${ports[$i]}"
        fi
    done
}

# Función para mostrar información de conexión
show_connection_info() {
    echo
    print_success "¡Devnet de Madara está ejecutándose correctamente con Podman!"
    echo
    print_status "Información de conexión:"
    echo "  • RPC Endpoint: http://127.0.0.1:9945"
    echo "  • WebSocket: ws://127.0.0.1:9946"
    echo "  • P2P: 127.0.0.1:9944"
    echo
    print_status "Características de la devnet:"
    echo "  • Ligera y rápida para desarrollo"
    echo "  • No liquida transacciones en cadena subyacente"
    echo "  • Perfecta para testing y desarrollo"
    echo "  • Ejecutándose con Podman (sin Docker)"
    echo
    print_status "Próximos pasos:"
    echo "  1. Interactúa con la devnet usando las URLs de conexión"
    echo "  2. Despliega contratos Cairo para testing"
    echo "  3. Configura el gRPC Gateway para comunicación"
    echo "  4. Ejecuta tests de integración"
    echo
    print_warning "Nota: Esta devnet es solo para desarrollo local"
}

# Función para crear scripts de utilidad
create_utility_scripts() {
    print_status "Creando scripts de utilidad..."
    
    # Script para detener la devnet
    cat > stop-devnet.sh << 'EOF'
#!/bin/bash
echo "Deteniendo devnet de Madara..."
podman stop $(podman ps -q) 2>/dev/null || true
echo "Devnet detenida"
EOF
    chmod +x stop-devnet.sh
    
    # Script para verificar estado
    cat > check-devnet-status.sh << 'EOF'
#!/bin/bash
echo "Verificando estado de la devnet de Madara..."
echo "Contenedores Podman:"
podman ps --format "table {{.Names}}\t{{.Status}}\t{{.Ports}}" | grep -i madara || echo "No hay contenedores de Madara ejecutándose"
echo
echo "Puertos activos:"
netstat -tuln | grep -E ":(9944|9945|9946) " || echo "No hay puertos de Madara activos"
EOF
    chmod +x check-devnet-status.sh
    
    # Script para logs
    cat > view-devnet-logs.sh << 'EOF'
#!/bin/bash
echo "Mostrando logs de la devnet de Madara..."
CONTAINER_ID=$(podman ps -q | head -1)
if [ -n "$CONTAINER_ID" ]; then
    podman logs -f "$CONTAINER_ID"
else
    echo "No se encontró contenedor de Madara ejecutándose"
fi
EOF
    chmod +x view-devnet-logs.sh
    
    # Script para reiniciar
    cat > restart-devnet.sh << 'EOF'
#!/bin/bash
echo "Reiniciando devnet de Madara..."
./stop-devnet.sh
sleep 2
cd madara-cli && cargo run --release create devnet
EOF
    chmod +x restart-devnet.sh
    
    print_success "Scripts de utilidad creados"
}

# Función para mostrar información post-instalación
show_post_installation_info() {
    echo
    print_success "¡Configuración de devnet de Madara con Podman completada exitosamente!"
    echo
    print_status "Archivos creados:"
    echo "  • stop-devnet.sh - Script para detener la devnet"
    echo "  • check-devnet-status.sh - Script para verificar estado"
    echo "  • view-devnet-logs.sh - Script para ver logs"
    echo "  • restart-devnet.sh - Script para reiniciar la devnet"
    echo
    print_status "Comandos útiles:"
    echo "  • ./stop-devnet.sh           - Detener devnet"
    echo "  • ./check-devnet-status.sh   - Verificar estado"
    echo "  • ./view-devnet-logs.sh      - Ver logs en tiempo real"
    echo "  • ./restart-devnet.sh        - Reiniciar devnet"
    echo "  • podman ps                  - Ver contenedores ejecutándose"
    echo "  • podman logs <container>    - Ver logs de un contenedor"
    echo
    print_status "Recursos útiles:"
    echo "  • Documentación Madara: https://docs.madara.build/"
    echo "  • Madara CLI GitHub: https://github.com/madara-alliance/madara-cli"
    echo "  • Podman Docs: https://docs.podman.io/"
    echo "  • Starknet Docs: https://docs.starknet.io/"
    echo
    print_warning "Importante: Mantén esta terminal abierta para que la devnet siga ejecutándose"
}

# Función principal
main() {
    echo "=========================================="
    echo "  Keiko DApp - Madara Devnet Setup"
    echo "  Con Podman en Ubuntu 24.04 LTS"
    echo "  Versión Interactiva"
    echo "  Basado en: https://docs.madara.build/quickstart/run_devnet"
    echo "=========================================="
    echo
    
    # Detectar sistema operativo
    detect_os
    print_status "Sistema operativo detectado: $OS $VERSION"
    
    # Verificar dependencias del sistema
    check_system_dependencies
    
    # Instalar Rust si es necesario
    install_rust
    
    # Instalar Podman
    install_podman
    
    # Instalar Madara CLI
    install_madara_cli
    
    # Compilar Madara CLI
    build_madara_cli
    
    # Configurar Podman como alias de Docker
    setup_podman_docker_alias
    
    # Iniciar la devnet
    start_devnet
    
    # Verificar estado
    verify_devnet
    
    # Crear scripts de utilidad
    create_utility_scripts
    
    # Mostrar información de conexión
    show_connection_info
    
    # Mostrar información post-instalación
    show_post_installation_info
}

# Ejecutar función principal
main "$@"
