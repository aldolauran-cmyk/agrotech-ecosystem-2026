## AgroTech Ecosystem 2026

Monorepo para el proyecto AgroTech. Incluye el backend FastAPI y la app móvil Flutter.

### Estructura

```
agrotech-ecosystem-2026/
├── backend/            # API REST (FastAPI, SQLAlchemy, JWT)
│   └── main.py         # Entry point del backend
├── mobile/             # App móvil (Flutter)
├── .env.example        # Variables de entorno de referencia
└── .gitignore
```

## Backend (FastAPI)

### Requisitos
- Python 3.11+

### Instalación
```bash
python -m venv venv
source venv/bin/activate
pip install -r backend/app/requirements.txt
cp .env.example .env
```

Configura `.env` con:
- `SECRET_KEY` (obligatorio)
- `ADMIN_USERNAME` y `ADMIN_PASSWORD` para sembrar el usuario admin

### Ejecutar
```bash
uvicorn backend.main:app --reload
```

### Swagger
Disponible en `http://localhost:8000/docs`.

### Endpoints principales (v1)
- `POST /api/v1/token` → login JWT
- `POST /api/v1/users` → crear usuario (solo admin)
- `GET /api/v1/parcels` → listar parcelas (admin ve todas)
- `POST /api/v1/parcels` → crear parcela

### Documentación detallada
- [Backend](docs/backend.md)

## Mobile (Flutter)

### Requisitos
- Flutter 3.19+

### Ejecutar
```bash
cd mobile
flutter pub get
flutter run --dart-define=API_BASE_URL=http://10.0.2.2:8000/api/v1
```

La app guarda el token en `flutter_secure_storage` y actualiza la lista de parcelas cada 15s.

### Documentación detallada
- [Mobile](docs/mobile.md)
