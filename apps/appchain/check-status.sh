#!/bin/bash
echo "Verificando estado de Keikochain..."
echo "Puertos activos:"
netstat -tuln | grep -E ":(9944|9945|9946|8080|8081) "
echo
echo "Procesos de Madara:"
ps aux | grep -E "(madara|app-chain)" | grep -v grep
