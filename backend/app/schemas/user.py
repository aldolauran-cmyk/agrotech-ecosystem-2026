from enum import Enum

from pydantic import BaseModel, Field


class RoleEnum(str, Enum):
    admin = "admin"
    farmer = "farmer"
    viewer = "viewer"

class UserCreate(BaseModel):
    username: str = Field(min_length=3, max_length=50)
    password: str = Field(min_length=6, max_length=128)
    role: RoleEnum = Field(default=RoleEnum.farmer)

class UserResponse(BaseModel):
    id: int
    username: str
    role: RoleEnum

    class Config:
        from_attributes = True
