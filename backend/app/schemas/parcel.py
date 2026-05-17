from pydantic import BaseModel


class ParcelCreate(BaseModel):
    name: str
    location: str
    soil_type: str


class ParcelResponse(BaseModel):
    id: int
    name: str
    location: str
    soil_type: str
    owner_id: int

    class Config:
        from_attributes = True
