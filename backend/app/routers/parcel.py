from fastapi import APIRouter, Depends
from sqlalchemy.orm import Session

from backend.app.core.database import get_db
from backend.app.core.security import get_current_user
from backend.app.models.parcel import Parcel
from backend.app.models.user import User
from backend.app.schemas.parcel import ParcelCreate, ParcelResponse

router = APIRouter(prefix="/parcels", tags=["Parcels"])


@router.get("", response_model=list[ParcelResponse])
def list_parcels(
    db: Session = Depends(get_db),
    current_user: User = Depends(get_current_user),
):
    query = db.query(Parcel)
    if current_user.role != "admin":
        query = query.filter(Parcel.owner_id == current_user.id)
    return query.all()


@router.post("", response_model=ParcelResponse)
def create_parcel(
    parcel: ParcelCreate,
    db: Session = Depends(get_db),
    current_user: User = Depends(get_current_user),
):
    new_parcel = Parcel(
        name=parcel.name,
        location=parcel.location,
        soil_type=parcel.soil_type,
        owner_id=current_user.id,
    )
    db.add(new_parcel)
    db.commit()
    db.refresh(new_parcel)
    return new_parcel
