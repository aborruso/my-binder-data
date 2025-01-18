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

# Debug: mostra la risposta API
echo "Risposta API:"
echo "$RESPONSE" | jq

# Seleziona le 9 webcam più vicine con coordinate valide
echo "Seleziono le 9 webcam più vicine con coordinate valide..."
WEB_CAMS=$(echo "$RESPONSE" | jq -r --argjson lat "$PALERMO_LAT" --argjson lon "$PALERMO_LON" '
  .webcams | 
  map(select(.location.latitude != null and .location.longitude != null)) |
  sort_by(((.location.latitude - $lat) | tonumber | . * .) + 
          ((.location.longitude - $lon) | tonumber | . * .)) | 
  .[0:9] | .[].webcamId
')

# Debug: mostra le webcam selezionate
echo "Webcam selezionate:"
echo "$WEB_CAMS"

# Verifica che ci siano webcam da processare
if [ -z "$WEB_CAMS" ]; then
  echo "Errore: Nessuna webcam trovata con coordinate valide"
  echo "Risposta API:"
  echo "$RESPONSE" | jq
  exit 1
fi

# Scarica le immagini daylight
echo "Scarico le immagini daylight..."
for WEB_CAM in $WEB_CAMS; do
  echo "Processo webcam $WEB_CAM..."
  
  # Ottieni i dettagli della webcam
  WEB_CAM_DATA=$(curl -s -H "x-windy-api-key: $API_KEY" \
    "https://api.windy.com/webcams/api/v3/webcams/$WEB_CAM?include=images")
  
  # Debug: mostra i dati della webcam
  echo "$WEB_CAM_DATA" | jq
  
  # Estrai URL immagine daylight
  IMAGE_URL=$(echo "$WEB_CAM_DATA" | jq -r '.images.daylight.preview?')
  
  # Se non c'è immagine daylight, usa l'immagine corrente
  if [ "$IMAGE_URL" == "null" ] || [ -z "$IMAGE_URL" ]; then
    IMAGE_URL=$(echo "$WEB_CAM_DATA" | jq -r '.images.current.preview?')
  fi
  
  if [ "$IMAGE_URL" != "null" ]; then
    echo "Scarico immagine da $IMAGE_URL"
    curl -s "$IMAGE_URL" -o "$OUTPUT_DIR/webcam_$WEB_CAM.jpg"
    echo "Scaricata webcam $WEB_CAM"
  else
    echo "Nessuna immagine daylight disponibile per webcam $WEB_CAM"
  fi
done

# Crea mosaico 3x3
echo "Creo mosaico 3x3..."
IMAGES=$(ls $OUTPUT_DIR/*.jpg 2>/dev/null | head -n 9)

if [ -z "$IMAGES" ]; then
  echo "Errore: Nessuna immagine scaricata"
  exit 1
fi

montage $IMAGES -tile 3x3 -geometry +0+0 $MOSAIC_OUTPUT

echo "Mosaico creato con successo: $MOSAIC_OUTPUT"
