#!/bin/bash

set -x
set -e
set -u
set -o pipefail

source ~/.api-keys

# Verifica dipendenze
command -v curl >/dev/null 2>&1 || { echo >&2 "curl non installato. Installalo con: sudo apt-get install curl"; exit 1; }
command -v jq >/dev/null 2>&1 || { echo >&2 "jq non installato. Installalo con: sudo apt-get install jq"; exit 1; }
command -v montage >/dev/null 2>&1 || { echo >&2 "ImageMagick non installato. Installalo con: sudo apt-get install imagemagick"; exit 1; }

# Configurazioni
API_KEY=${WINDY_API_KEY}
PALERMO_LAT=38.1157
PALERMO_LON=13.3615
RADIUS=30
LIMIT=9
OUTPUT_DIR="webcam_images"
MOSAIC_OUTPUT="mosaico_palermo.jpg"

# Crea directory output
mkdir -p $OUTPUT_DIR

# Ottieni le prime 9 webcam vicino a Palermo
echo "Recupero le webcam nel raggio di 30 km da Palermo..."
RESPONSE=$(curl -s -H "x-windy-api-key: $API_KEY" \
  "https://api.windy.com/webcams/api/v3/webcams?nearby=$PALERMO_LAT,$PALERMO_LON,$RADIUS&limit=$LIMIT")

# Verifica se la risposta contiene webcam
WEB_CAMS=$(echo "$RESPONSE" | jq -r '.result.webcams[].id?')
if [ -z "$WEB_CAMS" ]; then
  echo "Errore: Nessuna webcam trovata nel raggio specificato"
  echo "Risposta API:"
  echo "$RESPONSE" | jq
  exit 1
fi

# Scarica le immagini daylight
echo "Scarico le immagini daylight..."
for WEB_CAM in $WEB_CAMS; do
  IMAGE_URL=$(curl -s -H "x-windy-api-key: $API_KEY" \
    "https://api.windy.com/webcams/api/v3/webcams/$WEB_CAM?include=images" | \
    jq -r '.images.daylight.preview')

  curl -s "$IMAGE_URL" -o "$OUTPUT_DIR/webcam_$WEB_CAM.jpg"
  echo "Scaricata webcam $WEB_CAM"
done

# Crea mosaico 3x3
echo "Creo mosaico 3x3..."
montage "$OUTPUT_DIR/*.jpg" -tile 3x3 -geometry +0+0 $MOSAIC_OUTPUT

echo "Mosaico creato con successo: $MOSAIC_OUTPUT"
