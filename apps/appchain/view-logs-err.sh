#!/bin/bash
echo "Mostrando logs de Keikochain..."
if [ -d "logs" ]; then
    tail -f logs/*.err
else
    echo "No se encontraron error logs"
fi
