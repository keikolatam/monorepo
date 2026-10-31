#!/bin/bash

# Script para configurar devnet de Madara en WSL2 - Keiko DApp
# Basado en: https://docs.madara.build/quickstart/run_devnet
# Solución para WSL2 con Docker Desktop

set -e  # Salir si cualquier comando falla

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

# Función para verificar Docker en WSL2
check_docker_wsl2() {
    print_status "Verificando configuración de Docker en WSL2..."
    
    # Verificar si Docker está disponible
    if ! command -v docker &> /dev/null; then
        print_error "Docker no está disponible en WSL2"
        print_status "Para usar Madara devnet en WSL2, necesitas:"
        echo
        echo "1. Instalar Docker Desktop en Windows"
        echo "2. Habilitar WSL2 integration en Docker Desktop:"
        echo "   - Abre Docker Desktop"
        echo "   - Ve a Settings > Resources > WSL Integration"
        echo "   - Habilita 'Enable integration with my default WSL distro'"
        echo "   - Habilita la integración con tu distro específico"
        echo "3. Reinicia WSL2: wsl --shutdown"
        echo "4. Reinicia Docker Desktop"
        echo
        print_warning "Alternativamente, puedes usar Starknet Devnet directamente"
        return 1
    fi
    
    # Verificar si Docker está ejecutándose
    if ! docker info &> /dev/null; then
        print_error "Docker no está ejecutándose"
        print_status "Inicia Docker Desktop y vuelve a intentar"
        return 1
    fi
    
    print_success "Docker está configurado correctamente en WSL2"
    return 0
}

# Función para configurar Starknet Devnet como alternativa
setup_starknet_devnet() {
    print_status "Configurando Starknet Devnet como alternativa..."
    
    # Verificar si Starknet Devnet está disponible
    if command -v starknet-devnet &> /dev/null; then
        print_success "Starknet Devnet ya está instalado"
    else
        print_status "Instalando Starknet Devnet..."
        
        # Instalar via pip
        if command -v pip3 &> /dev/null; then
            pip3 install starknet-devnet
        elif command -v pip &> /dev/null; then
            pip install starknet-devnet
        else
            print_error "pip no está disponible. Instala Python y pip primero."
            return 1
        fi
    fi
    
    # Crear script para iniciar Starknet Devnet
    cat > start-starknet-devnet.sh << 'EOF'
#!/bin/bash
echo "Iniciando Starknet Devnet..."
echo "RPC: http://127.0.0.1:5050"
echo "WebSocket: ws://127.0.0.1:5050/ws"
echo "Presiona Ctrl+C para detener"
starknet-devnet --host 0.0.0.0 --port 5050
EOF
    chmod +x start-starknet-devnet.sh
    
    print_success "Starknet Devnet configurado"
    return 0
}

# Función para crear configuración de desarrollo
create_dev_config() {
    print_status "Creando configuración de desarrollo..."
    
    # Crear archivo de configuración para desarrollo
    cat > dev-config.toml << 'EOF'
# Configuración de desarrollo para Keiko DApp
# Usando Starknet Devnet como alternativa a Madara

[development]
# Starknet Devnet
starknet_devnet_rpc = "http://127.0.0.1:5050"
starknet_devnet_ws = "ws://127.0.0.1:5050/ws"

# Madara Devnet (cuando Docker esté disponible)
madara_devnet_rpc = "http://127.0.0.1:9945"
madara_devnet_ws = "ws://127.0.0.1:9946"

[contracts]
# Direcciones de contratos en desarrollo
proof_of_humanity = "0x0"
learning_interactions = "0x0"
life_learning_passport = "0x0"
reputation_system = "0x0"
governance = "0x0"
learning_marketplace = "0x0"

[testing]
# Configuración para tests
test_accounts = 10
initial_balance = 1000000000000000000000
EOF

    print_success "Configuración de desarrollo creada"
}

# Función para crear scripts de utilidad
create_utility_scripts() {
    print_status "Creando scripts de utilidad..."
    
    # Script para verificar estado de Docker
    cat > check-docker.sh << 'EOF'
#!/bin/bash
echo "Verificando estado de Docker en WSL2..."
echo "Docker version:"
docker --version 2>/dev/null || echo "Docker no está disponible"
echo
echo "Docker info:"
docker info 2>/dev/null || echo "Docker no está ejecutándose"
echo
echo "Contenedores ejecutándose:"
docker ps 2>/dev/null || echo "No se pueden listar contenedores"
EOF
    chmod +x check-docker.sh
    
    # Script para iniciar Madara devnet (cuando Docker esté disponible)
    cat > start-madara-devnet.sh << 'EOF'
#!/bin/bash
echo "Iniciando Madara devnet..."
cd madara-cli
cargo run --release create devnet
EOF
    chmod +x start-madara-devnet.sh
    
    # Script para detener contenedores
    cat > stop-devnet.sh << 'EOF'
#!/bin/bash
echo "Deteniendo devnet..."
docker stop $(docker ps -q) 2>/dev/null || true
echo "Devnet detenida"
EOF
    chmod +x stop-devnet.sh
    
    print_success "Scripts de utilidad creados"
}

# Función para mostrar información de conexión
show_connection_info() {
    echo
    print_success "¡Configuración de desarrollo completada!"
    echo
    print_status "Opciones disponibles:"
    echo
    echo "1. Starknet Devnet (Recomendado para WSL2):"
    echo "   • RPC: http://127.0.0.1:5050"
    echo "   • WebSocket: ws://127.0.0.1:5050/ws"
    echo "   • Iniciar: ./start-starknet-devnet.sh"
    echo
    echo "2. Madara Devnet (Requiere Docker Desktop):"
    echo "   • RPC: http://127.0.0.1:9945"
    echo "   • WebSocket: ws://127.0.0.1:9946"
    echo "   • Iniciar: ./start-madara-devnet.sh"
    echo
    print_status "Scripts disponibles:"
    echo "  • ./start-starknet-devnet.sh  - Iniciar Starknet Devnet"
    echo "  • ./start-madara-devnet.sh    - Iniciar Madara Devnet"
    echo "  • ./check-docker.sh           - Verificar estado de Docker"
    echo "  • ./stop-devnet.sh            - Detener devnet"
    echo
    print_warning "Para usar Madara devnet, configura Docker Desktop con WSL2 integration"
}

# Función principal
main() {
    echo "=========================================="
    echo "  Keiko DApp - Devnet Setup para WSL2"
    echo "  Basado en: https://docs.madara.build/quickstart/run_devnet"
    echo "=========================================="
    echo
    
    # Verificar Docker en WSL2
    if check_docker_wsl2; then
        print_success "Docker está disponible. Puedes usar Madara devnet."
    else
        print_warning "Docker no está disponible. Configurando Starknet Devnet como alternativa."
        setup_starknet_devnet
    fi
    
    # Crear configuración de desarrollo
    create_dev_config
    
    # Crear scripts de utilidad
    create_utility_scripts
    
    # Mostrar información de conexión
    show_connection_info
}

# Ejecutar función principal
main "$@"
