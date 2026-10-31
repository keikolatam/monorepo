#!/bin/bash
echo "Mostrando logs de Keikochain..."
if [ -d "logs" ]; then
    tail -f logs/*.out
else
    echo "No se encontraron output logs"
fi
