# Windy Webcams API - Guida Base per CLI

Questa guida mostra come usare l'API di Windy Webcams direttamente da terminale usando `curl` e `jq`.

## Prerequisiti
- `curl` installato
- `jq` installato (per formattare il JSON)
- API key di Windy (ottenibile da https://api.windy.com/keys)

## Configurazione
Esporta la tua API key:
```bash
export WINDY_API_KEY="your_api_key_here"
```

## Esempi Base

### 1. Ottenere l'elenco delle webcam (limite 5)
```bash
curl -s -H "x-windy-api-key: $WINDY_API_KEY" \
  "https://api.windy.com/webcams/api/v3/webcams?limit=5" | jq
```

### 2. Ottenere informazioni su una specifica webcam (usa un ID dall'elenco precedente)
```bash
WEB_CAM_ID="1665404395"  # Sostituisci con un ID valido
curl -s -H "x-windy-api-key: $WINDY_API_KEY" \
  "https://api.windy.com/webcams/api/v3/webcams/$WEB_CAM_ID" | jq
```

### 3. Ottenere informazioni complete su Piazza San Babila, Milano (ID 1665404395)
```bash
curl -s -H "x-windy-api-key: $WINDY_API_KEY" \
  "https://api.windy.com/webcams/api/v3/webcams/1665404395?lang=en&include=categories,images,location,player,urls" | jq
```

### 4. Ottenere solo le informazioni sulle immagini
```bash
curl -s -H "x-windy-api-key: $WINDY_API_KEY" \
  "https://api.windy.com/webcams/api/v3/webcams/1665404395?include=images" | \
  jq '.images'
```

Questo restituirà:
- URL delle immagini correnti (icon, thumbnail, preview)
- Dimensioni delle immagini
- URL delle immagini diurne
- Token di autenticazione per accedere alle immagini

### 5. Ottenere URL delle immagini correnti
```bash
curl -s -H "x-windy-api-key: $WINDY_API_KEY" \
  "https://api.windy.com/webcams/api/v3/webcams/1665404395?include=images" | \
  jq '.images.current'
```

### 6. Scaricare e salvare un'immagine
```bash
# Ottieni l'URL dell'immagine preview
IMAGE_URL=$(curl -s -H "x-windy-api-key: $WINDY_API_KEY" \
  "https://api.windy.com/webcams/api/v3/webcams/1665404395?include=images" | \
  jq -r '.images.current.preview')

# Scarica e salva l'immagine
curl -s "$IMAGE_URL" -o milano_san_babila.jpg

echo "Immagine salvata come milano_san_babila.jpg"
```

Questo esempio:
1. Recupera l'URL dell'immagine preview
2. Scarica l'immagine usando curl
3. La salva come file JPG

## Filtri Utili (da aggiungere alla query)
- `nearby=lat,lon,radius` (es. "45.4642,9.1900,50") - radius è in kilometri
- `category=category_id` (es. "beach")
- `country=country_code` (es. "IT")
- `limit=numero` (default 10, max 100)
- `offset=numero` (per paginazione)

Esempio con filtri:

1. Webcam nel raggio di 30 km dal centro di Palermo (38.1157,13.3615):
```bash
curl -s -H "x-windy-api-key: $WINDY_API_KEY" \
  "https://api.windy.com/webcams/api/v3/webcams?nearby=38.1157,13.3615,30" | jq
```

2. Webcam nel raggio di 50 km da Milano (45.4642,9.1900), limite 3 risultati:
```bash
curl -s -H "x-windy-api-key: $WINDY_API_KEY" \
  "https://api.windy.com/webcams/api/v3/webcams?nearby=45.4642,9.1900,50&limit=3" | jq
```

## Installazione dipendenze
Se non hai curl o jq installati:
```bash
sudo apt-get install curl jq  # Per Debian/Ubuntu
brew install curl jq         # Per macOS
```
