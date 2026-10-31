#!/bin/bash

# Script de configuración rápida para el API Gateway (GraphQL + WSS) - Keiko DApp
# Requisitos de referencia: .kiro/specs/01-keiko-dapp/requirements.md (Req 9 y 36)

set -e

# Colores
RED='\033[0;31m'
GREEN='\033[0;32m'
YELLOW='\033[1;33m'
BLUE='\033[0;34m'
NC='\033[0m'

# Config por defecto
HTTP_PORT=${HTTP_PORT:-8088}
WSS_PORT=${WSS_PORT:-8090}
GRPC_GATEWAY_ADDR=${GRPC_GATEWAY_ADDR:-"http://127.0.0.1:50051"}
REDIS_URL=${REDIS_URL:-"redis://127.0.0.1:6379"}
JWT_SECRET=${JWT_SECRET:-"dev_jwt_secret_change_me"}
OTLP_ENDPOINT=${OTLP_ENDPOINT:-"http://127.0.0.1:4317"}
CERTS_DIR=${CERTS_DIR:-"api-gateway/certs"}
ENV_FILE=${ENV_FILE:-"api-gateway/.env"}
BIN_DIR=${BIN_DIR:-"api-gateway/target/release"}
BIN_NAME=${BIN_NAME:-"graphql_server"}
LOG_DIR=${LOG_DIR:-"api-gateway/logs"}

# Flags
NON_INTERACTIVE=false
GENERATE_CERTS=false
FORCE_ENV=false
RUN_BACKGROUND=true
NO_DEPS_CHECK=false

print_status(){ echo -e "${BLUE}[INFO]${NC} $1"; }
print_success(){ echo -e "${GREEN}[SUCCESS]${NC} $1"; }
print_warning(){ echo -e "${YELLOW}[WARNING]${NC} $1"; }
print_error(){ echo -e "${RED}[ERROR]${NC} $1"; }

show_help(){
    echo "Uso: $0 [opciones]"
    echo "  --http-port <p>           Puerto HTTP GraphQL (default: $HTTP_PORT)"
    echo "  --wss-port <p>            Puerto WSS GraphQL (default: $WSS_PORT)"
    echo "  --grpc-gateway <url>      Dirección del gRPC Gateway (default: $GRPC_GATEWAY_ADDR)"
    echo "  --redis-url <url>         URL de Redis (default: $REDIS_URL)"
    echo "  --jwt-secret <s>          Secreto JWT (dev)"
    echo "  --otlp-endpoint <url>     Endpoint OTLP (OpenTelemetry) (default: $OTLP_ENDPOINT)"
    echo "  --generate-certs          Generar certificados autofirmados para WSS"
    echo "  --force-env               Sobrescribir .env"
    echo "  --no-deps-check           Omitir verificación de dependencias"
    echo "  -y, --yes                 No interactivo"
    echo "  --no-background           Ejecutar en primer plano"
    echo "  -h, --help                Ayuda"
}

process_args(){
    while [[ $# -gt 0 ]]; do
        case "$1" in
            --http-port) HTTP_PORT="$2"; shift 2;;
            --wss-port) WSS_PORT="$2"; shift 2;;
            --grpc-gateway) GRPC_GATEWAY_ADDR="$2"; shift 2;;
            --redis-url) REDIS_URL="$2"; shift 2;;
            --jwt-secret) JWT_SECRET="$2"; shift 2;;
            --otlp-endpoint) OTLP_ENDPOINT="$2"; shift 2;;
            --generate-certs) GENERATE_CERTS=true; shift;;
            --force-env) FORCE_ENV=true; shift;;
            --no-deps-check) NO_DEPS_CHECK=true; shift;;
            -y|--yes|--non-interactive) NON_INTERACTIVE=true; shift;;
            --no-background) RUN_BACKGROUND=false; shift;;
            -h|--help) show_help; exit 0;;
            *) print_error "Opción desconocida: $1"; show_help; exit 1;;
        esac
    done
}

