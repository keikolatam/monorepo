#!/bin/bash

# Keiko DApp - Quick Start Setup Script
# Configura asdf, Scarb y Starknet Foundry para desarrollo
# Basado en: https://asdf-vm.com/guide/getting-started.html
#           https://docs.swmansion.com/scarb/download.html#install-via-asdf
#           https://foundry-rs.github.io/starknet-foundry/getting-started/installation.html

set -e

# Colores para output
RED='\033[0;31m'
GREEN='\033[0;32m'
YELLOW='\033[1;33m'
BLUE='\033[0;34m'
NC='\033[0m' # No Color

# Función para imprimir mensajes con colores
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

# Función para detectar el sistema operativo
detect_os() {
    if [[ "$OSTYPE" == "linux-gnu"* ]]; then
        if command -v apt-get &> /dev/null; then
            OS="ubuntu"
        elif command -v yum &> /dev/null; then
            OS="centos"
        elif command -v pacman &> /dev/null; then
            OS="arch"
        else
            OS="linux"
        fi
    elif [[ "$OSTYPE" == "darwin"* ]]; then
        OS="macos"
    else
        OS="unknown"
    fi
}

# Función para verificar dependencias del sistema
check_system_dependencies() {
    print_status "Verificando dependencias del sistema..."
    
    local missing_deps=()
    
    # Verificar dependencias básicas
    for dep in git bash curl gawk; do
        if ! command -v $dep &> /dev/null; then
            missing_deps+=($dep)
        fi
    done
    
    # Verificar dependencias específicas según el OS
    case $OS in
        "ubuntu")
            for dep in dirmngr gpg; do
                if ! command -v $dep &> /dev/null; then
                    missing_deps+=($dep)
                fi
            done
            ;;
        "centos")
            for dep in gnupg2; do
                if ! command -v $dep &> /dev/null; then
                    missing_deps+=($dep)
                fi
            done
            ;;
        "arch")
            for dep in gnupg; do
                if ! command -v $dep &> /dev/null; then
                    missing_deps+=($dep)
                fi
            done
            ;;
        "macos")
            for dep in gpg; do
                if ! command -v $dep &> /dev/null; then
                    missing_deps+=($dep)
                fi
            done
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
                echo "  brew install ${missing_deps[*]}"
                ;;
            *)
                echo "  Instala manualmente: ${missing_deps[*]}"
                ;;
        esac
        
        print_warning "Continuando con la instalación de asdf..."
        return 1
    fi
}

# Función para instalar asdf
install_asdf() {
    print_status "Instalando asdf..."

    # Si ya existe, mostrar versión y salir
    if command -v asdf &> /dev/null; then
        print_warning "asdf ya está instalado: $(asdf --version)"
        return 0
    fi

    # Instalar binario de asdf (Go) en ~/.asdf/bin
    ASDF_VER="0.16.2"
    mkdir -p "$HOME/.asdf/bin"
    print_status "Descargando asdf v$ASDF_VER (linux-amd64)"
    curl -fsSL "https://github.com/asdf-vm/asdf/releases/download/v${ASDF_VER}/asdf-v${ASDF_VER}-linux-amd64.tar.gz" \
      | tar -xz -C "$HOME/.asdf/bin"

    # Configurar ASDF_DATA_DIR y PATH según guía 0.16+
    if ! grep -q '^export ASDF_DATA_DIR=' "$HOME/.bashrc" 2>/dev/null; then
        echo 'export ASDF_DATA_DIR="$HOME/.asdf"' >> "$HOME/.bashrc"
    fi

    # Eliminar líneas antiguas que sourceaban asdf.sh (pre-0.16)
    sed -i.bak '/\. \"\$HOME\/\.asdf\/asdf\.sh\"/d' "$HOME/.bashrc" 2>/dev/null || true
    sed -i.bak '/\. \/opt\/homebrew\/opt\/asdf\/libexec\/asdf\.sh/d' "$HOME/.bashrc" 2>/dev/null || true

    # Añadir PATH y completions para bash
    if [ -n "$BASH_VERSION" ]; then
        if ! grep -q 'PATH="$HOME/.asdf/bin:$ASDF_DATA_DIR/shims:$PATH"' "$HOME/.bashrc" 2>/dev/null; then
            echo 'export PATH="$HOME/.asdf/bin:$ASDF_DATA_DIR/shims:$PATH"' >> "$HOME/.bashrc"
        fi
        if ! grep -q 'asdf completion bash' "$HOME/.bashrc" 2>/dev/null; then
            echo 'command -v asdf >/dev/null 2>&1 && asdf completion bash' >> "$HOME/.bashrc"
        fi
    fi

    # Añadir PATH para zsh/fish (best-effort)
    if [ -n "$ZSH_VERSION" ]; then
        if ! grep -q 'PATH="$HOME/.asdf/bin:$HOME/.asdf/shims:$PATH"' "$HOME/.zshrc" 2>/dev/null; then
            echo 'export PATH="$HOME/.asdf/bin:$HOME/.asdf/shims:$PATH"' >> "$HOME/.zshrc"
        fi
    fi
    if [ -n "$FISH_VERSION" ]; then
        mkdir -p "$HOME/.config/fish"
        if ! grep -q "asdf/shims" "$HOME/.config/fish/config.fish" 2>/dev/null; then
            echo 'set -gx PATH $HOME/.asdf/bin $HOME/.asdf/shims $PATH' >> "$HOME/.config/fish/config.fish"
        fi
    fi

    # Cargar en esta sesión
    export ASDF_DATA_DIR="$HOME/.asdf"
    export PATH="$HOME/.asdf/bin:$ASDF_DATA_DIR/shims:$PATH"

    if command -v asdf &> /dev/null; then
        print_success "asdf instalado: $(asdf --version)"
        # Regenerar shims por si existían previas instalaciones
        asdf reshim || true
    else
        print_warning "asdf no se detecta en PATH. Abre una nueva terminal o ejecuta: source ~/.bashrc"
    fi
}

