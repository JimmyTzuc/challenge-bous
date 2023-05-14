#!/bin/bash

# Verifica si se proporcionó un argumento
if [ $# -eq 0 ]; then
    echo "Debe proporcionar un archivo Excel como argumento."
    exit 1
fi

# Directorio de trabajo
dir_trabajo="directorio_de_trabajo"
mkdir -p "$dir_trabajo"

# Copia el archivo Excel al directorio de trabajo
cp "$1" "$dir_trabajo"

# Verifica si el archivo existe
if [ ! -f "$dir_trabajo/$(basename "$1")" ]; then
    echo "No se pudo copiar el archivo al directorio de trabajo."
    exit 1
fi

# Ejecuta el script valida_header.py
python valida_header.py "$dir_trabajo/$(basename "$1")"
validacion_exitosa=$?

# Verifica el resultado de la validación del encabezado
if [ $validacion_exitosa -ne 0 ]; then
    echo "El archivo tiene errores en el encabezado. Abortando."
    exit 1
fi

# Convierte el Excel a formato CSV
csv_file="$dir_trabajo/$(basename "$1" .xlsx).csv"
# Comando para convertir el archivo Excel a CSV (reemplaza con el método o herramienta que desees)
# ejemplo: xlsx2csv "$dir_trabajo/$(basename "$1")" > "$csv_file"

# Verifica si se generó correctamente el archivo CSV
if [ ! -f "$csv_file" ]; then
    echo "No se pudo convertir el archivo a formato CSV."
    exit 1
fi

# Carga el CSV en la tabla de trabajo en PostgreSQL
psql -U usuario -d basedatos -c "COPY challenge_bous.tabla_trabajo FROM '$csv_file' WITH (FORMAT csv, HEADER true)"

# Ejecuta el script carga_y_calculos.sql en la base de datos
psql -U usuario -d basedatos -f carga_y_calculos.sql

# Mueve el archivo Excel al directorio de archivos procesados
directorio_procesados="directorio_procesados"
mkdir -p "$directorio_procesados"
mv "$1" "$directorio_procesados"

# Obtiene el folio de la ejecución
folio_ejecucion=$(psql -U usuario -d basedatos -t -c "SELECT folio FROM challenge_bous.tabla_ejecuciones ORDER BY fecha_ejecucion DESC LIMIT 1;")

# Muestra el folio de la ejecución
echo "Folio de la ejecución: $folio_ejecucion"