detect_os(){
    if [[ "$OSTYPE" == "linux-gnu"* ]]; then
        if command -v apt-get &>/dev/null; then OS="ubuntu";
        elif command -v yum &>/dev/null; then OS="centos";
        elif command -v pacman &>/dev/null; then OS="arch"; else OS="linux"; fi
    elif [[ "$OSTYPE" == "darwin"* ]]; then OS="macos"; else OS="unknown"; fi
}

check_dependencies(){
    if [ "$NO_DEPS_CHECK" = true ]; then print_warning "Omitiendo verificación de dependencias"; return 0; fi
    print_status "Verificando dependencias del sistema..."
    local missing=()
    for dep in curl git openssl protoc redis-cli; do
        if ! command -v $dep >/dev/null 2>&1; then missing+=($dep); fi
    done
    if ! command -v rustc >/dev/null 2>&1; then missing+=(rust); fi
    if [ ${#missing[@]} -gt 0 ]; then
        print_warning "Faltan dependencias: ${missing[*]}"
        case $OS in
            ubuntu) echo "sudo apt-get update && sudo apt-get install -y build-essential pkg-config libssl-dev protobuf-compiler redis-tools openssl";;
            centos) echo "sudo yum install -y gcc-c++ openssl-devel protobuf-compiler redis";;
            arch) echo "sudo pacman -S --noconfirm base-devel openssl protobuf redis";;
            macos) echo "brew install openssl protobuf redis";;
            *) echo "Instala manualmente: ${missing[*]}";;
        esac
    else
        print_success "Dependencias encontradas"
    fi
    if ! command -v cargo >/dev/null 2>&1; then
        print_status "Instalando Rust..."
        curl --proto '=https' --tlsv1.2 -sSf https://sh.rustup.rs | sh -s -- -y
        # shellcheck disable=SC1091
        source "$HOME/.cargo/env"
        print_success "Rust instalado"
    fi
}

ensure_env_file(){
    mkdir -p "$(dirname "$ENV_FILE")"
    if [ -f "$ENV_FILE" ] && [ "$FORCE_ENV" != true ]; then
        print_warning ".env ya existe en $ENV_FILE (usa --force-env para sobrescribir)"
        return 0
    fi
    cat > "$ENV_FILE" << EOF
# API Gateway - Variables de entorno
HTTP_PORT=$HTTP_PORT
WSS_PORT=$WSS_PORT
GRPC_GATEWAY_ADDR=$GRPC_GATEWAY_ADDR
REDIS_URL=$REDIS_URL
JWT_SECRET=$JWT_SECRET
OTLP_ENDPOINT=$OTLP_ENDPOINT
RUST_LOG=info,api_gateway=debug
EOF
    print_success ".env generado en $ENV_FILE"
}

generate_certs(){
    if [ "$GENERATE_CERTS" != true ]; then return 0; fi
    print_status "Generando certificados autofirmados para WSS..."
    mkdir -p "$CERTS_DIR"
    local key="$CERTS_DIR/server.key"
    local crt="$CERTS_DIR/server.crt"
    if [ -f "$key" ] && [ -f "$crt" ] && [ "$NON_INTERACTIVE" = true ]; then
        print_warning "Certificados ya existen, omitiendo (modo no interactivo)"
        return 0
    fi
    openssl req -x509 -nodes -days 365 -newkey rsa:2048 \
        -keyout "$key" -out "$crt" \
        -subj "/C=AR/ST=CABA/L=BA/O=Keiko/OU=Dev/CN=localhost"
    print_success "Certificados creados en $CERTS_DIR"
}

build_binary(){
    print_status "Compilando API Gateway (modo release)..."
    pushd "$(dirname "$0")" >/dev/null
    if cargo build -p graphql_server --release; then
        print_success "Compilado correctamente"
    else
        print_error "Fallo de compilación de graphql_server"
        exit 1
    fi
    popd >/dev/null
}