# Función para instalar Scarb
install_scarb() {
    print_status "Instalando Scarb..."
    
    # Agregar plugin de Scarb
    asdf plugin add scarb https://github.com/software-mansion/asdf-scarb.git || true
    
    # Instalar versión fija (evita fallos con 'latest')
    local SCARB_VERSION="2.12.2"
    if asdf list scarb 2>/dev/null | grep -q "$SCARB_VERSION"; then
        print_warning "Scarb $SCARB_VERSION ya instalado, omitiendo instalación"
    else
        asdf install scarb "$SCARB_VERSION"
    fi
    # Fijar para el usuario (home)
    asdf set --home scarb "$SCARB_VERSION"
    
    print_success "Scarb instalado correctamente"
}

# Función para instalar Starknet Foundry
install_starknet_foundry() {
    print_status "Instalando Starknet Foundry..."
    
    # Agregar plugin de Starknet Foundry (según documentación oficial)
    if ! asdf plugin add starknet-foundry; then
        print_warning "Error al agregar plugin de Starknet Foundry. Intentando instalación con Starkup..."
        
        # Instalación alternativa con Starkup
        print_status "Instalando Starknet Foundry con Starkup..."
        if curl --proto '=https' --tlsv1.2 -sSf https://sh.starkup.sh | sh; then
            print_success "Starknet Foundry instalado con Starkup"
            return 0
        else
            print_error "Error al instalar con Starkup. Por favor, instala manualmente siguiendo la documentación oficial."
            return 1
        fi
    fi
    
    # Instalar versión fija (evita fallos con 'latest')
    local FOUNDRY_VERSION="0.49.0"
    if ! asdf install starknet-foundry "$FOUNDRY_VERSION"; then
        print_warning "Error al instalar Starknet Foundry via asdf. Intentando con Starkup..."
        if curl --proto '=https' --tlsv1.2 -sSf https://sh.starkup.sh | sh; then
            print_success "Starknet Foundry instalado con Starkup"
            return 0
        else
            print_error "Error al instalar Starknet Foundry. Por favor, instala manualmente."
            return 1
        fi
    fi
    
    # Fijar para el usuario (home)
    asdf set --home starknet-foundry "$FOUNDRY_VERSION"
    
    print_success "Starknet Foundry instalado correctamente"
}

