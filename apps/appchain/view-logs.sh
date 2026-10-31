#!/bin/bash
echo "Mostrando logs de Keikochain..."
if [ -d "madara-cli/logs" ]; then
    tail -f madara-cli/logs/*.log
else
    echo "No se encontraron logs en madara-cli/logs/"
fi
