from contextlib import asynccontextmanager
from fastapi import FastAPI
from fastapi.middleware.cors import CORSMiddleware

from backend.app.core.config import get_settings
from backend.app.core.database import Base, engine
from backend.app.core.seed import seed_admin
from backend.app.core.mqtt import start_mqtt_listener, stop_mqtt_listener
import backend.app.models.parcel
import backend.app.models.user
import backend.app.models.telemetry  # Aseguramos la importación del modelo de telemetría
from backend.app.routers import auth, parcel as parcel_router, user, telemetry

settings = get_settings()

tags_metadata = [
    {
        "name": "Auth",
        "description": "Autenticación y emisión de tokens JWT.",
    },
    {
        "name": "Users",
        "description": "Gestión de usuarios (solo administradores).",
    },
    {
        "name": "Parcels",
        "description": "Registro y consulta de parcelas agrícolas.",
    },
    {
        "name": "Telemetry",
        "description": "Recepción y consulta de datos de sensores IoT.",
    },
]

# Corregido: Usamos lifespan para manejar el encendido del servidor de forma moderna
@asynccontextmanager
async def lifespan(app: FastAPI):
    # Rompe las tablas viejas y crea unas limpias con los datos actuales
    Base.metadata.drop_all(bind=engine)
    Base.metadata.create_all(bind=engine)
    seed_admin()
    # Encendemos el oyente MQTT en segundo plano si está habilitado
    if settings.enable_mqtt_listener:
        start_mqtt_listener()
    yield
    # Apagamos el oyente MQTT de forma segura si está habilitado
    if settings.enable_mqtt_listener:
        stop_mqtt_listener()

app = FastAPI(
    title=settings.project_name,
    version=settings.version,
    description=settings.description,
    openapi_tags=tags_metadata,
    lifespan=lifespan,  # Pasamos el manejador de ciclo de vida aquí
)

# Middleware de CORS para permitir la conexión del simulador y frontend
app.add_middleware(
    CORSMiddleware,
    allow_origins=["*"],
    allow_credentials=True,
    allow_methods=["*"],
    allow_headers=["*"],
)

# Registro de routers bajo el prefijo global (/api/v1)
app.include_router(user.router, prefix=settings.api_v1_prefix)
app.include_router(auth.router, prefix=settings.api_v1_prefix)
app.include_router(parcel_router.router, prefix=settings.api_v1_prefix)
app.include_router(telemetry.router, prefix=settings.api_v1_prefix)

@app.get("/")
def root():
    return {"message": "API AgroTech funcionando 🚜"}