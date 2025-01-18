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
PALERMO_LAT=38.1295726276908
PALERMO_LON=13.3471925068464
RADIUS=30
LIMIT=20  # Recuperiamo 20 webcam per poi selezionare le 9 più vicine
OUTPUT_DIR="webcam_images"
MOSAIC_OUTPUT="mosaico_palermo.jpg"

# Crea directory output
mkdir -p $OUTPUT_DIR

# Ottieni le prime 20 webcam vicino a Palermo
echo "Recupero le webcam nel raggio di 30 km da Palermo..."
RESPONSE=$(curl -s -H "x-windy-api-key: $API_KEY" \
  "https://api.windy.com/webcams/api/v3/webcams?nearby=$PALERMO_LAT,$PALERMO_LON,$RADIUS&limit=$LIMIT")

# Lista delle webcam specifiche
WEB_CAMS="1665413069 1398172386 1663280572 1663363960 1663364904 1200850755"
# Verifica che ci siano webcam da processare
if [ -z "$WEB_CAMS" ]; then
  echo "Errore: Nessuna webcam specificata"
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
