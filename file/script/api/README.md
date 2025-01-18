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
WEB_CAM_ID="1234567890"  # Sostituisci con un ID valido
curl -s -H "x-windy-api-key: $WINDY_API_KEY" \
  "https://api.windy.com/webcams/api/v3/webcams/$WEB_CAM_ID" | jq
```

## Filtri Utili (da aggiungere alla query)
- `nearby=lat,lon,radius` (es. "45.4642,9.1900,50km")
- `category=category_id` (es. "beach")
- `country=country_code` (es. "IT")
- `limit=numero` (default 10, max 100)
- `offset=numero` (per paginazione)

Esempio con filtri:
```bash
curl -s -H "x-windy-api-key: $WINDY_API_KEY" \
  "https://api.windy.com/webcams/api/v3/webcams?nearby=45.4642,9.1900,50km&limit=3" | jq
```

## Installazione dipendenze
Se non hai curl o jq installati:
```bash
sudo apt-get install curl jq  # Per Debian/Ubuntu
brew install curl jq         # Per macOS
```
