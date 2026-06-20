# Convertisseur PDF fiscal

Ce service transforme le classeur Excel SYSCEBNL genere par l'application en PDF.
Il utilise LibreOffice en mode headless afin que le PDF conserve les feuilles,
formules, zones d'impression et mises en page du fichier Excel officiel.

## Variables

| Variable | Description |
| --- | --- |
| `PORT` | Port HTTP du service. Defaut : `8080`. |
| `ALLOWED_ORIGINS` | Origines CORS autorisees, separees par des virgules. Exemple : `https://app.example.com,http://127.0.0.1:8081`. |
| `SUPABASE_URL` | URL du projet Supabase, requise si `VERIFY_SUPABASE_JWT=true`. |
| `SUPABASE_ANON_KEY` | Cle anon Supabase, requise si `VERIFY_SUPABASE_JWT=true`. |
| `VERIFY_SUPABASE_JWT` | `true` par defaut. Verifie le token utilisateur avec Supabase Auth. |
| `MAX_UPLOAD_BYTES` | Taille maximale du fichier Excel decode. Defaut : `10485760` (10 Mo). |
| `CONVERSION_TIMEOUT_MS` | Delai maximum LibreOffice. Defaut : `60000`. |

## Lancement local

```bash
cd server/fiscal-pdf-converter
npm install
VERIFY_SUPABASE_JWT=false ALLOWED_ORIGINS=http://127.0.0.1:8081 npm start
```

LibreOffice doit etre installe localement et disponible via `soffice`.
Sur Windows uniquement, si `soffice` est absent, le service tente un fallback
Excel COM pour les tests locaux. Ce fallback suppose que Microsoft Excel est
installe sur la machine et ne remplace pas le mode Docker/LibreOffice recommande
en production.

## Docker

```bash
docker build -t eab-fiscal-pdf-converter server/fiscal-pdf-converter
docker run --rm -p 8088:8080 \
  -e ALLOWED_ORIGINS=http://127.0.0.1:8081 \
  -e SUPABASE_URL=https://votre-projet.supabase.co \
  -e SUPABASE_ANON_KEY=votre-anon-key \
  eab-fiscal-pdf-converter
```

Puis compiler le frontend avec :

```bash
flutter build web --release --dart-define=FISCAL_PDF_CONVERTER_URL=http://127.0.0.1:8088
```

Sans cette variable, le bouton PDF bloque volontairement l'export officiel au lieu
de produire un PDF approximatif.

## API

`POST /convert`

Headers :

- `Authorization: Bearer <supabase-access-token>`
- `Content-Type: application/json`

Body :

```json
{
  "filename": "dossier_fiscal_syscebnl_eab_2025.xlsx",
  "xlsxBase64": "..."
}
```

Reponse : `application/pdf`.

`GET /health` retourne l'etat du service.
