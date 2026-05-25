from fastapi import APIRouter, Depends, HTTPException, status
from sqlalchemy.orm import Session

from backend.app.core.database import get_db
from backend.app.core.security import get_current_user
from backend.app.models.parcel import Parcel
from backend.app.models.user import User
from backend.app.schemas.parcel import ParcelCreate, ParcelResponse

# Corregido: Quitamos el prefijo local para evitar la duplicación con main.py
router = APIRouter(tags=["Parcels"])


@router.get("/parcels", response_model=list[ParcelResponse])
def list_parcels(
    db: Session = Depends(get_db),
    current_user: User = Depends(get_current_user),
):
    query = db.query(Parcel)
    if current_user.role != "admin":
        query = query.filter(Parcel.owner_id == current_user.id)
    return query.all()


@router.post(
    "/parcels",
    response_model=ParcelResponse,
    status_code=status.HTTP_201_CREATED,
    summary="Crear parcela",
)
def create_parcel(
    parcel: ParcelCreate,
    db: Session = Depends(get_db),
    current_user: User = Depends(get_current_user),
):
    owner_id = current_user.id
    if current_user.role == "admin" and parcel.owner_id:
        owner = db.query(User).filter(User.id == parcel.owner_id).first()
        if not owner:
            raise HTTPException(
                status_code=status.HTTP_404_NOT_FOUND,
                detail="Owner not found",
            )
        owner_id = owner.id
    new_parcel = Parcel(
        name=parcel.name,
        location=parcel.location,
        soil_type=parcel.soil_type,
        owner_id=owner_id,
    )
    db.add(new_parcel)
    db.commit()
    db.refresh(new_parcel)
    return new_parcel