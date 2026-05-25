from fastapi import APIRouter, Depends
from sqlalchemy.orm import Session

from backend.app.core.database import get_db
from backend.app.core.security import get_current_user
from backend.app.models.telemetry import Telemetry
from backend.app.models.user import User  # Importamos para el tipado de current_user
from backend.app.schemas.telemetry import (
    TelemetryCreate,
    TelemetryResponse
)

# Corregido: Quitamos el prefijo local para evitar duplicación con main.py
router = APIRouter(tags=["Telemetry"])


@router.post("/telemetry", response_model=TelemetryResponse)
def create_telemetry(
    telemetry: TelemetryCreate,
    db: Session = Depends(get_db),
    _current_user: User = Depends(get_current_user),  # Protegemos el endpoint con JWT
):
    # Actualizado a model_dump() para compatibilidad total con Pydantic v2
    new_data = Telemetry(**telemetry.model_dump())

    db.add(new_data)
    db.commit()
    db.refresh(new_data)

    return new_data


@router.get("/telemetry/{parcel_id}", response_model=list[TelemetryResponse])
def get_telemetry(
    parcel_id: int,
    db: Session = Depends(get_db),
    _current_user: User = Depends(get_current_user),  # Protegemos la consulta
):
    return (
        db.query(Telemetry)
        .filter(Telemetry.parcel_id == parcel_id)
        .all()
    )