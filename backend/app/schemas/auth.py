from enum import Enum
from pydantic import BaseModel, Field, EmailStr

class RoleEnum(str, Enum):
    admin = "admin"
    farmer = "farmer"
    user = "user"

class Token(BaseModel):
    access_token: str
    token_type: str

class TokenData(BaseModel):
    username: str | None = None

class UserBase(BaseModel):
    username: str = Field(..., min_length=3, max_length=50)

class UserCreate(UserBase):
    password: str = Field(..., min_length=6)
    role: RoleEnum = RoleEnum.user

class UserResponse(UserBase):
    id: int
    role: str

    class Config:
        from_attributes = True