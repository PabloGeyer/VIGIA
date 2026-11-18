#!/bin/bash
# simulador.sh: automatizaciones falsas para probar Vigía sin tener automatizaciones reales.
#
# Uso:
#   1. Registrá en Vigía tres automatizaciones que corran cada 1 minuto y copiá sus IDs.
#   2. Completá los IDs abajo (o pasalos como variables de entorno).
#   3. Ejecutá: bash ejemplos/simulador.sh
#
# Qué simula:
#   - backup-nocturno:  anda siempre bien.
#   - ventas-planilla:  falla 1 de cada 3 veces, con errores variados (útil para probar el diagnóstico con IA).
#   - envio-facturas:   nunca avisa, así que Vigía debería alertar que "no corrió".

VIGIA="${VIGIA:-http://localhost:8080/ping}"
ID_BACKUP="${ID_BACKUP:-backup-nocturno}"
ID_VENTAS="${ID_VENTAS:-ventas-planilla}"
# ID_FACTURAS no se usa a propósito: esa automatización "se cayó" y nunca avisa.

ERRORES=(
  "Error 401 Unauthorized: Google Sheets token expired"
  "ECONNREFUSED 127.0.0.1:5432 - could not connect to database"
  "Disk full: no space left on device /var/backups"
)

echo "Simulando automatizaciones contra $VIGIA (Ctrl+C para cortar)"

while true; do
  curl -fsS "$VIGIA/$ID_BACKUP" > /dev/null && echo "$(date +%H:%M:%S)  backup-nocturno  ✅ ok"

  if [ $((RANDOM % 3)) -eq 0 ]; then
    ERROR="${ERRORES[$((RANDOM % ${#ERRORES[@]}))]}"
    curl -fsS -d "$ERROR" "$VIGIA/$ID_VENTAS/fail" > /dev/null && echo "$(date +%H:%M:%S)  ventas-planilla  🔴 falló: $ERROR"
  else
    curl -fsS "$VIGIA/$ID_VENTAS" > /dev/null && echo "$(date +%H:%M:%S)  ventas-planilla  ✅ ok"
  fi

  sleep 60
done
