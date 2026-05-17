from fastapi import APIRouter, Depends, HTTPException, status
from sqlalchemy.orm import Session
from backend.app.core.database import get_db
from backend.app.models.user import User
from backend.app.schemas.user import RoleEnum, UserCreate, UserResponse
from backend.app.core.security import hash_password, require_admin

router = APIRouter(prefix="/users", tags=["Users"])

@router.post(
    "/",
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
