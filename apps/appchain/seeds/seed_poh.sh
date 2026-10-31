#!/bin/bash

set -e

FIXTURES_PATH="$1"

if [ -z "$FIXTURES_PATH" ]; then
  echo "Uso: $0 <ruta_a_fixtures_json>" >&2
  exit 1
fi

if [ ! -f "$FIXTURES_PATH" ]; then
  echo "[seed_poh] Fixtures no encontrados: $FIXTURES_PATH" >&2
  exit 1
fi

echo "[seed_poh] Sembrando PoH desde $FIXTURES_PATH"

# Hook de integración: aquí deberías invocar tu cliente RPC/gateway o CLI para
# registrar cada humanity_proof_key en la devnet. Por ahora, solo parseamos JSON.

if ! command -v jq >/dev/null 2>&1; then
  echo "[seed_poh] jq no está instalado. Instalalo para parsear JSON, o implementa tu lector." >&2
  exit 0
fi

COUNT=$(jq length "$FIXTURES_PATH")
echo "[seed_poh] Registros a sembrar: $COUNT"

idx=0
while [ $idx -lt $COUNT ]; do
  entry=$(jq -r ".[$idx]" "$FIXTURES_PATH")
  user_id=$(echo "$entry" | jq -r '.user_id')
  hkey=$(echo "$entry" | jq -r '.humanity_proof_key_hex')

  echo "[seed_poh] user_id=$user_id humanity_proof_key_hex=$hkey"

  # TODO: Implementar invocación real (RPC o gateway)
  # Ejemplo placeholder:
  # curl -s -X POST http://127.0.0.1:9945/register_poh -d "{...}"

  idx=$((idx+1))
done

echo "[seed_poh] Seeding PoH finalizado (modo placeholder)"