# Función para instalar Starknet CLI oficial
install_starknet_cli() {
    print_status "Instalando Starknet CLI oficial..."
    
    # Verificar si ya está instalado
    if command -v starknet &> /dev/null; then
        print_success "Starknet CLI ya está instalado: $(starknet --version)"
        return 0
    fi
    
    # Instalación con Starkup (incluye el comando starknet)
    print_status "Instalando Starknet CLI con Starkup..."
    if curl --proto '=https' --tlsv1.2 -sSf https://sh.starkup.dev | sh; then
        print_success "Starknet CLI instalado con Starkup (dev)"
    else
        print_warning "Fallo instalando con sh.starkup.dev, intentando sh.starkup.sh..."
        if curl --proto '=https' --tlsv1.2 -sSf https://sh.starkup.sh | sh; then
            print_success "Starknet CLI instalado con Starkup (sh)"
        else
            print_warning "No se pudo instalar Starknet CLI con Starkup"
        fi
    fi

    # Asegurar que ~/.local/bin esté en PATH (starkup instala ahí)
    if ! grep -q 'export PATH="$HOME/.local/bin:$PATH"' "$HOME/.bashrc" 2>/dev/null; then
        echo 'export PATH="$HOME/.local/bin:$PATH"' >> "$HOME/.bashrc"
    fi
    export PATH="$HOME/.local/bin:$PATH"

    # Comprobar disponibilidad; marcar como opcional si no está
    if command -v starknet &> /dev/null; then
        print_success "Starknet CLI disponible: $(starknet --version)"
        return 0
    else
        print_warning "Starknet CLI no se encontró en PATH tras la instalación. Este paso es opcional."
        return 0
    fi
}

# Función para verificar instalaciones
verify_installations() {
    print_status "Verificando instalaciones..."
    
    # Verificar asdf
    if command -v asdf &> /dev/null; then
        print_success "asdf: $(asdf --version)"
    else
        print_error "asdf no está disponible"
        return 1
    fi
    
    # Verificar Scarb
    if command -v scarb &> /dev/null; then
        print_success "Scarb: $(scarb --version)"
    else
        print_error "Scarb no está disponible"
        return 1
    fi
    
    # Verificar Starknet Foundry
    if command -v snforge &> /dev/null; then
        print_success "Starknet Foundry: $(snforge --version)"
    else
        print_error "Starknet Foundry no está disponible"
        return 1
    fi
    
    if command -v starknet &> /dev/null; then
        print_success "Starknet CLI: $(starknet --version)"
    else
        print_warning "Starknet CLI no está disponible (opcional)"
    fi
}

# Función para crear archivo .tool-versions
create_tool_versions() {
    print_status "Creando archivo .tool-versions..."
    
    cat > .tool-versions << EOF
# Keiko DApp - Versiones de herramientas
# Generado automáticamente por quick-start.sh

scarb 2.12.2
starknet-foundry 0.49.0
# starknet se instala manualmente en ~/.local/bin
EOF
    
    print_success "Archivo .tool-versions creado"
}

# Función para mostrar información post-instalación
show_post_install_info() {
    print_success "¡Instalación completada!"
    echo
    print_status "Información importante:"
    echo "  • asdf: $(asdf --version)"
    echo "  • Scarb: $(scarb --version)"
    echo "  • Starknet Foundry: $(snforge --version)"
    echo "  • Starknet CLI: $(starknet --version)"
    echo
    print_status "Próximos pasos:"
    echo "  1. Reinicia tu terminal o ejecuta: source ~/.bashrc (o ~/.zshrc)"
    echo "  2. Navega al directorio appchain/ para trabajar con contratos Cairo"
    echo "  3. Ejecuta 'scarb build' para compilar contratos"
    echo "  4. Ejecuta 'snforge test' para ejecutar tests"
    echo
    print_status "Recursos útiles:"
    echo "  • Documentación Scarb: https://docs.swmansion.com/scarb/"
    echo "  • Documentación Starknet Foundry: https://foundry-rs.github.io/starknet-foundry/"
    echo "  • Documentación asdf: https://asdf-vm.com/guide/"
    echo
    print_warning "Nota: Si tienes problemas, reinicia tu terminal y verifica que las herramientas estén en tu PATH"
}

# Función principal
main() {
    echo "=========================================="
    echo "  Keiko DApp - Quick Start Setup"
    echo "=========================================="
    echo
    
    # Detectar sistema operativo
    detect_os
    print_status "Sistema operativo detectado: $OS"
    
    # Verificar dependencias del sistema
    check_system_dependencies
    
    # Instalar asdf
    install_asdf
    
    # Instalar Scarb
    install_scarb
    
    # Instalar Starknet Foundry
    install_starknet_foundry
    
    # Usar snforge (Starknet Foundry) como herramienta principal
    print_status "snforge disponible: $(snforge --version)"

    # Crear archivo .tool-versions
    create_tool_versions
    
    # Verificar instalaciones
    verify_installations
    
    # Mostrar información post-instalación
    show_post_install_info
}

# Ejecutar función principal
main "$@"