start_gateway(){
    mkdir -p "$LOG_DIR"
    local bin_path="$BIN_DIR/$BIN_NAME"
    if [ ! -x "$bin_path" ]; then
        # fallback si target está en workspace raíz
        if [ -x "target/release/$BIN_NAME" ]; then bin_path="target/release/$BIN_NAME"; fi
    fi
    if [ ! -x "$bin_path" ]; then
        print_warning "Binario no encontrado en $bin_path. Intentando usar cargo run..."
        if [ "$RUN_BACKGROUND" = true ]; then
            nohup bash -lc "cd api-gateway && RUST_LOG=info dotenv -f .env -- cargo run --release -p graphql_server -- 2>&1 | tee -a ../$LOG_DIR/gateway.out" >/dev/null 2>&1 &
            print_success "graphql_server iniciado en segundo plano (cargo run). Logs en $LOG_DIR/gateway.out"
        else
            (cd api-gateway && RUST_LOG=info dotenv -f .env -- cargo run --release -p graphql_server)
        fi
        return 0
    fi
    if [ "$RUN_BACKGROUND" = true ]; then
        nohup env $(grep -v '^#' "$ENV_FILE" | xargs) "$bin_path" > "$LOG_DIR/gateway.out" 2> "$LOG_DIR/gateway.err" &
        print_success "graphql_server iniciado en segundo plano. Logs en $LOG_DIR/gateway.out"
    else
        env $(grep -v '^#' "$ENV_FILE" | xargs) "$bin_path"
    fi
}

verify_ports(){
    print_status "Verificando puertos..."
    local ok=0
    if ss -tuln 2>/dev/null | grep -q ":$HTTP_PORT"; then print_success "HTTP en :$HTTP_PORT"; ok=$((ok+1)); else print_warning "HTTP no detectado en :$HTTP_PORT"; fi
    if ss -tuln 2>/dev/null | grep -q ":$WSS_PORT"; then print_success "WSS en :$WSS_PORT"; ok=$((ok+1)); else print_warning "WSS no detectado en :$WSS_PORT"; fi
    if [ $ok -eq 0 ]; then
        print_warning "Servicios no detectados aún. Revisa logs: $LOG_DIR/gateway.out"
    fi
}

create_utils(){
    print_status "Creando scripts utilitarios..."
    cat > api-gateway/stop-api-gateway.sh << 'EOF'
#!/bin/bash
echo "Deteniendo API Gateway..."
pkill -f "graphql_server" || true
echo "API Gateway detenido"
EOF
    chmod +x api-gateway/stop-api-gateway.sh

    cat > api-gateway/view-logs.sh << 'EOF'
#!/bin/bash
LOG="api-gateway/logs/gateway.out"
if [ -f "$LOG" ]; then tail -f "$LOG"; else echo "No hay logs en $LOG"; fi
EOF
    chmod +x api-gateway/view-logs.sh
}

connection_info(){
    echo
    print_status "API Gateway ejecutándose"
    echo "  • GraphQL HTTP: http://127.0.0.1:$HTTP_PORT/graphql"
    echo "  • GraphQL WSS: wss://127.0.0.1:$WSS_PORT/graphql-ws"
    echo "  • Redis: $REDIS_URL"
    echo "  • gRPC Gateway: $GRPC_GATEWAY_ADDR"
    echo
    print_status "Comandos útiles"
    echo "  • ./api-gateway/stop-api-gateway.sh"
    echo "  • ./api-gateway/view-logs.sh"
}

main(){
    process_args "$@"
    echo "=========================================="
    echo "  Keiko DApp - API Gateway Quick Start"
    echo "=========================================="
    detect_os
    print_status "OS: $OS"
    check_dependencies
    ensure_env_file
    generate_certs
    build_binary
    start_gateway
    sleep 2
    verify_ports
    create_utils
    connection_info
}

main "$@"


