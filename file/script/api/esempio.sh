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

# Verifica parametri
if [ "$#" -ne 2 ]; then
    echo "Usage: $0 <latitude> <longitude>"
    echo "Example: $0 38.1295726276908 13.3471925068464"
    exit 1
fi

# Configurazioni
API_KEY=${WINDY_API_KEY}
CENTER_LAT=$1
CENTER_LON=$2
RADIUS=30
LIMIT=20  # Recuperiamo 20 webcam per poi selezionare le 9 più vicine
OUTPUT_DIR="webcam_images_${CENTER_LAT}_${CENTER_LON}"
MOSAIC_OUTPUT="${OUTPUT_DIR}/mosaico_${CENTER_LAT}_${CENTER_LON}.jpg"

# Crea directory output principale
mkdir -p $OUTPUT_DIR

# Ottieni le prime 20 webcam vicino alle coordinate specificate
echo "Recupero le webcam nel raggio di 30 km da ($CENTER_LAT, $CENTER_LON)..."
RESPONSE=$(curl -s -H "x-windy-api-key: $API_KEY" \
  "https://api.windy.com/webcams/api/v3/webcams?nearby=$CENTER_LAT,$CENTER_LON,$RADIUS&limit=$LIMIT")

# Debug: mostra la risposta API
echo "Risposta API:"
echo "$RESPONSE" | jq

# Prima otteniamo i dettagli completi di ogni webcam per estrarre le coordinate
echo "Recupero i dettagli delle webcam per estrarre le coordinate..."
WEB_CAMS_DETAILS=$(for WEB_CAM in $(echo "$RESPONSE" | jq -r '.webcams[].webcamId'); do
  curl -s -H "x-windy-api-key: $API_KEY" \
    "https://api.windy.com/webcams/api/v3/webcams/$WEB_CAM?include=location"
  echo
done | jq -s)

# Seleziona le 9 webcam più vicine con coordinate valide
echo "Seleziono le 9 webcam più vicine con coordinate valide..."
WEB_CAMS=$(echo "$WEB_CAMS_DETAILS" | jq -r --argjson lat "$CENTER_LAT" --argjson lon "$CENTER_LON" '
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
    # Crea sottodirectory per la webcam
    WEB_CAM_DIR="$OUTPUT_DIR/$WEB_CAM"
    mkdir -p "$WEB_CAM_DIR"
    
    # Scarica immagine nella sottodirectory
    curl -s "$IMAGE_URL" -o "$WEB_CAM_DIR/webcam_$WEB_CAM.jpg"
    echo "Scaricata webcam $WEB_CAM"
  else
    echo "Nessuna immagine daylight disponibile per webcam $WEB_CAM"
  fi
done

# Crea mosaico 3x3
echo "Creo mosaico 3x3..."
IMAGES=$(find $OUTPUT_DIR -name "*.jpg" | head -n 9)

if [ -z "$IMAGES" ]; then
  echo "Errore: Nessuna immagine scaricata"
  exit 1
fi

montage $IMAGES -tile 3x3 -geometry +0+0 $MOSAIC_OUTPUT

echo "Mosaico creato con successo: $MOSAIC_OUTPUT"
