#!/usr/bin/env bash
set -euo pipefail

# Quick Start para Flutter/Dart (frontend) con Android SDK en WSL2
# - Instala/Configura: JDK 17, Flutter, Android SDK (Linux) o enlaza el de Windows si existe
# - Prepara variables de entorno y ejecuta flutter doctor

FLUTTER_CHANNEL="stable"
FLUTTER_VERSION="latest" # usa el tarball del canal estable más reciente
FLUTTER_INSTALL_DIR="$HOME/.flutter"
FLUTTER_WINDOWS_LINK="$HOME/.flutter-windows"
ANDROID_SDK_LINUX_DIR="$HOME/.android-sdk"
ANDROID_SDK_WINDOWS_LINK="$HOME/.android-sdk-windows"
SHELL_RC="$HOME/.bashrc"

IS_WSL=false
if grep -qi "microsoft" /proc/version 2>/dev/null; then
  IS_WSL=true
fi

log() { echo -e "\033[1;34m[quick-start]\033[0m $*"; }
warn() { echo -e "\033[1;33m[quick-start]\033[0m $*"; }
err() { echo -e "\033[1;31m[quick-start]\033[0m $*"; }

require_cmd() {
  if ! command -v "$1" >/dev/null 2>&1; then
    err "Comando requerido no encontrado: $1"
    exit 1
  fi
}

ensure_packages() {
  if [ "${QUICKSTART_SKIP_APT:-}" = "1" ]; then
    warn "Omitiendo instalación por apt (QUICKSTART_SKIP_APT=1). Asegúrate de tener curl, unzip, git, JDK 17."
    return 0
  fi
  if command -v apt-get >/dev/null 2>&1; then
    if sudo -n true 2>/dev/null; then
      sudo apt-get update -y
      sudo DEBIAN_FRONTEND=noninteractive apt-get install -y \
        curl unzip zip ca-certificates git xz-utils libglu1-mesa \
        openjdk-17-jdk
    else
      warn "sudo requiere contraseña y no es interactivo. Ejecuta 'sudo -v' y reintenta o exporta QUICKSTART_SKIP_APT=1."
    fi
  else
    warn "apt-get no disponible; instala manualmente curl, unzip, zip, git, JDK 17."
  fi
}

ensure_java() {
  if command -v java >/dev/null 2>&1; then
    JAVA_VER=$(java -version 2>&1 | head -n1 || true)
    log "Java detectado: $JAVA_VER"
  else
    warn "Java no detectado. Si no puedes instalar automáticamente, instala JDK 17 o establece JAVA_HOME."
    ensure_packages || true
  fi
  if [ -d "/usr/lib/jvm/java-17-openjdk-amd64" ]; then
    export JAVA_HOME="/usr/lib/jvm/java-17-openjdk-amd64"
  elif [ -d "/usr/lib/jvm/java-17-openjdk" ]; then
    export JAVA_HOME="/usr/lib/jvm/java-17-openjdk"
  fi
}

