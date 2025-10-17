# Tasks API

API de gestion de tâches avec FastAPI et PostgreSQL.

## Configuration

1. Copiez le fichier `.env.example` vers `.env` :
   ```bash
   cp .env.example .env
   ```

2. Modifiez les valeurs dans `.env` selon vos besoins, notamment :
   - `BEARER_TOKEN` : Token d'authentification pour sécuriser l'API
   - `DATABASE_*` : Configuration de la base de données PostgreSQL

## Authentification

Toutes les routes de l'API (sauf `/health` et `/metrics`) nécessitent une authentification par Bearer token.

### Headers requis

Chaque requête doit inclure les headers suivants :

```
Authorization: Bearer <votre-token>
Correlation-Id: <id-unique-de-correlation>
```

### Exemple avec curl

```bash
curl -X GET http://localhost:8443/tasks \
  -H "Authorization: Bearer your-secret-token-here" \
  -H "Correlation-Id: 12345-67890"
```

### Exemple avec Python requests

```python
import requests

headers = {
    "Authorization": "Bearer your-secret-token-here",
    "Correlation-Id": "12345-67890"
}

response = requests.get("http://localhost:8443/tasks", headers=headers)
print(response.json())
```

## Installation

1. Installez les dépendances :
   ```bash
   pip install -r requirements.txt
   ```

2. Assurez-vous que PostgreSQL est démarré :
   ```bash
   sudo systemctl start postgresql
   ```

3. Lancez l'application :
   ```bash
   python3 run_server.py
   ```

## Endpoints

### Santé de l'application
- `GET /health` - Vérification de l'état de l'application (pas d'authentification requise)
- `GET /metrics` - Métriques Prometheus (pas d'authentification requise)

### Gestion des tâches (authentification requise)
- `POST /tasks` - Créer une nouvelle tâche
- `GET /tasks` - Lister toutes les tâches
- `GET /tasks/{id}` - Récupérer une tâche spécifique
- `PUT /tasks/{id}` - Mettre à jour une tâche
- `DELETE /tasks/{id}` - Supprimer une tâche

## Sécurité

⚠️ **Important** : En production, changez le `BEARER_TOKEN` par une valeur sécurisée et aléatoire. Vous pouvez générer un token sécurisé avec :

```bash
python3 -c "import secrets; print(secrets.token_urlsafe(32))"
```
