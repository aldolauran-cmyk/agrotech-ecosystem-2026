from backend.app.core.config import get_settings
from backend.app.core.database import SessionLocal
from backend.app.core.security import hash_password
from backend.app.models.user import User


def seed_admin() -> None:
    settings = get_settings()
    if not settings.admin_username or not settings.admin_password:
        return

    db = SessionLocal()
    try:
        existing_admin = (
            db.query(User).filter(User.username == settings.admin_username).first()
        )
        if existing_admin:
            return

        # Corregido: Pasamos "admin" directamente como string para evitar que busque un setting inexistente
        admin = User(
            username=settings.admin_username,
            password=hash_password(settings.admin_password),
            role="admin", 
        )
        db.add(admin)
        db.commit()
    finally:
        db.close()