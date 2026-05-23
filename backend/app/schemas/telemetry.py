from datetime import datetime
from pydantic import BaseModel


class TelemetryCreate(BaseModel):
    humidity: float
    temperature: float
    ph: float
    parcel_id: int


class TelemetryResponse(TelemetryCreate):
    id: int
    timestamp: datetime

    class Config:
        from_attributes = True