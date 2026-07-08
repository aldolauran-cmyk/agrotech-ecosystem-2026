from fastapi import APIRouter, Depends, HTTPException, status
from sqlalchemy.orm import Session
from backend.app.core.database import get_db
from backend.app.models.user import User
from backend.app.schemas.user import RoleEnum, UserCreate, UserResponse
from backend.app.core.security import hash_password, require_admin, get_current_user

# Corregido: Quitamos el prefijo de aquí porque ya se lo pones en main.py de manera global
router = APIRouter(tags=["Users"])

@router.post(
    "/users", # <-- Ponemos la ruta directa aquí de forma explícita
    response_model=UserResponse,
    status_code=status.HTTP_201_CREATED,
    summary="Crear usuario",
)
def create_user(
    user: UserCreate,
    db: Session = Depends(get_db),
    _current_user: User = Depends(require_admin),
):
    existing_user = db.query(User).filter(User.username == user.username).first()
    if existing_user:
        raise HTTPException(
            status_code=status.HTTP_409_CONFLICT,
            detail="Username already registered",
        )
    new_user = User(
        username=user.username,
        password=hash_password(user.password),
        role=user.role.value if isinstance(user.role, RoleEnum) else user.role,
    )
    db.add(new_user)
    db.commit()
    db.refresh(new_user)
    return new_user


@router.get(
    "/users/me",
    response_model=UserResponse,
    summary="Obtener perfil del usuario autenticado",
)
def read_user_me(
    current_user: User = Depends(get_current_user),
):
    return current_user