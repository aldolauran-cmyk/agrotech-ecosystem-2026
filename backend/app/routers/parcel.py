from fastapi import APIRouter, Depends, HTTPException, status
from sqlalchemy.orm import Session

from backend.app.core.database import get_db
from backend.app.core.security import get_current_user, require_admin
from backend.app.models.parcel import Parcel
from backend.app.models.user import User
from backend.app.schemas.parcel import ParcelCreate, ParcelUpdate, ParcelResponse

# Quitamos el prefijo local para evitar la duplicación con main.py
router = APIRouter(tags=["Parcels"])


@router.get("/parcels", response_model=list[ParcelResponse], summary="Listar parcelas")
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


@router.patch(
    "/parcels/{parcel_id}",
    response_model=ParcelResponse,
    summary="Actualizar parcela (nombre, ubicación, tipo de suelo, reasignar dueño)",
)
def update_parcel(
    parcel_id: int,
    parcel_data: ParcelUpdate,
    db: Session = Depends(get_db),
    current_user: User = Depends(get_current_user),
):
    parcel = db.query(Parcel).filter(Parcel.id == parcel_id).first()
    if not parcel:
        raise HTTPException(status_code=status.HTTP_404_NOT_FOUND, detail="Parcel not found")

    # Solo el dueño o el admin pueden editar
    if current_user.role != "admin" and parcel.owner_id != current_user.id:
        raise HTTPException(status_code=status.HTTP_403_FORBIDDEN, detail="Not enough permissions")

    # Reasignar dueño — solo admin
    if parcel_data.owner_id is not None:
        if current_user.role != "admin":
            raise HTTPException(status_code=status.HTTP_403_FORBIDDEN, detail="Only admins can reassign parcels")
        new_owner = db.query(User).filter(User.id == parcel_data.owner_id).first()
        if not new_owner:
            raise HTTPException(status_code=status.HTTP_404_NOT_FOUND, detail="New owner not found")
        parcel.owner_id = parcel_data.owner_id

    if parcel_data.name is not None:
        parcel.name = parcel_data.name
    if parcel_data.location is not None:
        parcel.location = parcel_data.location
    if parcel_data.soil_type is not None:
        parcel.soil_type = parcel_data.soil_type

    db.commit()
    db.refresh(parcel)
    return parcel


@router.delete(
    "/parcels/{parcel_id}",
    status_code=status.HTTP_204_NO_CONTENT,
    summary="Eliminar parcela (dueño o admin)",
)
def delete_parcel(
    parcel_id: int,
    db: Session = Depends(get_db),
    current_user: User = Depends(get_current_user),
):
    parcel = db.query(Parcel).filter(Parcel.id == parcel_id).first()
    if not parcel:
        raise HTTPException(status_code=status.HTTP_404_NOT_FOUND, detail="Parcel not found")

    if current_user.role != "admin" and parcel.owner_id != current_user.id:
        raise HTTPException(status_code=status.HTTP_403_FORBIDDEN, detail="Not enough permissions")

    db.delete(parcel)
    db.commit()