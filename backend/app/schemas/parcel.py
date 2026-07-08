from pydantic import BaseModel, Field
from typing import Optional


class ParcelCreate(BaseModel):
    name: str = Field(min_length=2, max_length=100)
    location: str = Field(min_length=2, max_length=120)
    soil_type: str = Field(min_length=2, max_length=60)
    owner_id: int | None = None


class ParcelUpdate(BaseModel):
    name: Optional[str] = Field(default=None, min_length=2, max_length=100)
    location: Optional[str] = Field(default=None, min_length=2, max_length=120)
    soil_type: Optional[str] = Field(default=None, min_length=2, max_length=60)
    owner_id: Optional[int] = None


class ParcelResponse(BaseModel):
    id: int
    name: str
    location: str
    soil_type: str
    owner_id: int
    moisture: float
    ph: float
    temperature: float
    has_water_stress: bool

    class Config:
        from_attributes = True