install_flutter() {
  # Siempre usar Flutter nativo de Linux en WSL para evitar .bat/.exe
  if [ -x "$FLUTTER_INSTALL_DIR/bin/flutter" ]; then
    log "Flutter ya instalado en $FLUTTER_INSTALL_DIR"
  else
    log "Instalando Flutter ($FLUTTER_CHANNEL) en $FLUTTER_INSTALL_DIR"
    mkdir -p "$FLUTTER_INSTALL_DIR"
    TMPDIR=$(mktemp -d)
    pushd "$TMPDIR" >/dev/null
    # Resolver último tarball estable usando releases_linux.json (vía python3)
    RELEASES_JSON="https://storage.googleapis.com/flutter_infra_release/releases/releases_linux.json"
    ARCHIVE=$(python3 - <<'PY' 2>/dev/null || true
import json, sys, urllib.request
url = 'https://storage.googleapis.com/flutter_infra_release/releases/releases_linux.json'
with urllib.request.urlopen(url, timeout=30) as r:
    data = json.load(r)
stable_hash = data['current_release']['stable']
for rel in data['releases']:
    if rel.get('hash') == stable_hash:
        print(rel['archive'])
        break
PY
)
    if [ -z "${ARCHIVE:-}" ]; then
      # Fallback simple: intentar un patrón conocido (puede fallar si cambia la versión)
      warn "No se pudo resolver por JSON; intentando patrón genérico (puede fallar)"
      TARBALL_URL="https://storage.googleapis.com/flutter_infra_release/releases/stable/linux/flutter_linux_stable.tar.xz"
    else
      TARBALL_URL="https://storage.googleapis.com/flutter_infra_release/releases/$ARCHIVE"
    fi
    log "Descargando: $TARBALL_URL"
    curl -fsSLo flutter.tar.xz "$TARBALL_URL"
    tar -xJf flutter.tar.xz
    rsync -a flutter/ "$FLUTTER_INSTALL_DIR/"
    # Normalizar finales de línea a Unix para evitar /usr/bin/env: 'bash\r'
    if command -v dos2unix >/dev/null 2>&1; then
      dos2unix "$FLUTTER_INSTALL_DIR/bin/"* >/dev/null 2>&1 || true
    else
      sed -i 's/\r$//' "$FLUTTER_INSTALL_DIR/bin/"* || true
    fi
    popd >/dev/null
    rm -rf "$TMPDIR"
  fi

  export PATH="$FLUTTER_INSTALL_DIR/bin:$PATH"
}

