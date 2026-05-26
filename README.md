# AgroTech Ecosystem 2026

Monorepo para el proyecto AgroTech. Incluye el backend FastAPI, la app móvil Flutter y el entorno de simulación.

### Estructura
agrotech-ecosystem-2026/
├── backend/            # API REST (FastAPI, SQLAlchemy, JWT)
│   └── main.py         # Entry point del backend
├── mobile/             # App móvil (Flutter)
├── iot_industrial/     # Scripts de sensores y telemetría (Python)
├── simulation_godot/   # Plataforma de simulación (Godot Engine)
├── .env.example        # Variables de entorno de referencia
└── .gitignore
## 🖥️ Backend (FastAPI)

### Requisitos
- Python 3.11+

### Instalación
```bash
python -m venv venv
source venv/bin/activate  
pip install -r backend/app/requirements.txt
cp .env.example .env

Configura .env con:

SECRET_KEY (obligatorio)

ADMIN_USERNAME y ADMIN_PASSWORD para sembrar el usuario admin

Ejecutar
Bash
uvicorn backend.main:app --reload
Swagger (API Documentation)
Disponible en http://localhost:8000/docs.

Endpoints principales (v1)
POST /api/v1/token → login JWT

POST /api/v1/users → crear usuario (solo admin)

GET /api/v1/parcels → listar parcelas (admin ve todas)

POST /api/v1/parcels → crear parcela

Documentación detallada
Backend

📱 Mobile (Flutter)
Requisitos
Flutter 3.19+

Ejecutar en Emulador (Android/iOS)
Bash cd mobile
flutter pub get
flutter run --dart-define=API_BASE_URL=[http://10.0.2.2:8000/api/v1](http://10.0.2.2:8000/api/v1)

Ejecutar en Entorno Web (Chrome)
Para pruebas locales en el navegador omitiendo restricciones CORS de origen cruzado:

Bash
cd mobile
flutter pub get
flutter run -d chrome --web-browser-flag "--disable-web-security"

Nota: Asegurarse de que api_constants.dart apunte temporalmente a http://127.0.0.1:8000/api/v1 en modo web.

La app guarda el token en flutter_secure_storage y actualiza la lista de parcelas cada 15s.

Documentación detallada
Mobile

🎮 Simulation (Godot Engine)
Estructura base inicializada en la carpeta simulation_godot/ de acuerdo a los requerimientos del Monorepo. Lógica visual del Gemelo Digital programada para el Hito 2.




---


```powershell
git add .

git commit -m "Docs: Sincronizar README.md oficial con guías del equipo, soporte Web y simulación"

git push origin main
