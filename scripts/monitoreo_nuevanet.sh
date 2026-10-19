#!/bin/bash
# Automatizacion de supervision - NuevaNet

LOG_DIR="/var/log/nuevanet"
LOG_FILE="$LOG_DIR/monitoreo.log"

registrar() {
    local NIVEL="$1"
    shift
    printf '[%s] [%s] %s\n' \
        "$(date '+%Y-%m-%d %H:%M:%S')" \
        "$NIVEL" "$*" >> "$LOG_FILE"
}

if ! mkdir -p "$LOG_DIR" 2>/dev/null; then
    echo "ERROR: no se pudo crear el directorio de registros: $LOG_DIR" >&2
    exit 1
fi

if [[ ! -w "$LOG_DIR" ]]; then
    echo "ERROR: no hay permisos de escritura en $LOG_DIR" >&2
    exit 1
fi

if ! touch "$LOG_FILE"; then
    echo "ERROR: no se pudo escribir en $LOG_FILE" >&2
    exit 1
fi

if [[ "${1:-}" == "--prueba-error" ]]; then
    registrar "ERROR" "Prueba controlada: se verifico el registro de errores"
    echo "Prueba controlada de error registrada."
    exit 1
fi

if [[ $# -gt 1 ]] || {
    [[ $# -eq 1 && "$1" != "--automatico" ]]
}; then
    echo "Uso: $0 [--automatico|--prueba-error]" >&2
    registrar "ERROR" "Se recibieron parametros no validos"
    exit 2
fi

registrar "INFO" "Inicio de la supervision de NuevaNet"

if SALIDA=$(df -h 2>&1); then
    registrar "INFO" "Uso del almacenamiento:"
    while IFS= read -r LINEA; do
        registrar "INFO" "$LINEA"
    done <<< "$SALIDA"
else
    registrar "ERROR" "No se pudo consultar el almacenamiento: $SALIDA"
fi

if SALIDA=$(free -h 2>&1); then
    registrar "INFO" "Uso de memoria RAM:"
    while IFS= read -r LINEA; do
        registrar "INFO" "$LINEA"
    done <<< "$SALIDA"
else
    registrar "ERROR" "No se pudo consultar la memoria: $SALIDA"
fi

if SALIDA=$(uptime 2>&1); then
    registrar "INFO" "Estado de carga: $SALIDA"
else
    registrar "ERROR" "No se pudo consultar la carga: $SALIDA"
fi

for SERVICIO in sshd crond; do
    if systemctl is-active --quiet "$SERVICIO"; then
        registrar "INFO" "Servicio $SERVICIO: ACTIVO"
    else
        registrar "ERROR" "Servicio $SERVICIO: INACTIVO o no disponible"
    fi
done

registrar "INFO" "Fin de la supervision de NuevaNet"
echo "Supervision finalizada. Registro: $LOG_FILE"