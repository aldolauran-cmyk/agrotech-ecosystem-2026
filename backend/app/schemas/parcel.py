from pydantic import BaseModel, Field


class ParcelCreate(BaseModel):
    name: str = Field(min_length=2, max_length=100)
    location: str = Field(min_length=2, max_length=120)
    soil_type: str = Field(min_length=2, max_length=60)
    owner_id: int | None = None


class ParcelResponse(BaseModel):
    id: int
    name: str
    location: str
    soil_type: str
    owner_id: int

    class Config:
        from_attributes = True
