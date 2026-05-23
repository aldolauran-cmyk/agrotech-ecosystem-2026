from fastapi import APIRouter, Depends
from sqlalchemy.orm import Session

from backend.app.core.database import get_db
from backend.app.core.security import get_current_user
from backend.app.models.telemetry import Telemetry
from backend.app.schemas.telemetry import (
    TelemetryCreate,
    TelemetryResponse
)

router = APIRouter(prefix="/telemetry", tags=["Telemetry"])


@router.post("", response_model=TelemetryResponse)
def create_telemetry(
    telemetry: TelemetryCreate,
    db: Session = Depends(get_db),
):
    new_data = Telemetry(**telemetry.dict())

    db.add(new_data)
    db.commit()
    db.refresh(new_data)

    return new_data


@router.get("/{parcel_id}", response_model=list[TelemetryResponse])
def get_telemetry(
    parcel_id: int,
    db: Session = Depends(get_db),
):
    return (
        db.query(Telemetry)
        .filter(Telemetry.parcel_id == parcel_id)
        .all()
    )