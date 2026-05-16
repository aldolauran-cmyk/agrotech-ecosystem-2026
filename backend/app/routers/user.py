from fastapi import APIRouter, Depends
from sqlalchemy.orm import Session
from backend.app.core.database import SessionLocal
from backend.app.models.user import User
from backend.app.schemas.user import UserCreate, UserResponse
from backend.app.core.security import hash_password

router = APIRouter(prefix="/users", tags=["Users"])

def get_db():
    db = SessionLocal()
    try:
        yield db
    finally:
        db.close()

@router.post("/", response_model=UserResponse)
def create_user(user: UserCreate, db: Session = Depends(get_db)):
    new_user = User(
        username=user.username,
        password=hash_password(user.password)
    )
    db.add(new_user)
    db.commit()
    db.refresh(new_user)
    return new_user
