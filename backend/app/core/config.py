from functools import lru_cache

from pydantic_settings import BaseSettings


class Settings(BaseSettings):
    project_name: str = "AgroTech API"
    version: str = "1.0.0"
    description: str = "Sistema Inteligente de Monitoreo Agricola"

    api_v1_prefix: str = "/api/v1"

    secret_key: str
    algorithm: str = "HS256"
    access_token_expire_minutes: int = 60

    admin_username: str = "admin"
    admin_password: str = "admin123"
    admin_role: str = "admin"

    class Config:
        env_file = "backend/.env"


@lru_cache
def get_settings():
    return Settings()