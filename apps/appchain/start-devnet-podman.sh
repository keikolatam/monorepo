#!/bin/bash

# Script para iniciar devnet de Madara con Podman
# Soluciona el problema de conflicto con Docker de Windows

set -e

# Colores para output
RED='\033[0;31m'
GREEN='\033[0;32m'
YELLOW='\033[1;33m'
BLUE='\033[0;34m'
NC='\033[0m' # No Color

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

echo "=========================================="
echo "  Iniciando Madara Devnet con Podman"
echo "  Solucionando conflicto con Docker Windows"
echo "=========================================="
echo

# Verificar que estamos en el directorio correcto
if [ ! -d "madara-cli" ]; then
    print_error "Directorio madara-cli no encontrado. Ejecuta desde el directorio appchain"
    exit 1
fi

# Verificar que Podman está instalado
if ! command -v podman &> /dev/null; then
    print_error "Podman no está instalado. Ejecuta setup-devnet-podman-interactive.sh primero"
    exit 1
fi

print_success "Podman encontrado: $(podman --version)"

# Crear función docker que use Podman
create_docker_wrapper() {
    print_status "Creando wrapper de Docker para Podman..."
    
    # Crear directorio bin local si no existe
    mkdir -p ~/.local/bin
    
    # Crear wrapper de docker
    cat > ~/.local/bin/docker << 'EOF'
#!/bin/bash
# Wrapper para usar Podman como Docker
exec podman "$@"
EOF
    
    # Crear wrapper de docker-compose
    cat > ~/.local/bin/docker-compose << 'EOF'
#!/bin/bash
# Wrapper para docker-compose usando Podman
if command -v podman-compose &> /dev/null; then
    exec podman-compose "$@"
else
    echo "Error: podman-compose no está instalado"
    echo "Instala con: pip install podman-compose"
    exit 1
fi
EOF
    
    # Hacer ejecutables
    chmod +x ~/.local/bin/docker
    chmod +x ~/.local/bin/docker-compose
    
    # Agregar al PATH si no está
    if ! echo "$PATH" | grep -q "$HOME/.local/bin"; then
        echo 'export PATH="$HOME/.local/bin:$PATH"' >> ~/.bashrc
        export PATH="$HOME/.local/bin:$PATH"
    fi
    
    print_success "Wrappers de Docker creados"
}

# Verificar si podman-compose está instalado
check_podman_compose() {
    if ! command -v podman-compose &> /dev/null; then
        print_warning "podman-compose no está instalado"
        print_status "Instalando podman-compose..."
        
        if command -v pip3 &> /dev/null; then
            pip3 install --user podman-compose
        elif command -v pip &> /dev/null; then
            pip install --user podman-compose
        else
            print_error "pip no está disponible. Instala podman-compose manualmente:"
            echo "pip install podman-compose"
            exit 1
        fi
        
        if command -v podman-compose &> /dev/null; then
            print_success "podman-compose instalado correctamente"
        else
            print_error "Error al instalar podman-compose"
            exit 1
        fi
    else
        print_success "podman-compose ya está instalado: $(podman-compose --version)"
    fi
}

# Función para iniciar la devnet
start_devnet() {
    print_status "Iniciando devnet de Madara..."
    
    cd madara-cli
    
    # Configurar variables de entorno para usar Podman
    export DOCKER_HOST="unix:///run/user/$(id -u)/podman/podman.sock"
    
    print_warning "Esto puede tomar unos minutos la primera vez (descarga de imágenes)..."
    
    # Ejecutar Madara CLI
    if cargo run --release create devnet; then
        print_success "¡Devnet iniciada correctamente!"
    else
        print_error "Error al iniciar la devnet"
        exit 1
    fi
    
    cd ..
}

# Función para verificar el estado
verify_devnet() {
    print_status "Verificando estado de la devnet..."
    
    # Verificar contenedores
    local containers=$(podman ps --format "table {{.Names}}\t{{.Status}}" | grep -i madara || true)
    if [ -n "$containers" ]; then
        print_success "Contenedores de Madara ejecutándose:"
        echo "$containers"
    else
        print_warning "No se encontraron contenedores de Madara ejecutándose"
    fi
    
    # Verificar puertos
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
    print_success "¡Devnet de Madara está ejecutándose!"
    echo
    print_status "Información de conexión:"
    echo "  • RPC Endpoint: http://127.0.0.1:9945"
    echo "  • WebSocket: ws://127.0.0.1:9946"
    echo "  • P2P: 127.0.0.1:9944"
    echo
    print_status "Comandos útiles:"
    echo "  • podman ps                  - Ver contenedores"
    echo "  • podman logs <container>    - Ver logs"
    echo "  • ./stop-devnet.sh          - Detener devnet"
    echo
    print_warning "Mantén esta terminal abierta para que la devnet siga ejecutándose"
}

# Función principal
main() {
    # Crear wrappers de Docker
    create_docker_wrapper
    
    # Verificar podman-compose
    check_podman_compose
    
    # Iniciar devnet
    start_devnet
    
    # Verificar estado
    verify_devnet
    
    # Mostrar información
    show_connection_info
}

# Ejecutar función principal
main "$@"
