#!/bin/bash

# Script para solucionar el warning de mounts de Podman en WSL2
# Soluciona: WARN[0000] "/" is not a shared mount, this could cause issues or missing mounts with rootless containers

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
echo "  Solucionando Warning de Podman Mounts"
echo "  Para WSL2 + Ubuntu 24.04 LTS"
echo "=========================================="
echo

# Verificar si estamos en WSL2
if [ -f /proc/version ] && grep -q Microsoft /proc/version; then
    print_status "WSL2 detectado correctamente"
else
    print_warning "No se detectó WSL2. Este script está optimizado para WSL2"
fi

# Verificar el estado actual del mount
print_status "Verificando estado actual del mount raíz..."
if mount | grep -q "on / type"; then
    mount_info=$(mount | grep "on / type")
    print_status "Estado actual: $mount_info"
    
    if echo "$mount_info" | grep -q "shared"; then
        print_success "El mount ya está configurado como shared"
        exit 0
    else
        print_warning "El mount no está configurado como shared"
    fi
else
    print_warning "No se pudo obtener información del mount raíz"
fi

echo
print_status "Soluciones disponibles:"
echo
echo "1. Configurar mount como shared (Recomendado)"
echo "2. Usar Podman con --privileged (Menos seguro)"
echo "3. Ignorar el warning (Puede funcionar para casos simples)"
echo

read -p "¿Qué opción prefieres? (1/2/3): " -n 1 -r
echo

case $REPLY in
    1)
        print_status "Configurando mount como shared..."
        echo
        echo "Ejecuta estos comandos en tu terminal:"
        echo
        echo "# Hacer el mount raíz como shared"
        echo "sudo mount --make-shared /"
        echo
        echo "# Verificar que se aplicó correctamente"
        echo "mount | grep 'on / type'"
        echo
        echo "# Reiniciar Podman para aplicar cambios"
        echo "podman system reset"
        echo
        print_warning "Nota: Este cambio se pierde al reiniciar WSL2"
        echo "Para hacerlo permanente, agrega esta línea a ~/.bashrc:"
        echo "sudo mount --make-shared / 2>/dev/null || true"
        ;;
    2)
        print_status "Configurando Podman para usar --privileged..."
        echo
        echo "Crea o edita el archivo ~/.config/containers/containers.conf:"
        echo
        echo "mkdir -p ~/.config/containers"
        echo "cat > ~/.config/containers/containers.conf << 'EOF'"
        echo "[containers]"
        echo "privileged = true"
        echo "EOF"
        echo
        print_warning "Nota: Esto reduce la seguridad pero elimina el warning"
        ;;
    3)
        print_status "Ignorando el warning..."
        echo
        echo "El warning es solo informativo. Podman puede funcionar normalmente"
        echo "aunque aparezca este mensaje. Si no tienes problemas específicos,"
        echo "puedes ignorarlo sin problemas."
        echo
        print_success "No se requieren cambios adicionales"
        ;;
    *)
        print_error "Opción inválida"
        exit 1
        ;;
esac

echo
print_status "Información adicional sobre el warning:"
echo
echo "• El warning aparece porque WSL2 no configura automáticamente"
echo "  los mounts como 'shared'"
echo "• Esto puede afectar la funcionalidad de contenedores rootless"
echo "• Para la mayoría de casos de uso, el warning es solo informativo"
echo "• Si Madara devnet funciona correctamente, puedes ignorarlo"
echo
print_status "Para verificar si Podman funciona correctamente:"
echo "podman run --rm hello-world"
echo
print_success "Script completado"
