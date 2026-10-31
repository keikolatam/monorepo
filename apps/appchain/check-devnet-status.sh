#!/bin/bash
echo "Verificando estado de la devnet de Madara..."
echo "Contenedores Podman:"
podman ps --format "table {{.Names}}\t{{.Status}}\t{{.Ports}}" | grep -i madara || echo "No hay contenedores de Madara ejecutándose"
echo
echo "Puertos activos:"
netstat -tuln | grep -E ":(9944|9945|9946) " || echo "No hay puertos de Madara activos"
