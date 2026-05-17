from functools import lru_cache
from pathlib import Path

from pydantic_settings import BaseSettings, SettingsConfigDict


BASE_DIR = Path(__file__).resolve().parents[3]
ENV_PATH = BASE_DIR / ".env"


class Settings(BaseSettings):
    project_name: str = "AgroTech API"
    version: str = "1.0.0"
    description: str = (
        "API para monitoreo agrícola con autenticación JWT, gestión de parcelas "
        "y telemetría."
    )
    api_v1_prefix: str = "/api/v1"
    secret_key: str
    algorithm: str = "HS256"
    access_token_expire_minutes: int = 60
    admin_username: str | None = None
    admin_password: str | None = None
    admin_role: str = "admin"

    model_config = SettingsConfigDict(
        env_file=str(ENV_PATH),
        env_file_encoding="utf-8",
    )


@lru_cache
def get_settings() -> Settings:
    return Settings()
