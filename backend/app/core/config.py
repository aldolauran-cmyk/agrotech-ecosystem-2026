from pydantic_settings import BaseSettings

class Settings(BaseSettings):
    project_name: str = "AgroTech Ecosystem API"
    version: str = "1.0.0"
    description: str = "API para el control y simulación de telemetría agrícola IoT"
    api_v1_prefix: str = "/api/v1"
    
    # Configuración de Seguridad y JWT
    secret_key: str = "SUPER_SECRET_KEY_PARA_DESARROLLO_2026_XYZ"
    algorithm: str = "HS256"
    access_token_expire_minutes: int = 60
    
    # Credenciales por defecto para el Administrador
    admin_username: str = "admin"
    admin_password: str = "admin123"
    admin_email: str = "admin@agrotech.com"

    class Config:
        env_file = ".env"
        extra = "ignore"

def get_settings():
    return Settings()