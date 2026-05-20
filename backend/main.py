from fastapi import FastAPI
from fastapi.middleware.cors import CORSMiddleware  # <-- 1. Importamos CORS

from backend.app.core.config import get_settings
from backend.app.core.database import Base, engine
from backend.app.core.seed import seed_admin
import backend.app.models.parcel
import backend.app.models.user
from backend.app.routers import auth, parcel as parcel_router, user

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
]

app = FastAPI(
    title=settings.project_name,
    version=settings.version,
    description=settings.description,
    openapi_tags=tags_metadata,
)

# <-- 2. Añadimos el Middleware de CORS justo debajo de definir 'app'
app.add_middleware(
    CORSMiddleware,
    allow_origins=["*"],  # Permite que Chrome reciba datos desde cualquier puerto local
    allow_credentials=True,
    allow_methods=["*"],  # Permite POST, GET, PUT, DELETE, etc.
    allow_headers=["*"],  # Permite enviar el token en las cabeceras (Headers)
)

@app.on_event("startup")
def on_startup():
    Base.metadata.create_all(bind=engine)
    seed_admin()

app.include_router(user.router, prefix=settings.api_v1_prefix)
app.include_router(auth.router, prefix=settings.api_v1_prefix)
app.include_router(parcel_router.router, prefix=settings.api_v1_prefix)

@app.get("/")
def root():
    return {"message": "API AgroTech funcionando 🚜"}