detect_windows_sdk() {
  if [ "$IS_WSL" != true ]; then
    return 1
  fi
  # Preferir C:\\AndroidSdk si existe
  if [ -d "/mnt/c/AndroidSdk" ]; then
    echo "/mnt/c/AndroidSdk"
    return 0
  fi
  # Busca SDK en Windows: C:\\Users\\<User>\\AppData\\Local\\Android\\Sdk
  local candidates=()
  for d in /mnt/c/Users/*/AppData/Local/Android/Sdk; do
    if [ -d "$d" ]; then candidates+=("$d"); fi
  done
  if [ ${#candidates[@]} -gt 0 ]; then
    echo "${candidates[0]}"
    return 0
  fi
  return 1
}

configure_android_sdk() {
  local win_sdk
  if win_sdk=$(detect_windows_sdk); then
    log "SDK de Android en Windows detectado: $win_sdk"
    ln -snf "$win_sdk" "$ANDROID_SDK_WINDOWS_LINK"
    export ANDROID_SDK_ROOT="$ANDROID_SDK_WINDOWS_LINK"
    export ANDROID_HOME="$ANDROID_SDK_WINDOWS_LINK"
    # Cuando usamos el SDK de Windows, no ejecutamos sdkmanager (es .bat)
    export PATH="$ANDROID_SDK_ROOT/platform-tools:$PATH"
    # Crear wrapper de adb sin extensión para herramientas que esperan 'adb'
    mkdir -p "$HOME/.local/bin"
    cat > "$HOME/.local/bin/adb" <<'ADBWRAP'
#!/usr/bin/env bash
exec "/mnt/c/AndroidSdk/platform-tools/adb.exe" "$@"
ADBWRAP
    chmod +x "$HOME/.local/bin/adb"
    # Crear wrapper dentro del propio SDK para que flutter doctor lo encuentre donde espera
    if [ -d "$ANDROID_SDK_ROOT/platform-tools" ]; then
      cat > "$ANDROID_SDK_ROOT/platform-tools/adb" <<'ADBWRAP2'
#!/usr/bin/env bash
exec "/mnt/c/AndroidSdk/platform-tools/adb.exe" "$@"
ADBWRAP2
      chmod +x "$ANDROID_SDK_ROOT/platform-tools/adb"
    fi
  else
    log "Instalando Android SDK (Linux) en $ANDROID_SDK_LINUX_DIR"
    mkdir -p "$ANDROID_SDK_LINUX_DIR/cmdline-tools"
    TMPDIR=$(mktemp -d)
    pushd "$TMPDIR" >/dev/null
    SDK_TOOLS_URL="https://dl.google.com/android/repository/commandlinetools-linux-11076708_latest.zip"
    curl -fsSLo cmdline-tools.zip "$SDK_TOOLS_URL"
    unzip -q cmdline-tools.zip -d cmdline-tools-tmp
    # Estructura requerida: cmdline-tools/latest/...
    mkdir -p "$ANDROID_SDK_LINUX_DIR/cmdline-tools/latest"
    rsync -a cmdline-tools-tmp/cmdline-tools/ "$ANDROID_SDK_LINUX_DIR/cmdline-tools/latest/"
    popd >/dev/null
    rm -rf "$TMPDIR"
    export ANDROID_SDK_ROOT="$ANDROID_SDK_LINUX_DIR"
    export ANDROID_HOME="$ANDROID_SDK_LINUX_DIR"
    export PATH="$ANDROID_SDK_ROOT/cmdline-tools/latest/bin:$ANDROID_SDK_ROOT/platform-tools:$PATH"

    # Acepta licencias e instala paquetes clave de forma no interactiva (solo en SDK Linux)
    yes | sdkmanager --licenses >/dev/null || true
    yes | sdkmanager \
      "platform-tools" \
      "platforms;android-34" \
      "build-tools;34.0.0" \
      >/dev/null || true
  fi
}

persist_shell_rc() {
  local markers_begin="# >>> flutter-android-sdk (quick-start) >>>"
  local markers_end="# <<< flutter-android-sdk (quick-start) <<<"
  sed -i "/$markers_begin/,/$markers_end/d" "$SHELL_RC" || true
  {
    echo "$markers_begin"
    echo "export JAVA_HOME=\"${JAVA_HOME:-}\""
    echo "export ANDROID_SDK_ROOT=\"${ANDROID_SDK_ROOT:-}\""
    echo "export ANDROID_HOME=\"${ANDROID_HOME:-}\""
    # PATH para Flutter Linux y Flutter Windows (si existe)
    echo "[ -d \"$FLUTTER_INSTALL_DIR/bin\" ] && export PATH=\"$FLUTTER_INSTALL_DIR/bin:\$PATH\""
    echo "[ -d \"$HOME/.local/bin\" ] && export PATH=\"$HOME/.local/bin:\$PATH\""
    # SDK de Windows: solo platform-tools; SDK Linux: cmdline-tools + platform-tools
    echo "if echo \"\$ANDROID_SDK_ROOT\" | grep -q '^/mnt/c/'; then"
    echo "  export PATH=\"\$ANDROID_SDK_ROOT/platform-tools:\$PATH\""
    echo "else"
    echo "  export PATH=\"\$ANDROID_SDK_ROOT/cmdline-tools/latest/bin:\$ANDROID_SDK_ROOT/platform-tools:\$PATH\""
    echo "fi"
    echo "$markers_end"
  } >> "$SHELL_RC"
}

configure_flutter_android() {
  if command -v flutter >/dev/null 2>&1; then
    if [ -n "${ANDROID_SDK_ROOT:-}" ]; then
      flutter config --android-sdk "$ANDROID_SDK_ROOT" || true
    fi
    flutter doctor -v || true
  else
    warn "flutter no está en PATH tras la instalación"
  fi
}

main() {
  log "Iniciando quick-start para Flutter/Dart (WSL2 soporte: $IS_WSL)"
  ensure_packages
  ensure_java
  install_flutter
  configure_android_sdk
  persist_shell_rc
  configure_flutter_android
  log "Listo. Abre una nueva terminal o ejecuta: source $SHELL_RC"
}

main "$@"


