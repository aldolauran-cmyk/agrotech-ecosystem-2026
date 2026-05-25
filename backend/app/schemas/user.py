from enum import Enum
from typing import Optional
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

    # Actualizado al estándar de Pydantic v2
    model_config = {
        "from_attributes": True
    }


# 🚀 CLASES AGREGADAS PARA CORREGIR EL IMPORT ERROR EN AUTH.PY
class Token(BaseModel):
    access_token: str
    token_type: str


class TokenData(BaseModel):
    username: Optional[str] = None
    role: Optional[str] = None