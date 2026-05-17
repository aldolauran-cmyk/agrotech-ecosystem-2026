from pydantic import BaseModel, Field

class UserCreate(BaseModel):
    username: str
    password: str
    role: str = Field(default="farmer")

class UserResponse(BaseModel):
    id: int
    username: str
    role: str

    class Config:
        from_attributes = True
