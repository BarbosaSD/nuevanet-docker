#!/bin/bash
# RESPALDOS AUTOMATICOS - NUEVANET
ORIGEN="/home/usuario/datos"
DESTINO="/backups"
ESTADO="$DESTINO/nuevanet.snar"
LOG="$DESTINO/registro_respaldos.log"
TIPO="$1"
FECHA=$(date +"%Y%m%d_%H%M%S")

registrar() {
    echo "[$(date '+%Y-%m-%d %H:%M:%S')] $1" >> "$LOG"
}

mkdir -p "$DESTINO" || exit 1

if [[ "$TIPO" != "completo" && "$TIPO" != "incremental" ]]; then
    echo "Uso: $0 completo|incremental"
    exit 1
fi

registrar "INICIO del respaldo $TIPO"

if [[ ! -d "$ORIGEN" ]]; then
    registrar "ERROR: No existe el directorio de origen"
    exit 1
fi

if [[ "$TIPO" == "incremental" && ! -f "$ESTADO" ]]; then
    registrar "ERROR: No existe el archivo de seguimiento"
    exit 1
fi

TEMP=$(mktemp "$DESTINO/.estado_XXXXXX") || exit 1

if [[ "$TIPO" == "incremental" ]]; then
    cp "$ESTADO" "$TEMP" || exit 1
else
    rm -f "$TEMP"
fi

ARCHIVO="$DESTINO/respaldo_${TIPO}_${FECHA}.tar.gz"

if ! tar --listed-incremental="$TEMP" -czf "$ARCHIVO" -C /home/usuario datos 2>> "$LOG"; then
    registrar "ERROR: Fallo la creacion del respaldo"
    rm -f "$ARCHIVO" "$TEMP"
    exit 1
fi

if ! tar -tzf "$ARCHIVO" >/dev/null 2>> "$LOG"; then
    registrar "ERROR: Fallo la verificacion del respaldo"
    rm -f "$ARCHIVO" "$TEMP"
    exit 1
fi

if [[ "$TIPO" == "completo" && -f "$ESTADO" ]]; then
    cp -p "$ESTADO" "$DESTINO/estado_anterior_${FECHA}.snar" || exit 1
fi

mv -f "$TEMP" "$ESTADO" || exit 1

TAMANO=$(stat -c %s "$ARCHIVO")
registrar "EXITO: Respaldo $TIPO generado: $ARCHIVO"
registrar "Tamano del respaldo: $TAMANO bytes"
registrar "FIN del respaldo $TIPO"

echo "Respaldo $TIPO creado y verificado correctamente"
echo "Archivo: $ARCHIVO"