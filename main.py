from fastapi import FastAPI
from backend.app.core.database import Base, engine
import backend.app.models.parcel
from backend.app.routers import auth, parcel as parcel_router, user

app = FastAPI()

Base.metadata.create_all(bind=engine)

app.include_router(user.router)
app.include_router(auth.router)
app.include_router(parcel_router.router)

@app.get("/")
def root():
    return {"message": "API AgroTech funcionando 🚜"}
