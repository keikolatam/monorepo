#!/bin/bash
echo "Deteniendo devnet de Madara..."
podman stop $(podman ps -q) 2>/dev/null || true
echo "Devnet detenida"
