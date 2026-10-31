#!/bin/bash

# Script simplificado para iniciar devnet de Madara con Podman
# Sin dependencia de podman-compose

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
echo "  Iniciando Madara Devnet (Versión Simple)"
echo "  Con Podman - Sin docker-compose"
echo "=========================================="
echo

# Verificar que estamos en el directorio correcto
if [ ! -d "madara-cli" ]; then
    print_error "Directorio madara-cli no encontrado. Ejecuta desde el directorio appchain"
    exit 1
fi

# Verificar que Podman está instalado
if ! command -v podman &> /dev/null; then
    print_error "Podman no está instalado"
    exit 1
fi

print_success "Podman encontrado: $(podman --version)"

# Crear función docker que use Podman
setup_docker_wrapper() {
    print_status "Configurando wrapper de Docker para Podman..."
    
    # Crear directorio bin local si no existe
    mkdir -p ~/.local/bin
    
    # Crear wrapper de docker
    cat > ~/.local/bin/docker << 'EOF'
#!/bin/bash
# Wrapper para usar Podman como Docker
exec podman "$@"
EOF
    
    # Hacer ejecutable
    chmod +x ~/.local/bin/docker
    
    # Agregar al PATH si no está
    if ! echo "$PATH" | grep -q "$HOME/.local/bin"; then
        echo 'export PATH="$HOME/.local/bin:$PATH"' >> ~/.bashrc
        export PATH="$HOME/.local/bin:$PATH"
    fi
    
    print_success "Wrapper de Docker configurado"
}

# Función para iniciar la devnet directamente con Podman
start_devnet_direct() {
    print_status "Iniciando devnet de Madara directamente con Podman..."
    
    cd madara-cli
    
    # Verificar si existe el archivo compose
    if [ -f "deps/madara/compose.yaml" ]; then
        print_status "Archivo compose.yaml encontrado"
        
        # Intentar ejecutar con podman directamente
        print_warning "Intentando iniciar servicios con Podman..."
        
        # Configurar variables de entorno
        export DOCKER_HOST="unix:///run/user/$(id -u)/podman/podman.sock"
        
        # Ejecutar podman directamente en lugar de docker compose
        if podman play kube deps/madara/compose.yaml 2>/dev/null || \
           podman-compose -f deps/madara/compose.yaml up -d 2>/dev/null || \
           podman run -d --name madara-devnet -p 9944:9944 -p 9945:9945 -p 9946:9946 madara/madara:latest; then
            print_success "¡Devnet iniciada con Podman!"
        else
            print_warning "Método directo falló, intentando con Madara CLI..."
            # Fallback: usar Madara CLI
            if cargo run --release create devnet; then
                print_success "¡Devnet iniciada con Madara CLI!"
            else
                print_error "Error al iniciar la devnet"
                exit 1
            fi
        fi
    else
        print_warning "Archivo compose.yaml no encontrado, usando Madara CLI..."
        if cargo run --release create devnet; then
            print_success "¡Devnet iniciada con Madara CLI!"
        else
            print_error "Error al iniciar la devnet"
            exit 1
        fi
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
    echo "  • podman stop <container>    - Detener contenedor"
    echo "  • podman restart <container> - Reiniciar contenedor"
    echo
    print_warning "Mantén esta terminal abierta para que la devnet siga ejecutándose"
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
    
    print_success "Scripts de utilidad creados"
}

# Función principal
main() {
    # Configurar wrapper de Docker
    setup_docker_wrapper
    
    # Iniciar devnet
    start_devnet_direct
    
    # Verificar estado
    verify_devnet
    
    # Crear scripts de utilidad
    create_utility_scripts
    
    # Mostrar información
    show_connection_info
}

# Ejecutar función principal
main "$@"
